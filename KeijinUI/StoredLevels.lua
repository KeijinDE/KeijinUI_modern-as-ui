-- Native stored choices, with no automatic spending and no preference changes at startup.
local K=KeijinUI
local S={}
K.storedLevels=S
local frame=CreateFrame("Button","KeijinUIStoredLevels",UIParent)
frame:SetWidth(176); frame:SetHeight(34); frame:SetFrameStrata("LOW"); K.Skin(frame,7); frame:Hide()
local icon=frame:CreateTexture(nil,"ARTWORK")
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09"); icon:SetWidth(22); icon:SetHeight(22); icon:SetPoint("LEFT",frame,"LEFT",6,0)
local label=K.Text(frame,"",11,"LEFT",35,0,132); label:SetHeight(22)
S.frame,S.label=frame,label
K.layout.Register("levels",frame,"Gespeicherte Level",function(f)
    f:ClearAllPoints(); f:SetPoint("BOTTOM",KeijinUISkills or UIParent,KeijinUISkills and "TOP" or "BOTTOM",0,KeijinUISkills and 10 or 160)
end,{hidden=true})
function S.On() return K.ModuleOn("storedLevels") and K.DB().storedLevels~=false end
function S.Supported()
    return type(AZS_GetStoredLevels)=="function" and type(AZS_OpenStoredLevels)=="function"
        and type(AZS_SetHudShown)=="function" and type(AZS_IsHudShown)=="function"
        and type(AZS_HUD_CVARS)=="table" and type(AZS_HUD_CVARS.levels)=="string"
end
function S.CanStore() return type(AZS_IsStoringLevels)=="function" and type(AZS_SetStoringLevels)=="function" end
function S.Storing() return S.CanStore() and AZS_IsStoringLevels() and true or false end
function S.SetStoring(on)
    if not S.CanStore() then return false end
    AZS_SetStoringLevels(on and true or false); S.Update(); return true
end
function S.Set(on) K.DB().storedLevels=on and true or false; S.Update() end
-- Module "Gespeicherte Level" off: the game offers every level-up at once again. The switch it had is remembered
-- and restored when the module comes back.
function S.Suspend()
    local db=K.DB()
    if S.Storing() then db.storedLevelsHeld=true; AZS_SetStoringLevels(false) end
    S.Update()
end
function S.Resume()
    local db=K.DB()
    if db.storedLevelsHeld then db.storedLevelsHeld=nil; S.SetStoring(true) end
    S.Update()
end
function S.Count()
    if not S.Supported() then return 0 end
    local value=AZS_GetStoredLevels()
    if not K.Number(value) then return 0 end
    return math.floor(value)
end
function S.Update()
    local supported=S.Supported()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local active=K.navigation.Active()
    local count=active and S.Count() or 0
    -- Only take ownership of a supported native HUD. K.Native restores the player's earlier setting.
    local hud=type(AZS_HUD_CVARS)=="table" and AZS_HUD_CVARS.levels
    if hud and supported and not S.On() then K.NativeFollow("levels",false)
    else K.Native("levels",hud and supported and S.On() and active and true or false) end
    S.count=count
    if not supported or not S.On() or count<=0 then frame:Hide(); return end
    local canOpen=phase=="playing"
    label:SetText(K.T("Levelaufstieg (%d)",count))
    label:SetTextColor(1,.82,.28); frame:SetAlpha(canOpen and 1 or .65); frame:Show()
end
frame:SetScript("OnClick",function()
    -- Paused or already choosing: do not enqueue repeated requests or change the game phase.
    if S.On() and S.Supported() and K.navigation.Active() and AZS_GetPhase and AZS_GetPhase()=="playing" and S.Count()>0 then AZS_OpenStoredLevels() end
end)
frame:SetScript("OnEnter",function()
    GameTooltip:SetOwner(frame,"ANCHOR_TOP"); GameTooltip:SetText(K.T("Gespeicherte Level"),1,.82,.28)
    GameTooltip:AddLine(K.T("%d Auswahlen warten. Klicken, um sie nacheinander auszugeben.",S.count or 0),.9,.88,.8,true)
    GameTooltip:AddLine(K.T("Im Kampf verfügbar. Pause und laufende Auswahl zuerst schließen."),.7,.7,.7,true); GameTooltip:Show()
end)
frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
frame:SetScript("OnHide",function() if GameTooltip.GetOwner and GameTooltip:GetOwner()==frame then GameTooltip:Hide() end end)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.layout.Place("levels"); S.Update() end end)
K.Update("storedLevels",S.Update)

function S.Debug()
    K.Say("Stored levels: supported="..tostring(S.Supported())..", storing="..tostring(S.Storing())..", count="..S.Count()..", shown="..tostring(frame:IsShown()))
end
