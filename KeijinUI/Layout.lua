local K=KeijinUI
K.layout={entries={}}
local L=K.layout
local editing,active,lastWidth,lastHeight
local function Scale(f) return f:GetEffectiveScale() end
local function Finite(n) return type(n)=="number" and n==n and math.abs(n)<1e15 end
local function Clamp(entry)
    local f=entry.frame
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if not w or not h or w<40 or h<40 then return end
    local ratio=Scale(f)/Scale(UIParent)
    if entry.options.follow and entry.options.follow() then return end
    local extra=entry.options.bottom and entry.options.bottom() or 0
    local width,height=f:GetWidth()*ratio,(f:GetHeight()+extra)*ratio
    if width>w-16 or height>h-16 then
        f:SetScale(f:GetScale()*math.min((w-16)/width,(h-16)/height))
        ratio=Scale(f)/Scale(UIParent); width,height=f:GetWidth()*ratio,(f:GetHeight()+extra)*ratio
    end
    local x,y=f:GetLeft(),f:GetBottom()
    if not Finite(x) or not Finite(y) then return end
    x,y=x*ratio,(y-extra)*ratio
    local left=math.max(8,math.min(w-width-8,x))
    local bottom=math.max(8,math.min(h-height-8,y))
    if math.abs(left-x)>0.1 or math.abs(bottom-y)>0.1 then
        f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/ratio,(bottom+height)/ratio)
        return true
    end
end
local function Save(entry)
    Clamp(entry)
    local f,ratio=entry.frame,Scale(entry.frame)/Scale(UIParent)
    local x,y=f:GetLeft(),f:GetTop()
    if not Finite(x) or not Finite(y) then return end
    K.DB().layout[entry.key]={x=x*ratio/UIParent:GetWidth(),y=y*ratio/UIParent:GetHeight(),scale=f:GetScale()/entry.baseScale}
end
-- Standard layout (version 0.5.1, statistics taller since 0.7.4): same format as the saved layout, never written to the DB by Apply.
L.defaults={
    achievements={x=0.3588,y=0.3057,scale=1},
    bosses={x=0.4076,y=0.9906,scale=1},
    buffs={x=0.4096,y=0.3660,scale=1},
    chat={x=0.0053,y=0.2082,scale=1},
    crits={x=0.0053,y=0.5293,scale=0.9},
    loot={x=0.8157,y=0.4990,scale=0.9},
    meter={x=0.0053,y=0.7762,scale=0.9},
    minimap={x=0.8682,y=0.9906,scale=1},
    player={x=0.2587,y=0.4320,scale=1},
    skills={x=0.4092,y=0.4230,scale=0.9},
    statistics={x=0.0053,y=0.9906,scale=0.9},
    target={x=0.6054,y=0.4320,scale=1},
    tooltip={x=0.7596,y=0.2391,scale=1},
    tracker={x=0.8156,y=0.7578,scale=0.9},
}
local function Valid(p) return type(p)=="table" and Finite(p.x) and Finite(p.y) and K.Number(p.scale) and p.scale>0 end
local function Apply(entry)
    local f,p=entry.frame,K.DB().layout[entry.key]
    if entry.options.follow and entry.options.follow() then entry.anchor(f); return end
    if entry.options.scale then entry.baseScale=entry.options.scale() end
    local saved=Valid(p)
    if not saved then p=L.defaults and L.defaults[entry.key] end
    if Valid(p) then
        f:SetScale(entry.baseScale*math.max(0.5,math.min(1.8,p.scale)))
        local ratio=Scale(UIParent)/Scale(f)
        f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",p.x*UIParent:GetWidth()*ratio,p.y*UIParent:GetHeight()*ratio)
    else f:SetScale(entry.baseScale); entry.anchor(f) end
    if Clamp(entry) and saved then Save(entry) end
end
local STEP,NEAR=32,10
local function Rect(f)
    local ratio=Scale(f)/Scale(UIParent)
    local l,b=f:GetLeft(),f:GetBottom()
    if not Finite(l) or not Finite(b) then return end
    l,b=l*ratio,b*ratio
    return l,b,l+f:GetWidth()*ratio,b+f:GetHeight()*ratio
end
-- Smallest shift (within NEAR) that moves one of the edges onto a target; nil if none.
local function Best(best,edges,targets)
    for _,a in ipairs(edges) do for _,t in ipairs(targets) do
        local d=t-a
        if math.abs(d)<=NEAR and (not best or math.abs(d)<math.abs(best)) then best=d end
    end end
    return best
end
local function GridTargets(edges,size)
    local list={}
    for _,a in ipairs(edges) do table.insert(list,size/2+math.floor((a-size/2)/STEP+0.5)*STEP) end
    return list
