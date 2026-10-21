local K=KeijinUI
local O=K.settings
-- Core settings are always shown. A section with a module key (third argument of O.Section) is only shown while that
-- module is on (OptionalModules.lua); the whole section, its heading and its link in the sidebar disappear otherwise.
local function Hidden(page,key,label)
    return O.Toggle(page,key,label,function() return not K.DB().hidden[key] end,function(on) K.DB().hidden[key]=not on end)
end
local p=O.Page("display","Layout & Anzeige","Alle Anzeigen, Positionen und Größen an einem Ort.")
O.Section(p,"Größe & Position")
O.Help(p,"Alt halten: Rahmen anzeigen und verschieben.\nAlt + Mausrad: Größe ändern.\nShift beim Loslassen: ohne Einrasten.")
O.Slider(p,"optionsScale","Menügröße",O.MenuScale,O.SetMenuScale,70,100)
O.Requires(O.Slider(p,"uiScale","Gesamte UI",O.UIScale,O.SetUIScale,64,150),O.UIScaleSupported)
O.Help(p,"Gesamte UI skaliert auch die Spielfenster. Einzelne Rahmengrößen bleiben erhalten. Änderungen beim Loslassen.")
O.Slider(p,"bgAlpha","Hintergrund-Deckkraft",K.BackgroundAlpha,K.SetBackgroundAlpha,20,100)
O.Help(p,"Deckkraft der Fensterhintergründe und der Einheitenrahmen. Standard 91 Prozent.")
O.Toggle(p,"snap","Raster und Einrasten",function() return K.DB().snap~=false end,function(on) if (K.DB().snap~=false)~=on then K.layout.ToggleGrid() end end)
O.Help(p,"Layout bearbeiten öffnet den Bearbeitungsmodus. Änderungen werden gespeichert.")

O.Choice(p,"headers","Abschnittstitel",K.headers.Mode,K.headers.Set,{{"normal","Normal"},{"thin","Schmal"},{"off","Aus"}})

-- Core windows: only show or hide. What a module adds is switched in that module's section further down.
O.Section(p,"Fenster")
Hidden(p,"tracker","Runübersicht")
Hidden(p,"bosses","Begegnungen")
Hidden(p,"statistics","Runstatistiken")
Hidden(p,"meter","Schadensanzeige"); Hidden(p,"crits","Kritische Treffer")
Hidden(p,"tally","Kills und Gold")
Hidden(p,"xp","Erfahrung")
O.Toggle(p,"buildBar","Zauber & Schmuck",K.buildBar.On,K.buildBar.Set)
O.Help(p,"Buildübersicht mit Stufen und Tooltips. Schmuckeffekte und Abklingzeiten stehen am jeweiligen Gegenstandssymbol.")
O.Toggle(p,"actionBar","Aktionsleiste",K.buildBar.ActionOn,K.buildBar.SetAction)
O.Requires(O.Choice(p,"cooldownStyle","Abklingzeit",function() return K.CooldownClockwise() and "clock" or "down" end,K.SetCooldownStyle,{{"clock","Im Uhrzeigersinn"},{"down","Von oben nach unten"}}),K.buildBar.ActionOn)
O.Help(p,"Leiste mit den Abklingzeiten deiner Zauber. Ist eines unserer Fenster aus, erscheint das passende des Spiels.")

