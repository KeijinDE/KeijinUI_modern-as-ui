-- Commands remain the same; presentation lives in SettingsWidgets/SettingsPages.
local K=KeijinUI
local O=K.settings
local panel=O.panel
local function RefreshAll() O.Refresh() end
local MODE_NAMES={off="Aus",compact="Kompakt",scroll="Scrollend",native="Spiel"}
local announced=false
local function Announce()
    if not announced then
        announced=true
        DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88[KeijinAddons]|r |cffffff88KeijinUI|r v"..K.version.." – Use /kui")
    end
end
K.On("PLAYER_ENTERING_WORLD",Announce)
if UnitExists("player") then Announce() end
SLASH_KEIJINUI1="/kui"
SlashCmdList.KEIJINUI=function(message)
    local command=string.lower(string.gsub(message or "","^%s*(.-)%s*$","%1"))
    if command=="" then if panel:IsShown() then panel:Hide() else panel:Show() end
    elseif command=="edit" then K.layout.Toggle()
    elseif command=="reset" then K.layout.Reset()
    elseif command=="grid" then K.layout.ToggleGrid()
    elseif command=="meter reset" then K.ResetMeter()
    elseif command=="crits reset" then K.ResetCrits()
    elseif command=="tooltip reset" then K.ResetTooltip()
    elseif command=="plates all" then K.SetNameplates("all")
    elseif command=="plates bosses" then K.SetNameplates("bosses")
    elseif command=="plates off" then K.SetNameplates("off")
    elseif command=="plates debug" then K.PlateDebug()
    elseif command=="bosses debug" then K.BossDebug()
    elseif command=="heal debug" then K.HealDebug()
    elseif command=="resources debug" then K.ResourceDebug()
    elseif command=="pace debug" then K.pace.Debug()
    elseif command=="caches" or string.find(command,"^caches%s") then
        local _,_,rest=string.find(command,"^caches%s+(.-)$")
        K.CachesCommand(rest or "")
        RefreshAll()
    elseif command=="runs" or string.find(command,"^runs%s") then
        local _,_,rest=string.find(command,"^runs%s+(.-)$")
        K.RunsCommand(rest or "")
        RefreshAll()
    elseif command=="guardians" or string.find(command,"^guardians%s") then
        local _,_,rest=string.find(command,"^guardians%s+(.-)$")
        K.guardians.Command(rest or "")
        RefreshAll()
    elseif command=="button" or string.find(command,"^button%s") then
        local _,_,rest=string.find(command,"^button%s+(.-)$")
        K.MinimapButtonCommand(rest or "")
        RefreshAll()
    elseif command=="build" then SlashCmdList.KEIJINBUILDBAR("toggle")
    elseif command=="text icons" then
        K.DB().combatTextIcons=(K.DB().combatTextIcons==false)
        K.Say(K.T("Zaubersymbole")..": "..(K.DB().combatTextIcons~=false and K.T("An") or K.T("Aus")))
        RefreshAll()
    elseif command=="text" or string.find(command,"^text%s") then
        local _,_,value=string.find(command,"^text%s+(%S+)$")
        local mode
        if value then
            mode=({off="off",compact="compact",scroll="scroll",game="native",native="native"})[value]
        else
            local current=K.CombatTextMode()
            for i,m in ipairs(K.CombatModes) do
                if m==current then mode=K.CombatModes[math.mod(i,table.getn(K.CombatModes))+1] end
            end
        end
        if mode then
            K.SetCombatTextMode(mode)
            K.Say(K.T("Schadenszahlen")..": "..K.T(MODE_NAMES[mode]))
            RefreshAll()
        else
            K.Say(K.T("/kui text off|compact|scroll|game. Aktuell: %s.",K.T(MODE_NAMES[K.CombatTextMode()])))
        end
    elseif command=="reload" then ReloadUI()
    elseif command=="lang" or string.find(command,"^lang%s") then
        local _,_,value=string.find(command,"^lang%s+(%S+)$")
        if value=="de" or value=="en" then
            K.SetLang(value)
            K.Say(K.T("Sprache")..": "..(value=="de" and "Deutsch" or "English"))
            RefreshAll()
        else
            K.Say(K.T("/kui lang de|en. Aktuell: %s.",K.lang=="de" and "Deutsch" or "English"))
        end
    else K.Say(K.T("/kui, /kui edit, /kui reset, /kui grid (Raster und Einrasten), /kui text off|compact|scroll|game, /kui plates all|bosses|off|debug, /kui bosses debug, /kui heal debug, /kui caches icons, edge, arrow, msg, source, debug, /kui runs (Rundenübersicht), /kui runs msg, /kui guardians on|off|debug (Wächter), /kui button on|off (Minimapknopf), /kui tooltip reset, /kui meter reset, /kui crits reset, /kui lang de|en (Sprache), /kui reload (Oberfläche neu laden). /kbb für Buildtipps, /kachi für Erfolge.")) end
end
