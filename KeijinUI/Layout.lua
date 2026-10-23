local K=KeijinUI
K.layout={entries={}}
local L=K.layout
local editing,active,lastWidth,lastHeight
local function Scale(f) return f:GetEffectiveScale() end
local function Finite(n) return type(n)=="number" and n==n and math.abs(n)<1e15 end
-- A frame handed back to the game (module off) keeps the game's own place and scale.
local function Off(entry) return entry.options.inactive and entry.options.inactive() end
-- A frame that grows upwards (options.grow, loot list) is anchored and saved by its bottom edge, all others by the top edge.
-- options.keepBottom keeps the bottom edge as well but, unlike grow, still allows docking (build panel).
local function Up(entry)
    if entry.dock then return entry.dock.edge=="above" end
    if entry.options.keepBottom then return true end
    return entry.options.grow and entry.options.grow() and true or false
end
local function ValidDock(dock)
    return type(dock)=="table" and type(dock.target)=="string" and
        (dock.edge=="above" or dock.edge=="below") and Finite(dock.x)
end
local function CanDock(entry,target)
    local seen={[entry.key]=true}
    while target do
        if seen[target.key] then return false end
        seen[target.key]=true
        target=target.dock and L.entries[target.dock.target] or nil
    end
    return true
end
local function Dock(entry)
    local d=entry.dock
    local target=d and L.entries[d.target]
    if not target or entry==active or not CanDock(entry,target) then return end
    local f=entry.frame
    local ratio=Scale(f)/Scale(UIParent)
    f:ClearAllPoints()
    -- A dock with ref="bar" holds the distance of the options.edge bar edge, not of the frame's left edge.
    local ox=d.ref=="bar" and entry.options.edge and (entry.options.edge()) or 0
    f:SetPoint(d.edge=="above" and "BOTTOMLEFT" or "TOPLEFT",target.frame,
        d.edge=="above" and "TOPLEFT" or "BOTTOMLEFT",d.x/ratio-ox,0)
end
local function Detach(entry)
    if not entry.dock then return end
    local f=entry.frame
    local left,top=f:GetLeft(),f:GetTop()
    entry.dock=nil
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top)
end
local function Clamp(entry)
    if Off(entry) then return end
    local f=entry.frame
    local w,h=K.UIWidth(),K.UIHeight()
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
    -- No margin: frames may sit flush on the screen edge (snapping targets the edges too).
    local left=math.max(0,math.min(w-width,x))
    local bottom=math.max(0,math.min(h-height,y))
    if math.abs(left-x)>0.1 or math.abs(bottom-y)>0.1 then
        f:ClearAllPoints()
        if Up(entry) then f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",left/ratio,bottom/ratio)
        else f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/ratio,(bottom+height)/ratio) end
        return true
    end
end
local function Save(entry)
    if Off(entry) then return end
    Clamp(entry)
    local f,ratio=entry.frame,Scale(entry.frame)/Scale(UIParent)
    local up=Up(entry)
    local x,y=f:GetLeft(),up and f:GetBottom() or f:GetTop()
    if not Finite(x) or not Finite(y) then return end
    -- Keep the bottom edge as the anchor, so a later change of the height does not move it.
    if not entry.dock then
        f:ClearAllPoints(); f:SetPoint(up and "BOTTOMLEFT" or "TOPLEFT",UIParent,"BOTTOMLEFT",x,y)
    end
    -- options.edge: distance from the frame's left edge and top edge to the corner of the bar that stays put
    -- when the frame's geometry changes. Such an entry stores that corner (ref="bar") instead of the frame corner.
    -- (A frame anchored by its bottom keeps the bottom, which is the same in both styles.)
    local edge=entry.options.edge
    local ox,oy=0,0
    if edge then ox,oy=edge(); if up then oy=0 end end
    K.DB().layout[entry.key]={x=(x+ox)*ratio/K.UIWidth(),y=(y-oy)*ratio/K.UIHeight(),scale=f:GetScale()/entry.baseScale,dock=entry.dock,ref=edge and "bar" or nil,
        bottom=entry.options.legacyHeight and up and true or nil}
