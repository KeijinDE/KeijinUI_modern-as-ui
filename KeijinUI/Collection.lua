-- A diary of native item observations, not an invented complete item catalogue.
local K=KeijinUI
local C={slots={2,11,12,13,14},offset=0,query=""}
K.collection=C
local scan
local revision=0
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
    local name,link,icon=entry.name or e.name,entry.item or entry.link or e.link,entry.icon or e.icon
    local hasLines=type(lines)=="table" and table.getn(lines)>0
    if db[key] and not found and e.name==name and e.link==link and e.icon==icon
        and (not hasLines or table.concat(e.lines or {},"\n")==table.concat(lines,"\n")) then return e end
    e.name=name; e.link=link; e.icon=icon
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
    db[key]=e; revision=revision+1
    if C.panel and C.panel:IsShown() and not C.scanning then C.Render() end
    return e
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
panel:SetFrameStrata("DIALOG"); panel:SetMovable(true); panel:EnableMouse(true); panel:Hide()
-- Like settings, a browser dialog stays opaque even with a transparent HUD.
panel.noOpacity=true; panel:SetBackdropColor(.045,.045,.05,1)
local function Coordinate(value) return type(value)=="number" and value==value and math.abs(value)<1e15 end
local function RestorePosition()
    local saved=K.DB().collectionPosition
    panel:ClearAllPoints()
    if type(saved)=="table" and saved.point and saved.relative and Coordinate(saved.x) and Coordinate(saved.y) then
        panel:SetPoint(saved.point,UIParent,saved.relative,saved.x,saved.y)
    else panel:SetPoint("CENTER",UIParent,"CENTER",0,0) end
end
RestorePosition()
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then RestorePosition() end end)
-- Keep complete window trees together. Raising just the parent leaves the row
-- text frames above a neighbouring window on clients with fixed child levels.
local windows={}
local hooked={}
local function Tree(frame,list,base)
    table.insert(list,{frame=frame,offset=math.max(0,frame:GetFrameLevel()-base)})
    for _,child in ipairs({frame:GetChildren()}) do Tree(child,list,base) end
end
function C.Focus(root)
    if not panel:IsShown() then return end
    local ordered={}
    for _,window in ipairs(windows) do if window~=root then table.insert(ordered,window) end end
    table.insert(ordered,root); windows=ordered
    local trees={}
    for _,window in ipairs(windows) do
        local tree={}; Tree(window,tree,window:GetFrameLevel()); table.insert(trees,tree)
    end
    if root.Raise then root:Raise() end
    local level=10
    for _,tree in ipairs(trees) do
        local span=0
        for _,entry in ipairs(tree) do
            entry.frame:SetFrameLevel(level+entry.offset); span=math.max(span,entry.offset)
        end
        level=level+span+2
    end
end
local function HookFocus(frame,root)
    if not hooked[frame] then
        hooked[frame]=true
        K.windowTools.Hook(frame,"OnMouseDown",function() C.Focus(root) end)
    end
    for _,child in ipairs({frame:GetChildren()}) do HookFocus(child,root) end
end
local function InstallFocus()
    for _,window in ipairs({getglobal("KeijinUIOptions"),getglobal("KeijinUIRuns"),panel}) do
        if window and not window.collectionFocus then
            window.collectionFocus=true; table.insert(windows,window)
            if window.SetToplevel then window:SetToplevel(true) end
            local root=window
            K.windowTools.Hook(root,"OnShow",function() C.Focus(root) end)
        end
        if window then HookFocus(window,window) end
    end
end
K.On("PLAYER_ENTERING_WORLD",InstallFocus)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then InstallFocus() end end)
local drag=CreateFrame("Frame",nil,panel); C.drag=drag
drag:SetPoint("TOPLEFT",panel,"TOPLEFT",7,-5); drag:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-44,-5); drag:SetHeight(25)
drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
drag:SetScript("OnMouseDown",function() C.Focus(panel) end)
drag:SetScript("OnDragStart",function() C.Focus(panel); C.moving=true; panel:StartMoving() end)
local function StopMoving()
    if not C.moving then return end
    panel:StopMovingOrSizing(); C.moving=nil
    local point,_,relative,x,y=panel:GetPoint()
    K.DB().collectionPosition={point=point,relative=relative,x=x,y=y}