O.Section(p,"Einheitenrahmen")
O.Choice(p,"healthColor","Lebensbalken",function() return K.DB().classHealth~=false end,function(on) K.DB().classHealth=on end,{{true,"Klassenfarbe"},{false,"Grün / Rot"}})
O.Toggle(p,"portraits","Porträts anzeigen",function() return K.DB().portraits~=false end,function(on) K.DB().portraits=on; if K.UpdateUnits then K.UpdateUnits() end end)
O.Help(p,"Aus: kompakter Rahmen ohne Porträt und Kreis.")
O.Choice(p,"buffs","Buffs",function() return K.DB().buffsLeft==true end,K.SetBuffsLeft,{{true,"linksbündig"},{false,"rechtsbündig"}})
O.Toggle(p,"resources","Klassenressourcen",function() return K.DB().classResources~=false end,K.SetClassResources)
O.Choice(p,"resourcePosition","Ressourcenposition",function() return K.DB().resourceFree==true end,K.SetResourceFree,{{false,"Am Spieler"},{true,"Frei"}})
O.Toggle(p,"targetDebuffs","Debuffs an beiden Stellen",function() return K.DB().targetDebuffsBoth~=false end,K.SetTargetDebuffsBoth)
O.Help(p,"Debuffs am Zielframe und an seiner Namensplakette anzeigen.")
-- The 30 percent marker also sits on the target frame, so it stays core and is not tied to the nameplate module.
O.Toggle(p,"executeMarker","30 Prozent Markierung",function() return K.DB().executeMarker==true end,function(on) K.DB().executeMarker=on end)
O.Help(p,"Markiert 30 Prozent am Ziel und an Namensplaketten. Farben der Gegner bleiben erhalten.")

O.Section(p,"Charakterwerte","attributes")
local attributesY=p.y
local attributes=O.Toggle(p,"attributes","Charakterwerte",K.characterStats.On,K.characterStats.Set)
attributes:SetWidth(342); attributes.name:SetWidth(250)
O.Button(p,"Werte wählen…",376,attributesY-1,140,function() O.ShowPage("attributes") end)
O.Help(p,"Krit, Tempo, Lebensraub und weitere Werte")

O.Section(p,"Beute","loot")
O.Choice(p,"lootMode","Beuteanzeige",K.loot.Mode,K.loot.SetMode,{{"notice","Meldung"},{"list","Liste"},{"small","Liste klein"},{"icons","Nur Symbole"}})
O.Choice(p,"lootGrow","Wachstum",K.loot.GrowMode,K.loot.SetGrow,{{"down","Nach unten"},{"up","Nach oben"}})
O.Toggle(p,"lootNew","Nur neuer Loot",K.loot.NewOnly,K.loot.SetNewOnly)
local function ListMode() local mode=K.loot.Mode(); return mode=="list" or mode=="small" end
O.Requires(O.Toggle(p,"lootIcons","Symbole",K.loot.Icons,K.loot.SetIcons),ListMode)
O.Requires(O.Toggle(p,"lootStatus","Sammelstatus anzeigen",K.loot.Status,K.loot.SetStatus),function() return K.loot.Mode()~="notice" end)
O.Help(p,"Meldung: 8 Sekunden. Liste: alle Gegenstände des Runs, Mausrad blättert. Liste klein: kompakte Zeilen. Nur Symbole: Raster mit Haken (neu) und X (gesammelt).")
O.Help(p,"Nach oben: Titel unten, unterer Rand bleibt fest. Das Fenster bleibt beim Umschalten an seiner Stelle.")
O.Help(p,"Nur neuer Loot blendet Gegenstände aus, die das Spiel als bereits gesammelt meldet.")

O.Section(p,"Namensplaketten","nameplates")
O.Choice(p,"nameplates","Gegner anzeigen",function() return K.DB().nameplates or "bosses" end,K.SetNameplates,{{"all","Alle Gegner"},{"bosses","Boss, Elite, Rare"},{"off","Aus"}})
-- Nameplates refresh their own labels after a slash-command change.
function K.UpdateNameplateLabels() O.Refresh() end

O.Section(p,"Minimap","minimap")
O.Toggle(p,"minimapStyle","Minimap im KeijinUI Stil",function() return K.DB().minimapStyle~=false end,K.SetMinimapStyle)
O.Toggle(p,"minimapButton","Minimapknopf",K.MinimapButtonOn,K.SetMinimapButton)
O.Requires(O.Choice(p,"minimapButtonSpot","Position des Minimapknopfs",K.MinimapButtonSpot,K.SetMinimapButtonSpot,K.minimapButtonSpots),K.MinimapButtonOn)
-- A compact cycling pair avoids an oversized 27-item dropdown.
local zone=O.Row(p,"clockOffset","Zeitzone der Uhr",34)
zone.value=K.Text(zone,"",11,"RIGHT",-108,0)
O.Button(zone,"−",420,-2,40,function() K.SetClockOffset(K.ClockOffset()-1) end)
O.Button(zone,"+",468,-2,40,function() K.SetClockOffset(K.ClockOffset()+1) end)
O.Watch(function() zone.value:SetText(K.ClockOffsetText()) end)

