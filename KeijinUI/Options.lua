local K=KeijinUI
local panel=K.Panel("KeijinUIOptions","KeijinUI",440,473)
panel:SetFrameStrata("DIALOG")
-- Opaque background: the dialog texture itself is translucent, so the panel uses the flat fill.
K.Skin(panel,7)
panel:SetBackdropColor(0.055,0.055,0.065,1)
-- The panel moves with the left mouse button; its position is kept in KeijinUIDB.options.
local saved=K.DB().options
if type(saved)=="table" and saved.point then panel:SetPoint(saved.point,UIParent,saved.relative,saved.x,saved.y)
else panel:SetPoint("CENTER",UIParent,"CENTER",0,0) end
panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart",function() this:StartMoving() end)
panel:SetScript("OnDragStop",function()
    this:StopMovingOrSizing()
    local point,_,relative,x,y=this:GetPoint()
    K.DB().options={point=point,relative=relative,x=x,y=y}
end)

-- Everything whose caption depends on a setting is refreshed through this list (language change, click).
local captions={}
local function RefreshAll() for _,fn in ipairs(captions) do fn() end end
K.OnLang(RefreshAll)
local GOLD={1,0.82,0.28}
local function Mark(button,active)
    button:SetBackdropBorderColor(active and 1 or 0.4,active and 0.82 or 0.38,0.28,1)
end

-- Tabs: one row of buttons under the title, one content frame per tab, only one visible.
local PAGE_WIDTH=408
local tabs={ {"display","Anzeige"},{"units","Einheiten"},{"layout","Layout"},{"general","Allgemein"} }
local pages,tabButtons={},{}
for _,entry in ipairs(tabs) do
    local page=CreateFrame("Frame",nil,panel)
    page:SetWidth(PAGE_WIDTH); page:SetHeight(341); page:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-68)
    page:Hide()
    pages[entry[1]]=page
end
local function ShowTab(key)
    if not pages[key] then key="display" end
    for name,page in pairs(pages) do
        if name==key then page:Show() else page:Hide() end
        Mark(tabButtons[name],name==key)
    end
    K.DB().optionsTab=key
end

local function Button(parent,text,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent)
    b:SetWidth(width); b:SetHeight(26); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    K.Skin(b, 7); b.text=K.Text(b,text,10,"CENTER",0,0)
    b:SetScript("OnClick",fn)
    if text~="" then K.Live(b.text,function() return K.T(text) end) end
    return b
end
for i,entry in ipairs(tabs) do
    local key=entry[1]
    tabButtons[key]=Button(panel,entry[2],16+(i-1)*102,-34,98,function() ShowTab(key) end)
end

local function Heading(page,text,y)
    local fs=K.LText(page,text,11,"TOPLEFT",0,y,PAGE_WIDTH)
    fs:SetTextColor(GOLD[1],GOLD[2],GOLD[3])
    return fs
end
-- A text line that is rebuilt on language change and on every refresh.
local function Line(page,fn,size,x,y,width)
    local fs=K.Text(page,"",size,"TOPLEFT",x,y,width)
    K.Live(fs,fn)
    table.insert(captions,function() fs:SetText(fn()) end)
    return fs
end
-- A whole row is the button: name on the left, state on the right.
-- state() returns the text and the color of the state.
local function Row(page,label,y,state,fn)
    local row=CreateFrame("Button",nil,page)
    row:SetWidth(PAGE_WIDTH); row:SetHeight(23); row:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
    row:SetBackdrop({ bgFile = K.flat })
    row:SetBackdropColor(0.1,0.1,0.115,0.9)
    row:SetScript("OnEnter",function() this:SetBackdropColor(0.18,0.17,0.13,0.95) end)
    row:SetScript("OnLeave",function() this:SetBackdropColor(0.1,0.1,0.115,0.9) end)
    row.name=K.Text(row,"",11,"LEFT",8,0)
    K.Live(row.name,function() return K.T(label) end)
    row.value=K.Text(row,"",11,"RIGHT",-8,0)
    local function Refresh()
        local text,color=state()
        row.value:SetText(text); row.value:SetTextColor(color[1],color[2],color[3])
    end
    row:SetScript("OnClick",function() fn(); RefreshAll() end)
    Refresh(); table.insert(captions,Refresh)
    return row
