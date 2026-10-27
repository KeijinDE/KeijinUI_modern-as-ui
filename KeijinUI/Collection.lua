-- A diary of native item observations, not an invented complete item catalogue.
local K=KeijinUI
local C={slots={2,11,12,13,14},offset=0,query=""}
K.collection=C
local scan
local function Store()
    local db=K.DB(); if type(db.itemDiary)~="table" then db.itemDiary={} end
    return db.itemDiary
end
function C.NativeLines(slot)
    if not scan then
        scan=CreateFrame("GameTooltip","KeijinUICollectionScan",UIParent,"GameTooltipTemplate")
    end
    if not scan.SetInventoryItem then return {} end
    scan:SetOwner(UIParent,"ANCHOR_NONE")
    if scan.ClearLines then scan:ClearLines() end
    scan:SetInventoryItem("player",slot)
    local lines={}
    local n=scan.NumLines and scan:NumLines() or 0
    for i=1,math.min(30,n) do
        local left=getglobal("KeijinUICollectionScanTextLeft"..i)
        local right=getglobal("KeijinUICollectionScanTextRight"..i)
        local a=left and left:GetText(); local b=right and right:GetText()
        if a and a~="" then table.insert(lines,string.sub(a,1,300)) end
        if b and b~="" then table.insert(lines,string.sub(b,1,300)) end
    end
    scan:Hide(); return lines
end
local function Key(entry)
    if entry.item or entry.link then
        local _,_,item=string.find(entry.item or entry.link,"(item:[^|]+)")
        if item then return item end
    end
    if type(entry.name)=="string" and entry.name~="" then return "name:"..entry.name end
end
function C.Observe(entry,found,lines)
    if not K.ModuleOn("collection") or K.DB().collectionRecord==false then return end
    local key=Key(entry); if not key then return end
    local db=Store(); local count=0; for _ in pairs(db) do count=count+1 end
    if not db[key] and count>=500 then return end
    local e=db[key] or {name=entry.name or "?",finds=0,variants={},ranges={}}
    e.name=entry.name or e.name; e.link=entry.item or entry.link or e.link; e.icon=entry.icon or e.icon
    e.finds=e.finds+(found and 1 or 0); e.observed=true
    if type(lines)=="table" and table.getn(lines)>0 then
        local joined=table.concat(lines,"\n")
        e.lines=lines
        local exists=false; for _,v in ipairs(e.variants) do if v==joined then exists=true end end
        if not exists and table.getn(e.variants)<12 then table.insert(e.variants,joined) end
        for _,line in ipairs(lines) do
            local shape=string.gsub(line,"[%+%-]?%d+%.?%d*","#")
            local values={}; for number in string.gfind(line,"[%+%-]?%d+%.?%d*") do table.insert(values,tonumber(number)) end
            if table.getn(values)>0 then
                local ranges=e.ranges[shape] or {}
                for i,value in ipairs(values) do
                    local r=ranges[i] or {min=value,max=value}; r.min=math.min(r.min,value); r.max=math.max(r.max,value); ranges[i]=r
                end
                e.ranges[shape]=ranges
            end
        end
    end
    db[key]=e; return e
end
function C.List(query)
    query=string.lower(query or "")
    local list={}
    for key,e in pairs(Store()) do
        if type(e)=="table" and (query=="" or string.find(string.lower((e.name or "").."\n"..table.concat(e.lines or {},"\n")),query,1,true)) then
            table.insert(list,{key=key,item=e})
        end
    end
    table.sort(list,function(a,b) if a.item.name~=b.item.name then return a.item.name<b.item.name end return a.key<b.key end)
    return list
end
function C.Detail(e)
    local lines={K.T("Beobachtete Funde: %s",e.finds or 0)}
    for _,line in ipairs(e.lines or {}) do table.insert(lines,line) end
    local shapes={}; for shape in pairs(e.ranges or {}) do table.insert(shapes,shape) end; table.sort(shapes)
    for _,shape in ipairs(shapes) do
        local index=0
        local text=string.gsub(shape,"#",function()
            index=index+1; local r=e.ranges[shape][index]
            return r and (r.min==r.max and tostring(r.min) or tostring(r.min).."–"..tostring(r.max)) or "?"
        end)
        table.insert(lines,K.T("Beobachteter Bereich: %s",text))
    end
    if not e.link then table.insert(lines,K.T("Nur Name bekannt; genaue Gegenstandsvariante unbekannt.")) end
    return table.concat(lines,"\n")