O.Section(p,"Caches","caches")
for _,entry in ipairs({{"icons","Cache Symbole"},{"edge","Cache Randpfeil"},{"arrow","Cache Bildschirmpfeil"},{"msg","Cache Meldung"}}) do
    local key=entry[1]
    O.Toggle(p,"cache_"..key,entry[2],function() return K.caches.Get(key) end,function(on) K.caches.Set(key,on) end)
end
O.Requires(O.Slider(p,"cache_size","Cache Symbolgröße",K.caches.IconScale,K.caches.SetIconScale,50,200),K.caches.IconsOn)
O.Help(p,"Caches nutzen Weltkoordinaten, wenn das Spiel sie liefert, auch in Instanzen.")

O.Section(p,"Wächter","guardians")
O.Toggle(p,"guardians","Wächter in der Runübersicht",K.guardians.On,K.guardians.Set)
O.Toggle(p,"guardianGuide","Richtungspfeile bei Wächtern",K.guardianNav.On,K.guardianNav.Set)
O.Toggle(p,"guardianPins","Hortmarker statt Spielflagge",K.guardianNav.PinsOn,K.guardianNav.SetPins)
O.Requires(O.Choice(p,"guardianMarker","Hortmarker",K.guardianNav.MarkerStyle,K.guardianNav.SetMarker,{{"creatures","Kreaturen"},{"raid","Raidmarker"},{"skulls","Farbschädel mit Ziffer"},{"seals","Siegel mit Ziffer"},{"classic","Klassisch"}}),K.guardianNav.PinsOn)
O.Requires(O.Slider(p,"guardian_size","Hortmarkergröße",K.guardianNav.IconScale,K.guardianNav.SetIconScale,50,200),K.guardianNav.PinsOn)
O.Help(p,"Jeder Hort hat für den ganzen Run sein eigenes Symbol, auf der Minimap und vor dem Namen in der Runübersicht. Mit ! im Kampf, abgedunkelt mit x leer. Ersetzt die rote Flagge des Spiels (ab 0.102), davor nur Symbole für besiegte Horte. Tooltip mit Rückkehrzeit.")
O.Help(p,"Kleine Richtungspfeile rechts neben den Wächternamen. Entfernung zum festen Hort im Tooltip. Mit der Runübersicht verschiebbar.")

O.Section(p,"Run-Analyse","analysis")
O.Toggle(p,"pace","Pace-Indikator",K.pace.On,K.pace.Set)
O.Help(p,"Gegnerfortschritt und DPS der letzten 30 Spielsekunden im Vergleich zu deinen Runden. Details per Mauszeiger.")
O.Toggle(p,"runResources","Leben und Rerolls",function() return K.DB().runResources==true end,function(on) K.DB().runResources=on; K.tally.UpdateExtras() end)
O.Help(p,"Zweite Reihe in der Anzeige für Kills, Gold und Caches. Rerolls zeigen zuerst die freie Anzahl, danach den nächsten Preis mit G.")
O.Toggle(p,"xpRate","XP Rate und Levelschätzung",function() return K.DB().xpRate==true end,function(on) K.DB().xpRate=on end)
O.Help(p,"Benötigt mindestens drei XP Zuwächse und zehn Spielsekunden. Bei Messlücken erscheint ein Fragezeichen.")

O.Section(p,"Zurücksetzen")
O.Pair(p,"Layout zurücksetzen",K.layout.Reset,"Tooltip zurücksetzen",K.ResetTooltip)
O.Pair(p,"UI Größen zurücksetzen",function() O.SetMenuScale(.8); O.SetUIScale(.9) end)
O.Finish(p)