end
-- Standard layout (3.1.2, 300 point panels): only scales. Positions come from each frame's own anchor
-- (minimap top right, run overview below it, loot below that, statistics/meter/crits top left, unit frames
-- beside the action bar), so the start layout fits every screen width without overlaps.
L.defaults={
    buffs={scale=0.9},
    crits={scale=0.9},
    loot={scale=0.9},
    meter={scale=0.9},
    minimap={scale=0.8},
    skills={scale=0.9},
    statistics={scale=0.9},
    summons={scale=0.9},
    tracker={scale=0.9},
}
local function Valid(p) return type(p)=="table" and Finite(p.x) and Finite(p.y) and K.Number(p.scale) and p.scale>0 end
local function Apply(entry)
    local f,p=entry.frame,K.DB().layout[entry.key]
    if Off(entry) then
        entry.dock=nil
        if entry.options.release then entry.options.release(f) end
        return
    end
    entry.dock=Valid(p) and ValidDock(p.dock) and p.dock or nil
    -- Dynamic panels must have their final width before applying and clamping a saved position.
    if entry.options.width then f:SetWidth(entry.options.width()) end
    if entry.options.follow and entry.options.follow() then entry.anchor(f); return end
    if entry.options.scale then entry.baseScale=entry.options.scale() end
    local saved=Valid(p)
    if not saved then p=L.defaults and L.defaults[entry.key] end
    if Valid(p) then
        f:SetScale(entry.baseScale*math.max(0.5,math.min(1.8,p.scale)))
        local ratio=Scale(UIParent)/Scale(f)
        local ox,oy=0,0
        if entry.options.edge then ox,oy=entry.options.edge() end
        local up=Up(entry)
        if up then oy=0 end
        -- Older positions hold frame corners: ref=nil both corners, ref="edge" (3.5.0, x only) the bar edge and the
        -- frame top. Convert once, in the style now active, so nothing jumps; ref="bar" holds the bar corner.
        if saved and entry.options.edge and p.ref~="bar" then
            if p.ref==nil then p.x=p.x+ox/ratio/K.UIWidth() end
            p.y=p.y-oy/ratio/K.UIHeight(); p.ref="bar"
        end
        -- options.legacyHeight: the frame grew downwards before (build panel up to 3.7.0) and its older
        -- positions hold the top edge. Convert once to the bottom edge at that height (the build panel's
        -- one-row size at login and run start), so the panel sits exactly as before and grows upwards.
        if saved and up and entry.options.legacyHeight and not p.bottom and not ValidDock(p.dock) then
            p.y=p.y-entry.options.legacyHeight/ratio/K.UIHeight(); p.bottom=true
        end
        if saved and entry.options.edge and ValidDock(p.dock) and p.dock.ref~="bar" then
            p.dock.x=p.dock.x+ox/ratio; p.dock.ref="bar"
        end
        f:ClearAllPoints()
        -- For a frame growing upwards p.y is the bottom edge (also in the standard layout).
        f:SetPoint(up and "BOTTOMLEFT" or "TOPLEFT",UIParent,"BOTTOMLEFT",p.x*K.UIWidth()*ratio-ox,p.y*K.UIHeight()*ratio+oy)
    else
        local d=not saved and L.defaults and L.defaults[entry.key]
        local scale=d and K.Number(d.scale) and d.scale>0 and d.scale or 1
        f:SetScale(entry.baseScale*scale); entry.anchor(f)
    end
    if Clamp(entry) and saved then Save(entry) end
    Dock(entry)
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
-- Grid lines are counted from the screen centre (UIParent:GetCenter), the same origin the overlay uses.
local function GridTargets(edges,middle)
    local list={}
    for _,a in ipairs(edges) do table.insert(list,middle+math.floor((a-middle)/STEP+0.5)*STEP) end
    return list
end
local function Snap(entry)
    if K.DB().snap==false or IsShiftKeyDown() then return end
    local f=entry.frame
    local w,h=K.UIWidth(),K.UIHeight()
    local l,b,r,t=Rect(f)
    if not l or not w or not h or w<40 or h<40 then return end
    local cx,cy=UIParent:GetCenter()
    if not Finite(cx) or not Finite(cy) then cx,cy=w/2,h/2 end
    -- Screen edges are snap targets, so a frame can rest flush on the border.
    local xs,ys={cx,0,w},{cy,0,h}
    for _,e in pairs(L.entries) do
        if e~=entry and e.frame:IsShown() then
            local el,eb,er,et=Rect(e.frame)
            if el then table.insert(xs,el); table.insert(xs,er); table.insert(ys,eb); table.insert(ys,et) end
        end
    end
    local dx=Best(nil,{l,r,(l+r)/2},xs)
    local dy=Best(nil,{b,t,(b+t)/2},ys)
    if not dx then dx=Best(nil,{l,r},GridTargets({l,r},cx)) end
    if not dy then dy=Best(nil,{b,t},GridTargets({b,t},cy)) end
    if not dx and not dy then return end
    local ratio=Scale(f)/Scale(UIParent)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",(l+(dx or 0))/ratio,(t+(dy or 0))/ratio)
    -- A touching horizontal edge is a real attachment, not just a one-time position.
    -- Above a neighbour the bottom remains fixed, so new rows grow away from it.
    if entry.options.grow then return end
    l,b,r,t=Rect(f)
    for _,target in pairs(L.entries) do
        if target~=entry and target.frame:IsShown() and CanDock(entry,target) then
            local tl,tb,tr,tt=Rect(target.frame)
            if tl and math.min(r,tr)-math.max(l,tl)>1 then
                local edge=math.abs(b-tt)<.1 and "above" or (math.abs(t-tb)<.1 and "below" or nil)
                if edge then
                    local ox=entry.options.edge and (entry.options.edge())
                    entry.dock={target=target.key,edge=edge,x=l-tl+(ox or 0)*ratio,ref=ox and "bar" or nil}; break
                end
            end
        end
    end
