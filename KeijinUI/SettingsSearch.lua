-- Bilingual live search. Move the real controls temporarily; never duplicate callbacks
-- or turn a result into a link to its source page.
local K=KeijinUI
local O=K.settings
local panel=O.panel
local groups={
    "player spieler playerframe spielerrahmen spielerfenster", "target ziel targetframe zielrahmen zielfenster", "enemy enemies gegner mob mobs",
    "damage dmg schaden schadenszahlen", "healing heal heilung heilen hps",
    "health hp leben lebenspunkte gesundheit", "critical crit crits krit kritisch kritische",
    "nameplate nameplates namensplakette namensplaketten", "frame frames rahmen fenster panel",
    "minimap minikarte", "loot beute drops", "cache caches chest chests kiste kisten truhe truhen",
    "guardian guardians waechter miniboss minibosse hort horte", "boss bosses bosse begegnung begegnungen encounter",
    "size scale scaling groesse skalierung", "font fonts schrift schriftart",
    "color colour farbe farben faerbung", "cooldown cooldowns cd abklingzeit abklingzeiten",
    "xp ep exp erfahrung experience", "buff buffs aura auren", "debuff debuffs schwaechung",
    "tooltip tooltipp tooltips", "thin schmal", "compact kompakt", "hide hidden ausblenden verstecken",
    "autorun autowalk automatisch laufen", "levels levelups levelaufstiege levelaufstieg",
    "reset zuruecksetzen", "attributes charakterwerte stats werte values", "haste tempo",
    "lifesteal lebensraub", "module modules modul module", "cursor mauszeiger cursortracker",
}
local aliases={
    cooldownStyle="cooldown abklingzeit timer clockwise uhrzeigersinn sweep action bar aktionsleiste top bottom oben unten",
    portraits="player spieler target ziel portrait portraet portraits portraets bild compact kompakt rahmen frame kreis circle",
    bgAlpha="background opacity transparency hintergrund deckkraft transparenz durchsichtig player spieler target ziel frames rahmen panel",
    healthColor="player spieler target ziel health bar lebensbalken",
    resources="player spieler class resource mana energy combo soulshard wut seelensplitter combopunkte",
    resourcePosition="player spieler class resources position klassenressourcen",
    buffs="player spieler buffs auren",
    targetDebuffs="target ziel enemy debuffs",
    executeMarker="target ziel health execute 30 prozent",
    guardianMarker="marker markers raid raidmarker symbol symbole totenkopf skull schaedel kreatur kreaturen creature siegel seal ziffer number hort lair minimap wächter guardian",
    shortcutAction="binding keybind raidmarker layout taste tastenbelegung",
    layoutKey="binding keybind layout taste tastenbelegung",
    fps="fps framerate frames bildrate performance leistung",
    fpsFrame="fps border frame rahmen",
    fpsAlpha="fps opacity alpha transparenz deckkraft",
    fpsOpacity="fps opacity alpha transparenz deckkraft text",
    fpsSize="fps font size schriftgröße",
    fpsColor="fps font color schriftfarbe",
    autoWalk="autorun autowalk automatisch laufen taste key maus mouse",
    attributes="player spieler character stats charakterwerte",
    attributesMaster="player spieler character stats charakterwerte",
    optionsScale="settings menu menue einstellungen size groesse scale skalierung",
    uiScale="interface ui gesamt scale skalierung groesse",
    cache_size="minimap minikarte chest chests truhe truhen symbol icon groesse size scale skalierung",
    guardian_size="minimap minikarte hort lair wächter waechter guardian marker symbol icon groesse size scale skalierung",
    combatTextSize="damage schaden zahlen numbers kampftext combat text groesse size scale skalierung textgroesse",
    combatTextPosition="damage schaden position fixed fest gegner enemy",
    -- The switches of the modules are found by what the module does, also while its own settings are hidden.
    module_combatText="damage schaden healing heilung incoming eingehend zahlen numbers kampftext combat text",
    module_nameplates="namensplaketten nameplates gegner enemy",
    module_minimap="minimap minikarte knopf button uhr clock zeitzone timezone",
    module_caches="cache caches truhe kiste chest",
    module_guardians="waechter guardian guardians flagge flag skull totenkopf horte lair",
    module_analysis="pace xp rate rerolls leben lives analyse analysis",
    module_attributes="charakterwerte character stats attributes",
    module_loot="beute loot drops",
    module_collection="schmuck jewelry cooldown cooldowns sammlung collection",
    module_advisor="buildtipps build tips tipps empfehlung advisor",
    module_storedLevels="levelaufstiege levelups level stored gespeicherte",
    module_achievements="erfolg erfolge achievement achievements popup",
    module_cursor="cursor mauszeiger ring",
    module_autowalk="autorun autowalk automatisch laufen",
    module_shortcuts="tasten keys bindings raidmarker",
    module_basisHud="run overview uebersicht boss statistik statistics damage meter schaden kills gold xp",
    module_units="player target spieler ziel buffs debuffs resources ressourcen",
    module_build="build zauber schmuck spells jewelry",
    module_action="actionbar aktionsleiste spells cooldown abklingzeit",
    module_effects="effekte effects timer talent",
    module_characterWindow="charakter character paperdoll ausruestung equipment",
    module_worldMap="map weltkarte world map",
    module_fps="fps bildrate framerate",
    module_chat="chat copy kopieren",
    module_tooltip="tooltip",
    module_history="runs history historie verlauf runden",
    module_summons="beschwoerungen summons pets begleiter daemonen demons hexenmeister warlock treants wolf",
    module_party="party partyfenster gruppe koop coop co-op wiederbelebung revive",
}
local links={
    ["Werte wählen…"]=true,["Module verwalten…"]=true,
    ["Zurück zu Layout & Anzeige"]=true,["Zurück zu Allgemein"]=true,
}
local function Normalize(text)
    text=tostring(text or "")
    for _,pair in ipairs({{"Ä","ae"},{"ä","ae"},{"Ö","oe"},{"ö","oe"},{"Ü","ue"},{"ü","ue"},{"ß","ss"}}) do
        text=string.gsub(text,pair[1],pair[2])
    end
    text=string.lower(text)
    text=string.gsub(text,"[^%w%s]"," ")
    return string.gsub(text,"%s+"," ")