p=O.Page("combat","Kampf","Schadenszahlen und Hinweise im Kampf.")
O.Section(p,"Schadenszahlen","combatText")
O.Choice(p,"combatText","Stil",K.CombatTextMode,K.SetCombatTextMode,{{"off","Aus"},{"compact","Kompakt"},{"scroll","Scrollend"},{"rise","Aufsteigend"},{"native","Spiel"}})
-- Icons, merging and position only apply to KeijinUI's own numbers (compact, scroll, rise). In the style
-- "Spiel" the client draws its floating text itself; an addon cannot place it.
local function OwnNumbers() local mode=K.CombatTextMode(); return mode=="compact" or mode=="scroll" or mode=="rise" end
O.Requires(O.Toggle(p,"icons","Zaubersymbole",function() return K.DB().combatTextIcons~=false end,function(on) K.DB().combatTextIcons=on end),OwnNumbers)
O.Requires(O.Toggle(p,"merge","Flächentreffer bündeln",function() return K.DB().combatTextMerge~=false end,function(on) K.DB().combatTextMerge=on end),OwnNumbers)
O.Help(p,"Fasst gleiche Treffer innerhalb kurzer Zeit zusammen.")
O.Requires(O.Choice(p,"combatTextPosition","Position",K.damageText.Position,K.damageText.SetPosition,{{"plate","Am Gegner"},{"fixed","Feste Stelle"}}),OwnNumbers)
local function PositionHelp()
    local mode=K.CombatTextMode()
    if mode=="native" then return K.T("Im Stil Spiel zeichnet das Spiel die Zahlen selbst. Ihre Position lässt sich nicht verschieben; für Feste Stelle Kompakt, Scrollend oder Aufsteigend wählen.") end
    if mode=="off" then return K.T("Schadenszahlen sind aus.") end
    return K.T("Am Gegner: Zahlen steigen über der Namensplakette. Feste Stelle: alle Zahlen starten im Kampftext Anker. Alt halten, um den Anker zu verschieben, Alt und Mausrad ändert die Größe.")
end
local positionHelp=O.Help(p,"")
K.Live(positionHelp,PositionHelp)
O.Watch(function() positionHelp:SetText(PositionHelp()) end)
O.Toggle(p,"healingText","Heilzahlen am Spieler",function() return K.DB().healingText==true end,function(on) K.DB().healingText=on end)
O.Toggle(p,"incomingText","Eingehender Schaden am Spieler",function() return K.DB().incomingText==true end,function(on) K.DB().incomingText=on end)
O.Help(p,"Beide Anzeigen gehören zu deinem Charakter und erscheinen am Spieler: erhaltene Heilung und erlittener Schaden als Änderung der nativen Summen je Datenpaket, keine einzelnen Treffer.")
O.Section(p,"Vorschau","combatText")
O.combatPreview=K.CreateCombatPreview(p,0,p.y)
O.Track(p,O.combatPreview,0,p.y)
O.Watch(function() O.combatPreview:Refresh() end)
p.y=p.y-148; O.Help(p,"Animierte Beispieltreffer. Zaubersymbole erscheinen in den Stilen Scrollend und Aufsteigend.")
O.Section(p,"Schadensanzeige")
O.Toggle(p,"meterIcons","Spellsymbole anzeigen",function() return K.DB().meterIcons==true end,function(on) K.DB().meterIcons=on end)
O.Toggle(p,"meterAutoBoss","Bei Bosskampf auf Boss umschalten",function() return K.DB().meterAutoBoss==true end,K.SetMeterAuto)
O.Help(p,"Die Schadensanzeige wechselt auf den Reiter Boss, solange ein Boss lebt, und danach zurück.")
O.Help(p,"Der Reiter Heilung zeigt die nativen Quellen und HPS des gesamten Runs, ohne Überheilung.")
O.Help(p,"Schaden erlitten zeigt native Quellen im Tooltip. Der Reiter Run zeigt beobachtete Trefferzahlen, Mittelwert, Min/Max und Kritquote pro Quelle im Tooltip.")
O.Finish(p)