end
drag:SetScript("OnDragStop",StopMoving)
panel:SetScript("OnHide",function() StopMoving(); C.search:ClearFocus(); GameTooltip:Hide() end)
table.insert(UISpecialFrames,"KeijinUICollection")
local search=CreateFrame("EditBox",nil,panel); C.search=search
search:SetPoint("TOPLEFT",panel,"TOPLEFT",14,-38); search:SetWidth(460); search:SetHeight(26)
K.SetFontSize(search,12); search:SetTextInsets(8,8,3,3); search:SetAutoFocus(false); K.fontStrings=K.fontStrings or {}; table.insert(K.fontStrings,{search,12}); K.Skin(search,4)
search:SetScript("OnTextChanged",function() C.query=search:GetText() or ""; C.offset=0; C.Render() end)
search:SetScript("OnEscapePressed",function() search:ClearFocus() end)
local close=CreateFrame("Button",nil,panel); close:SetWidth(28); close:SetHeight(24); close:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-10,-6)
K.Text(close,"×",13,"CENTER",0,0); close:SetScript("OnClick",function() panel:Hide() end)
local rows={}; C.rows=rows
for i=1,10 do
    local row=K.ValueRow(panel,i,27); row:ClearAllPoints(); row:SetPoint("TOPLEFT",panel,"TOPLEFT",12,-72-(i-1)*29)
    row.label:SetWidth(395); row.value:SetWidth(110); rows[i]=row
    local original=K.SafeGetScript(row,"OnEnter")
    row:SetScript("OnEnter",function()
        if this.item then this.detail=C.Detail(this.item) end
        original()
    end)
end
local footer=K.LText(panel,"Nur beobachtete Funde. Nicht beobachtete Gegenstände und Werte bleiben unbekannt.",10,"BOTTOMLEFT",14,14,530)
footer:SetHeight(30)
panel:EnableMouseWheel(true); panel:SetScript("OnMouseWheel",function() C.offset=math.max(0,C.offset+(arg1>0 and -1 or 1)); C.Render() end)
local cache,cacheRevision,cacheQuery,cacheStore
local paintedRevision,paintedQuery,paintedOffset,paintedLang
function C.Render()
    local store=Store()
    if not cache or cacheRevision~=revision or cacheQuery~=C.query or cacheStore~=store then
        cache=C.List(C.query); cacheRevision=revision; cacheQuery=C.query; cacheStore=store
        paintedRevision=nil
    end
    local list=cache; C.offset=math.min(C.offset,math.max(0,table.getn(list)-10))
    if paintedRevision==revision and paintedQuery==C.query and paintedOffset==C.offset and paintedLang==K.lang then return end
    paintedRevision=revision; paintedQuery=C.query; paintedOffset=C.offset; paintedLang=K.lang
    for i,row in ipairs(rows) do
        local v=list[i+C.offset]
        if v then
            row.label:SetText(v.item.name); row.value:SetText(K.T("%s Funde",v.item.finds or 0))
            row.tip=v.item.name; row.detail=nil; row.item=v.item; row:Show()
        else row:Hide() end
    end
end
K.OnLang(function() if panel:IsShown() then C.Render() end end)
-- Inventory events replace the old permanent OnUpdate tooltip polling.
local equipped={}
local observedStore
function C.ScanInventory(force)
    if not K.ModuleOn("collection") or K.DB().collectionRecord==false then return end
    local store=Store(); force=force or observedStore~=store; observedStore=store
    C.scanning=true
    for _,slot in ipairs(C.slots) do
        local link=GetInventoryItemLink and GetInventoryItemLink("player",slot)
        if link and (force or equipped[slot]~=link) then
            local _,_,name=string.find(link,"|h%[(.-)%]|h")
            C.Observe({link=link,name=name,icon=GetInventoryItemTexture("player",slot)},false,C.NativeLines(slot))
        end
        equipped[slot]=link
    end
    C.scanning=nil
    if panel:IsShown() then C.Render() end
end
function C.Toggle()
    if not K.ModuleOn("collection") then panel:Hide(); return end
    if panel:IsShown() then panel:Hide()
    else
        InstallFocus(); C.ScanInventory(); C.Render(); panel:Show(); C.Focus(panel)
    end
end
-- Kept as the module lifecycle handle, with no per-frame work or scripts.
C.driver=CreateFrame("Frame")
K.On("UNIT_INVENTORY_CHANGED",function(_,unit) if unit=="player" then C.ScanInventory(true) end end,"collection")
K.On("PLAYER_ENTERING_WORLD",function() C.ScanInventory(true) end,"collection")
