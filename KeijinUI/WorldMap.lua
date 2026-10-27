-- Native geometry/evidence: FrameXML WorldMapFrame.xml/.lua, UIParent.lua.
-- Keep the native map button, tiles, arrows, dropdowns and their scripts together.
-- A fullscreen UIPanel hides UIParent; a windowed map must leave that manager first.
local K=KeijinUI
local W=K.windowTools
local M={}
K.worldMap=M
local frame,native,panel,drag,close,applied
local changed={}
function M.On() return K.DB().smallWorldMap~=false end
local function BaseScale()
    return math.min(.65,(K.UIWidth()-32)/1024,(K.UIHeight()-32)/768)
end
local function NativeClose()
    if HideUIPanel then HideUIPanel(frame) else frame:Hide() end
end
local function Release()
    if not native then return end
    W.Restore(changed); changed={}
    frame:SetParent(native.parent)
    frame:SetScale(native.scale); frame:SetWidth(native.width); frame:SetHeight(native.height)
    W.Place(frame,native.points); frame:SetFrameStrata(native.strata)
    if UIPanelWindows and UIPanelWindows.WorldMapFrame==nil then UIPanelWindows.WorldMapFrame=native.manager end
    if panel then panel:Hide(); drag:Hide(); close:Hide() end
    applied=false
end
local function Apply()
    if not frame or not M.On() then return end
    -- The native OnShow calls SetupFullscreenScale every time: apply AFTER it.
    frame:SetParent(UIParent)
    frame:ClearAllPoints(); frame:SetWidth(1024); frame:SetHeight(768)
    frame:SetFrameStrata("DIALOG")
    if UIPanelWindows then UIPanelWindows.WorldMapFrame=nil end
    W.Art(changed,frame,"interface\\worldmap\\ui-worldmap-")
    for _,region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType()=="FontString" then W.Remember(changed,region); region:SetAlpha(0) end
    end
    if BlackoutWorld then W.Remember(changed,BlackoutWorld); BlackoutWorld:SetAlpha(0) end
    if WorldMapFrameCloseButton then W.Remember(changed,WorldMapFrameCloseButton); WorldMapFrameCloseButton:SetAlpha(0) end
    K.layout.Place("worldmap")
    panel:Show(); drag:Show(); close:Show(); applied=true
end
function M.Set(on)
    local shown=frame and frame:IsShown()
    if shown then K.layout.EndMove("worldmap"); NativeClose() end
    K.DB().smallWorldMap=on and true or false
    if M.On() then Apply() else Release() end
    if shown then if ShowUIPanel then ShowUIPanel(frame) else frame:Show() end end
end
local function Build()
    if frame or not WorldMapFrame then return end
    frame=WorldMapFrame
    native={points=W.Points(frame),width=frame:GetWidth(),height=frame:GetHeight(),scale=frame:GetScale(),
        strata=frame:GetFrameStrata(),parent=frame:GetParent(),manager=UIPanelWindows and UIPanelWindows.WorldMapFrame}
    -- Do not restyle an already open fullscreen panel before its manager releases UIParent.
    local shown=frame:IsShown()
    if shown and M.On() then NativeClose() end
    panel=K.Panel("KeijinUIWorldMap","Weltkarte",1024,768)
    panel:SetParent(frame); panel:SetAllPoints(frame); panel:SetFrameLevel(frame:GetFrameLevel())
    panel:SetFrameStrata("DIALOG")
    drag=CreateFrame("Frame","KeijinUIWorldMapDrag",frame)
    drag:SetFrameStrata("DIALOG"); drag:SetFrameLevel(frame:GetFrameLevel()+10)
    drag:SetWidth(960); drag:SetHeight(25); drag:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-4)
    W.Drag(drag,"worldmap",frame)
    close=CreateFrame("Button","KeijinUIWorldMapClose",frame)
    close:SetFrameStrata("DIALOG"); close:SetFrameLevel(frame:GetFrameLevel()+10)
    close:SetWidth(26); close:SetHeight(24); close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-9,-4)
    K.Text(close,"x",16,"CENTER",0,0)
    close:SetScript("OnClick",NativeClose)
    K.layout.Register("worldmap",frame,"Weltkarte",function(f)
        f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    end,{inactive=function() return not M.On() end,scale=BaseScale,titleDrag=true,
        maxScale=function() return math.min((K.UIWidth()-32)/1024,(K.UIHeight()-32)/768)/BaseScale() end})
    local special=false
    for _,name in ipairs(UISpecialFrames) do if name=="WorldMapFrame" then special=true end end
    if not special then table.insert(UISpecialFrames,"WorldMapFrame") end
    W.Hook(frame,"OnShow",Apply)
    W.Hook(frame,"OnHide",function() K.layout.EndMove("worldmap") end)
    if M.On() then Apply() end
    if shown and M.On() then if ShowUIPanel then ShowUIPanel(frame) else frame:Show() end end
end
function M.Refresh()
    Build()
    if not frame then return end
    if M.On() then
        if not applied then Apply() end
    elseif applied then M.Set(false) end
end
K.On("ADDON_LOADED",M.Refresh)
K.On("PLAYER_ENTERING_WORLD",M.Refresh)
K.Update("worldmap",M.Refresh)
M.Refresh()
