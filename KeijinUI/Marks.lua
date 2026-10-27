-- Raid markers for units: a small menu (right click on target, player and party rows), /kui mark and key bindings.
-- API evidence: analysis/mpq/patch/Interface/FrameXML/TargetFrame.lua (SetRaidTargetIcon calls SetRaidTarget(unit,0|n),
-- SetRaidTargetIconTexture) and UnitPopup.lua (atlas, 4x4 cells of 0.25, marker colours); GetRaidTargetIndex(unit).
-- Whether the marker was applied is only known from GetRaidTargetIndex: without a group the game ignores the call,
-- so a short chat hint follows when nothing changed. Missing functions never raise an error.
local K=KeijinUI
local M={}
K.marks=M
local ATLAS="Interface\\TargetingFrame\\UI-RaidTargetingIcons"
-- German source texts (translated by K.T); same order as the atlas.
local NAMES={"Stern","Kreis","Diamant","Dreieck","Mond","Quadrat","Kreuz","Totenkopf"}
local COLORS={{1,0.92,0},{0.98,0.57,0},{0.83,0.22,0.9},{0.04,0.95,0},{0.7,0.82,0.875},{0,0.71,1},{1,0.24,0.168},{0.98,0.98,0.98}}
local CELL,GAP,PAD,COLS=30,4,10,4
local WIDTH=PAD*2+COLS*CELL+(COLS-1)*GAP
local LABEL_Y,GRID_Y,REMOVE_H=-9,-30,20
local REMOVE_Y=GRID_Y-2*CELL-GAP-6
local HEIGHT=-REMOVE_Y+REMOVE_H+PAD
-- Inspect row below the remove button, only for other players; the menu grows by one row then.
local INSPECT_Y=REMOVE_Y-REMOVE_H-GAP
local INSPECT_HEIGHT=HEIGHT+REMOVE_H+GAP
local CHECK_AFTER=1.0
M.WIDTH,M.HEIGHT,M.CELL,M.INSPECT_HEIGHT=WIDTH,HEIGHT,CELL,INSPECT_HEIGHT
M.names=NAMES

-- Mark of a unit as 0..8 (0 = none or unknown).
local function Current(unit)
    if type(GetRaidTargetIndex)~="function" or not unit or not UnitExists(unit) then return 0 end
    local index=GetRaidTargetIndex(unit)
    if not K.Number(index) or index<1 or index>8 or index~=math.floor(index) then return 0 end
    return index
end
M.Current=Current
local function InGroup()
    local party=type(GetNumPartyMembers)=="function" and GetNumPartyMembers() or 0
    local raid=type(GetNumRaidMembers)=="function" and GetNumRaidMembers() or 0
    return (K.Number(party) and party>0) or (K.Number(raid) and raid>0)
end

local pending
-- Sets (1..8), toggles (same marker again) or removes (0) the marker of the unit. Returns true when the call was made.
function M.Set(unit,index)
    if type(SetRaidTarget)~="function" then return false end
    if not unit or not UnitExists(unit) then K.Say(K.T("Kein Ziel")); return false end
    index=tonumber(index)
    if not index or index<0 or index>8 or index~=math.floor(index) then return false end
    if index>0 and index==Current(unit) then index=0 end
    SetRaidTarget(unit,index)
    pending={unit=unit,want=index,time=GetTime()}
    return true
end
-- Waits for a marker change after the call; no change and no group means the game ignored it.
K.Update("marks",function()
    if not pending or GetTime()-pending.time<CHECK_AFTER then return end
    local check=pending
    pending=nil
    if Current(check.unit)~=check.want and not InGroup() then K.Say(K.T("Raidmarker gehen nur in einer Gruppe.")) end
end)
K.On("RAID_TARGET_UPDATE",function() pending=nil end)

-- Inspect (UnitPopup.lua:552 calls InspectUnit(unit), greyed out unless CheckInteractDistance(unit,1), UnitPopup.lua:470).
-- InspectUnit loads Blizzard_InspectUI and opens the game's own window (UIParent.lua:223).
local function Inspectable(unit)
    if type(InspectUnit)~="function" or not unit or unit=="player" or not UnitExists(unit) then return false end
    if type(UnitIsUnit)=="function" and UnitIsUnit(unit,"player") then return false end
    if type(UnitIsPlayer)~="function" or not UnitIsPlayer(unit) then return false end
    if type(UnitIsFriend)=="function" and not UnitIsFriend("player",unit) then return false end
    return true
end
local function InRange(unit)
    if type(CheckInteractDistance)~="function" then return true end
    return CheckInteractDistance(unit,1) and true or false
end
M.Inspectable,M.InRange=Inspectable,InRange
function M.Inspect(unit)
    if not Inspectable(unit) then return false end
    if not InRange(unit) then K.Say(K.T("Zu weit entfernt zum Betrachten.")); return false end
    InspectUnit(unit)
    return true
