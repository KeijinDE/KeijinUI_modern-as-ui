-- A small original alpha ring; uses the same physical-cursor/scale conversion
-- as the client's FloatingChatFrame.lua. It never captures mouse input.
local K=KeijinUI
local C={}
K.cursor=C
local frame=CreateFrame("Frame","KeijinUICursor",UIParent)
frame:SetFrameStrata("TOOLTIP"); frame:EnableMouse(false); frame:Hide()
local texture=frame:CreateTexture(nil,"OVERLAY")
texture:SetTexture("Interface\\AddOns\\KeijinUI\\media\\CursorRing.tga"); texture:SetAllPoints(frame)
C.frame,C.texture=frame,texture
function C.On() return K.ModuleOn("cursor") and K.DB().cursorTracker==true end
function C.Size()
    local size=K.DB().cursorSize
    return K.Number(size) and math.max(16,math.min(64,math.floor(size+0.5))) or 24
end
function C.Color()
    local c=K.DB().cursorColor
    if type(c)=="table" and K.Number(c[1]) and K.Number(c[2]) and K.Number(c[3]) then
        return math.min(1,c[1]),math.min(1,c[2]),math.min(1,c[3])
    end
    return 0.88,0.68,0.32
end
local function Position()
    if not C.On() then frame:Hide(); return end
    local x,y=GetCursorPosition()
    local scale=UIParent:GetEffectiveScale()
    if not K.Number(x) or not K.Number(y) or not scale or scale<=0 then frame:SetAlpha(0); return end
    frame:ClearAllPoints(); frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
    frame:SetAlpha(1)
end
function C.Apply()
    frame:SetWidth(C.Size()); frame:SetHeight(C.Size())
    texture:SetVertexColor(C.Color())
    if C.On() and type(GetCursorPosition)=="function" then
        frame:SetScript("OnUpdate",Position); frame:Show(); Position()
    else frame:SetScript("OnUpdate",nil); frame:Hide() end
end
function C.Set(on) K.DB().cursorTracker=on and true or false; C.Apply() end
function C.SetSize(value)
    if not K.Number(value) then return end
    K.DB().cursorSize=math.max(16,math.min(64,math.floor(value+0.5))); C.Apply()
end
function C.SetColor(r,g,b)
    if not K.Number(r) or not K.Number(g) or not K.Number(b) then return end
    K.DB().cursorColor={math.min(1,r),math.min(1,g),math.min(1,b)}; C.Apply()
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then C.Apply() end end)
K.On("PLAYER_ENTERING_WORLD",C.Apply)
C.Apply()

K.moduleRefresh.cursor=C.Apply