end
local ON,OFF={0.4,0.9,0.4},{0.6,0.6,0.62}
local function OnOff(on) if on then return K.T("An"),ON end return K.T("Aus"),OFF end
-- Switch for a run module hidden through K.DB().hidden[key].
local function HiddenSwitch(page,key,label,y)
    return Row(page,label,y,function() return OnOff(not K.DB().hidden[key]) end,
        function() K.DB().hidden[key]=not K.DB().hidden[key] end)
end

-- Tab Anzeige
local page=pages.display
Heading(page,"Übersichten",0)
HiddenSwitch(page,"tracker","Runübersicht",-18)
Row(page,"Wächter in der Runübersicht",-43,function() return OnOff(K.guardians.On()) end,
    function() K.guardians.Set(not K.guardians.On()) end)
HiddenSwitch(page,"bosses","Begegnungen",-68)
HiddenSwitch(page,"statistics","Runstatistiken",-93)
HiddenSwitch(page,"tally","Kills und Gold",-118)
HiddenSwitch(page,"xp","Erfahrung",-143)
Heading(page,"Kampf",-175)
HiddenSwitch(page,"meter","Schadensanzeige",-193)
HiddenSwitch(page,"crits","Kritische Treffer",-218)
local MODE_NAMES={off="Aus",compact="Kompakt",scroll="Scrollend",native="Spiel"}
Row(page,"Schadenszahlen",-243,function()
    local mode=K.CombatTextMode()
    return K.T(MODE_NAMES[mode]),mode=="off" and OFF or GOLD
end,
    function() SlashCmdList.KEIJINUI("text") end)
Row(page,"Zaubersymbole",-268,function() return OnOff(K.DB().combatTextIcons~=false) end,
    function() SlashCmdList.KEIJINUI("text icons") end)
Row(page,"Buildtipps",-293,function() return OnOff(not (KeijinUIBuildDB and KeijinUIBuildDB.advisor==false)) end,
    function() SlashCmdList.KEIJINBUILDBAR("tipps") end)
Row(page,"Minimap im KeijinUI Stil",-318,function() return OnOff(K.DB().minimapStyle~=false) end,
    function() K.SetMinimapStyle(K.DB().minimapStyle==false) end)

-- Tab Einheiten
page=pages.units
Heading(page,"Einheitenrahmen",0)
Row(page,"Lebensbalken",-18,function()
    return K.DB().classHealth~=false and K.T("Klassenfarbe") or K.T("Grün / Rot"),GOLD
end,function() K.DB().classHealth=(K.DB().classHealth==false) end)
Row(page,"Buffs",-43,function()
    return K.DB().buffsLeft and K.T("linksbündig") or K.T("rechtsbündig"),GOLD
end,function() K.SetBuffsLeft(not K.DB().buffsLeft) end)
Row(page,"Klassenressourcen",-68,function()
    return K.DB().classResources~=false and K.T("Automatisch") or K.T("Aus"),GOLD
end,function() K.SetClassResources(K.DB().classResources==false) end)
Row(page,"Ressourcenposition",-93,function()
    return K.DB().resourceFree and K.T("Frei") or K.T("Am Spieler"),GOLD
end,function() K.SetResourceFree(not K.DB().resourceFree) end)
Heading(page,"Namensplaketten",-128)
local plateButtons={}
for i,entry in ipairs({{"all","Alle Gegner"},{"bosses","Boss, Elite, Rare"},{"off","Aus"}}) do
    plateButtons[entry[1]]=Button(page,entry[2],(i-1)*139,-148,130,function() K.SetNameplates(entry[1]) end)