-- The whole page belongs to the module "Eingabehilfen": without it the sidebar entry goes away.
p=O.Page("comfort","Eingabehilfen","Mauszeiger und Tasten nach deinem Geschmack.")
O.Section(p,"Mauszeiger","comfort")
O.Toggle(p,"cursor","Cursortracker",K.cursor.On,K.cursor.Set)
O.Help(p,"Ein Ring macht deinen Mauszeiger leichter sichtbar.")
local preview=CreateFrame("Frame",nil,p); preview:SetWidth(64); preview:SetHeight(64); preview:SetPoint("TOPRIGHT",p,"TOPRIGHT",-12,p.y-8)
O.Track(p,preview,-12,p.y-8,"TOPRIGHT")
local ring=preview:CreateTexture(nil,"ARTWORK"); ring:SetTexture("Interface\\AddOns\\KeijinUI\\media\\CursorRing.tga"); ring:SetPoint("CENTER",preview,"CENTER",0,0)
local cursor=preview:CreateTexture(nil,"OVERLAY"); cursor:SetTexture("Interface\\CURSOR\\Point"); cursor:SetWidth(28); cursor:SetHeight(28); cursor:SetPoint("TOPLEFT",preview,"CENTER",0,0)
local previewTitle=K.LText(preview,"Vorschau",9,"BOTTOM",0,72)
local sizeRow=O.Row(p,"cursorSize","Größe",38); sizeRow.name:SetWidth(120)
local size=CreateFrame("Slider","KeijinUICursorSize",sizeRow); size:SetPoint("LEFT",sizeRow,"LEFT",136,0); size:SetWidth(206); size:SetHeight(14)
size:SetOrientation("HORIZONTAL"); size:SetMinMaxValues(16,64); size:SetValueStep(1)
size:SetBackdrop({bgFile=K.flat}); size:SetBackdropColor(.25,.2,.1,1); size:SetThumbTexture(K.flat)
local handle=size:GetThumbTexture(); if handle then handle:SetWidth(12); handle:SetHeight(18); handle:SetVertexColor(.85,.65,.28,1) end
local sizeText=K.Text(sizeRow,"",11,"LEFT",354,0,40)
local syncing
size:SetScript("OnValueChanged",function() if not syncing then K.cursor.SetSize(size:GetValue()); O.Refresh() end end)
O.controls.cursorSize.slider=size
O.Watch(function() syncing=true; size:SetValue(K.cursor.Size()); syncing=false; sizeText:SetText(tostring(K.cursor.Size())); ring:SetWidth(K.cursor.Size()); ring:SetHeight(K.cursor.Size()); ring:SetVertexColor(K.cursor.Color()) end)
local colorRow=O.Row(p,"cursorColor","Farbe",36)
local swatch=colorRow:CreateTexture(nil,"ARTWORK"); swatch:SetTexture(K.flat); swatch:SetWidth(28); swatch:SetHeight(20); swatch:SetPoint("LEFT",colorRow,"LEFT",136,0)
local colorText=K.LText(colorRow,"Wählen…",10,"LEFT",175,0)
O.Watch(function() swatch:SetVertexColor(K.cursor.Color()) end)
colorRow:SetScript("OnClick",function()
    O.CloseChoice()
    local picker=ColorPickerFrame
    if not picker or not picker.SetColorRGB or not picker.GetColorRGB then K.Say(K.T("Farbwahl nicht verfügbar.")); return end
    picker:Hide()
    local r,g,b=K.cursor.Color()
    picker.func=function() K.cursor.SetColor(picker:GetColorRGB()); O.Refresh() end
    picker.cancelFunc=function() K.cursor.SetColor(r,g,b); O.Refresh() end
    picker.hasOpacity=false; picker.opacityFunc=nil
    picker:SetColorRGB(r,g,b); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:Show()
end)
O.Section(p,"Automatisch laufen","comfort")
local walk=O.Row(p,"autoWalk","Aktuelle Taste")
walk.value=K.Text(walk,"",11,"RIGHT",-4,0)
O.Watch(function() walk.value:SetText(K.autoWalk.Label()) end)
O.Pair(p,"Taste zuweisen",function() K.autoWalk.Capture() end,"Eigene Belegung entfernen",K.autoWalk.Clear)
O.Help(p,"Belegte Tasten müssen zum Ersetzen zweimal gedrückt werden. Escape bricht ab.")
K.autoWalk.onChange=O.Refresh

