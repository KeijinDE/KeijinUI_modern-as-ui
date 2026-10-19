-- Minimap button: left click opens the settings, right click the run overview, drag moves it along the map edge.
-- Client evidence (same API as the other files): CreateFrame("Button"), RegisterForClicks, RegisterForDrag,
-- GetCursorPosition, GetEffectiveScale, GameTooltip:SetOwner/SetText/AddLine/Show/Hide. Symbol: the wordmark "Kui" in the UI font.
-- The angle (degrees, 0 = east, counterclockwise) is kept in KeijinUIDB.minimapButtonAngle. On the square
-- KeijinUI minimap the angle is projected onto the square edge, on the original minimap onto a circle.
local K=KeijinUI
-- 225 degrees: the lower left corner of the square map (on the round map the lower left of the ring).
local SIZE,DEFAULT_ANGLE=32,225
local EDGE,RING=2,9
local button,placedStyle,placedWidth,placedAngle,dragging
local function Wanted() return K.DB().minimapButton~=false end
local function Angle()
    local a=tonumber(K.DB().minimapButtonAngle)
    if not a then return DEFAULT_ANGLE end
    return a
end
-- Centre of the button relative to the centre of the minimap for an angle.
function K.MinimapButtonOffset(angle,half,square)
    local a=math.rad(angle)
    local dx,dy=math.cos(a),math.sin(a)
    if square then
        local m=math.max(math.abs(dx),math.abs(dy))
        local h=half+EDGE
        return dx/m*h,dy/m*h
    end
    local r=half+RING
    return dx*r,dy*r
end
local function Place()
    if not button or not Minimap then return end
    local half=Minimap:GetWidth()/2
    local x,y=K.MinimapButtonOffset(Angle(),half,K.MinimapStyled and K.MinimapStyled())
    button:ClearAllPoints(); button:SetPoint("CENTER",Minimap,"CENTER",x,y)
    placedStyle=K.MinimapStyled and K.MinimapStyled() and true or false
    placedWidth=Minimap:GetWidth(); placedAngle=Angle()
end
local function Drag()
    if not dragging or not Minimap.GetLeft or not Minimap:GetLeft() then return end
    local cx,cy=GetCursorPosition()
    local scale=Minimap:GetEffectiveScale()
    local mx=Minimap:GetLeft()+Minimap:GetWidth()/2
    local my=Minimap:GetBottom()+Minimap:GetHeight()/2
    local a=math.deg(math.atan2(cy/scale-my,cx/scale-mx))
    if a<0 then a=a+360 end
    K.DB().minimapButtonAngle=a
    Place()
end
local function Tip()
    GameTooltip:SetOwner(this,"ANCHOR_LEFT")
    GameTooltip:SetText("KeijinUI",1,0.82,0.28)
    GameTooltip:AddLine(K.T("Linksklick: Optionen"),0.9,0.9,0.9)
    GameTooltip:AddLine(K.T("Rechtsklick: Rundenübersicht"),0.9,0.9,0.9)
    GameTooltip:AddLine(K.T("Ziehen: verschieben"),0.6,0.6,0.62)
    GameTooltip:Show()
end
local function Build()
    if button or not Minimap then return end
    button=CreateFrame("Button","KeijinUIMinimapButton",Minimap)
    button:SetWidth(SIZE); button:SetHeight(SIZE)
    button:SetFrameStrata("MEDIUM"); button:SetFrameLevel(Minimap:GetFrameLevel()+8)
    K.Chamfer(button,2,{0.055,0.055,0.065,0.95},{0.62,0.57,0.43,0.9})
    -- Wordmark "Kui": a large gold K with a small pale "ui" on its baseline.
    local icon=K.Text(button,"K",21,"CENTER",-4,1)
    local sub=K.Text(button,"ui",11,"BOTTOMRIGHT",-4,5)
    button.icon,button.sub=icon,sub
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick",function()
        if arg1=="RightButton" then K.runs.Toggle() else SlashCmdList.KEIJINUI("") end
    end)
    button:SetScript("OnEnter",function()
        this:SetBackdropBorderColor(1,0.82,0.28,1); icon:SetTextColor(1,0.9,0.5); sub:SetTextColor(1,1,1)
        if not dragging then Tip() end
    end)
    button:SetScript("OnLeave",function()
        this:SetBackdropBorderColor(0.62,0.57,0.43,0.9); icon:SetTextColor(1,0.82,0.28); sub:SetTextColor(0.94,0.91,0.82)
        GameTooltip:Hide()
    end)
    icon:SetTextColor(1,0.82,0.28); sub:SetTextColor(0.94,0.91,0.82)
    button:SetScript("OnDragStart",function()
        dragging=true; GameTooltip:Hide()
        this:SetScript("OnUpdate",Drag)
    end)
    button:SetScript("OnDragStop",function()
        dragging=false
        this:SetScript("OnUpdate",nil)
    end)
    Place()
end
function K.MinimapButtonOn() return Wanted() end
-- Eight fixed spots around the map, as angles (0 = right middle, counterclockwise). A dragged angle shows the nearest.
K.minimapButtonSpots={{"0","Rechts mittig"},{"45","Rechts oben"},{"90","Oben mittig"},{"135","Links oben"},
    {"180","Links mittig"},{"225","Links unten"},{"270","Unten mittig"},{"315","Rechts unten"}}
function K.MinimapButtonSpot()
    local a=math.mod(Angle(),360); if a<0 then a=a+360 end
    return tostring(math.mod(math.floor(a/45+0.5),8)*45)
end
function K.SetMinimapButtonSpot(value)
    local a=tonumber(value); if not a then return end
    K.DB().minimapButtonAngle=a; Place()
end
function K.SetMinimapButton(on)
    K.DB().minimapButton=on and true or false
    if on then Build(); Place(); if button then button:Show() end
    elseif button then button:Hide() end
end
local function Update()
    if not Minimap then return end
    if not Wanted() then
        if button and button:IsShown() then button:Hide() end
        return
    end
    Build()
    if not button then return end
    if not button:IsShown() then button:Show() end
    local styled=K.MinimapStyled and K.MinimapStyled() and true or false
    -- The saved angle arrives after the files load (ADDON_LOADED), so a changed angle re-places the button too.
    if styled~=placedStyle or Minimap:GetWidth()~=placedWidth or Angle()~=placedAngle then Place() end
end
-- /kui button [on|off]
function K.MinimapButtonCommand(arg)
    arg=arg or ""
    local on
    if arg=="on" then on=true elseif arg=="off" then on=false else on=not Wanted() end
    K.SetMinimapButton(on)
    K.Say(K.T("Minimapknopf")..": "..(on and K.T("An") or K.T("Aus")))
end
table.insert(K.updates,Update)
Update()