end
local function Snap(entry)
    if K.DB().snap==false or IsShiftKeyDown() then return end
    local f=entry.frame
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    local l,b,r,t=Rect(f)
    if not l or not w or not h or w<40 or h<40 then return end
    local xs,ys={w/2},{h/2}
    for _,e in pairs(L.entries) do
        if e~=entry and e.frame:IsShown() then
            local el,eb,er,et=Rect(e.frame)
            if el then table.insert(xs,el); table.insert(xs,er); table.insert(ys,eb); table.insert(ys,et) end
        end
    end
    local dx=Best(nil,{l,r,(l+r)/2},xs)
    local dy=Best(nil,{b,t,(b+t)/2},ys)
    if not dx then dx=Best(nil,{l,r},GridTargets({l,r},w)) end
    if not dy then dy=Best(nil,{b,t},GridTargets({b,t},h)) end
    if not dx and not dy then return end
    local ratio=Scale(f)/Scale(UIParent)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",(l+(dx or 0))/ratio,(t+(dy or 0))/ratio)
end
local function Stop()
    if not active then return end
    active.frame:StopMovingOrSizing(); Snap(active); Save(active); active=nil
    if L.SyncFollowers then L.SyncFollowers() end
end
-- Grid overlay: thin textures every STEP units from the screen centre, shown only while editing.
local grid=CreateFrame("Frame",nil,UIParent)
grid:SetFrameStrata("TOOLTIP"); grid:SetFrameLevel(170); grid:EnableMouse(false)
grid:SetWidth(UIParent:GetWidth()); grid:SetHeight(UIParent:GetHeight()); grid:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0)
grid:Hide(); L.grid=grid
local lines,gridW,gridH={}
local function Line(i,vertical,pos,size,center)
    local t=lines[i]
    if not t then t=grid:CreateTexture(nil,"BACKGROUND"); t:SetTexture(K.flat); lines[i]=t end
    t:ClearAllPoints()
    if vertical then t:SetWidth(1); t:SetHeight(size); t:SetPoint("BOTTOMLEFT",grid,"BOTTOMLEFT",pos,0)
    else t:SetHeight(1); t:SetWidth(size); t:SetPoint("BOTTOMLEFT",grid,"BOTTOMLEFT",0,pos) end
    if center then t:SetVertexColor(1,0.9,0.4,0.35) else t:SetVertexColor(1,1,1,0.12) end
    t:Show()
end
local function BuildGrid(w,h)
    grid:SetWidth(w); grid:SetHeight(h)
    local n=0
    local function Add(vertical,size,span)
        n=n+1; Line(n,vertical,size/2,span,true)
        local k=1
        while k*STEP<size/2 do
            n=n+1; Line(n,vertical,size/2-k*STEP,span,false)
            n=n+1; Line(n,vertical,size/2+k*STEP,span,false)
            k=k+1
        end
    end
    Add(true,w,h); Add(false,h,w)
    for i=n+1,table.getn(lines) do lines[i]:Hide() end
    gridW,gridH=w,h
end
local function RefreshGrid(enabled)
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if enabled and K.DB().snap~=false and w and h and w>=40 and h>=40 then
        if w~=gridW or h~=gridH then BuildGrid(w,h) end
        grid:Show()
    else grid:Hide() end
end
function L.Register(key,frame,name,anchor,options)
    if not frame or L.entries[key] then return L.entries[key] end
    local e={key=key,frame=frame,anchor=anchor,name=name,baseScale=frame:GetScale(),options=options or {}}
    L.entries[key]=e
    frame:SetMovable(true); frame:SetClampedToScreen(true)
    if frame.SetUserPlaced then frame:SetUserPlaced(false) end
    local handle=CreateFrame("Frame",nil,UIParent); e.handle=handle
    handle:SetFrameStrata("TOOLTIP"); handle:SetFrameLevel(180)
    if key=="player" or key=="target" then
        local outline=handle:CreateTexture(nil,"OVERLAY")
        outline:SetTexture("Interface\\AddOns\\KeijinUI\\media\\soft\\FrameRim.tga"); outline:SetAllPoints(handle)
        outline:SetVertexColor(1,0.8,0.25,1)
        if key=="target" then outline:SetTexCoord(1,0,0,1) end
    else K.Chamfer(handle,4,{0.15,0.3,0.36,0.28},{1,0.8,0.25,1}) end
    handle.label=K.Text(handle,"",10,"TOP",0,-5)
    K.Live(handle.label,function() return K.T(name).." | "..K.T("Mausrad: Größe") end)
    handle:EnableMouse(true); handle:EnableMouseWheel(true); handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart",function()
        if not editing and not IsAltKeyDown() then return end
        if e.options.beforeMove then e.options.beforeMove() end
        active=e; frame:StartMoving()
    end)
    handle:SetScript("OnDragStop",Stop)
    handle:SetScript("OnMouseWheel",function()
        if e.options.beforeMove then e.options.beforeMove() end
        local scale=frame:GetScale()/e.baseScale
        frame:SetScale(e.baseScale*math.max(0.5,math.min(1.8,scale+(arg1>0 and 0.05 or -0.05))))
        Save(e)
        if L.SyncFollowers then L.SyncFollowers() end
    end)
    handle:Hide(); Apply(e)
    return e
