-- Commands remain the same; presentation lives in SettingsWidgets/SettingsPages.
local K=KeijinUI
local O=K.settings
local panel=O.panel
local function RefreshAll() O.Refresh() end
local MODE_NAMES={off="Aus",compact="Kompakt",scroll="Scrollend",rise="Aufsteigend",native="Spiel"}
local announced=false
local function Announce()
    if not announced then
        announced=true
        DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88[KeijinAddons]|r |cffffff88KeijinUI|r v"..K.version.." – Use /kui")
    end
end
K.On("PLAYER_ENTERING_WORLD",Announce)
if UnitExists("player") then Announce() end

-- /kui menu: for 60 seconds, reports whether ESC opens the Lua GameMenuFrame, BenillaOptionsFrame or neither.
-- ToggleGameMenu is wrapped only during the watch and restored afterwards if nobody replaced it meanwhile.
local menuWatch
local function MenuState(frame) if not frame then return "missing" end; return frame:IsShown() and "shown" or "hidden" end
local function MenuStates() return MenuState(GameMenuFrame),MenuState(BenillaOptionsFrame) end
local function MenuDebug()
    if menuWatch then menuWatch.left=60; K.Say("Menu debug: watching 60 more seconds."); return end
    local watch=CreateFrame("Frame")
    menuWatch=watch
    watch.left=60
    watch.game,watch.options=MenuStates()
    K.Say("Menu debug: GameMenuFrame="..watch.game..", BenillaOptionsFrame="..watch.options..". Press ESC within 60 seconds.")
    local original=ToggleGameMenu
    if original then
        watch.wrapper=function(a1,a2) watch.toggled=true; return original(a1,a2) end
        ToggleGameMenu=watch.wrapper
    end
    watch:SetScript("OnUpdate",function()
        local game,options=MenuStates()
        if watch.toggled or game~=watch.game or options~=watch.options then
            K.Say("Menu debug: "..(watch.toggled and "ToggleGameMenu called, " or "")
                .."GameMenuFrame="..game..", BenillaOptionsFrame="..options)
            watch.toggled,watch.game,watch.options=nil,game,options
        end
        watch.left=watch.left-(arg1 or 0)
        if watch.left<=0 then
            if watch.wrapper and ToggleGameMenu==watch.wrapper then ToggleGameMenu=original end
            watch:SetScript("OnUpdate",nil); watch:Hide(); menuWatch=nil
            K.Say("Menu debug: finished.")
        end
    end)
end
SLASH_KEIJINUI1="/kui"
SlashCmdList.KEIJINUI=function(message)
    local command=string.lower(string.gsub(message or "","^%s*(.-)%s*$","%1"))
    if command=="" then if panel:IsShown() then panel:Hide() else panel:Show() end
    elseif command=="edit" then K.layout.Toggle()
    elseif command=="reset" then K.layout.Reset()
    elseif command=="grid" then K.layout.ToggleGrid()
    elseif command=="grid debug" then K.layout.GridDebug()
    elseif command=="meter reset" then K.ResetMeter()
    elseif command=="crits reset" then K.ResetCrits()
    elseif command=="tooltip reset" then K.ResetTooltip()
    elseif command=="plates all" then K.SetNameplates("all")
    elseif command=="plates bosses" then K.SetNameplates("bosses")
    elseif command=="plates off" then K.SetNameplates("off")
    elseif command=="plates debug" then K.PlateDebug()
    elseif command=="bosses debug" then K.BossDebug()
    elseif command=="heal" or command=="heal debug" then K.HealDebug()
    elseif command=="party debug" then K.party.Debug()
    elseif command=="resources debug" then K.ResourceDebug()
    elseif command=="pace debug" then K.pace.Debug()
    elseif command=="navigation debug" then K.navigation.Debug()
    elseif command=="levels debug" then K.storedLevels.Debug()
    elseif command=="menu" or command=="menu debug" then MenuDebug()
    elseif command=="collection" then K.collection.Toggle()
    elseif command=="chat copy" then K.chatCopy.Open()
    elseif command=="caches" or string.find(command,"^caches%s") then
        local _,_,rest=string.find(command,"^caches%s+(.-)$")
        K.CachesCommand(rest or "")
        RefreshAll()
    elseif command=="runs" or string.find(command,"^runs%s") then
        local _,_,rest=string.find(command,"^runs%s+(.-)$")
        K.RunsCommand(rest or "")
        RefreshAll()
    elseif command=="loot" or string.find(command,"^loot%s") then
        local _,_,rest=string.find(command,"^loot%s+(.-)$")
        K.loot.Command(rest or "")
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
            mode=({off="off",compact="compact",scroll="scroll",rise="rise",game="native",native="native"})[value]
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
            K.Say(K.T("/kui text off|compact|scroll|rise|game. Aktuell: %s.",K.T(MODE_NAMES[K.CombatTextMode()])))
        end
    elseif command=="reload" then ReloadUI()
    elseif command=="font" or string.find(command,"^font%s") then
        local _,_,value=string.find(command,"^font%s+(%S+)$")
        if value and K.SetFontChoice(value) then
            K.Say(K.T("Schrift")..": "..K.FontName(value))
            RefreshAll()
        else
            local keys
            for _,item in ipairs(K.fontChoices) do keys=keys and (keys..", "..item[1]) or item[1] end
            K.Say(K.T("/kui font <Name>. Aktuell: %s. Verfügbar: %s.",K.FontName(K.FontChoice()),keys))
        end
        if K.FontSubstituted() then K.Say(K.T("Die gewählte Schrift enthält nicht alle Zeichen dieser Sprache. Es wird eine Ersatzschrift verwendet.")) end
    elseif command=="lang" or string.find(command,"^lang%s") then
        local _,_,value=string.find(command,"^lang%s+(%S+)$")
        if K.IsLang(value) then
            K.SetLang(value)
            K.Say(K.T("Sprache")..": "..K.LangName(value))
            RefreshAll()
        else
            K.Say(K.T("/kui lang de|en. Aktuell: %s.",K.LangName(K.lang)).." "..K.T("Sprachcodes: %s",K.LangCodes()))
        end
    else
        K.Say(K.T("/kui party debug: Partyfenster und Partydaten prüfen."))
        K.Say(K.T("/kui font: Schrift anzeigen oder wählen."))
        K.Say(K.T("/kui, /kui edit, /kui reset, /kui grid (Raster und Einrasten), /kui text off|compact|scroll|rise|game, /kui plates all|bosses|off|debug, /kui bosses debug, /kui heal debug, /kui caches icons, edge, arrow, msg, size, source, debug, /kui runs (Rundenübersicht), /kui runs msg, /kui guardians on|off|debug (Wächter), /kui loot clear|debug (Beuteliste), /kui button on|off (Minimapknopf), /kui tooltip reset, /kui meter reset, /kui crits reset, /kui lang de|en (Sprache), /kui reload (Oberfläche neu laden). /kbb für Buildtipps, /kachi für Erfolge."))
 end
end