O.Finish(p)

p=O.Page("general","Allgemein","Sprache, Rundenhistorie und Oberfläche.")
O.Section(p,"Sprache")
O.Choice(p,"language","Sprache",function() return K.DB().lang end,K.SetLang,{{"en","English"},{"de","Deutsch"}})
O.Section(p,"Gespeicherte Level","storedLevels")
O.Requires(O.Toggle(p,"storeLevels","Levelaufstiege speichern",K.storedLevels.Storing,K.storedLevels.SetStoring),K.storedLevels.CanStore)
O.Help(p,"Der Kampf läuft weiter. Gespeicherte Auswahlen per Button öffnen. Ausschalten bietet wartende Auswahlen sofort an.")
O.Requires(O.Toggle(p,"storedLevelButton","Gespeicherte Level anzeigen",K.storedLevels.On,K.storedLevels.Set),K.storedLevels.Supported)
O.Help(p,"Zeigt wartende Levelaufstiege als verschiebbaren Button über der Aktionsleiste.")
O.Section(p,"Runs")
O.Pair(p,"Rundenübersicht",function() K.runs.Toggle() end)
O.Toggle(p,"runMessage","Run Meldung",K.runs.MessageOn,K.runs.SetMessage)
O.Toggle(p,"compactMessages","Kompakte Run Meldungen",function() return K.DB().compactMessages==true end,function(on) K.DB().compactMessages=on end)
O.Help(p,"Nur die Run Einleitung wird kürzer. Diagnose und Fehlermeldungen bleiben unverändert.")
O.Section(p,"Schmucksammlung","collection")
O.Toggle(p,"collectionRecord","Funde und Werte beobachten",function() return K.DB().collectionRecord~=false end,function(on) K.DB().collectionRecord=on end)
O.Toggle(p,"jewelryCooldowns","Schmuckcooldowns",K.collection.CooldownsOn,function(on) K.DB().jewelryCooldowns=on end)
O.Pair(p,"Sammlung öffnen",K.collection.Toggle)
O.Help(p,"Nur tatsächlich beobachtete Funde und native Tooltipwerte. Ein vollständiger Katalog unbekannter Gegenstände ist nicht verfügbar.")
O.Section(p,"Erfolgsmeldungen","achievements")
O.Pair(p,"Erfolgsvorschau",function() SlashCmdList.KEIJINACHIEVEMENTS("test") end)
O.Help(p,"Zeigt das Erfolgsfenster mit einem Beispiel. /kachi move verschiebt es, /kachi sound schaltet den Ton.")
O.Section(p,"Oberfläche")
O.Pair(p,"Oberfläche neu laden",function() ReloadUI() end)
O.Help(p,"/kui: Einstellungen, Layout und Sprache\n/kui runs: Rundenübersicht\n/kbb: Zauber, Schmuck und Buildtipps\n/kachi: Erfolgsmeldung")
O.Finish(p)

