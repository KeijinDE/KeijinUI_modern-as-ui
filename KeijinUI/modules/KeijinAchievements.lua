-- Azeroth Survivors 0.87.0 emits completed achievements as SYSTEM chat.
-- No progress estimates, invented unlocks or changes to the account save.
local FONT = "Fonts\\FRIZQT__.TTF"
local DEFAULT_ICON = "Interface\\Icons\\INV_Jewelry_Talisman_07"
local DURATION, FADE_IN, FADE_OUT = 6, 0.3, 0.7
local queue, seen = {}, {}
local current, age, moving, dragging, announced = nil, 0, false, false, false

-- Exact translations embedded in the installed client. The server formats:
-- |cffffd100Achievement earned:|r |cffffff00[Name]|r |cff9d9d9d(10 points)|r
local FORMATS = {
    { "Achievement earned:", "(%d+) points" },
    { "Zdobyto osiągnięcie:", "(%d+) pkt" },
    { "Conquista obtida:", "(%d+) pontos" },
    { "Logro conseguido:", "(%d+) puntos" },
    { "Haut fait obtenu :", "(%d+) points" },
    { "Başarım kazanıldı:", "(%d+) puan" },
    { "Получено достижение:", "(%d+) очков" },
    { "获得成就：", "(%d+)点" },
    { "업적 달성:", "(%d+)점" },
}

local function Settings()
    if type(KeijinUIAchievementsDB) ~= "table" then KeijinUIAchievementsDB = {} end
    local db = KeijinUIAchievementsDB
    if db.enabled == nil then db.enabled = true end
    if db.sound == nil then db.sound = true end
    return db
end

local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88[KeijinAddons]|r " .. text)
end

local function Parse(message)
    if type(message) ~= "string" then return nil end
    local text = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    for i = 1, table.getn(FORMATS) do
        local prefix, pointPattern = FORMATS[i][1], FORMATS[i][2]
        if string.sub(text, 1, string.len(prefix)) == prefix then
            local body = string.sub(text, string.len(prefix) + 1)
            local _, _, name, points = string.find(body, "^%s*%[(.+)%]%s*%(" .. pointPattern .. "%)$")
            if name and points then return name, tonumber(points) end
        end
    end
    -- No German text is known from the client: accept the same shape in any language,
    -- "<text>: [Name] (<number> <word>)".
    local _, _, name, points = string.find(text, "^[^%[]-:%s*%[(.+)%]%s*%((%d+)%s*[^%d%)]*%)$")
    if name and points then return name, tonumber(points) end
end

-- /kachi debug: records system chat (and achievement looking lines of other chat events) in
-- KeijinUIAchievementsDB.log, so a real unlock shows whether and how the line reaches addons.
local DEBUG_EVENTS = { "CHAT_MSG_SYSTEM", "CHAT_MSG_MONSTER_EMOTE", "CHAT_MSG_MONSTER_SAY",
    "CHAT_MSG_MONSTER_YELL", "CHAT_MSG_CHANNEL", "CHAT_MSG_ADDON", "UI_INFO_MESSAGE" }
local LOG_SIZE = 60
local function LooksLikeAchievement(text)
    if type(text) ~= "string" then return false end
    local lower = string.lower(text)
    return string.find(lower, "chiev", 1, true) or string.find(lower, "erfolg", 1, true)
        or string.find(lower, "errungenschaft", 1, true) or Parse(text) ~= nil
end
local function Record(eventName, text, extra)
    local db = Settings()
    if type(db.log) ~= "table" then db.log = {} end
    local stamp = date and date("%Y-%m-%d %H:%M:%S") or tostring(GetTime())
    table.insert(db.log, { time = stamp, event = eventName, text = tostring(text), extra = extra,
        parsed = Parse(text) and true or false })
    while table.getn(db.log) > LOG_SIZE do table.remove(db.log, 1) end
end
local debugFrame = CreateFrame("Frame")
debugFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        Record(event, arg1)
        if LooksLikeAchievement(arg1) then
            Print("|cffffd100" .. KeijinUI.T("Mitschnitt") .. "|r " .. (Parse(arg1) and KeijinUI.T("erkannt") or KeijinUI.T("nicht erkannt"))
                .. ": " .. string.gsub(arg1, "|", "||"))
        end
    elseif event == "CHAT_MSG_ADDON" then
        if type(arg1) == "string" and string.sub(arg1, 1, 3) ~= "AZS" then Record(event, arg2, arg1) end
    elseif LooksLikeAchievement(arg1) then
        Record(event, arg1, arg2)
        Print("|cffffd100" .. KeijinUI.T("Mitschnitt") .. "|r " .. event .. ": " .. string.gsub(arg1, "|", "||"))
    end