end
local function Stop()
    if not active then return end
    active.frame:StopMovingOrSizing(); Snap(active); Save(active); active=nil
    if L.SyncFollowers then L.SyncFollowers() end
end
-- Both the layout handle and a panel's own drag regions use this lifecycle.
function L.BeginMove(key)
    local e=L.entries[key]
    if not e or Off(e) or (not editing and not IsAltKeyDown()) then return end
    if e.options.locked and e.options.locked() then return end
    if active and active~=e then Stop() end
    if e.options.beforeMove then e.options.beforeMove() end
    Detach(e); active=e; e.frame:StartMoving()
end
function L.EndMove(key)
    if active and active.key==key then Stop() end
end
-- Grid overlay: thin textures every STEP units from the screen centre, shown only while editing.
-- Lines hang from the centre and run edge to edge with two anchors, so the middle line stays in the screen
-- centre even if the reported UIParent size and the drawn area differ (game 0.101).
local grid=CreateFrame("Frame",nil,UIParent)
grid:SetFrameStrata("TOOLTIP"); grid:SetFrameLevel(170); grid:EnableMouse(false)
grid:SetAllPoints(UIParent)
grid:Hide(); L.grid=grid
local lines,gridW,gridH={}
local function Line(i,vertical,offset,center)
    local t=lines[i]
    if not t then t=grid:CreateTexture(nil,"BACKGROUND"); t:SetTexture(K.flat); lines[i]=t end
    t:ClearAllPoints()
    if vertical then t:SetWidth(1); t:SetPoint("TOP",grid,"TOP",offset,0); t:SetPoint("BOTTOM",grid,"BOTTOM",offset,0)
    else t:SetHeight(1); t:SetPoint("LEFT",grid,"LEFT",0,offset); t:SetPoint("RIGHT",grid,"RIGHT",0,offset) end
    if center then t:SetVertexColor(1,0.9,0.4,0.35) else t:SetVertexColor(1,1,1,0.12) end
    t:Show()
end
local function BuildGrid(w,h)
    local n=0
    local function Add(vertical,size)
        n=n+1; Line(n,vertical,0,true)
        local k=1
        -- Two extra steps cover a drawn area slightly larger than the reported size.
        while k*STEP<size/2+2*STEP do
            n=n+1; Line(n,vertical,-k*STEP,false)
            n=n+1; Line(n,vertical,k*STEP,false)
            k=k+1
        end
    end
    Add(true,w); Add(false,h)
    for i=n+1,table.getn(lines) do lines[i]:Hide() end
    gridW,gridH=w,h
end
local function RefreshGrid(enabled)
    local w,h=K.UIWidth(),K.UIHeight()
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
        handle.outline=outline
        outline:SetTexture("Interface\\AddOns\\KeijinUI\\media\\soft\\FrameRim.tga"); outline:SetAllPoints(handle)
        outline:SetVertexColor(1,0.8,0.25,1)
        if key=="target" then outline:SetTexCoord(1,0,0,1) end
    else K.Chamfer(handle,4,{0.15,0.3,0.36,0.28},{1,0.8,0.25,1}) end
    handle.label=K.Text(handle,"",10,"TOP",0,-5)
    K.Live(handle.label,function() return K.T(name).." | "..K.T("Mausrad: Größe") end)
    handle:EnableMouse(true); handle:EnableMouseWheel(true); handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart",function()
        L.BeginMove(key)
    end)
    handle:SetScript("OnDragStop",Stop)
    handle:SetScript("OnMouseWheel",function()
        if e.options.locked and e.options.locked() then return end
        if e.options.beforeMove then e.options.beforeMove() end
        local scale=frame:GetScale()/e.baseScale
        frame:SetScale(e.baseScale*math.max(0.5,math.min(1.8,scale+(arg1>0 and 0.05 or -0.05))))
        Save(e)
        if L.SyncFollowers then L.SyncFollowers() end
        -- Open settings show the new size at once (the combat text slider).
        if K.settings and K.settings.panel and K.settings.panel:IsShown() then K.settings.Refresh() end
    end)
    handle:Hide(); Apply(e)
    for _,other in pairs(L.entries) do Dock(other) end
    return e
