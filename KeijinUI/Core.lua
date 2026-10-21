KeijinUI = { version = "3.5.2", title = "KeijinUI", tools = {}, updates = {}, events = {} }
local K = KeijinUI
-- Shared unscaled width of the movable HUD housings. Layout scales stay personal.
K.PANEL_WIDTH = 300
K.font = "Fonts\\FRIZQT__.TTF"
K.flat = "Interface\\Buttons\\WHITE8X8"
function K.Number(n) return type(n) == "number" and n == n and n >= 0 and n < 1e15 end
-- Game 0.101 can report a K.UIWidth()/GetHeight() that differs from the area it actually covers;
-- frames are placed and clamped within its edges, so the size is taken from them when available.
function K.UIWidth()
    local l,r=UIParent:GetLeft(),UIParent:GetRight()
    if l and r and r-l>40 then return r-l end
    return UIParent:GetWidth()
end
function K.UIHeight()
    local b,t=UIParent:GetBottom(),UIParent:GetTop()
    if b and t and t-b>40 then return t-b end
    return UIParent:GetHeight()
end
-- Class colour from RAID_CLASS_COLORS (token from the second UnitClass return). The 1.12 table gives shamans the
-- paladin pink, so they get the later dark blue instead. Returns nil for unknown tokens.
local CLASS_OVERRIDE = { SHAMAN = { r = 0.00, g = 0.44, b = 0.87 } }
-- Run time as last reported by the game, without the API's interpolation. AZS_GetRunTime() adds GetTime() since
-- the last report; when the game lags its clock falls behind and the next report jumps back. Restart checks
-- therefore compare reported times and allow K.RUN_BACK seconds of fall back (as the run history does).
K.RUN_BACK = 3
function K.ReportedRunTime()
    local t = type(AZS_RUN) == "table" and AZS_RUN.t
    if K.Number(t) then return t end
end
function K.ClassColor(token)
    local c = token and (CLASS_OVERRIDE[token] or type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[token])
    if type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
end
-- Modules (OptionalModules.lua). Older module keys that were merged map onto the new key.
K.moduleAlias = { damageText = "combatText", resourceText = "combatText", guardianNav = "guardians",
    cursor = "comfort", jewelry = "collection", insights = "analysis" }
local MODULE_SCHEMA = 340
-- 3.4.0: modules that were switched off stay off under their new key. Nothing a player stored is removed.
local function MigrateModules(db)
    local old = db.modules
    local function Off(key) return type(old) == "table" and old[key] == false end
    local function Stop(key)
        if type(db.modules) ~= "table" then db.modules = {} end
        db.modules[key] = false
    end
    if Off("damageText") then Stop("combatText")
    elseif Off("resourceText") then db.healingText = false; db.incomingText = false end
    if Off("guardianNav") then Stop("guardians") end
    if Off("cursor") then Stop("comfort") end
    if Off("insights") then Stop("analysis") end
    if Off("jewelry") and not Off("collection") then db.jewelryCooldowns = false end
    if type(KeijinUIBuildDB) == "table" and KeijinUIBuildDB.advisor == false then Stop("advisor") end
    if type(KeijinUIAchievementsDB) == "table" and KeijinUIAchievementsDB.enabled == false then Stop("achievements") end
    db.moduleSchema = MODULE_SCHEMA
