-- Commit only at logout, after the existing native HUD/CVar cleanup. Keeping
-- bindings and collected data separate also makes restoring an older backup safe.
local K=KeijinUI
local O=K.settings
local R={}
K.settingsReset=R
local pending
local keep={lang=true,runs=true,runSnapshots=true,snapshotSerial=true,runTrace=true,
    paceHistory=true,itemDiary=true,autoWalkKey=true,autoWalkSet=true,autoWalkPrevious=true,
    autoWalkHeld=true,shortcuts=true,shortcutsHeld=true}
local transient={settingsBackup=true,native=true,originalCombatDamage=true,originalShowCombatText=true}
local function Copy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}
    if seen[value] then return seen[value] end
    local out={}; seen[value]=out
    for key,item in pairs(value) do out[key]=Copy(item,seen) end
    return out
end
local function Snapshot()
    local options={}
    for key,value in pairs(K.DB()) do
        if not keep[key] and not transient[key] then options[key]=Copy(value) end
    end
    local achievements=Copy(KeijinUIAchievementsDB or {}); achievements.log=nil
    return {schema=1,options=options,build=Copy(KeijinUIBuildDB or {}),achievements=achievements}
end
function R.HasBackup()
    local backup=K.DB().settingsBackup
    return type(backup)=="table" and backup.schema==1 and type(backup.options)=="table"
        and type(backup.build)=="table" and type(backup.achievements)=="table"
end
function R.Request(restore)
    if pending or type(ReloadUI)~="function" or (restore and not R.HasBackup()) then return false end
    pending=restore and "restore" or "reset"
    ReloadUI()
    return true
end
-- Registered after the normal cleanup handlers. Records updated by other logout
-- frames remain the same tables; a backup never rewinds a run or the diary.
K.On("PLAYER_LOGOUT",function()
    if not pending then return end
    local db=K.DB()
    local backup=pending=="reset" and Snapshot() or db.settingsBackup
    local options,build,achievements={},{},{}
    if pending=="restore" then
        options=Copy(backup.options); build=Copy(backup.build); achievements=Copy(backup.achievements)
    end
    for key in pairs(keep) do options[key]=db[key] end
    if type(KeijinUIAchievementsDB)=="table" then achievements.log=KeijinUIAchievementsDB.log end
    options.settingsBackup=backup
    KeijinUIDB,KeijinUIBuildDB,KeijinUIAchievementsDB=options,build,achievements
    pending=nil
end)

local shield=CreateFrame("Frame","KeijinUIResetConfirm",UIParent)
shield:SetAllPoints(UIParent); shield:SetFrameStrata("FULLSCREEN_DIALOG"); shield:EnableMouse(true); shield:Hide()
table.insert(UISpecialFrames,"KeijinUIResetConfirm")
local dialog=K.Panel("KeijinUIResetDialog","Zurücksetzen",520,246)
dialog:SetParent(shield); dialog:SetPoint("CENTER",shield,"CENTER",0,0)
dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:SetFrameLevel(shield:GetFrameLevel()+1); dialog:EnableMouse(true)
dialog.noOpacity=true; dialog:SetBackdropColor(.045,.045,.05,1); dialog:Show()
local body=K.Text(dialog,"",11,"TOPLEFT",20,-46,480); body:SetHeight(130)
local restoreMode=false
local yes=O.Button(dialog,"Zurücksetzen",20,-198,232,function()
    if R.Request(restoreMode) then shield:Hide() end
end)
O.Button(dialog,"Abbrechen",268,-198,232,function() shield:Hide() end)
local function BodyText()
    local action=restoreMode and "Gesicherte Einstellungen wiederherstellen?" or "Alle Addoneinstellungen zurücksetzen?"
    return K.T(action).."\n\n"..K.T("Sprache, Tastenbelegungen, Runhistorie und Sammlung bleiben erhalten.").."\n\n"
        ..K.T(restoreMode and "Die Oberfläche wird anschließend neu geladen." or "Vorher wird eine Sicherung angelegt. Die Oberfläche wird anschließend neu geladen.")
end
K.Live(body,BodyText)
function R.Open(restore)
    if pending or (restore and not R.HasBackup()) then return false end
    restoreMode=restore and true or false
    dialog.title:SetText(K.T(restoreMode and "Sicherung wiederherstellen" or "Einstellungen zurücksetzen"))
    yes.text:SetText(K.T(restoreMode and "Wiederherstellen" or "Zurücksetzen"))
    -- Live text also needs refreshing when the same dialog changes its purpose.
    body:SetText(BodyText())
    dialog:SetScale(math.min(O.MenuScale(),math.max(.1,(K.UIWidth()-24)/520),math.max(.1,(K.UIHeight()-24)/246)))
    O.CloseChoice(); shield:Show()
    return true
end
R.confirm,R.accept=shield,yes
