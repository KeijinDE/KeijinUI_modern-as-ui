-- Compact headers only for the four HUD panels, never dialogs or untitled groups.
local K=KeijinUI
local H={panels={},eligible={KeijinUITracker=true,KeijinUIStatistics=true,KeijinUIDamage=true,KeijinUICrits=true}}
K.headers=H
function H.Mode()
    local mode=K.DB().panelHeaders
    return (mode=="thin" or mode=="off") and mode or "normal"
end
function K.HeaderOffset(panel)
    if not panel or not panel.compactHeader then return 0 end
    local mode=H.Mode()
    return mode=="thin" and 12 or (mode=="off" and 25 or 0)
end
function K.HeaderPoint(child,panel,point,x,y,relative)
    child:ClearAllPoints()
    child:SetPoint(point,panel,relative or point,x,y+K.HeaderOffset(panel))
    if panel.compactHeader then
        local list=panel.headerPoints
        if not list[child] then list[child]={point,x,y,relative or point} end
    end
end
local function Apply(f)
    local mode=H.Mode()
    f.headerNativeHeight(f,f.headerHeight-K.HeaderOffset(f))
    if mode=="off" then f.title:Hide(); f.strip:Hide()
    else
        f.title:Show(); f.strip:Show()
        f.title:SetFont(K.font,mode=="thin" and 10 or 12,"OUTLINE")
        f.title:ClearAllPoints()
        if mode=="thin" then
            f.title:SetHeight(14); f.title:SetJustifyV("MIDDLE")
            f.title:SetPoint("LEFT",f.strip,"LEFT",6,0)
        else
            f.title:SetHeight(17); f.title:SetJustifyV("MIDDLE")
            f.title:SetPoint("TOPLEFT",f,"TOPLEFT",13,-11)
        end
        f.strip:SetHeight(mode=="thin" and 14 or 23)
    end
    for child,p in pairs(f.headerPoints) do
        child:ClearAllPoints(); child:SetPoint(p[1],f,p[4],p[2],p[3]+K.HeaderOffset(f))
    end
    if f.headerExtra then f.headerExtra(mode) end
end
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
