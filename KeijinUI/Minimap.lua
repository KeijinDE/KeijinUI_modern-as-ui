-- Square minimap in the style of the other panels.
-- Client evidence (analysis/benilla-reference): the Minimap widget exists (FrameXML Minimap.xml) and
-- has SetMaskTexture, GetZoom, SetZoom and GetZoomLevels. The mask is read from its alpha channel
-- and stretched over the widget rectangle, so a fully opaque TGA gives a square map. A path under
-- Interface\AddOns\ loads like the other addon art. The default mask is Textures\MinimapMask.
-- MinimapCluster is the layout frame (key "minimap"): its size follows the style, the map and the
-- panel sit inside it. Native pieces that are hidden (all named in FrameXML Minimap.xml or
-- GameTime.xml): MinimapBorderTop, MinimapBackdrop (round border, holds MinimapBorder and the
-- MinimapZoomIn and MinimapZoomOut buttons), MinimapToggleButton, MinimapZoneTextButton and
-- GameTimeFrame. The tracking, mail, battleground and meeting stone icons stay as they are.
local K=KeijinUI
local PANEL_W,PANEL_H,SIZE=180,198,160
local MASK="Interface\\AddOns\\KeijinUI\\media\\MinimapMask.tga"
local DEFAULT_MASK="Textures\\MinimapMask"
local NATIVE={"MinimapBorderTop","MinimapBorder","MinimapBackdrop","MinimapToggleButton","MinimapZoneTextButton","GameTimeFrame"}
local saved,styled,panel,zone,lastZone
local hidden={}
local function Wanted() return K.DB().minimapStyle~=false end
local function Register()
    if MinimapCluster then
        K.layout.Register("minimap",MinimapCluster,"Minimap",function(f)
            f:ClearAllPoints(); f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12,-12)
        end)
    end
end
local function Build()
    if panel then return end
    panel=K.Panel("KeijinUIMinimap","",PANEL_W,PANEL_H)
    panel.title:Hide()
    panel:SetParent(MinimapCluster); panel:SetFrameStrata("BACKGROUND")
    panel:SetFrameLevel(math.max(0,Minimap:GetFrameLevel()-1))
    panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",MinimapCluster,"TOPLEFT",0,0)
    zone=K.Text(panel,"",11,"TOPLEFT",13,-10,PANEL_W-26)
    zone:SetTextColor(1,0.82,0.28)
    -- Thin border around the map, above it (higher frame level), only the edge is drawn.
    local inner=CreateFrame("Frame",nil,MinimapCluster)
    inner:SetFrameLevel(Minimap:GetFrameLevel()+1)
    inner:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-3,3); inner:SetPoint("BOTTOMRIGHT",Minimap,"BOTTOMRIGHT",3,-3)
    inner:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10})
    inner:SetBackdropBorderColor(0.62,0.57,0.43,0.8)
    inner:EnableMouse(false)
    panel.inner=inner
end
local function Wheel()
    local map=Minimap
    if not (map.GetZoom and map.SetZoom and map.GetZoomLevels) then return end
    local top=(tonumber(map:GetZoomLevels()) or 1)-1
    local zoom=(tonumber(map:GetZoom()) or 0)+((arg1 or 0)>0 and 1 or -1)
    map:SetZoom(math.max(0,math.min(top,zoom)))
end
local function HideNative()
    for _,name in ipairs(NATIVE) do
        local f=getglobal(name)
        if f and f.IsShown and f:IsShown() then
            if hidden[name]==nil then hidden[name]=true end
            f:Hide()
        end
    end
end
local function Enable()
    local cluster,map=MinimapCluster,Minimap
    if not cluster or not map then return end
    if not saved then
        saved={cw=cluster:GetWidth(),ch=cluster:GetHeight(),mw=map:GetWidth(),mh=map:GetHeight(),point={map:GetPoint()}}
    end
    Build()
    cluster:SetWidth(PANEL_W); cluster:SetHeight(PANEL_H)
    panel:SetWidth(PANEL_W); panel:SetHeight(PANEL_H)
    map:ClearAllPoints(); map:SetPoint("TOPLEFT",cluster,"TOPLEFT",10,-28)
    map:SetWidth(SIZE); map:SetHeight(SIZE)
    if map.SetMaskTexture then map:SetMaskTexture(MASK) end
    map:EnableMouseWheel(true); map:SetScript("OnMouseWheel",Wheel)
    styled=true
    panel:Show(); panel.inner:Show()
    HideNative()
end
local function Disable()
    local cluster,map=MinimapCluster,Minimap
    styled=false
    if panel then panel:Hide(); panel.inner:Hide() end
    if not saved or not cluster or not map then return end
    cluster:SetWidth(saved.cw); cluster:SetHeight(saved.ch)
    map:SetWidth(saved.mw); map:SetHeight(saved.mh)
    map:ClearAllPoints()
    local p=saved.point
    if p[1] then map:SetPoint(p[1],p[2] or cluster,p[3] or p[1],p[4] or 0,p[5] or 0) else map:SetPoint("CENTER",cluster,"TOP",9,-92) end
    if map.SetMaskTexture then map:SetMaskTexture(DEFAULT_MASK) end
    map:EnableMouseWheel(false); map:SetScript("OnMouseWheel",nil)
    for name in pairs(hidden) do
        local f=getglobal(name)
        if f then f:Show() end
    end
    hidden={}
    lastZone=nil
end
-- Style on or off; the setting is saved, off restores the native look.
function K.SetMinimapStyle(on)
    K.DB().minimapStyle=on and true or false
    if not MinimapCluster or not Minimap then return end
    if on then Enable() else Disable() end
    if K.layout then K.layout.Place("minimap"); K.layout.Place("tracker") end
end
function K.MinimapStyled() return styled and true or false end
local function Update()
    if not MinimapCluster or not Minimap then return end
    Register()
    if Wanted() and not styled then Enable()
    elseif not Wanted() and styled then Disable() end
    if not styled then return end
    HideNative()
    local text=(GetMinimapZoneText and GetMinimapZoneText()) or (GetRealZoneText and GetRealZoneText()) or ""
    if text~=lastZone then lastZone=text; zone:SetText(text) end
end
table.insert(K.updates,Update)
Register()
Update()
