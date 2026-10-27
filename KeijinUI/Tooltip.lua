local K=KeijinUI
local anchor=CreateFrame("Frame","KeijinUITooltipAnchor",UIParent)
anchor:SetWidth(K.PANEL_WIDTH); anchor:SetHeight(90); anchor:Hide()
K.layout.Register("tooltip",anchor,"Tooltip",function(f)
    f:ClearAllPoints(); f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-24,34)
end,{hidden=true,inactive=function() return not K.ModuleOn("tooltip") end})
local saved,skins={},{}
local function Place()
    if not K.ModuleOn("tooltip") or not GameTooltip or not GameTooltip:IsShown() or not K.DB().layout.tooltip then return end
    local ratio=anchor:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y=anchor:GetLeft()*ratio,anchor:GetBottom()*ratio
    local tooltipScale=GameTooltip:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local w,h=GameTooltip:GetWidth()*tooltipScale,GameTooltip:GetHeight()*tooltipScale
    x=math.max(8,math.min(K.UIWidth()-w-8,x)); y=math.max(8,math.min(K.UIHeight()-h-8,y))
    GameTooltip:ClearAllPoints(); GameTooltip:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/tooltipScale,y/tooltipScale)
end
local function Apply(tooltip)
    local state=saved[tooltip]
    if K.ModuleOn("tooltip") then
        if state then return end
        state={backdrop=tooltip.GetBackdrop and tooltip:GetBackdrop(),points={},owner=tooltip.SetOwner,show=tooltip:GetScript("OnShow")}
        if tooltip.GetBackdropColor then state.bg={tooltip:GetBackdropColor()} end
        if tooltip.GetBackdropBorderColor then state.border={tooltip:GetBackdropBorderColor()} end
        for i=1,tooltip:GetNumPoints() do state.points[i]={tooltip:GetPoint(i)} end
        local skin=skins[tooltip]
        if not skin then
            skin=CreateFrame("Frame",nil,tooltip); skin:SetAllPoints(tooltip); skin:EnableMouse(false)
            skin:SetFrameLevel(tooltip:GetFrameLevel()); K.Skin(skin,7); skins[tooltip]=skin
        end
        skin:Show(); state.skin=skin
        tooltip:SetBackdrop({}); saved[tooltip]=state
        if tooltip==GameTooltip then
            state.wrapper=function(self,frame,position,x,y)
                if K.ModuleOn("tooltip") and K.DB().layout.tooltip then state.owner(self,frame,"ANCHOR_NONE")
                else state.owner(self,frame,position,x,y) end
            end
            tooltip.SetOwner=state.wrapper
            state.onshow=function() if state.show then state.show() end; Place() end
            tooltip:SetScript("OnShow",state.onshow)
        end
    elseif state then
        state.skin:Hide()
        tooltip:SetBackdrop(state.backdrop or {})
        if state.bg then tooltip:SetBackdropColor(unpack(state.bg)) end
        if state.border then tooltip:SetBackdropBorderColor(unpack(state.border)) end
        if tooltip.SetOwner==state.wrapper then tooltip.SetOwner=state.owner end
        if tooltip:GetScript("OnShow")==state.onshow then tooltip:SetScript("OnShow",state.show) end
        tooltip:ClearAllPoints()
        for _,point in ipairs(state.points) do tooltip:SetPoint(unpack(point)) end
        saved[tooltip]=nil
    end
end
function K.moduleRefresh.tooltip()
    for _,name in ipairs({"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2"}) do
        local tooltip=getglobal(name); if tooltip then Apply(tooltip) end
    end
end
K.Update("tooltip",Place)
K.On("ADDON_LOADED",K.moduleRefresh.tooltip)
K.On("PLAYER_ENTERING_WORLD",K.moduleRefresh.tooltip)
K.ResetTooltip=function() K.layout.ResetKey("tooltip") end
K.moduleRefresh.tooltip()