end)
local function SetDebug(on)
    Settings().debug = on and true or nil
    for i = 1, table.getn(DEBUG_EVENTS) do
        if on then debugFrame:RegisterEvent(DEBUG_EVENTS[i]) else debugFrame:UnregisterEvent(DEBUG_EVENTS[i]) end
    end
end

local popup = CreateFrame("Frame", "KeijinAchievementsFrame", UIParent)
popup:SetWidth(420)
popup:SetHeight(100)
popup:SetFrameStrata("DIALOG")
popup:SetMovable(true)
popup:SetClampedToScreen(true)
popup:EnableMouse(false)
popup:RegisterForDrag("LeftButton")
popup:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 7, right = 7, top = 7, bottom = 7 },
})
popup:SetBackdropColor(0.19, 0.14, 0.07, 0.98)
popup:SetBackdropBorderColor(1, 0.88, 0.55, 1)
popup:Hide()

local POINTS = { TOP = true, TOPLEFT = true, TOPRIGHT = true, CENTER = true,
    LEFT = true, RIGHT = true, BOTTOM = true, BOTTOMLEFT = true, BOTTOMRIGHT = true }

local function Coordinate(v)
    return type(v) == "number" and v == v and math.abs(v) <= 100000
end

local function Position()
    if KeijinUI.layout.entries.achievements then KeijinUI.layout.Place("achievements"); return end
    popup:ClearAllPoints()
    local p = Settings().position
    if type(p) == "table" and POINTS[p.point] and POINTS[p.relativePoint]
        and Coordinate(p.x) and Coordinate(p.y) then
        popup:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        popup:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
    end
end

local function SavePosition()
    local point, relative, relativePoint, x, y = popup:GetPoint()
    if (not relative or relative == UIParent) and POINTS[point] and POINTS[relativePoint]
        and Coordinate(x) and Coordinate(y) then
        Settings().position = { point = point, relativePoint = relativePoint, x = x, y = y }
    end
end

local function Label(text, x, y, width, height, size, r, g, b, justify)
    local label = popup:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, size, "OUTLINE")
    label:SetPoint("TOPLEFT", popup, "TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetHeight(height)
    label:SetJustifyH(justify or "LEFT")
    label:SetTextColor(r, g, b)
    label:SetText(text)
    return label
end

local iconFrame = CreateFrame("Frame", nil, popup)
iconFrame:SetWidth(60)
iconFrame:SetHeight(60)
iconFrame:SetPoint("LEFT", popup, "LEFT", 16, 0)
iconFrame:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 8 })
local icon = iconFrame:CreateTexture(nil, "ARTWORK")
icon:SetTexture(DEFAULT_ICON)
icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 6, -6)
icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -6, 6)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local heading = Label("ERFOLG ERRUNGEN", 88, -15, 246, 15, 10, 1, 0.82, 0.26)
local title = Label("", 88, -32, 246, 42, 15, 1, 0.94, 0.77)
local footer = Label("Azeroth Survivors", 88, -76, 246, 12, 9, 0.67, 0.60, 0.44)
local amount = Label("", 344, -30, 60, 27, 19, 1, 0.82, 0.22, "CENTER")
Label("PUNKTE", 344, -59, 60, 12, 8, 0.76, 0.66, 0.44, "CENTER")

local function StopDrag()
    if dragging then
        popup:StopMovingOrSizing()
        SavePosition()
        dragging = false
    end
end

popup:SetScript("OnDragStart", function()
    if moving then dragging = true; popup:StartMoving() end
end)
popup:SetScript("OnDragStop", StopDrag)

local function Display(item)
    current, age = item, 0
    title:SetText(item.name)
    amount:SetText("+" .. item.points)
    heading:SetText(item.preview and KeijinUI.T("VORSCHAU") or KeijinUI.T("ERFOLG ERRUNGEN"))
    footer:SetText(moving and KeijinUI.T("Ziehen. /kachi lock zum Fixieren.")
        or "Azeroth Survivors")
    popup:EnableMouse(moving)
    popup:SetAlpha(moving and 1 or 0)
    popup:Show()
    if Settings().sound and not moving then PlaySound("igQuestListComplete") end
