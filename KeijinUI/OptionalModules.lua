-- Modules: 14 features that can be switched off as a whole. A module that is off keeps no scripts, no combat event
-- subscriptions and no settings rows; where the game has its own version it comes back. Shared run telemetry stays active.
-- Core settings (sizes, windows, unit frames, run history, general) are not modules.
-- Older keys that were merged (damageText, resourceText, guardianNav, cursor, jewelry, insights) map to the new key
-- through K.moduleAlias (Core.lua), which also moves old saved switches over once (K.DB).
local K=KeijinUI
local M={definitions={},order={}}
K.modules=M
-- text: what the module does and what you get when it is off (German source text, translated in Locale.lua).
local function Bind(key,label,text,drivers,stop,resume,events,reload)
    local entry={key=key,label=label,text=text,drivers={},stop=stop,resume=resume,events=events,reload=reload}
    for _,frame in ipairs(drivers or {}) do
        table.insert(entry.drivers,{frame=frame,update=frame:GetScript("OnUpdate"),event=frame:GetScript("OnEvent")})
    end
    M.definitions[key]=entry
    table.insert(M.order,key)
end
function M.Apply(key)
    key=K.ModuleKey(key)
    local entry=M.definitions[key]; if not entry then return end
    local enabled=K.ModuleOn(key)
    for _,d in ipairs(entry.drivers) do
        d.frame:SetScript("OnUpdate",enabled and d.update or nil)
        d.frame:SetScript("OnEvent",enabled and d.event or nil)
        for ev in pairs(d.event and entry.events or {}) do
            if enabled then d.frame:RegisterEvent(ev) else d.frame:UnregisterEvent(ev) end
        end
    end
    if enabled then if entry.resume then entry.resume() end
    elseif entry.stop then entry.stop() end
end
function M.Set(key,on)
    key=K.ModuleKey(key)
    local entry=M.definitions[key]; if not entry then return false end
    local db=K.DB(); if type(db.modules)~="table" then db.modules={} end
    db.modules[key]=on and true or false; M.Apply(key)
    if entry.reload then M.reloadHint=entry.label end
    -- Settings rows and sections of this module appear or disappear at once.
    if K.settings and K.settings.ReflowAll then K.settings.ReflowAll() end
    return true
end
-- Label of the module whose last switch suggests a reload; empty after a reload (new Lua state).
M.reloadHint=nil

Bind("combatText","Kampftext","Schadenszahlen im KeijinUI Stil mit Vorschau sowie Heil- und eingehender Kampftext. Aus: Das Spiel zeigt seinen eigenen Kampftext.",
    K.damageText.drivers,function() K.damageText.Stop() end,function() K.ApplyCombatText(); K.resourceText.Clear() end,K.tools.CombatEvents)
Bind("nameplates","Namensplaketten","Gegner mit Namensplakette im KeijinUI Stil. Aus: Die Namensplaketten des Spiels.",
    {KeijinUIPlates},K.ReleaseNameplates,function() K.SetNameplates(K.DB().nameplates or "bosses") end)
Bind("minimap","Minimap","Minimap im KeijinUI Stil mit Uhr und Minimapknopf. Aus: Minimap des Spiels ohne Knopf; /kui öffnet die Einstellungen weiterhin. Bei Problemen neu laden.",
    {},function() K.MinimapRefresh(); K.MinimapButtonRefresh() end,function() K.MinimapRefresh(); K.MinimapButtonRefresh() end,nil,true)
Bind("caches","Caches","Cachesymbole, Randpfeil, Bildschirmpfeil und Meldung. Aus: keine Cachehinweise von KeijinUI.",
    {},K.caches.Stop,K.caches.Update)
Bind("guardians","Wächter","Wächter in der Runübersicht, Richtungspfeile und Hortmarker an den Horten. Aus: Die rote Wächterflagge des Spiels kommt zurück.",
    {},K.guardianNav.Update,K.guardianNav.Update)
Bind("analysis","Run-Analyse","Pace-Indikator, XP Rate mit Levelschätzung sowie Leben und Rerolls. Aus: Die Runübersicht zeigt nur die Grundwerte.",
    {},function() K.xpRate.label:Hide(); K.tally.UpdateExtras() end,function() K.xpRate.Reset(); K.tally.UpdateExtras() end)
Bind("attributes","Charakterwerte","Eine kompakte Wertetafel mit Krit, Tempo, Lebensraub und weiteren Werten. Aus: keine Tafel.",
    {},function() K.characterStats.frame:Hide() end,K.characterStats.Update)
Bind("loot","Beute","Beuteanzeige als Meldung, Liste oder Symbolraster. Aus: Das Beutefenster entfällt, die Beutemeldungen des Spiels im Chat bleiben.",
    {},K.loot.Stop,K.loot.Resume)
Bind("collection","Schmucksammlung","Beobachtete Funde, die Sammlung und Schmuckcooldowns. Aus: nichts wird beobachtet, keine Cooldowns an den Schmucksymbolen.",
    {K.collection.driver},function() K.collection.panel:Hide() end)
Bind("advisor","Buildtipps","Empfehlung passend zu deinem Build in der Zauberübersicht. Aus: keine Empfehlung.",
    {},K.buildBar.Refresh,K.buildBar.Refresh)
Bind("storedLevels","Gespeicherte Level","Levelaufstiege sammeln und später gesammelt auswählen. Aus: Das Spiel zeigt die Levelauswahl sofort wie gewohnt.",
    {},K.storedLevels.Suspend,K.storedLevels.Resume)
Bind("achievements","Erfolgsmeldungen","Erfolgsfenster beim Freischalten eines Erfolgs. Aus: kein Fenster, die Chatmeldung bleibt.",
    {},function() K.achievements.Stop() end)
Bind("comfort","Eingabehilfen","Cursortracker (Ring um den Mauszeiger) und die Taste für Automatisch laufen. Aus: kein Ring, deine Laufbelegung ist inaktiv; die Spielbelegung bleibt unverändert.",
    {K.cursor.frame},function() K.cursor.frame:Hide(); K.autoWalk.Suspend() end,function() K.cursor.Apply(); K.autoWalk.Resume() end)
Bind("summons","Beschwörungen","Leiste mit deinen aktiven Beschwörungen (Dämonen, Begleiter, Treants, Wölfe) mit Anzahl und Restzeit. Aus: keine Leiste.",
    {K.summons.driver},K.summons.Stop,K.summons.Refresh,{CHAT_MSG_ADDON=true,PLAYER_ENTERING_WORLD=true})
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then for _,key in ipairs(M.order) do M.Apply(key) end end end)
