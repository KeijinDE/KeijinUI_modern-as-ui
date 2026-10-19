local K=KeijinUI
-- Existing comparison/link tooltips share the contour; keep their native ownership and anchors.
for _,name in ipairs({"ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2"}) do
    local tooltip=getglobal(name)
    if tooltip then K.Skin(tooltip,7) end
end
local anchor=CreateFrame("Frame","KeijinUITooltipAnchor",UIParent)
anchor:SetWidth(250); anchor:SetHeight(90); anchor:Hide()
K.layout.Register("tooltip",anchor,"Tooltip",function(f)
    f:ClearAllPoints(); f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-24,34)
end,{hidden=true})
local function Place()
    if not GameTooltip or not GameTooltip:IsShown() or not K.DB().layout.tooltip then return end
    local ratio=anchor:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y=anchor:GetLeft()*ratio,anchor:GetBottom()*ratio
    local tooltipScale=GameTooltip:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local w,h=GameTooltip:GetWidth()*tooltipScale,GameTooltip:GetHeight()*tooltipScale
    x=math.max(8,math.min(K.UIWidth()-w-8,x))
    y=math.max(8,math.min(K.UIHeight()-h-8,y))
    GameTooltip:ClearAllPoints(); GameTooltip:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/tooltipScale,y/tooltipScale)
end
if GameTooltip then
    K.Skin(GameTooltip,7)
    local owner=GameTooltip.SetOwner
    GameTooltip.SetOwner=function(tooltip,frame,position,x,y)
        if K.DB().layout.tooltip then owner(tooltip,frame,"ANCHOR_NONE")
        else owner(tooltip,frame,position,x,y) end
    end
    local original=GameTooltip:GetScript("OnShow")
    GameTooltip:SetScript("OnShow",function() if original then original() end; Place() end)
end
table.insert(K.updates,Place)
K.ResetTooltip=function() K.layout.ResetKey("tooltip") end
