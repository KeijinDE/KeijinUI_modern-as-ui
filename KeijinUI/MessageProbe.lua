-- Temporary observation only. No hooks, events or timer while idle.
local K=KeijinUI
local P={active=false,budget=200}
K.messageProbe=P
local driver=CreateFrame("Frame","KeijinUIMessageProbe",UIParent)
P.driver=driver
local function Short(value,limit)
    return string.sub(string.gsub(tostring(value or ""),"[\r\n]"," "),1,limit or 240)
end
local function Say(text)
    DEFAULT_CHAT_FRAME:AddMessage("[KeijinUI probe] "..text)
end
local function Record(source,text,details)
    if not P.active then return end
    local rows=K.DB().messageProbe
    if type(rows)~="table" then rows={}; K.DB().messageProbe=rows end
    local row=details or {}
    row.time=GetTime(); row.elapsed=row.time-P.started
    row.source=source; row.text=Short(text)
    if table.getn(rows)>=200 then table.remove(rows,1) end
    table.insert(rows,row); P.count=P.count+1
    local extra=""
    if row.path then
        extra=" path="..row.path.." rgba="..table.concat(row.color,",")
            .." font="..table.concat(row.font,",").." xy="..table.concat(row.position,",")
            .." visible="..tostring(row.visible).." strata="..row.strata.." level="..row.level
    end
    Say(string.format("%.2f %s %s%s",row.elapsed,source,row.text,extra))
end
local function Describe(object,path)
    local r,g,b,a,f,size,flags,x,y
    if object.GetTextColor then r,g,b,a=object:GetTextColor() end
    if object.GetFont then f,size,flags=object:GetFont() end
    if object.GetCenter then x,y=object:GetCenter() end
    local parent=object
    if not parent.GetFrameStrata and parent.GetParent then parent=parent:GetParent() end
    return {path=path,color={tostring(r),tostring(g),tostring(b),tostring(a)},
        font={tostring(f),tostring(size),tostring(flags)},position={tostring(x),tostring(y)},
        visible=object.IsVisible and object:IsVisible() or false,
        strata=tostring(parent and parent.GetFrameStrata and parent:GetFrameStrata()),
        level=tostring(parent and parent.GetFrameLevel and parent:GetFrameLevel())}
end
local function Hook(target,key,label,textIndex)
    local original=target[key]
    if type(original)~="function" then return end
    -- Factory parameters, never a closure over a loop variable (Lua 5.0).
    local wrapper=function(...)
        if P.active then pcall(Record,label,arg[textIndex]) end
        return original(unpack(arg))
    end
    target[key]=wrapper
    table.insert(P.hooks,{target=target,key=key,original=original,wrapper=wrapper})
end
local function Banner(b)
    if type(b)=="table" then
        pcall(Record,"banner:"..Short(b.kind,40),b.text,{kind=Short(b.kind,40),boss=b.boss})
    end
end
local function OnEvent()
    if event=="CHAT_MSG_ADDON" then
        pcall(Record,event,Short(arg1,40).." "..Short(arg2,160))
    else pcall(Record,event,arg1) end
end
local function Match(text)
    if type(text)~="string" then return false end
    -- The chat also lives below UIParent. Never capture our own output again.
    if string.find(text,"[KeijinUI probe]",1,true) then return false end
    text=string.lower(text)
    for _,word in ipairs({"truhe","gold","naht","besiegt","chest","needs"}) do
        if string.find(text,word,1,true) then return true end
    end
    return false
end
local function Push(object,path,depth)
    if not object or P.visited[object] or depth>64 then return end
    P.visited[object]=true
    local name=object.GetName and object:GetName()
    table.insert(P.stack,{object=object,path=name or path,depth=depth,phase=0,index=1})
