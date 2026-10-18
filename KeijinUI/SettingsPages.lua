local K=KeijinUI
local O=K.settings
local function Hidden(page,key,label)
    return O.Toggle(page,key,label,function() return not K.DB().hidden[key] end,function(on) K.DB().hidden[key]=not on end)
end
local p=O.Page("display","Anzeige","Welche Anzeigen möchtest du im Spiel sehen?")
O.Section(p,"Run & Kampf")
Hidden(p,"tracker","Runübersicht"); Hidden(p,"statistics","Runstatistiken")
Hidden(p,"meter","Schadensanzeige"); Hidden(p,"crits","Kritische Treffer")
O.Choice(p,"headers","Abschnittstitel",K.headers.Mode,K.headers.Set,{{"normal","Normal"},{"thin","Schmal"},{"off","Aus"}})
O.Section(p,"Zusätzliche Anzeigen")
local attributesY=p.y
local attributes=O.Toggle(p,"attributes","Charakterwerte",K.characterStats.On,K.characterStats.Set)
attributes:SetWidth(342); attributes.name:SetWidth(250)
O.Button(p,"Werte wählen…",376,attributesY-1,140,function() O.ShowPage("attributes") end)
O.Help(p,"Krit, Tempo, Lebensraub und weitere Werte")
O.Toggle(p,"pace","Pace-Indikator",K.pace.On,K.pace.Set)
O.Help(p,"Gegnerfortschritt und DPS der letzten 30 Spielsekunden im Vergleich zu deinen Runden. Details per Mauszeiger.")
O.Section(p,"Weitere Runanzeigen")
Hidden(p,"bosses","Begegnungen")
O.Toggle(p,"guardians","Wächter in der Runübersicht",K.guardians.On,K.guardians.Set)
Hidden(p,"tally","Kills und Gold"); Hidden(p,"xp","Erfahrung")
O.Finish(p)

p=O.Page("combat","Kampf","Schadenszahlen und Hinweise im Kampf.")
O.Section(p,"Schadenszahlen")
O.Choice(p,"combatText","Stil",K.CombatTextMode,K.SetCombatTextMode,{{"off","Aus"},{"compact","Kompakt"},{"scroll","Scrollend"},{"native","Spiel"}})
O.Toggle(p,"icons","Zaubersymbole",function() return K.DB().combatTextIcons~=false end,function(on) K.DB().combatTextIcons=on end)
O.Toggle(p,"merge","Flächentreffer bündeln",function() return K.DB().combatTextMerge~=false end,function(on) K.DB().combatTextMerge=on end)
O.Help(p,"Fasst gleiche Treffer innerhalb kurzer Zeit zusammen.")
O.Section(p,"Vorschau")
O.combatPreview=K.CreateCombatPreview(p,0,p.y)
O.Watch(function() O.combatPreview:Refresh() end)
p.y=p.y-148; O.Help(p,"Animierte Beispieltreffer. Zaubersymbole erscheinen im Stil Scrollend.")
O.Section(p,"Buildtipps")
O.Toggle(p,"advisor","Buildtipps",function() return not (KeijinUIBuildDB and KeijinUIBuildDB.advisor==false) end,
    function(on) if not KeijinUIBuildDB then KeijinUIBuildDB={} end; KeijinUIBuildDB.advisor=on end)
O.Help(p,"Empfehlungen passend zu deinem aktuellen Build.")
O.Finish(p)