end
local function Corpus(entry)
    if entry.corpus then return entry.corpus end
    local parts={}
    local function Add(text)
        table.insert(parts,text or ""); table.insert(parts,K.EN[text] or "")
    end
    Add(entry.label); Add(entry.page.caption); Add(entry.page.description); Add(entry.section)
    table.insert(parts,entry.key or "")
    table.insert(parts,aliases[entry.key] or "")
    if entry.page.key=="attributes" then table.insert(parts,"player spieler character stats charakterwerte") end
    for _,help in ipairs(entry.help) do Add(help) end
    for _,item in ipairs(entry.items or {}) do Add(item[2]) end
    local out=Normalize(table.concat(parts," "))
    local extra={}
    for _,group in ipairs(groups) do
        for word in string.gfind(group,"%S+") do
            if string.find(" "..out.." "," "..word.." ",1,true) then table.insert(extra,group); break end
        end
    end
    entry.corpus=out.." "..table.concat(extra," ")
    return entry.corpus
end
function O.FindSettings(query)
    local terms={}
    for word in string.gfind(Normalize(query),"%S+") do table.insert(terms,word) end
    local found={}
    if table.getn(terms)==0 then return found end
    for _,entry in ipairs(O.searchEntries) do
        -- Settings of a module that is off are not offered; the module switch itself is found instead.
        if not links[entry.label] and O.EntryVisible(entry) then
            local corpus=Corpus(entry); local match=true
            for _,term in ipairs(terms) do if not string.find(corpus,term,1,true) then match=false; break end end
            if match then table.insert(found,entry) end
        end
    end
    return found
end

-- One search row above the page title. The sidebar keeps its original space.
local bar=CreateFrame("Frame",nil,panel)
bar:SetWidth(516); bar:SetHeight(28); bar:SetPoint("TOPLEFT",panel,"TOPLEFT",218,-56)
K.Chamfer(bar,4,{.035,.035,.045,1},{.62,.57,.43,1})
local edit=CreateFrame("EditBox","KeijinUISettingsSearch",bar)
edit:SetWidth(470); edit:SetHeight(22); edit:SetPoint("LEFT",bar,"LEFT",10,0)
K.SetFontSize(edit,11); edit:SetAutoFocus(false); edit:SetMaxLetters(120); K.fontStrings=K.fontStrings or {}; table.insert(K.fontStrings,{edit,11})
edit:SetTextColor(.94,.91,.82); edit:SetText("")
local hint=K.LText(bar,"Einstellungen suchen…",11,"LEFT",10,0,464)
hint:SetTextColor(.6,.59,.54)
-- Plain clear symbol inside the field on the right: no frame of its own, brighter on hover.
local clear=CreateFrame("Button","KeijinUISettingsSearchClear",bar)
clear:SetWidth(16); clear:SetHeight(16); clear:SetPoint("RIGHT",bar,"RIGHT",-8,0)
clear.icon=clear:CreateTexture(nil,"OVERLAY")
clear.icon:SetTexture("Interface\\AddOns\\KeijinUI\\media\\guardians\\GuardianEmpty.tga")
clear.icon:SetAllPoints(clear); clear.icon:SetVertexColor(.62,.59,.52,1)
clear:SetScript("OnClick",function() O.CloseChoice(); O.SetSearch(""); edit:SetFocus() end)
clear:SetScript("OnEnter",function() clear.icon:SetVertexColor(1,.9,.6,1) end)
clear:SetScript("OnLeave",function() clear.icon:SetVertexColor(.62,.59,.52,1) end)
clear:Hide()
O.searchEdit,O.searchClear=edit,clear
O.title:ClearAllPoints(); O.title:SetPoint("TOPLEFT",panel,"TOPLEFT",218,-95)
O.subtitle:ClearAllPoints(); O.subtitle:SetPoint("TOPLEFT",panel,"TOPLEFT",218,-127)
O.viewport:ClearAllPoints(); O.viewport:SetPoint("TOPLEFT",panel,"TOPLEFT",218,-157); O.viewport:SetHeight(340)
O.scrollbar:ClearAllPoints(); O.scrollbar:SetPoint("TOPLEFT",panel,"TOPLEFT",741,-157); O.scrollbar:SetHeight(340)
local page=O.Page("search","Suchergebnisse","",nil)
local empty=K.LText(page,"Keine passenden Einstellungen gefunden.",12,"TOPLEFT",0,-14,500)
empty:SetHeight(40); empty:SetTextColor(.75,.73,.67); empty:Hide()
local moved,presentation={},{}
local returnKey="display"
local showPage=O.ShowPage
local busy=false
local function Hint()
    local hasText=(edit:GetText() or "")~=""
    if hasText or O.searchFocused then hint:Hide() else hint:Show() end
    if hasText then clear:Show() else clear:Hide() end
