KeijinUI = { version = "0.6.1", tools = {}, updates = {}, events = {} }
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
function K.CombatScale() return math.min(1,math.max(0.5,(UIParent:GetWidth()-624)/686)) end
local sourceColors={{0.75,0.53,0.16},{0.18,0.4,0.65},{0.5,0.25,0.62},{0.25,0.5,0.32},{0.65,0.28,0.17},
    {0.2,0.65,0.7},{0.8,0.4,0.6},{0.48,0.6,0.25},{0.55,0.4,0.3},{0.4,0.5,0.8}}
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
-- Unit frames keep edge 10; panels and buttons use the thinner edge 7.
function K.Skin(frame, edge)
    edge = edge or 10
    local inset = edge >= 10 and 3 or 2
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true,
        tileSize = 16, edgeSize = edge, insets = {left=inset,right=inset,top=inset,bottom=inset} })
    frame:SetBackdropColor(0.055, 0.055, 0.065, 0.91)
    frame:SetBackdropBorderColor(0.62, 0.57, 0.43, 1)
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
    f:Hide()
    return f
end
function K.MetalBar(frame,bar)
    local path="Interface\\AddOns\\KeijinUI\\media\\"
    bar:SetStatusBarTexture(path.."FillWhite.tga")
    local overlay=CreateFrame("Frame",nil,frame)
    overlay:SetAllPoints(frame); overlay:SetFrameLevel(bar:GetFrameLevel()+1)
    local pieces={}
    for _,name in ipairs({"Left","Right","Center"}) do
        local tex=overlay:CreateTexture(nil,"OVERLAY")
        tex:SetTexture(path.."Border"..name..".tga")
        tex:SetPoint("TOP",overlay,"TOP",0,4); tex:SetPoint("BOTTOM",overlay,"BOTTOM",0,-4)
        tex:SetTexCoord(0,name=="Center" and 1 or 35/64,0,31/32)
        pieces[name]=tex
    end
    pieces.Left:SetWidth(24); pieces.Left:SetPoint("LEFT",frame,"LEFT",-3,0)
    pieces.Right:SetWidth(24); pieces.Right:SetPoint("RIGHT",frame,"RIGHT",3,0)
    pieces.Center:SetPoint("LEFT",pieces.Left,"RIGHT",0,0)
    pieces.Center:SetPoint("RIGHT",pieces.Right,"LEFT",0,0)
    return overlay
end
function K.Row(parent, index, height)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -33 - (index-1)*(height+2))
    row:SetWidth(parent:GetWidth()-20); row:SetHeight(height)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(K.flat); bg:SetVertexColor(0.04,0.04,0.05,0.6)
    -- The metal border has only slightly rounded corners, so the fill reaches under its edge.
    bg:SetPoint("TOPLEFT",row,"TOPLEFT",1,-1); bg:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-1,1)
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("TOPLEFT",row,"TOPLEFT",1,-1); row.bar:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-1,1); row.bar:SetMinMaxValues(0,1); row.bar:SetValue(0)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    K.MetalBar(row,row.bar)
    local textLayer = CreateFrame("Frame", nil, row)
    textLayer:SetAllPoints(row); textLayer:SetFrameLevel(row.bar:GetFrameLevel()+2)
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
end)
K.On("PLAYER_ENTERING_WORLD",function()
    if K.DB().originalCombatDamage == nil then K.DB().originalCombatDamage=GetCVar("CombatDamage") end
    -- The native floating numbers cannot split normal and critical hits, so DamageText.lua draws them.
    SetCVar("CombatDamage","0")
end)