p=O.Page("units","Einheiten","Spieler, Ziel, Namensplaketten und Caches.")
O.Section(p,"Einheitenrahmen")
O.Choice(p,"healthColor","Lebensbalken",function() return K.DB().classHealth~=false end,function(on) K.DB().classHealth=on end,{{true,"Klassenfarbe"},{false,"Grün / Rot"}})
O.Choice(p,"buffs","Buffs",function() return K.DB().buffsLeft==true end,K.SetBuffsLeft,{{true,"linksbündig"},{false,"rechtsbündig"}})
O.Toggle(p,"resources","Klassenressourcen",function() return K.DB().classResources~=false end,K.SetClassResources)
O.Choice(p,"resourcePosition","Ressourcenposition",function() return K.DB().resourceFree==true end,K.SetResourceFree,{{false,"Am Spieler"},{true,"Frei"}})
O.Toggle(p,"targetDebuffs","Debuffs an beiden Stellen",function() return K.DB().targetDebuffsBoth~=false end,K.SetTargetDebuffsBoth)
O.Help(p,"Debuffs am Zielframe und an seiner Namensplakette anzeigen.")
O.Section(p,"Namensplaketten")
O.Choice(p,"nameplates","Gegner anzeigen",function() return K.DB().nameplates or "bosses" end,K.SetNameplates,{{"all","Alle Gegner"},{"bosses","Boss, Elite, Rare"},{"off","Aus"}})
-- Nameplates refresh their own labels after a slash-command change.
function K.UpdateNameplateLabels() O.Refresh() end
O.Section(p,"Caches")
for _,entry in ipairs({{"icons","Cache Symbole"},{"edge","Cache Randpfeil"},{"arrow","Cache Bildschirmpfeil"},{"msg","Cache Meldung"}}) do
    local key=entry[1]
    O.Toggle(p,"cache_"..key,entry[2],function() return K.caches.Get(key) end,function(on) K.caches.Set(key,on) end)
end
O.Finish(p)

p=O.Page("comfort","Bedienung","Mauszeiger und Tasten nach deinem Geschmack.")
O.Section(p,"Mauszeiger")
O.Toggle(p,"cursor","Cursortracker",K.cursor.On,K.cursor.Set)
O.Help(p,"Ein Ring macht deinen Mauszeiger leichter sichtbar.")
local preview=CreateFrame("Frame",nil,p); preview:SetWidth(64); preview:SetHeight(64); preview:SetPoint("TOPRIGHT",p,"TOPRIGHT",-12,p.y-8)
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
O.Section(p,"Automatisch laufen")
local walk=O.Row(p,"autoWalk","Aktuelle Taste")
walk.value=K.Text(walk,"",11,"RIGHT",-4,0)
O.Watch(function() walk.value:SetText(K.autoWalk.Label()) end)
O.Pair(p,"Taste zuweisen",function() K.autoWalk.Capture() end,"Eigene Belegung entfernen",K.autoWalk.Clear)
O.Help(p,"Belegte Tasten müssen zum Ersetzen zweimal gedrückt werden. Escape bricht ab.")
K.autoWalk.onChange=O.Refresh
O.Finish(p)

p=O.Page("layout","Layout","Positionen und Größen deiner Anzeigen anpassen.")
O.Help(p,"Alt halten: Rahmen anzeigen und verschieben.\nAlt + Mausrad: Größe ändern.\nShift beim Loslassen: ohne Einrasten.")
O.Section(p,"Bearbeiten")
O.Choice(p,"optionsScale","Menügröße",O.MenuScale,O.SetMenuScale,{{.7,"70%"},{.8,"80%"},{.9,"90%"},{1,"100%"}})
O.Toggle(p,"snap","Raster und Einrasten",function() return K.DB().snap~=false end,function(on) if (K.DB().snap~=false)~=on then K.layout.ToggleGrid() end end)
O.Help(p,"Layout bearbeiten öffnet den Bearbeitungsmodus. Änderungen werden gespeichert.")
O.Section(p,"Zurücksetzen")
O.Pair(p,"Layout zurücksetzen",K.layout.Reset,"Tooltip zurücksetzen",K.ResetTooltip)
O.Finish(p)

