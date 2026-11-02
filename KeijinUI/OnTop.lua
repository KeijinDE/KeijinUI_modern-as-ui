-- Per layout element, default off. The game requires a global frame name.
local K=KeijinUI
local T={}
K.onTop=T
-- Fixed IDs also cover windows registered late, before profile decoding or world entry.
-- Pure positioning anchors do not own their visible content and are deliberately excluded.
T.elements={
    meter="KeijinUIDamage",statistics="KeijinUIStatistics",crits="KeijinUICrits",
    attributes="KeijinUICharacterStats",characterwindow="CharacterFrame",
    build="KeijinBuildBarFrame",skills="KeijinUISkills",effects="KeijinUIEffects",
    totems="KeijinUITotems",summons="KeijinUISummons",buffs="KeijinUIBuffs",resources="KeijinUIResources",
    tracker="KeijinUITracker",bosses="KeijinUIBosses",tally="KeijinUITally",xp="KeijinUIXP",
    guardianOverview="KeijinUIGuardianOverview",analysisOverview="KeijinUIAnalysisOverview",party="KeijinUIParty",
    minimap="MinimapCluster",worldmap="WorldMapFrame",levels="KeijinUIStoredLevels",
    achievements="KeijinAchievementsFrame",cachearrow="KeijinUICachesArrow",guardianarrow="KeijinUIGuardianArrow",
    combattextlist="KeijinUICombatTextList",healtext="KeijinUIHealingText",takentext="KeijinUITakenText",
}
function T.Available() return type(AZS_SetOnTopOfScreens)=="function" end
function T.Element(key) return T.elements[key] end
function T.Get(key)
    local saved=K.DB().onTop
    return T.Element(key)~=nil and type(saved)=="table" and saved[key]==true
end
local function EditableName(key)
    local name=T.Element(key)
    local e=K.layout.entries[key]
    if name and e and e.frame:GetName()==name and getglobal(name)==e.frame then return name end
end
function T.CanEdit(key)
    return EditableName(key)~=nil
end
function T.Apply(key)
    if not T.Available() then return end
    local name=EditableName(key)
    if name then pcall(AZS_SetOnTopOfScreens,name,T.Get(key)) end
end
function T.AnyOn()
    for key in pairs(T.elements) do if EditableName(key) and T.Get(key) then return true end end
    return false
end
-- GameTooltip is shared by all windows. Restore it when the last switch is off.
function T.ApplyTooltip()
    if not T.Available() or not getglobal("GameTooltip") then return end
    pcall(AZS_SetOnTopOfScreens,"GameTooltip",T.AnyOn())
end
function T.ApplyAll()
    for key in pairs(T.elements) do T.Apply(key) end
    T.ApplyTooltip()
end
function T.Set(key,on)
    if not T.Element(key) then return end
    local db=K.DB()
    if type(db.onTop)~="table" then db.onTop={} end
    db.onTop[key]=on and true or nil
    T.Apply(key)
    T.ApplyTooltip()
end
K.On("PLAYER_ENTERING_WORLD",T.ApplyAll)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then T.ApplyAll() end end)