end

-- /kui mark <1-8|0>: marker for the current target.
function M.Command(value)
    local index=tonumber(value)
    if not index or index<0 or index>8 or index~=math.floor(index) then
        K.Say(K.T("/kui mark <1-8|0>: Raidmarker auf das Ziel setzen (0 entfernt)."))
        return
    end
    M.Set("target",index)
end

-- Menu ------------------------------------------------------------------------------------------------------
-- A transparent frame over the whole screen catches the click outside the menu.
local catcher=CreateFrame("Frame","KeijinUIMarkCatcher",UIParent)
catcher:SetFrameStrata("DIALOG"); catcher:SetAllPoints(UIParent); catcher:EnableMouse(true); catcher:Hide()
local menu=CreateFrame("Frame","KeijinUIMarkMenu",UIParent)
menu:SetFrameStrata("DIALOG"); menu:SetFrameLevel(catcher:GetFrameLevel()+2)
menu:SetWidth(WIDTH); menu:SetHeight(HEIGHT); menu:EnableMouse(true); menu:SetClampedToScreen(true)
K.Skin(menu,7)
menu:Hide()
M.menu,M.catcher=menu,catcher
local label=K.Text(menu,"",11,"TOP",0,LABEL_Y,WIDTH-2*PAD)
label:SetJustifyH("CENTER")
M.label=label
local cells={}
M.cells=cells
local function Default()
    label:SetText(menu.unit and UnitName(menu.unit) or K.T("Raidmarker"))
    label:SetTextColor(1,0.82,0.28)
end
local function Mark()
    return Current(menu.unit)
end
local function Refresh()
    local current=Mark()
    for i=1,8 do
        local cell=cells[i]
        if i==current then cell.sel:Show() else cell.sel:Hide() end
    end
    menu.remove.text:SetTextColor(current>0 and 0.94 or 0.55,current>0 and 0.91 or 0.55,current>0 and 0.82 or 0.55)
    local near=menu.unit and InRange(menu.unit)
    menu.inspect.text:SetTextColor(near and 0.94 or 0.55,near and 0.91 or 0.55,near and 0.82 or 0.55)
end
function M.Close()
    menu:Hide(); catcher:Hide()
    menu.unit=nil
end
-- Unit tokens change their meaning: a new target or party roster would get the marker meant for the old one.
K.On("PLAYER_TARGET_CHANGED",function() if menu.unit=="target" then M.Close() end end)
K.On("PARTY_MEMBERS_CHANGED",function() if menu.unit and string.find(menu.unit,"^party") then M.Close() end end)
K.On("PLAYER_ENTERING_WORLD",function() if menu.unit then M.Close() end end)
-- A click on a marker applies it to the unit the menu was opened for and closes the menu.
function M.Choose(index)
    local unit=menu.unit
    M.Close()
    if unit then M.Set(unit,index) end
end
local function CellClick() M.Choose(this.index) end
local function CellEnter()
    this.hi:Show()
    local color=COLORS[this.index]
    label:SetText(K.T(NAMES[this.index])); label:SetTextColor(color[1],color[2],color[3])
end
local function CellLeave() this.hi:Hide(); Default() end
for i=1,8 do
    local cell=CreateFrame("Button","KeijinUIMarkCell"..i,menu)
    cell:SetWidth(CELL); cell:SetHeight(CELL)
    local column,row=math.mod(i-1,COLS),math.floor((i-1)/COLS)
    cell:SetPoint("TOPLEFT",menu,"TOPLEFT",PAD+column*(CELL+GAP),GRID_Y-row*(CELL+GAP))
    cell:RegisterForClicks("LeftButtonUp")
    cell.index=i
    cell.sel=cell:CreateTexture(nil,"BACKGROUND")
    cell.sel:SetTexture(K.flat); cell.sel:SetVertexColor(1,0.82,0.28,0.4); cell.sel:SetAllPoints(cell); cell.sel:Hide()
    cell.hi=cell:CreateTexture(nil,"BORDER")
    cell.hi:SetTexture(K.flat); cell.hi:SetVertexColor(1,1,1,0.16); cell.hi:SetAllPoints(cell); cell.hi:Hide()
    cell.icon=cell:CreateTexture(nil,"ARTWORK")
    cell.icon:SetWidth(CELL-6); cell.icon:SetHeight(CELL-6); cell.icon:SetPoint("CENTER",cell,"CENTER",0,0)
    cell.icon:SetTexture(ATLAS)
    local left,top=math.mod(i-1,4)/4,math.floor((i-1)/4)/4
    cell.icon:SetTexCoord(left,left+0.25,top,top+0.25)
    cell:SetScript("OnClick",CellClick)
    cell:SetScript("OnEnter",CellEnter)
    cell:SetScript("OnLeave",CellLeave)
    cells[i]=cell
