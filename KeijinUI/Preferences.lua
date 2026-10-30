-- Compact headers only for the HUD panels (run tracker, statistics, damage, crits, loot, character stats, party), never dialogs or untitled groups.
local K=KeijinUI
local H={panels={},eligible={KeijinUITracker=true,KeijinUIStatistics=true,KeijinUIDamage=true,KeijinUICrits=true,KeijinUILoot=true,KeijinUICharacterStats=true,KeijinUIParty=true}}
K.headers=H
function H.Mode(frame)
    local mode=frame and K.WindowConfig(K.WindowKey(frame)).headers
    if mode==nil then mode=K.DB().panelHeaders end
    return (mode=="thin" or mode=="off") and mode or "normal"
end
function K.HeaderOffset(panel)
    if not panel or not panel.compactHeader then return 0 end
    local mode=H.Mode(panel)
    return mode=="thin" and 10 or (mode=="off" and 25 or 0)
end
-- Title and strip height of a sized panel: grows with the font factor like the row pad, but a thin header
-- stays 9 smaller than the normal one, otherwise the strip would reach into the first row (rows sit 12 higher).
function K.HeaderStripHeight(panel,q)
    return H.Mode(panel)=="thin" and math.max(14,18*q-9) or math.max(23,18*q)
end
function K.HeaderTitleHeight(panel,q)
    return H.Mode(panel)=="thin" and math.max(14,15*q-3) or math.max(17,15*q)
end
-- Children anchored at the bottom (panel.growUp, the loot list growing upwards) move the opposite way,
-- because the header strip sits at the bottom edge there.
local function Sign(point) return string.find(point,"^BOTTOM") and -1 or 1 end
-- Write caches for the 0.1 s update path: every layout write invalidates the engine's layout, so an unchanged
-- size or anchor is not written again. The instance methods are wrapped once per object and record what anyone
-- sets (width, height) or forget the anchor (ClearAllPoints, SetAllPoints), so outside writes never go stale.
function K.SetW(f,v)
    if f.kuiW==v then return end
    if not f.kuiTracked then K.TrackLayout(f) end
    f:SetWidth(v)
end
function K.SetH(f,v)
    if f.kuiH==v then return end
    if not f.kuiTracked then K.TrackLayout(f) end
    f:SetHeight(v)
end
function K.TrackLayout(f)
    if f.kuiTracked then return end
    f.kuiTracked=true
    local width,height,clear,all=f.SetWidth,f.SetHeight,f.ClearAllPoints,f.SetAllPoints
    f.SetWidth=function(self,v) self.kuiW=v; return width(self,v) end
    f.SetHeight=function(self,v) self.kuiH=v; return height(self,v) end
    f.ClearAllPoints=function(self) self.kuiAnchored=nil; return clear(self) end
    f.SetAllPoints=function(self,other) self.kuiAnchored=nil; if other==nil then return all(self) end return all(self,other) end
end
-- Single anchor, written only when it differs from the last one set through here.
function K.Anchor(child,point,relativeTo,relativePoint,x,y)
    if child.kuiAnchored and child.kuiAP==point and child.kuiAR==relativeTo and child.kuiARP==relativePoint
        and child.kuiAX==x and child.kuiAY==y then return end
    if not child.kuiTracked then K.TrackLayout(child) end
    child:ClearAllPoints()
    child:SetPoint(point,relativeTo,relativePoint,x,y)
    child.kuiAnchored=true
    child.kuiAP,child.kuiAR,child.kuiARP,child.kuiAX,child.kuiAY=point,relativeTo,relativePoint,x,y
end
-- Show/Hide only on a change of state. The state is recorded by wrapping the instance's Show and Hide once,
-- because IsShown() can report the parent chain (hidden parent) instead of the frame's own flag.
function K.Shown(f,on)
    if not f.kuiShowTracked then
        f.kuiShowTracked=true
        local show,hide=f.Show,f.Hide
        f.Show=function(self) self.kuiShown=true; return show(self) end
        f.Hide=function(self) self.kuiShown=false; return hide(self) end
    end
    if on then
        if f.kuiShown==true and f:IsShown() then return end
        f:Show()
    else
        if f.kuiShown==false then return end
        f:Hide()
    end
end
function K.HeaderPoint(child,panel,point,x,y,relative)
    K.Anchor(child,point,panel,relative or point,x,y+K.HeaderOffset(panel)*Sign(point))
    if panel.compactHeader then
        local p=panel.headerPoints[child]
        if p then p[1],p[2],p[3],p[4]=point,x,y,relative or point
        else panel.headerPoints[child]={point,x,y,relative or point} end
    end
end
-- Header artwork is independent of rim and background; an off title mode still hides it.
function H.Strip(f)
    K.Shown(f.strip,H.Mode(f)~="off" and K.WindowShown(K.WindowKey(f),"strip") and true or false)
end
local function Apply(f)
    local mode=H.Mode(f)
    f.headerNativeHeight(f,f.headerHeight-K.HeaderOffset(f))
    if mode=="off" then f.title:Hide()
    else
        f.title:Show()
        K.SetFontSize(f.title,mode=="thin" and 10 or 12)
        f.title:ClearAllPoints()
        if mode=="thin" then
            f.title:SetHeight(14); f.title:SetJustifyV("MIDDLE")
            f.title:SetPoint("LEFT",f.strip,"LEFT",6,0)
        else
            f.title:SetHeight(17); f.title:SetJustifyV("MIDDLE")
            if f.growUp then f.title:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",13,11)
            else f.title:SetPoint("TOPLEFT",f,"TOPLEFT",13,-11) end
        end
        f.strip:SetHeight(mode=="thin" and 14 or 23)
    end
    f.strip:ClearAllPoints()
    if f.growUp then
        f.strip:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",7,5); f.strip:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-7,5)
    else
        f.strip:SetPoint("TOPLEFT",f,"TOPLEFT",7,-5); f.strip:SetPoint("TOPRIGHT",f,"TOPRIGHT",-7,-5)
    end
    for child,p in pairs(f.headerPoints) do
        child:ClearAllPoints(); child:SetPoint(p[1],f,p[4],p[2],p[3]+K.HeaderOffset(f)*Sign(p[1]))
    end
    H.Strip(f)
    if f.headerExtra then f.headerExtra(mode) end
end
H.Apply=Apply
function H.Attach(f)
    f.compactHeader=true; f.headerPoints={}; f.headerHeight=f:GetHeight()
    f.headerNativeHeight=f.SetHeight
    f.SetHeight=function(self,height)
        self.headerHeight=height
        self.headerNativeHeight(self,height-K.HeaderOffset(self))
    end
    table.insert(H.panels,f); Apply(f)
end
function H.Set(mode)
    K.DB().panelHeaders=(mode=="thin" or mode=="off") and mode or "normal"
    for _,f in ipairs(H.panels) do Apply(f) end
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then for _,f in ipairs(H.panels) do Apply(f) end end end)
K.On("PLAYER_ENTERING_WORLD",function() for _,f in ipairs(H.panels) do Apply(f) end end)

-- Default is both locations. Auto reproduces the old nameplate-first behavior.
function K.SetTargetDebuffsBoth(on)
    K.DB().targetDebuffsBoth=on and true or false
    if K.RefreshTargetDebuffs then K.RefreshTargetDebuffs() end
end