end
local function Restore()
    local hadMoved=table.getn(moved)>0
    for _,record in ipairs(moved) do
        local frame=record.frame
        frame:SetParent(record.parent); frame:ClearAllPoints()
        for _,point in ipairs(record.points) do frame:SetPoint(unpack(point)) end
        frame:Show()
    end
    moved={}
    for _,view in ipairs(presentation) do
        view.context:Hide()
        for _,help in ipairs(view.help) do help:Hide() end
    end
    -- The pages may have been rearranged (module switch) while their controls were away.
    if hadMoved then O.ReflowPages() end
end
local function Move(frame,y)
    local record={frame=frame,parent=frame:GetParent(),points={}}
    for i=1,frame:GetNumPoints() do table.insert(record.points,{frame:GetPoint(i)}) end
    table.insert(moved,record)
    frame:SetParent(page); frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y); frame:Show()
end
local function Render(query)
    O.CloseChoice(); Restore(); O.searchQuery=query
    local words=string.gsub(Normalize(query),"%s","")
    if words=="" then
        O.searchMatches={}
        empty:Hide(); showPage(returnKey); Hint(); return
    end
    local found=O.FindSettings(query)
    O.searchMatches=found
    local y=0
    for i,entry in ipairs(found) do
        local view=presentation[i]
        if not view then
            view={context=K.Text(page,"",9,"TOPLEFT",0,0,512),help={}}
            view.context:SetHeight(14); view.context:SetTextColor(.78,.67,.43)
            presentation[i]=view
        end
        view.context:ClearAllPoints(); view.context:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y)
        view.context:SetText(K.T(entry.page.caption)..(entry.section~="" and "  /  "..K.T(entry.section) or "")); view.context:Show()
        y=y+18; Move(entry.frame,y); y=y+entry.frame:GetHeight()+4
        for j,help in ipairs(entry.help) do
            local fs=view.help[j]
            if not fs then fs=K.Text(page,"",10,"TOPLEFT",0,0,512); fs:SetHeight(32); fs:SetTextColor(.68,.67,.62); view.help[j]=fs end
            fs:ClearAllPoints(); fs:SetPoint("TOPLEFT",page,"TOPLEFT",0,-y); fs:SetText(K.T(help)); fs:Show(); y=y+36
        end
        y=y+12
    end
    page:SetHeight(math.max(O.viewport:GetHeight(),y+8)); page.offset=0
    showPage("search")
    O.subtitle:SetText(K.T("%d passende Einstellungen",table.getn(found)))
    if table.getn(found)==0 then empty:Show() else empty:Hide() end
    Hint()
end
function O.SetSearch(query)
    if busy then return end
    busy=true; query=tostring(query or "")
    if O.current~=page then returnKey=O.current and O.current.key or (O.defaultPage or "general") end
    if edit:GetText()~=query then edit:SetText(query) end
    Render(query); busy=false
end
function O.ShowPage(key)
    if O.searchQuery and O.searchQuery~="" then
        busy=true; Restore(); O.searchQuery=""; O.searchMatches={}; edit:SetText(""); busy=false
    end
    showPage(key); Hint()
end
-- A module switched from inside the results: show the results again without the controls that went away.
O.afterReflow=function() if O.searchQuery and O.searchQuery~="" and not busy then O.SetSearch(O.searchQuery) end end
edit:SetScript("OnTextChanged",function() O.SetSearch(edit:GetText()) end)
edit:SetScript("OnEscapePressed",function() O.SetSearch(""); edit:ClearFocus() end)
edit:SetScript("OnEnterPressed",function() O.CloseChoice() end)
edit:SetScript("OnEditFocusGained",function() O.searchFocused=true; Hint() end)
edit:SetScript("OnEditFocusLost",function() O.searchFocused=false; Hint() end)
local onHide=panel:GetScript("OnHide")
panel:SetScript("OnHide",function()
    if onHide then onHide() end
    O.SetSearch(""); edit:ClearFocus()
end)
K.OnLang(function()
    if O.searchQuery and O.searchQuery~="" then O.SetSearch(O.searchQuery) else Hint() end
end)
Hint()

-- The search bar reduces the viewport; short standalone pages need no scrollbar.
O.ReflowAll()