end
local remove=CreateFrame("Button","KeijinUIMarkRemove",menu)
remove:SetWidth(WIDTH-2*PAD); remove:SetHeight(REMOVE_H)
remove:SetPoint("TOPLEFT",menu,"TOPLEFT",PAD,REMOVE_Y)
remove:RegisterForClicks("LeftButtonUp")
K.Skin(remove,4)
remove.text=K.LText(remove,"Entfernen",10,"CENTER",0,0)
remove.index=0
remove:SetScript("OnClick",CellClick)
remove:SetScript("OnEnter",function() remove:SetBackdropBorderColor(.94,.74,.37,1); label:SetText(K.T("Entfernen")); label:SetTextColor(1,0.82,0.28) end)
remove:SetScript("OnLeave",function() remove:SetBackdropBorderColor(.62,.57,.43,1); Default() end)
menu.remove=remove
local inspect=CreateFrame("Button","KeijinUIMarkInspect",menu)
inspect:SetWidth(WIDTH-2*PAD); inspect:SetHeight(REMOVE_H)
inspect:SetPoint("TOPLEFT",menu,"TOPLEFT",PAD,INSPECT_Y)
inspect:RegisterForClicks("LeftButtonUp")
K.Skin(inspect,4)
inspect.text=K.LText(inspect,"Betrachten",10,"CENTER",0,0)
inspect:SetScript("OnClick",function()
    local unit=menu.unit
    M.Close()
    if unit then M.Inspect(unit) end
end)
inspect:SetScript("OnEnter",function()
    inspect:SetBackdropBorderColor(.94,.74,.37,1); Refresh()
    label:SetText(K.T("Betrachten")); label:SetTextColor(1,0.82,0.28)
end)
inspect:SetScript("OnLeave",function() inspect:SetBackdropBorderColor(.62,.57,.43,1); Default() end)
inspect:Hide()
menu.inspect=inspect
menu:RegisterEvent("RAID_TARGET_UPDATE")
menu:SetScript("OnEvent",function() if menu:IsShown() then Refresh() end end)
-- Distance changes while the menu is open: the inspect row follows it a few times per second.
local sinceRange=0
menu:SetScript("OnUpdate",function()
    if not inspect:IsShown() then return end
    sinceRange=sinceRange+(arg1 or 0)
    if sinceRange<0.2 then return end
    sinceRange=0
    Refresh()
end)
menu:SetScript("OnHide",function() catcher:Hide() end)
catcher:SetScript("OnMouseDown",function() M.Close() end)
table.insert(UISpecialFrames,"KeijinUIMarkMenu")
K.OnLang(function() if menu:IsShown() then Default() end end)

-- Cursor position in UIParent points, or the centre of the anchor frame.
local function Origin(anchor)
    local scale=UIParent:GetEffectiveScale()
    if type(GetCursorPosition)=="function" and K.Number(scale) and scale>0 then
        local x,y=GetCursorPosition()
        if K.Number(x) and K.Number(y) then return x/scale,y/scale end
    end
    if anchor and anchor.GetCenter and K.Number(scale) and scale>0 then
        local x,y=anchor:GetCenter()
        local own=anchor:GetEffectiveScale()
        if K.Number(x) and K.Number(y) and K.Number(own) then return x*own/scale,y*own/scale end
    end
    return K.UIWidth()/2,K.UIHeight()/2
end
-- Opens the menu for a unit token next to the mouse pointer; it stays inside the screen.
function M.Open(unit,anchor)
    if type(SetRaidTarget)~="function" then return false end
    if not unit or not UnitExists(unit) then K.Say(K.T("Kein Ziel")); return false end
    local height=HEIGHT
    if Inspectable(unit) then height=INSPECT_HEIGHT; inspect:Show() else inspect:Hide() end
    menu:SetHeight(height)
    local x,y=Origin(anchor)
    local left=math.max(0,math.min(x-12,K.UIWidth()-WIDTH))
    local top=math.max(height,math.min(y+12,K.UIHeight()))
    menu.unit=unit
    menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top)
    Default(); Refresh()
    for i=1,8 do cells[i].hi:Hide() end
    catcher:Show(); menu:Show()
    return true
end

-- Key bindings (Bindings.xml): names are set as globals, in the current language.
local function BindingNames()
    setglobal("BINDING_HEADER_KEIJINUI","KeijinUI")
    setglobal("BINDING_NAME_KEIJINUI_LAYOUT",K.T("Layout bearbeiten"))
    for i=1,8 do setglobal("BINDING_NAME_KEIJINUI_MARK"..i,K.T("Raidmarker")..": "..K.T(NAMES[i])) end
    setglobal("BINDING_NAME_KEIJINUI_MARK0",K.T("Raidmarker")..": "..K.T("Entfernen"))
end
BindingNames()
K.OnLang(BindingNames)