end
function C.CooldownsOn() return K.ModuleOn("collection") and K.DB().jewelryCooldowns~=false end
function C.Cooldown(slot)
    if type(GetInventoryItemCooldown)~="function" then return end
    local start,duration,enabled=GetInventoryItemCooldown("player",slot)
    if enabled==0 or not K.Number(start) or not K.Number(duration) or duration<=0 then return end
    return math.max(0,start+duration-GetTime())
end
local panel=K.Panel("KeijinUICollection","Schmucksammlung",560,420); C.panel=panel
panel:SetPoint("CENTER",UIParent,"CENTER",0,0); panel:SetFrameStrata("DIALOG"); panel:Hide()
table.insert(UISpecialFrames,"KeijinUICollection")
local search=CreateFrame("EditBox",nil,panel); C.search=search
search:SetPoint("TOPLEFT",panel,"TOPLEFT",14,-38); search:SetWidth(460); search:SetHeight(26)
K.SetFontSize(search,12); search:SetAutoFocus(false); K.fontStrings=K.fontStrings or {}; table.insert(K.fontStrings,{search,12}); K.Skin(search,4)
search:SetScript("OnTextChanged",function() C.query=search:GetText() or ""; C.offset=0; C.Render() end)
search:SetScript("OnEscapePressed",function() search:ClearFocus() end)
local close=CreateFrame("Button",nil,panel); close:SetWidth(28); close:SetHeight(24); close:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-10,-6)
K.Text(close,"×",13,"CENTER",0,0); close:SetScript("OnClick",function() panel:Hide() end)
local rows={}
for i=1,10 do
    local row=K.ValueRow(panel,i,27); row:ClearAllPoints(); row:SetPoint("TOPLEFT",panel,"TOPLEFT",12,-72-(i-1)*29)
    row.label:SetWidth(395); row.value:SetWidth(110); rows[i]=row
end
local footer=K.LText(panel,"Nur beobachtete Funde. Nicht beobachtete Gegenstände und Werte bleiben unbekannt.",10,"BOTTOMLEFT",14,14,530)
footer:SetHeight(30)
panel:EnableMouseWheel(true); panel:SetScript("OnMouseWheel",function() C.offset=math.max(0,C.offset+(arg1>0 and -1 or 1)); C.Render() end)
function C.Render()
    local list=C.List(C.query); C.offset=math.min(C.offset,math.max(0,table.getn(list)-10))
    for i,row in ipairs(rows) do
        local v=list[i+C.offset]
        if v then
            row.label:SetText(v.item.name); row.value:SetText(K.T("%s Funde",v.item.finds or 0))
            row.tip=v.item.name; row.detail=C.Detail(v.item); row:Show()
        else row:Hide() end
    end
end
function C.Toggle() if not K.ModuleOn("collection") then panel:Hide(); return end; if panel:IsShown() then panel:Hide() else C.Render(); panel:Show() end end
-- Equipped gear is sampled by native inventory slot and native tooltip, never fictional run ranks.
local elapsed=0
local driver=CreateFrame("Frame")
C.driver=driver
driver:SetScript("OnUpdate",function()
    elapsed=elapsed+(tonumber(arg1) or 0); if elapsed<2 then return end; elapsed=0
    if K.DB().collectionRecord==false then return end
    for _,slot in ipairs(C.slots) do
        local link=GetInventoryItemLink and GetInventoryItemLink("player",slot)
        if link then
            local _,_,name=string.find(link,"|h%[(.-)%]|h")
            C.Observe({link=link,name=name,icon=GetInventoryItemTexture("player",slot)},false,C.NativeLines(slot))
        end
    end
    if panel:IsShown() then C.Render() end
end)
