KeijinUI = { version = "1.1.1", tools = {}, updates = {}, events = {} }
local K = KeijinUI
K.font = "Fonts\\FRIZQT__.TTF"
K.flat = "Interface\\Buttons\\WHITE8X8"
function K.Number(n) return type(n) == "number" and n == n and n >= 0 and n < 1e15 end
function K.DB()
    if type(KeijinUIDB) ~= "table" then KeijinUIDB = {} end
    local db = KeijinUIDB
    if type(db.layout) ~= "table" then db.layout = {} end
    if type(db.native) ~= "table" then db.native = {} end
    if type(db.hidden) ~= "table" then db.hidden = {} end
    if db.snap == nil then db.snap = true end
    if db.lang ~= "de" and db.lang ~= "en" then db.lang = "en" end
    db.detectedLang = nil
    if db.schema ~= 2 then
        for _,key in ipairs({"player","target","skills","build","tally","xp"}) do db.layout[key]=nil end
        db.schema=2
    end
    return db
end
-- Damage numbers: off, compact (DamageText.lua), scroll (DamageText.lua) or native (the game's own numbers).
-- Read when needed, not at load time: the saved variables arrive after all addon files.
K.CombatModes = { "off", "compact", "scroll", "native" }
function K.CombatTextMode()
    local db = K.DB()
    for _,mode in ipairs(K.CombatModes) do if db.combatTextMode == mode then return mode end end
    db.combatTextMode = db.hideCombatText == true and "off" or "scroll"
    return db.combatTextMode
end
-- The native floating numbers cannot split normal and critical hits, so they only run in the native mode.
-- The game's floating combat text (SHOW_COMBAT_TEXT, the "-N" over the character) is paused while
-- the own text runs; CombatText_UpdateDisplayedMessages drops its events at once.
function K.ApplyCombatText()
    local db, mode = K.DB(), K.CombatTextMode()
    if db.originalCombatDamage == nil then db.originalCombatDamage = GetCVar("CombatDamage") end
    SetCVar("CombatDamage", mode == "native" and "1" or "0")
    if db.originalShowCombatText == nil then db.originalShowCombatText = SHOW_COMBAT_TEXT or "0" end
    SHOW_COMBAT_TEXT = (mode == "compact" or mode == "scroll") and "0" or db.originalShowCombatText
    if CombatText_UpdateDisplayedMessages then CombatText_UpdateDisplayedMessages() end
end
function K.SetCombatTextMode(mode)
    for _,m in ipairs(K.CombatModes) do
        if m == mode then K.DB().combatTextMode = mode; K.ApplyCombatText(); return mode end
    end
    return K.CombatTextMode()
end
function K.CombatScale() return math.min(1,math.max(0.5,(UIParent:GetWidth()-624)/686)) end
local sourceColors={{0.75,0.53,0.16},{0.18,0.4,0.65},{0.5,0.25,0.62},{0.25,0.5,0.32},{0.65,0.28,0.17},
    {0.2,0.65,0.7},{0.8,0.4,0.6},{0.48,0.6,0.25},{0.55,0.4,0.3},{0.4,0.5,0.8}}
-- Deliberate ability colours for the warlock set. These identify abilities;
-- they are not damage-school data (the meter does not provide that).
-- Other sources retain their stable hash colour, independent of row order.
local abilityColors={
    shadow_bolt={0.48,0.36,0.76}, corruption={0.56,0.28,0.49},
    immolate={0.76,0.39,0.20}, curse_of_agony={0.80,0.40,0.60},
    rain_of_fire={0.84,0.43,0.16}, hellfire={0.69,0.25,0.17},
    death_coil={0.35,0.62,0.43}, searing_pain={0.80,0.62,0.22},
    drain_life={0.31,0.62,0.34}, fear={0.46,0.40,0.59},
    soul_fire={0.90,0.53,0.29}
}
local sourceKeys
local function Key(s) return string.gsub(string.lower(s or ""),"[%s%p]","") end
-- Stable ability key of any localized name (English, German, ... from the Names and Aliases tables).
function K.SourceKey(name)
    if not sourceKeys then
        sourceKeys={melee="melee",nahkampf="melee"}
        for key,label in pairs(KeijinBuildBarNames or {}) do sourceKeys[Key(label)]=key; sourceKeys[Key(key)]=key end
        for key,aliases in pairs(KeijinBuildBarAliases or {}) do for _,label in ipairs(aliases) do sourceKeys[Key(label)]=key end end
    end
    return sourceKeys[Key(name)] or Key(name)
end
-- One language everywhere: German names for the German interface, English names otherwise.
-- Unknown names stay as they are.
function K.DisplayName(name)
    local key=K.SourceKey(name)
    if key=="melee" then return K.T("Nahkampf") end
    local names=K.lang=="de" and KeijinBuildBarGerman or KeijinBuildBarNames
    return names and names[key] or name
end
function K.SourceColor(name)
    local key=K.SourceKey(name)
    local known=abilityColors[key]
    if known then return known[1],known[2],known[3] end
    local hash=0
    for i=1,string.len(key) do hash=math.mod(hash*33+string.byte(key,i),1000003) end
    local color=sourceColors[math.mod(hash,table.getn(sourceColors))+1]
    return color[1],color[2],color[3]
end
function K.Say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88[KeijinAddons]|r " .. message) end
end
function K.Clock(value)
    if not K.Number(value) then return "?" end
    value = math.floor(value)
    return string.format("%d:%02d", math.floor(value / 60), math.mod(value, 60))
end
function K.Short(n)
    if not K.Number(n) then return "?" end
    if n >= 1000000 then return string.format("%.1fm", n / 1000000) end
    if n >= 10000 then return string.format("%.1fk", n / 1000) end
    return string.format("%.0f", n)
end
function K.Text(frame, text, size, point, x, y, width)
    local fs = frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont(K.font, size or 11, "OUTLINE")
    fs:SetTextColor(0.94, 0.91, 0.82)
    fs:SetPoint(point or "TOPLEFT", frame, point or "TOPLEFT", x or 0, y or 0)
    if width then fs:SetWidth(width); fs:SetHeight((size or 11) + 5); fs:SetJustifyH("LEFT") end
    fs:SetText(text or "")
    return fs
end
-- One original contour for panels and buttons; circles use their own artwork.
function K.Skin(frame, edge)
    local cut=(edge or 10)>=10 and 6 or 4
    K.Chamfer(frame,cut,{0.055,0.055,0.065,0.91},{0.62,0.57,0.43,1})
end
function K.Panel(name, title, width, height)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetWidth(width); f:SetHeight(height); f:SetFrameStrata("LOW")
    f:SetClampedToScreen(true)
    K.Skin(f, 7)
    local strip = f:CreateTexture(nil, "BORDER")
    strip:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
    strip:SetVertexColor(0.6, 0.53, 0.36, 0.55)
    strip:SetPoint("TOPLEFT", f, "TOPLEFT", 7, -5)
    strip:SetPoint("TOPRIGHT", f, "TOPRIGHT", -7, -5); strip:SetHeight(23)
    f.strip = strip
    f.title = K.Text(f, "", 12, "TOPLEFT", 13, -11, width - 26)
    K.Live(f.title, function() return K.T(title) end)
    f.title:SetTextColor(1, 0.82, 0.28)
    if K.headers and K.headers.eligible[name] then K.headers.Attach(f) end
    f:Hide()
    return f
end
-- Native value/range semantics with a clipped original fill and closed chamfered rim.
function K.MetalBar(frame,bar,fixedCut)
    local nativeValue=bar.SetValue
    local r,g,b,a=bar:GetStatusBarColor()
    local color={r or 1,g or 1,b or 1,a or 1}
    bar:SetStatusBarColor(0,0,0,0)
    local fill=K.CutFill(frame)
    fill:Color(unpack(color))
    local function Paint()
        local width,height=frame:GetWidth(),frame:GetHeight()
        if width<=2 or height<=2 then return end
        local cut=fixedCut or math.min(4,height*0.2)
        if not frame.chamfer or math.abs(frame.chamfer.cut-cut)>0.01 then
            K.Chamfer(frame,cut,{0.025,0.025,0.03,0.92})
        end
        local low,high=bar:GetMinMaxValues()
        local value=tonumber(bar:GetValue()) or low
        local share=high>low and (value-low)/(high-low) or 0
        fill:Paint(width-2,height-2,share,1,-1)
    end
    bar.SetValue=function(self,value) nativeValue(self,value); Paint() end
    bar.SetStatusBarColor=function(self,r,g,b,a) color={r,g,b,a or 1}; fill:Color(r,g,b,a) end
    bar.GetStatusBarColor=function() return unpack(color) end
    Paint()
    return fill
end
-- Shared part of all list rows: position in the panel, label, value and tooltip. The text
-- sits on its own layer above whatever the row draws.
local function RowBase(parent, index, height)
    local row = CreateFrame("Frame", nil, parent)
    K.HeaderPoint(row,parent,"TOPLEFT",10,-33-(index-1)*(height+2))
    row:SetWidth(parent:GetWidth()-20); row:SetHeight(height)
    local textLayer = CreateFrame("Frame", nil, row)
    textLayer:SetAllPoints(row); textLayer:SetFrameLevel(row:GetFrameLevel()+4)
    row.label = K.Text(textLayer, "", 10, "LEFT", 5, 0, parent:GetWidth()-105)
    row.value = K.Text(textLayer, "", 11, "RIGHT", -5, 0)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function()
        if not this.tip then return end
        GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText(this.tip,1,0.82,0.28)
        if this.detail then GameTooltip:AddLine(this.detail,0.94,0.91,0.82,true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end
-- Bar row with the straight line border (boss rows of the encounter group).
function K.Row(parent, index, height)
    local row = RowBase(parent, index, height)
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("TOPLEFT",row,"TOPLEFT",1,-1); row.bar:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-1,1); row.bar:SetMinMaxValues(0,1); row.bar:SetValue(0)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    K.MetalBar(row,row.bar)
    return row
end
-- Key and value without a bar or border, only a faint line below (run statistics).
function K.ValueRow(parent, index, height)
    local row = RowBase(parent, index, height)
    row.line = row:CreateTexture(nil, "BACKGROUND")
    row.line:SetTexture(K.flat); row.line:SetVertexColor(0.62,0.57,0.43,0.22)
    row.line:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",3,-1); row.line:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-3,-1)
    row.line:SetHeight(1)
    return row
end
-- Data bar with short chamfered corners (damage meter, critical hits). Inner area, fill and the
-- 1 unit outline are each built from a left end, a stretched middle and a mirrored right
-- end (media/list, made by development/keijinui/prepare_list_art.py). The ends keep their
-- width, so the corners never stretch. A partial fill crops texture and width together,
-- like the unit frames, and keeps the rounded left end.
local LIST="Interface\\AddOns\\KeijinUI\\media\\list\\"
local CAP=8
local CAP_U=31.5/32   -- stop at the last texel centre, no wrap seam at the join
local function ListPieces(row, layer, file, height)
    local l=row:CreateTexture(nil,layer); l:SetTexture(LIST..file.."Cap.tga")
    local m=row:CreateTexture(nil,layer); m:SetTexture(LIST..file.."Mid.tga"); m:SetTexCoord(0.25,0.75,0,1)
    local r=row:CreateTexture(nil,layer); r:SetTexture(LIST..file.."Cap.tga")
    for _,t in ipairs({l,m,r}) do t:SetHeight(height) end
    l:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    m:SetPoint("TOPLEFT",row,"TOPLEFT",CAP,0)
    r:SetPoint("TOPLEFT",row,"TOPLEFT",row:GetWidth()-CAP,0)
    return {l,m,r}
end
local function ListFull(pieces, width)
    pieces[1]:SetWidth(CAP); pieces[1]:SetTexCoord(0,CAP_U,0,1)
    pieces[2]:SetWidth(width-2*CAP)
    pieces[3]:SetWidth(CAP); pieces[3]:SetTexCoord(CAP_U,0,0,1)
end
function K.ListBarRow(parent, index, height)
    local row = RowBase(parent, index, height)
    local width = row:GetWidth()
    local back = ListPieces(row, "BACKGROUND", "Shape", height)
    ListFull(back, width)
    for _,t in ipairs(back) do t:SetVertexColor(0.04,0.04,0.05,0.6) end
    local rim = ListPieces(row, "OVERLAY", "Rim", height)
    ListFull(rim, width)
    for _,t in ipairs(rim) do t:SetVertexColor(0.62,0.57,0.43,0.95) end
    local fill = ListPieces(row, "ARTWORK", "Fill", height)
    -- Same calls as a StatusBar, so the panels need no special handling.
    local bar = { fill=fill, value=0 }
    function bar:SetMinMaxValues() end
    function bar:GetValue() return self.value end
    function bar:SetValue(value)
        value = math.max(0, math.min(1, tonumber(value) or 0)); self.value = value
        local w = width*value
        local a = math.min(w, CAP)
        local b = math.min(math.max(w-CAP, 0), width-2*CAP)
        local c = math.max(0, w-(width-CAP))
        if a > 0 then fill[1]:SetWidth(a); fill[1]:SetTexCoord(0,CAP_U*a/CAP,0,1); fill[1]:Show() else fill[1]:Hide() end
        if b > 0 then fill[2]:SetWidth(b); fill[2]:Show() else fill[2]:Hide() end
        if c > 0 then fill[3]:SetWidth(c); fill[3]:SetTexCoord(CAP_U,CAP_U*(1-c/CAP),0,1); fill[3]:Show() else fill[3]:Hide() end
    end
    function bar:SetStatusBarColor(r, g, b, a)
        self.barcolor = {r, g, b, a}
        for _,t in ipairs(self.fill) do t:SetVertexColor(r, g, b, a or 1) end
    end
    function bar:GetStatusBarColor() return unpack(self.barcolor) end
    bar:SetStatusBarColor(1, 1, 1, 1); bar:SetValue(0)
    row.bar, row.back, row.rim = bar, back, rim
    return row
end
function K.Native(part, replace)
    if not AZS_SetHudShown or not AZS_IsHudShown then return end
    local saved = K.DB().native
    if replace then
        if saved[part] == nil then saved[part] = AZS_IsHudShown(part) and true or false end
        if AZS_IsHudShown(part) then AZS_SetHudShown(part,false) end
    elseif saved[part] ~= nil then
        AZS_SetHudShown(part,saved[part]); saved[part] = nil
    end
end
function K.On(eventName, fn)
    if not K.events[eventName] then K.events[eventName] = {}; K.driver:RegisterEvent(eventName) end
    table.insert(K.events[eventName],fn)
end
K.driver = CreateFrame("Frame", "KeijinUIEvents")
K.driver:SetScript("OnEvent", function()
    for _,fn in ipairs(K.events[event] or {}) do fn(event,arg1,arg2) end
end)
local elapsed = 0
K.driver:SetScript("OnUpdate", function()
    elapsed = elapsed + (tonumber(arg1) or 0)
    if elapsed < 0.1 then return end
    elapsed = 0
    for _,fn in ipairs(K.updates) do fn() end
    if K.layout then K.layout.ClampAll() end
end)
K.On("PLAYER_LOGOUT", function()
    local parts = {}
    for part in pairs(K.DB().native) do table.insert(parts,part) end
    for _,part in ipairs(parts) do K.Native(part,false) end
    if K.DB().originalCombatDamage ~= nil then SetCVar("CombatDamage",K.DB().originalCombatDamage) end
    if K.DB().originalShowCombatText ~= nil then SHOW_COMBAT_TEXT = K.DB().originalShowCombatText end
end)
K.On("PLAYER_ENTERING_WORLD",function()
    K.ApplyCombatText()
end)