p=O.Page("attributes","Charakterwerte","Wähle die Werte für deine kompakte Anzeige.","display","attributes")
O.Toggle(p,"attributesMaster","Im HUD anzeigen",K.characterStats.On,K.characterStats.Set)
O.Help(p,"Standardmäßig ausgeschaltet. Die Vorschau bleibt sichtbar.")
O.Section(p,"Werte auswählen")
local previewFrame=CreateFrame("Frame",nil,p); previewFrame:SetWidth(238); previewFrame:SetPoint("TOPLEFT",p,"TOPLEFT",275,p.y)
K.Chamfer(previewFrame,4,{.04,.04,.05,1},{.62,.57,.43,1})
K.LText(previewFrame,"Charakterwerte",12,"TOPLEFT",10,-10,218):SetTextColor(1,.82,.28)
local previewRows={}
local examples={crit=.185,cm=2,cd=.88,lch=.045,reg=2.5,heal=5,spd=1.1,luck=.12,dmg=1.2,arm=.15,area=1.1,hp=280,
    echo=.2,cnt=2,pick=18,xp=1.15,gold=1.1,thn=.25,liv=1,bp=.1,dots=2,doth=.15,big=.2,exe=.3,cc=.1,dotd=.2,shd=.1,auto=.15,pet=.2}
for i,def in ipairs(K.characterStats.definitions) do
    local selected=def
    local row=O.Toggle(p,"stat_"..def.key,def.label,function() return K.characterStats.Selected(selected.key) end,function(on) K.characterStats.Select(selected.key,on) end)
    row:SetWidth(254); row.name:SetWidth(164); row.box:ClearAllPoints(); row.box:SetPoint("RIGHT",row,"RIGHT",-8,0); row.value:Hide()
    local up=O.Button(row,"^",174,-2,24,function() K.characterStats.Move(selected.key,-1) end); up:SetHeight(25)
    local down=O.Button(row,"v",202,-2,24,function() K.characterStats.Move(selected.key,1) end); down:SetHeight(25)
    local label=K.Text(previewFrame,"",9,"TOPLEFT",9,-34-(i-1)*19,158)
    local value=K.Text(previewFrame,"",10,"TOPRIGHT",-9,-34-(i-1)*19,57); value:SetJustifyH("RIGHT")
    previewRows[i]={label,value}
end
O.Watch(function()
    local n=0
    for _,def in ipairs(K.characterStats.Ordered()) do
        if K.characterStats.Selected(def.key) then
            n=n+1; previewRows[n][1]:SetText(K.T(def.label)); previewRows[n][2]:SetText(K.characterStats.Value(def,examples))
            previewRows[n][1]:Show(); previewRows[n][2]:Show()
        end
    end
    for i=n+1,table.getn(previewRows) do previewRows[i][1]:Hide(); previewRows[i][2]:Hide() end
    previewFrame:SetHeight(math.max(52,44+n*19))
end)
O.Pair(p,"Zurück zu Layout & Anzeige",function() O.ShowPage("display") end)
O.Help(p,"Beispielwerte")
O.Finish(p)

-- Central module page with its own entry in the sidebar. Every switch acts at once (K.modules.Set).
p=O.Page("modules","Module","Jedes Modul ein- oder ausschalten. Ausgeschaltete Module blenden ihre Einstellungen aus.")
O.Section(p,"Module")
for _,key in ipairs(K.modules.order) do
    local owner=key
    local definition=K.modules.definitions[key]
    O.Toggle(p,"module_"..key,definition.label,function() return K.ModuleOn(owner) end,function(on) K.modules.Set(owner,on) end)
    O.Help(p,definition.text)
end
O.Section(p,"Neu laden")
local reloadNote=O.Help(p,"")
O.Watch(function()
    local label=K.modules.reloadHint
    if label then reloadNote:SetText(K.T("%s wurde umgeschaltet. Für einen sauberen Zustand die Oberfläche neu laden.",K.T(label)))
    else reloadNote:SetText(K.T("Module wirken sofort. Nur bei der Minimap ist ein Neuladen ratsam, falls nach dem Ausschalten etwas hängen bleibt.")) end
end)
O.Pair(p,"Oberfläche neu laden",function() ReloadUI() end)
O.Finish(p)
O.Navigation({{"display","Layout & Anzeige"},{"combat","Kampf"},{"comfort","Eingabehilfen"},{"general","Allgemein"},{"modules","Module"}})
O.ShowPage("display")
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then O.ReflowAll(); O.ShowPage("display"); O.Fit() end end)