end

local function Advance()
    current, age = nil, 0
    popup:Hide()
    if not moving and Settings().enabled and table.getn(queue) > 0 then
        Display(table.remove(queue, 1))
    end
end

local function Receive(message)
    if not Settings().enabled then return end
    local name, points = Parse(message)
    if not name then return end
    local key = name .. "\031" .. points
    local now = GetTime()
    if seen[key] and now - seen[key] < 15 then return end
    seen[key] = now
    table.insert(queue, { name = name, points = points })
    if not current and not moving then Advance() end
end

local function EndMove()
    StopDrag()
    moving = false
    popup:EnableMouse(false)
    Advance()
end

local driver = CreateFrame("Frame", "KeijinAchievementsEvents")
driver:RegisterEvent("CHAT_MSG_SYSTEM")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        Receive(arg1)
    elseif event == "ADDON_LOADED" and arg1 == "KeijinAchievements"
        or event == "PLAYER_ENTERING_WORLD" then
        Position()
        if not announced then
            announced = true
        end
    end
end)
driver:SetScript("OnUpdate", function()
    if not current or moving then return end
    if type(arg1) ~= "number" or arg1 < 0 then return end
    age = age + arg1
    if age >= DURATION then Advance(); return end
    local alpha = 1
    if age < FADE_IN then alpha = age / FADE_IN end
    if age > DURATION - FADE_OUT then alpha = (DURATION - age) / FADE_OUT end
    popup:SetAlpha(alpha)
end)

SLASH_KEIJINACHIEVEMENTS1 = "/kachi"
SlashCmdList["KEIJINACHIEVEMENTS"] = function(message)
    local command = string.lower(message or "")
    command = string.gsub(command, "^%s+", "")
    command = string.gsub(command, "%s+$", "")
    if command == "test" then
        if moving then EndMove() end
        table.insert(queue, { name = KeijinUI.T("Ein denkwürdiger Augenblick"), points = 10, preview = true })
        if not current then Advance() end
        if not Settings().enabled then
            -- Explicit previews work while automatic alerts are disabled.
            Display(table.remove(queue, table.getn(queue)))
        end
    elseif command == "move" then
        if moving then EndMove(); return end
        if current and not current.preview then table.insert(queue, 1, current) end
        moving = true
        Display({ name = KeijinUI.T("Ein denkwürdiger Augenblick"), points = 10, preview = true })
    elseif command == "lock" then
        if moving then EndMove() end
    elseif command == "reset" then
        StopDrag()
        Settings().position = nil; KeijinUI.DB().layout.achievements=nil
        Position()
        Print(KeijinUI.T("Position zurückgesetzt."))
    elseif command == "off" then
        StopDrag()
        moving, current, queue = false, nil, {}
        popup:EnableMouse(false)
        popup:Hide()
        Settings().enabled = false
        Print(KeijinUI.T("Erfolgsfenster ausgeschaltet."))
    elseif command == "on" then
        Settings().enabled = true
        Print(KeijinUI.T("Erfolgsfenster eingeschaltet."))
    elseif command == "debug" then
        SetDebug(not Settings().debug)
        Print(Settings().debug and KeijinUI.T("Mitschnitt der Systemmeldungen läuft, auch nach Neustart. /kachi log zeigt ihn, /kachi debug beendet ihn.")
            or KeijinUI.T("Mitschnitt der Systemmeldungen beendet."))
    elseif command == "log" then
        local log = Settings().log
        local count = type(log) == "table" and table.getn(log) or 0
        if count == 0 then Print(KeijinUI.T("Mitschnitt ist leer.")); return end
        for i = math.max(1, count - 14), count do
            local e = log[i]
            Print(e.time .. " " .. e.event .. (e.extra and (" " .. tostring(e.extra)) or "") .. (e.parsed and " [+]" or "")
                .. ": " .. string.gsub(e.text, "|", "||"))
        end
    elseif command == "log clear" then
        Settings().log = {}
        Print(KeijinUI.T("Mitschnitt geleert."))
    elseif command == "sound" then
        Settings().sound = not Settings().sound
        Print(Settings().sound and KeijinUI.T("Erfolgston eingeschaltet.") or KeijinUI.T("Erfolgston ausgeschaltet."))
    else
        Print(KeijinUI.T("KeijinAchievements: /kachi test, move, lock, reset, on, off, sound, debug, log, log clear"))
    end
end

if Settings().debug then SetDebug(true) end
Position()