end
function L.Save(key) local e=L.entries[key]; if e then Save(e) end end
function L.SyncFollowers()
    for _,e in pairs(L.entries) do if e.options.follow and e.options.follow() then e.anchor(e.frame) end end
end
function L.Place(key) local e=L.entries[key]; if e and e~=active then Apply(e) end end
function L.IsEditing() return editing end
function L.Toggle() editing=not editing; if not editing then Stop() end; RefreshGrid(editing or IsAltKeyDown()) end
function L.ToggleGrid()
    K.DB().snap=(K.DB().snap==false)
    K.Say(K.T("Raster und Einrasten")..": "..(K.DB().snap and K.T("An (Shift beim Loslassen: ohne Einrasten)") or K.T("Aus")))
    RefreshGrid(editing or IsAltKeyDown())
end
function L.ResetKey(key) K.DB().layout[key]=nil; L.Place(key) end
function L.Reset()
    Stop(); K.DB().layout={}; K.DB().resourceFree=nil
    for _,e in pairs(L.entries) do Apply(e) end
end
function L.ClampAll()
    for _,e in pairs(L.entries) do
        if e~=active and Clamp(e) and K.DB().layout[e.key] then Save(e) end
    end
end
function L.Update()
    L.SyncFollowers()
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if lastWidth and (w~=lastWidth or h~=lastHeight) then
        Stop(); for _,e in pairs(L.entries) do Apply(e) end
    end
    lastWidth,lastHeight=w,h
    local enabled=editing or IsAltKeyDown()
    if active and not enabled then Stop() end
    RefreshGrid(enabled)
    for _,e in pairs(L.entries) do
        if e~=active and Clamp(e) and K.DB().layout[e.key] then Save(e) end
        local show=enabled and (e.frame:IsShown() or e.options.hidden)
        if show then
            local region=e.options.region or e.frame
            local ratio=Scale(region)/Scale(UIParent)
            e.handle:ClearAllPoints(); e.handle:SetPoint("TOPLEFT",region,"TOPLEFT",0,0)
            e.handle:SetWidth(math.max(30,region:GetWidth()*ratio))
            e.handle:SetHeight(math.max(28,region:GetHeight()*ratio)); e.handle:Show()
        else e.handle:Hide() end
    end
end
-- 0.7.4: the statistics grew by two rows (166 -> 204). A saved damage meter in the same column below
-- them moves down only as far as needed to stay clear of the taller panel (GAP units apart); critical
-- hits below the meter follow only as far as the meter at its tallest would otherwise cover them, and
-- never further than the meter moved. Frames with room to spare stay where they are. Once per account,
-- on ADDON_LOADED, when the saved variables exist.
local OLD_STATS,NEW_STATS,GAP=166,204,2
function L.MigrateStatistics()
    local db=K.DB()
    if db.layoutMigration074 then return end
    db.layoutMigration074=true
    local saved,stats=db.layout,db.layout.statistics
    local entry,meterEntry=L.entries.statistics,L.entries.meter
    local h=UIParent:GetHeight()
    if not Valid(stats) or not entry or not meterEntry or not Finite(h) or h<=0 then return end
    local s=entry.baseScale*stats.scale
    local width=entry.frame:GetWidth()*s/UIParent:GetWidth()
    local function Below(p,top) return Valid(p) and math.abs(p.x-stats.x)<width and p.y<top end
    local meter=saved.meter
    if not Below(meter,stats.y) then return end
    local limit=stats.y-NEW_STATS*s/h-GAP/h
    local moved=math.max(0,meter.y-limit)
    if moved<=0 then return end
    local crits,meterTop=saved.crits,meter.y
    meter.y=meter.y-moved
    if Below(crits,meterTop) then
        local ms=meterEntry.baseScale*meter.scale
        local tallest=K.MeterMaxHeight and K.MeterMaxHeight() or 232
        local critLimit=meter.y-tallest*ms/h-GAP/h
        crits.y=crits.y-math.min(moved,math.max(0,crits.y-critLimit))
    end
    L.Place("meter"); L.Place("crits")
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then L.MigrateStatistics() end end)
table.insert(K.updates,L.Update)
K.On("PLAYER_LEAVING_WORLD",function() editing=false; Stop(); grid:Hide(); for _,e in pairs(L.entries) do e.handle:Hide() end end)