end
function L.Save(key) local e=L.entries[key]; if e then Save(e) end end
function L.IsMoving(key) return active and active.key==key and true or false end
function L.SyncFollowers()
    for _,e in pairs(L.entries) do Dock(e) end
    for _,e in pairs(L.entries) do if e.options.follow and e.options.follow() then e.anchor(e.frame) end end
end
function L.Place(key) local e=L.entries[key]; if e and e~=active then Apply(e) end end
local hint=K.Panel("KeijinUILayoutHint","Layoutmodus aktiv",470,92)
hint:SetFrameStrata("TOOLTIP"); hint:SetFrameLevel(220); hint:SetScale(.85)
hint:SetPoint("TOP",UIParent,"TOP",0,-72); hint:SetBackdropColor(.04,.04,.05,1)
K.LText(hint,"Ziehen: verschieben · Mausrad: Größe ändern",11,"TOPLEFT",14,-35,335)
K.LText(hint,"Escape oder Fertig zum Beenden",11,"TOPLEFT",14,-59,335):SetTextColor(1,.82,.28)
local done=CreateFrame("Button",nil,hint); done:SetWidth(92); done:SetHeight(30)
done:SetPoint("RIGHT",hint,"RIGHT",-14,-10)
K.Chamfer(done,4,{.18,.14,.07,1},{.67,.57,.36,1}); K.LText(done,"Fertig",12,"CENTER",0,0)
L.hint,L.done=hint,done; hint:Hide()
table.insert(UISpecialFrames,"KeijinUILayoutHint")
function L.IsEditing() return editing end
function L.SetEditing(on)
    editing=on and true or false
    if editing then hint:Show() else Stop(); hint:Hide() end
    RefreshGrid(editing or IsAltKeyDown())
    L.Update()
end
function L.Toggle() L.SetEditing(not editing) end
done:SetScript("OnClick",function() L.SetEditing(false) end)
hint:SetScript("OnHide",function() if editing then L.SetEditing(false) end end)
-- /kui grid debug: reported sizes and centres, to compare the grid with the real screen.
function L.GridDebug()
    local function N(v) return v and string.format("%.1f",v) or "nil" end
    local cx,cy=UIParent:GetCenter()
    local gx,gy=grid:GetCenter()
    K.Say("Grid: UIParent "..N(UIParent:GetWidth()).." x "..N(UIParent:GetHeight()).." (edges "..N(K.UIWidth()).." x "..N(K.UIHeight())..") centre "..N(cx)..","..N(cy)
        ..", grid centre "..N(gx)..","..N(gy)..", scale "..N(UIParent:GetEffectiveScale())
        ..", screen "..N(GetScreenWidth and GetScreenWidth()).." x "..N(GetScreenHeight and GetScreenHeight()))
end
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
    local w,h=K.UIWidth(),K.UIHeight()
    if lastWidth and (w~=lastWidth or h~=lastHeight) then
        Stop(); for _,e in pairs(L.entries) do Apply(e) end
    end
    lastWidth,lastHeight=w,h
    local enabled=editing or IsAltKeyDown()
    if active and not enabled then Stop() end
    RefreshGrid(enabled)
    for _,e in pairs(L.entries) do
        if e~=active and Clamp(e) and K.DB().layout[e.key] then Save(e) end
        local show=enabled and not Off(e) and not (e.options.locked and e.options.locked()) and (e.frame:IsShown() or e.options.hidden)
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
local GAP=2
function L.MigrateStatistics()
    local db=K.DB()
    if db.layoutMigration074 then return end
    db.layoutMigration074=true
    local saved,stats=db.layout,db.layout.statistics
    local entry,meterEntry=L.entries.statistics,L.entries.meter
    local h=K.UIHeight()
    if not Valid(stats) or not entry or not meterEntry or not Finite(h) or h<=0 then return end
    local s=entry.baseScale*stats.scale
    local width=entry.frame:GetWidth()*s/K.UIWidth()
    local function Below(p,top) return Valid(p) and math.abs(p.x-stats.x)<width and p.y<top end
    local meter=saved.meter
    if not Below(meter,stats.y) then return end
    local limit=stats.y-(entry.frame.headerHeight or entry.frame:GetHeight())*s/h-GAP/h
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
K.On("PLAYER_LEAVING_WORLD",function() editing=false; Stop(); hint:Hide(); grid:Hide(); for _,e in pairs(L.entries) do e.handle:Hide() end end)