end
function K.DB()
    if type(KeijinUIDB) ~= "table" then KeijinUIDB = {} end
    local db = KeijinUIDB
    if db.moduleSchema ~= MODULE_SCHEMA then MigrateModules(db) end
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
-- Damage numbers: off, compact, scroll, rise (all DamageText.lua) or native (the game's own numbers).
-- Read when needed, not at load time: the saved variables arrive after all addon files.
K.CombatModes = { "off", "compact", "scroll", "rise", "native" }
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
    if K.ModuleOn and not K.ModuleOn("combatText") then if K.damageText and K.damageText.Stop then K.damageText.Stop() end; return end
    local db, mode = K.DB(), K.CombatTextMode()
    if db.originalCombatDamage == nil then db.originalCombatDamage = GetCVar("CombatDamage") end
    SetCVar("CombatDamage", mode == "native" and "1" or "0")
    if db.originalShowCombatText == nil then db.originalShowCombatText = SHOW_COMBAT_TEXT or "0" end
    SHOW_COMBAT_TEXT = (mode == "compact" or mode == "scroll" or mode == "rise") and "0" or db.originalShowCombatText
    if CombatText_UpdateDisplayedMessages then CombatText_UpdateDisplayedMessages() end
end
function K.SetCombatTextMode(mode)
    for _,m in ipairs(K.CombatModes) do
        if m == mode then K.DB().combatTextMode = mode; K.ApplyCombatText(); return mode end
    end
    return K.CombatTextMode()
end
function K.CombatScale()
    local width=K.UIWidth()
    -- Once the global slider is used, keep the responsive base tied to the physical viewport.
    -- Otherwise a larger uiScale makes UIParent narrower and would shrink unit/action frames again.
    local reference=K.DB().layoutScaleReference
    if K.Number(reference) and reference>0 then width=width*UIParent:GetEffectiveScale()/reference end
    return math.min(1,math.max(0.5,(width-624)/686))
end
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
-- Spell book as name -> texture, rebuilt on SPELLS_CHANGED and at the first need (same calls as KeijinBuildBar.lua).
local book, byName
-- Lower case for A to Z only: string.lower follows the C locale and could alter UTF-8 bytes (Ü, Ä).
local function AsciiLower(c) return string.char(string.byte(c)+32) end
local function Lower(s) return (string.gsub(s,"[A-Z]",AsciiLower)) end
local gear, gearDirty, gearScan = {}, true, 0
function K.SpellIcon(name)
    if not name or name=="" or K.SourceKey(name)=="melee" then
        if type(GetInventoryItemTexture)=="function" then return GetInventoryItemTexture("player",16) end
        return nil
    end
    if not book then
        book={}
        if type(GetNumSpellTabs)=="function" and type(GetSpellTabInfo)=="function"
            and type(GetSpellName)=="function" and type(GetSpellTexture)=="function" then
            for tab=1,math.min(16,GetNumSpellTabs()) do
                local _,_,offset,count=GetSpellTabInfo(tab)
                if type(offset)=="number" and type(count)=="number" then
                    for index=math.max(1,offset+1),math.min(1023,offset+count) do
                        local spell=GetSpellName(index,"spell")
                        if spell then book[spell]=GetSpellTexture(index,"spell") end
                    end
                end
            end
        end
    end
    if book[name] then return book[name] end
    -- Items that deal damage under their own name: worn gear, remembered for the session so the icon
    -- stays after the item is taken off (death, victory). Rescanned on inventory changes and, in case the
    -- game equips items without that event, at most every 2 seconds while a name is still unknown.
    local now=type(GetTime)=="function" and GetTime() or 0
    if not gear[Lower(name)] and (gearDirty or now-gearScan>=2) then
        gearDirty=false; gearScan=now
        if type(GetInventoryItemLink)=="function" and type(GetInventoryItemTexture)=="function" then
            for slot=1,19 do
                local link=GetInventoryItemLink("player",slot)
                local _,_,item=string.find(link or "","%[(.-)%]")
                local texture=item and GetInventoryItemTexture("player",slot)
                if texture then gear[Lower(item)]=texture end
            end
        end
    end
    if gear[Lower(name)] then return gear[Lower(name)] end
    -- Fallback: spell name (English or localized) -> ability key -> fixed icon table.
    if not byName then
        byName={}
        for key,value in pairs(KeijinBuildBarNames or {}) do byName[value]=key end
        for key,list in pairs(KeijinBuildBarAliases or {}) do
            for index=1,table.getn(list) do if not byName[list[index]] then byName[list[index]]=key end end
        end
    end
    local key=byName[name]
    local icon=key and KeijinBuildBarIcons and KeijinBuildBarIcons[key]
    if icon then return icon end
    -- Last: talents that deal damage under their own name (Seal of Command), English and German.
    return KeijinTalentIcons and KeijinTalentIcons[Lower(name)] or nil
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
    K.fontStrings=K.fontStrings or {}; table.insert(K.fontStrings,{fs,size or 11})
    fs:SetTextColor(0.94, 0.91, 0.82)
    fs:SetPoint(point or "TOPLEFT", frame, point or "TOPLEFT", x or 0, y or 0)
    if width then fs:SetWidth(width); fs:SetHeight((size or 11) + 5); fs:SetJustifyH("LEFT") end
    fs:SetText(text or "")
    return fs
end
-- One original contour for panels and buttons; circles use their own artwork.
-- Background opacity (settings): panels and unit frame bodies. nil means the original 0.91.
K.BG_ALPHA=0.91
K.skinned={}
function K.BackgroundAlpha()
    local v=tonumber(K.DB().bgAlpha)
    if not v then return K.BG_ALPHA end
    return math.max(0.2,math.min(1,v))
end
function K.ApplyBackground()
    local a=K.BackgroundAlpha()
    for _,frame in ipairs(K.skinned) do
        local shape=frame.chamfer
        if shape and shape.background and not frame.noOpacity then
            local c=shape.background; frame:SetBackdropColor(c[1],c[2],c[3],a)
        end
    end
    if K.ApplyUnitBackground then K.ApplyUnitBackground() end
end
function K.SetBackgroundAlpha(v)
    v=math.max(0.2,math.min(1,tonumber(v) or K.BG_ALPHA))
    if math.abs(v-K.BG_ALPHA)<0.005 then K.DB().bgAlpha=nil else K.DB().bgAlpha=v end
    K.ApplyBackground()
end
function K.Skin(frame, edge)
    local cut=(edge or 10)>=10 and 6 or 4
    K.Chamfer(frame,cut,{0.055,0.055,0.065,K.BackgroundAlpha()},{0.62,0.57,0.43,1})
    if not frame.skinTracked then frame.skinTracked=true; table.insert(K.skinned,frame) end
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
-- A switch of the player decides: ours on, the game's part hidden; ours off, the game's part shown,
-- whatever it was before. K.Native(part,false) only gives back a temporarily taken part.
function K.NativeFollow(part, ours)
    if ours then K.Native(part,true); return end
    if not AZS_SetHudShown or not AZS_IsHudShown then return end
    K.DB().native[part] = nil
    if not AZS_IsHudShown(part) then AZS_SetHudShown(part,true) end
end
K.callbackOwners={}
function K.ModuleKey(key) return key and (K.moduleAlias[key] or key) end
function K.ModuleOn(key)
    key=K.ModuleKey(key)
    local modules=K.DB().modules
    return not (key and type(modules)=="table" and modules[key]==false)
end
function K.Update(owner,fn) table.insert(K.updates,fn); K.callbackOwners[fn]=owner end
function K.On(eventName, fn, owner)
    if not K.events[eventName] then K.events[eventName] = {}; K.driver:RegisterEvent(eventName) end
    table.insert(K.events[eventName],fn)
    K.callbackOwners[fn]=owner
end
K.driver = CreateFrame("Frame", "KeijinUIEvents")
K.driver:SetScript("OnEvent", function()
    for _,fn in ipairs(K.events[event] or {}) do if K.ModuleOn(K.callbackOwners[fn]) then fn(event,arg1,arg2) end end
end)
-- Shared cache stays current even when the combat text module is disabled.
K.On("SPELLS_CHANGED",function() book=nil end)
K.On("UNIT_INVENTORY_CHANGED",function(_,unit) if unit=="player" then gearDirty=true end end)
local elapsed = 0
K.driver:SetScript("OnUpdate", function()
    elapsed = elapsed + (tonumber(arg1) or 0)
    if elapsed < 0.1 then return end
    elapsed = 0
    for _,fn in ipairs(K.updates) do if K.ModuleOn(K.callbackOwners[fn]) then fn() end end
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