end
function K.UpdateNameplateLabels()
    for mode,button in pairs(plateButtons) do Mark(button,K.DB().nameplates==mode) end
end
K.UpdateNameplateLabels()
Heading(page,"Caches",-190)
for i,entry in ipairs({{"icons","Cache Symbole"},{"edge","Cache Randpfeil"},{"arrow","Cache Bildschirmpfeil"},{"msg","Cache Meldung"}}) do
    local part=entry[1]
    Row(page,entry[2],-208-(i-1)*25,function() return OnOff(K.caches.Get(part)) end,
        function() K.caches.Set(part,not K.caches.Get(part)) end)
end

-- Tab Layout
page=pages.layout
local hint=K.LText(page,"Alt halten: Rahmen anzeigen und verschieben.\nAlt + Mausrad: Größe ändern.\nShift beim Loslassen: ohne Einrasten.\nÄnderungen werden gespeichert.",10,"TOPLEFT",0,0,PAGE_WIDTH)
hint:SetHeight(56)
Heading(page,"Bearbeiten",-66)
Button(page,"Layout bearbeiten",0,-84,200,function() K.layout.Toggle(); panel:Hide() end)
Row(page,"Raster und Einrasten",-116,function() return OnOff(K.DB().snap~=false) end,function() K.layout.ToggleGrid() end)
Heading(page,"Zurücksetzen",-152)
Button(page,"Layout zurücksetzen",0,-170,200,function() K.layout.Reset() end)
Button(page,"Tooltip zurücksetzen",208,-170,200,function() K.ResetTooltip() end)

-- Tab Allgemein
page=pages.general
Heading(page,"Sprache",0)
local langButtons={}
for i,entry in ipairs({{"en","English"},{"de","Deutsch"}}) do
    langButtons[entry[1]]=Button(page,entry[2],(i-1)*139,-18,130,function() K.SetLang(entry[1]); RefreshAll() end)
end
table.insert(captions,function() for value,button in pairs(langButtons) do Mark(button,K.DB().lang==value) end end)
Heading(page,"Oberfläche",-80)
Button(page,"Oberfläche neu laden",0,-98,200,function() SlashCmdList.KEIJINUI("reload") end)
Button(page,"Erfolgsvorschau",208,-98,200,function() SlashCmdList.KEIJINACHIEVEMENTS("test") end)
Heading(page,"Befehle",-140)
local commands=K.LText(page,"/kui: Einstellungen, Layout und Sprache\n/kui runs: Rundenübersicht\n/kbb: Zauber, Schmuck und Buildtipps\n/kachi: Erfolgsmeldung",10,"TOPLEFT",0,-158,PAGE_WIDTH)
commands:SetHeight(56)
Heading(page,"Runs",-222)
Button(page,"Rundenübersicht",0,-240,200,function() K.runs.Toggle() end)
Row(page,"Run Meldung",-272,function() return OnOff(K.runs.MessageOn()) end,
    function() K.runs.SetMessage(not K.runs.MessageOn()) end)
Row(page,"Minimapknopf",-297,function() return OnOff(K.MinimapButtonOn()) end,
    function() K.SetMinimapButton(not K.MinimapButtonOn()) end)

Button(panel,"Schließen",170,-437,100,function() panel:Hide() end)
RefreshAll()
ShowTab(K.DB().optionsTab)
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
    else K.Say(K.T("/kui, /kui edit, /kui reset, /kui grid (Raster und Einrasten), /kui text off|compact|scroll|game, /kui plates all|bosses|off|debug, /kui bosses debug, /kui heal debug, /kui caches icons, edge, arrow, msg, source, debug, /kui runs (Rundenübersicht), /kui runs msg, /kui guardians on|off (Wächter), /kui button on|off (Minimapknopf), /kui tooltip reset, /kui meter reset, /kui crits reset, /kui lang de|en (Sprache), /kui reload (Oberfläche neu laden). /kbb für Buildtipps, /kachi für Erfolge.")) end
end
