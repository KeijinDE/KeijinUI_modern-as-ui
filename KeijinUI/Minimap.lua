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
-- Same base width as the run overview; personal layout scales remain independent.
local PANEL_W,PANEL_H=K.PANEL_WIDTH,K.PANEL_WIDTH+18
local MASK="Interface\\AddOns\\KeijinUI\\media\\MinimapMask.tga"
local DEFAULT_MASK="Textures\\MinimapMask"
local NATIVE={"MinimapBorderTop","MinimapBorder","MinimapBackdrop","MinimapToggleButton","MinimapZoneTextButton","GameTimeFrame"}
local CLOCK_W=40
local saved,styled,panel,zone,lastZone,clock,lastClock
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
    zone=K.Text(panel,"",11,"TOPLEFT",13,-10,PANEL_W-26-CLOCK_W)
    zone:SetTextColor(1,0.82,0.28)
    -- Clock at the right of the zone line. date() in this client always formats UTC (no timezone,
    -- benilla stdlib.rs) and GetGameTime() is the server time, so the clock is UTC plus the offset
    -- set in the options (K.DB().clockOffset, whole hours).
    clock=K.Text(panel,"",11,"TOPRIGHT",-13,-10)
    -- Thin border around the map, above it (higher frame level), only the edge is drawn.
    local inner=CreateFrame("Frame",nil,MinimapCluster)
    inner:SetFrameLevel(Minimap:GetFrameLevel()+1)
    inner:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-3,3); inner:SetPoint("BOTTOMRIGHT",Minimap,"BOTTOMRIGHT",3,-3)
    K.Chamfer(inner,3,nil,{0.62,0.57,0.43,0.8})
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
    local width=PANEL_W
    local size=width-20
    cluster:SetWidth(width); cluster:SetHeight(size+38)
    panel:SetWidth(width); panel:SetHeight(size+38)
    zone:SetWidth(width-26-CLOCK_W)
    map:ClearAllPoints(); map:SetPoint("TOPLEFT",cluster,"TOPLEFT",10,-28)
    map:SetWidth(size); map:SetHeight(size)
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
    lastZone=nil; lastClock=nil
end
-- Style on or off; the setting is saved, off restores the native look.
function K.SetMinimapStyle(on)
    K.DB().minimapStyle=on and true or false
    if not MinimapCluster or not Minimap then return end
    if on then Enable() else Disable() end
    if K.layout then K.layout.Place("minimap"); K.layout.Place("tracker") end
end
-- Clock offset to UTC in whole hours, -12 .. +14.
function K.ClockOffset()
    local v=tonumber(K.DB().clockOffset) or 0
    return math.max(-12,math.min(14,math.floor(v)))
end
function K.SetClockOffset(v)
    v=math.floor(tonumber(v) or 0)
    if v>14 then v=-12 elseif v<-12 then v=14 end
    K.DB().clockOffset=v
    lastClock=nil
end
function K.ClockOffsetText()
    local v=K.ClockOffset()
    if v==0 then return "UTC" end
    return "UTC"..(v>0 and "+" or "")..v
end
function K.MinimapStyled() return styled and true or false end
local function Update()
    if not MinimapCluster or not Minimap then return end
    Register()
    if Wanted() and not styled then Enable()
    elseif not Wanted() and styled then Disable() end
    if not styled then return end
    if MinimapCluster:GetWidth()~=PANEL_W then Enable() end
    HideNative()
    local text=(GetMinimapZoneText and GetMinimapZoneText()) or (GetRealZoneText and GetRealZoneText()) or ""
    if text~=lastZone then lastZone=text; zone:SetText(text) end
    local now=""
    if type(date)=="function" and type(time)=="function" then
        local ok,value=pcall(date,"!%H:%M",time()+K.ClockOffset()*3600)
        if ok and value then now=value end
    end
    if now~=lastClock then lastClock=now; clock:SetText(now) end
end
table.insert(K.updates,Update)
Register()
Update()