end
local function Scan()
    if table.getn(P.stack)==0 then
        P.visited={}; Push(WorldFrame,"WorldFrame",0); Push(UIParent,"UIParent",0)
    end
    P.lastWork=0
    -- One node, region or child per step. Lists are consumed incrementally.
    while P.lastWork<P.budget and table.getn(P.stack)>0 do
        P.lastWork=P.lastWork+1
        local top=P.stack[table.getn(P.stack)]
        local object=top.object
        if top.phase==0 then
            -- Regions may lack IsVisible in this client; IsShown is the fallback.
            local visible
            if object.IsVisible then visible=object:IsVisible() elseif object.IsShown then visible=object:IsShown() end
            if not visible then table.remove(P.stack)
            else
                if object.GetObjectType and object:GetObjectType()=="FontString" then
                    local text=object.GetText and object:GetText()
                    if Match(text) then
                        local key=top.path.."\n"..text
                        if not P.seen[key] then
                            P.seen[key]=true; Record("scan",text,Describe(object,top.path))
                        end
                    end
                end
                top.phase=1; top.list=object.GetRegions and {object:GetRegions()} or {}
            end
        elseif top.index<=table.getn(top.list) then
            local index=top.index; top.index=index+1
            Push(top.list[index],top.path..(top.phase==1 and "/region[" or "/child[")..index.."]",top.depth+1)
        elseif top.phase==1 then
            top.phase=2; top.index=1; top.list=object.GetChildren and {object:GetChildren()} or {}
        else table.remove(P.stack) end
    end
end
function P.Stop()
    if not P.active then return end
    P.active=false
    driver:SetScript("OnUpdate",nil); driver:SetScript("OnEvent",nil); driver:UnregisterAllEvents()
    for _,h in ipairs(P.hooks) do
        -- Do not overwrite a hook installed by another addon during the probe.
        if h.target[h.key]==h.wrapper then h.target[h.key]=h.original end
    end
    if P.raidWrapper and RaidNotice_AddMessage==P.raidWrapper then RaidNotice_AddMessage=P.raidOriginal end
    P.raidWrapper=nil; P.raidOriginal=nil
    if P.unregister then P.unregister(Banner) end
    P.hooks={}; P.stack={}; P.seen={}; P.visited={}; P.unregister=nil
    Say("off: "..P.count.." entries, "..table.getn(K.DB().messageProbe or {}).." saved (max 200).")
end
local function Tick()
    if not P.active then return end
    if GetTime()-P.started>=120 then P.Stop(); return end
    P.elapsed=P.elapsed+(tonumber(arg1) or 0)
    if P.elapsed<.25 then return end
    -- A scan error must end the probe, not spam errors every frame.
    P.elapsed=0; if not pcall(Scan) then Say("scan failed, stopping."); P.Stop() end
end
function P.Toggle()
    if P.active then P.Stop(); return end
    P.active=true; P.started=GetTime(); P.elapsed=0; P.count=0
    P.hooks={}; P.stack={}; P.seen={}; P.visited={}
    K.DB().messageProbe={}
    if UIErrorsFrame then Hook(UIErrorsFrame,"AddMessage","UIErrorsFrame:AddMessage",2) end
    if RaidWarningFrame then Hook(RaidWarningFrame,"AddMessage","RaidWarningFrame:AddMessage",2) end
    if RaidBossEmoteFrame then Hook(RaidBossEmoteFrame,"AddMessage","RaidBossEmoteFrame:AddMessage",2) end
    if type(RaidNotice_AddMessage)=="function" then
        -- Global access through the client API, without _G.
        local original=RaidNotice_AddMessage
        P.raidOriginal=original
        P.raidWrapper=function(...)
            if P.active then pcall(Record,"RaidNotice_AddMessage",arg[2]) end
            return original(unpack(arg))
        end
        RaidNotice_AddMessage=P.raidWrapper
    end
    for _,name in ipairs({"ZoneTextString","SubZoneTextString","PVPInfoTextString","PVPArenaTextString"}) do
        local object=getglobal(name)
        if object then Hook(object,"SetText",name..":SetText",2) end
    end
    for _,name in ipairs({"UI_ERROR_MESSAGE","UI_INFO_MESSAGE","SYSMSG","CHAT_MSG_RAID_BOSS_EMOTE",
        "CHAT_MSG_MONSTER_EMOTE","CHAT_MSG_SYSTEM","CHAT_MSG_ADDON"}) do driver:RegisterEvent(name) end
    if type(AZS_RegisterBannerHandler)=="function" and type(AZS_UnregisterBannerHandler)=="function" then
        P.unregister=AZS_UnregisterBannerHandler; AZS_RegisterBannerHandler(Banner)
    end
    driver:SetScript("OnEvent",OnEvent); driver:SetScript("OnUpdate",Tick)
    Say("on for 120s. Trigger chest / gold / boss messages; repeat command to stop.")
end