p=O.Page("general","Allgemein","Sprache, Minimap und deine Rundenhistorie.")
O.Section(p,"Sprache")
O.Choice(p,"language","Sprache",function() return K.DB().lang end,K.SetLang,{{"en","English"},{"de","Deutsch"}})
O.Section(p,"Minimap")
O.Toggle(p,"minimapStyle","Minimap im KeijinUI Stil",function() return K.DB().minimapStyle~=false end,K.SetMinimapStyle)
O.Toggle(p,"minimapButton","Minimapknopf",K.MinimapButtonOn,K.SetMinimapButton)
-- A compact cycling pair avoids an oversized 27-item dropdown.
local zone=O.Row(p,"clockOffset","Zeitzone der Uhr",34)
zone.value=K.Text(zone,"",11,"RIGHT",-108,0)
O.Button(zone,"−",420,-2,40,function() K.SetClockOffset(K.ClockOffset()-1) end)
O.Button(zone,"+",468,-2,40,function() K.SetClockOffset(K.ClockOffset()+1) end)
O.Watch(function() zone.value:SetText(K.ClockOffsetText()) end)
O.Section(p,"Runs")
O.Pair(p,"Rundenübersicht",function() K.runs.Toggle() end)
O.Toggle(p,"runMessage","Run Meldung",K.runs.MessageOn,K.runs.SetMessage)
O.Section(p,"Oberfläche")
O.Pair(p,"Oberfläche neu laden",function() ReloadUI() end,"Erfolgsvorschau",function() SlashCmdList.KEIJINACHIEVEMENTS("test") end)
O.Help(p,"/kui: Einstellungen, Layout und Sprache\n/kui runs: Rundenübersicht\n/kbb: Zauber, Schmuck und Buildtipps\n/kachi: Erfolgsmeldung")
O.Finish(p)

p=O.Page("attributes","Charakterwerte","Wähle die Werte für deine kompakte Anzeige.","display")
O.Toggle(p,"attributesMaster","Im HUD anzeigen",K.characterStats.On,K.characterStats.Set)
O.Help(p,"Standardmäßig ausgeschaltet. Die Vorschau bleibt sichtbar.")
O.Section(p,"Werte auswählen")
local previewFrame=CreateFrame("Frame",nil,p); previewFrame:SetWidth(238); previewFrame:SetPoint("TOPLEFT",p,"TOPLEFT",275,p.y)
K.Chamfer(previewFrame,4,{.04,.04,.05,1},{.62,.57,.43,1})
K.LText(previewFrame,"Charakterwerte",12,"TOPLEFT",10,-10,218):SetTextColor(1,.82,.28)
local previewRows={}
local examples={crit=.185,cm=2,cd=.88,lch=.045,reg=2.5,heal=5,spd=1.1,luck=.12,dmg=1.2,arm=.15,area=1.1,hp=280}
for i,def in ipairs(K.characterStats.definitions) do
    local selected=def
    local row=O.Toggle(p,"stat_"..def.key,def.label,function() return K.characterStats.Selected(selected.key) end,function(on) K.characterStats.Select(selected.key,on) end)
    row:SetWidth(254); row.name:SetWidth(205); row.box:ClearAllPoints(); row.box:SetPoint("RIGHT",row,"RIGHT",-8,0); row.value:Hide()
    local label=K.Text(previewFrame,"",9,"TOPLEFT",9,-34-(i-1)*19,158)
    local value=K.Text(previewFrame,"",10,"TOPRIGHT",-9,-34-(i-1)*19,57); value:SetJustifyH("RIGHT")
    previewRows[i]={label,value}
end
O.Watch(function()
    local n=0
    for _,def in ipairs(K.characterStats.definitions) do
        if K.characterStats.Selected(def.key) then
            n=n+1; previewRows[n][1]:SetText(K.T(def.label)); previewRows[n][2]:SetText(K.characterStats.Value(def,examples))
            previewRows[n][1]:Show(); previewRows[n][2]:Show()
        end
    end
    for i=n+1,table.getn(previewRows) do previewRows[i][1]:Hide(); previewRows[i][2]:Hide() end
    previewFrame:SetHeight(math.max(52,44+n*19))
end)
O.Pair(p,"Zurück zur Anzeige",function() O.ShowPage("display") end)
O.Help(p,"Beispielwerte")
O.Finish(p)
O.Navigation({{"display","Anzeige"},{"combat","Kampf"},{"units","Einheiten"},{"comfort","Bedienung"},{"layout","Layout"},{"general","Allgemein"}})
O.ShowPage("display")
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then O.ShowPage("display"); O.Fit() end end)
