-- KeijinUI combat line reader.
-- Turns the chat lines of the damage channels into small records
-- { kind="damage", amount, targetName, sourceName, spell, school, critical, periodic, origin }.
--
-- Nothing is hard coded in English. Every line shape is the client's own
-- format string (SPELLLOGSELFOTHER and friends). At first use a format string is
-- split into fixed text pieces and argument slots; a chat line is then checked
-- by walking the pieces from left to right. Because the pieces come from the
-- client, every client language is covered without a second table.

local K = KeijinUI

-- ---------------------------------------------------------------------------
-- 1. Format strings become piece lists
-- ---------------------------------------------------------------------------

local compiled = {}

-- Returns { {text="..."} | {arg=n, numeric=bool}, ... } or nil if the global is missing.
local function Split(globalName)
    local cached = compiled[globalName]
    if cached ~= nil then return cached or nil end
    local format = getglobal(globalName)
    if type(format) ~= "string" or format == "" then
        compiled[globalName] = false
        return nil
    end
    local pieces, literal, nextArg = {}, "", 0
    local at, size = 1, string.len(format)
    local function FlushLiteral()
        if literal ~= "" then table.insert(pieces, { text = literal }); literal = "" end
    end
    while at <= size do
        local ch = string.sub(format, at, at)
        if ch ~= "%" then
            literal = literal .. ch
            at = at + 1
        else
            local after = string.sub(format, at + 1, at + 1)
            if after == "%" then
                literal = literal .. "%"
                at = at + 2
            else
                -- "%s", "%d" or the numbered form "%2$s"
                local _, stop, position, kind = string.find(format, "^(%d*)%$?([sd])", at + 1)
                if not stop then
                    literal = literal .. "%"
                    at = at + 1
                else
                    FlushLiteral()
                    nextArg = nextArg + 1
                    table.insert(pieces, { arg = tonumber(position) or nextArg, numeric = (kind == "d") })
                    at = stop + 1
                end
            end
        end
    end
    FlushLiteral()
    compiled[globalName] = pieces
    return pieces
end

-- ---------------------------------------------------------------------------
-- 2. Matching a line against the pieces
-- ---------------------------------------------------------------------------

-- Fixed text must match exactly. A text slot takes the shortest span that lets
-- the rest of the line match (names may contain words such as " for "), and a
-- number slot takes the digits at the current position.
local function Walk(pieces, index, line, at, found)
    local piece = pieces[index]
    if not piece then return at == string.len(line) + 1 end
    if piece.text then
        local width = string.len(piece.text)
        if string.sub(line, at, at + width - 1) ~= piece.text then return false end
        return Walk(pieces, index + 1, line, at + width, found)
    end
    if piece.numeric then
        local _, last = string.find(line, "^%d+", at)
        if not last then return false end
        found[piece.arg] = tonumber(string.sub(line, at, last))
        return Walk(pieces, index + 1, line, last + 1, found)
    end
    for stop = at, string.len(line) + 1 do
        found[piece.arg] = string.sub(line, at, stop - 1)
        if Walk(pieces, index + 1, line, stop, found) then return true end
    end
    return false
end

-- fieldNames[n] is the record field that receives the client's argument n.
local function Read(line, globalName, fieldNames)
    local pieces = Split(globalName)
    if not pieces then return nil end
    local found = {}
    if not Walk(pieces, 1, line, 1, found) then return nil end
    local record = {}
    for n = 1, table.getn(fieldNames) do record[fieldNames[n]] = found[n] end
    return record
end

-- ---------------------------------------------------------------------------
-- 3. The shapes we know
-- ---------------------------------------------------------------------------

-- stem: global name without the SELFOTHER/OTHEROTHER ending
-- args: record fields in the order of the "you are the source" wording
-- sourceFirst: the "someone else" wording starts with the source's name
local SHAPES = {
    melee = {
        { stem = "COMBATHIT",           args = { "targetName", "amount" } },
        { stem = "COMBATHITCRIT",       args = { "targetName", "amount" }, critical = true },
        { stem = "COMBATHITSCHOOL",     args = { "targetName", "amount", "school" } },
        { stem = "COMBATHITCRITSCHOOL", args = { "targetName", "amount", "school" }, critical = true },
    },
    spell = {
        { stem = "SPELLLOG",            args = { "spell", "targetName", "amount" } },
        { stem = "SPELLLOGCRIT",        args = { "spell", "targetName", "amount" }, critical = true },
        { stem = "SPELLLOGSCHOOL",      args = { "spell", "targetName", "amount", "school" } },
        { stem = "SPELLLOGCRITSCHOOL",  args = { "spell", "targetName", "amount", "school" }, critical = true },
        { stem = "SPELLSPLITDAMAGE",    args = { "spell", "targetName", "amount" } },
    },
}

-- Damage over time and damage shields word the "someone else" case with their own
-- argument order, so both orders are listed.
local PERIODIC = {
    mine   = { stem = "PERIODICAURADAMAGESELFOTHER",  args = { "targetName", "amount", "school", "spell" } },
    theirs = { stem = "PERIODICAURADAMAGEOTHEROTHER", args = { "targetName", "amount", "school", "sourceName", "spell" } },
}
local SHIELD = {
    mine   = { stem = "DAMAGESHIELDSELFOTHER",  args = { "amount", "school", "targetName" } },
    theirs = { stem = "DAMAGESHIELDOTHEROTHER", args = { "sourceName", "amount", "school", "targetName" } },
}

local function WithSource(args)
    local list = { "sourceName" }
    for n = 1, table.getn(args) do table.insert(list, args[n]) end
    return list
end

-- ---------------------------------------------------------------------------
-- 4. Helpers for the result
-- ---------------------------------------------------------------------------

local function OwnedByPlayer(name)
    if not name or not UnitName then return false end
    return name == UnitName("player") or name == UnitName("pet")
end

-- Local school name -> stable English key (the client names are the ones in chat).
local function SchoolKey(localName)
    if not localName then return "Physical" end
    local keys = { [0] = "Physical", "Holy", "Fire", "Nature", "Frost", "Shadow", "Arcane" }
    for n = 0, 6 do
        if getglobal("SPELL_SCHOOL" .. n .. "_CAP") == localName then return keys[n] end
    end
    return localName
end

local function Finish(record, rule, origin)
    if not record or not record.amount or record.amount <= 0 then return nil end
    if not record.targetName or record.targetName == "" then return nil end
    record.kind = "damage"
    record.origin = origin
    record.school = SchoolKey(record.school)
    if rule.critical then record.critical = 1 end
    if origin == "periodic" then record.periodic = 1 end
    return record
end

-- ---------------------------------------------------------------------------
-- 5. Reading one line
-- ---------------------------------------------------------------------------

-- viewpoint: "mine" = the line is about the player, "theirs" = about a pet or another
-- unit, which only counts when the source is the player or the player's pet
-- (trusted = the chat channel itself already guarantees that).
local function TryShapes(line, list, origin, viewpoint, trusted)
    for n = 1, table.getn(list) do
        local rule = list[n]
        local record
        if viewpoint == "mine" then
            record = Read(line, rule.stem .. "SELFOTHER", rule.args)
        else
            record = Read(line, rule.stem .. "OTHEROTHER", WithSource(rule.args))
            if record and not trusted and not OwnedByPlayer(record.sourceName) then record = nil end
        end
        record = Finish(record, rule, origin)
        if record then return record end
    end
    return nil
end

local function TryPair(line, pair, origin, viewpoint, trusted)
    local rule = pair[viewpoint]
    local record = Read(line, rule.stem, rule.args)
    if record and not trusted and viewpoint == "theirs" and not OwnedByPlayer(record.sourceName) then
        record = nil
    end
    return Finish(record, rule, origin)
end

local function MeleeLine(viewpoint, trusted)
    return function(line) return TryShapes(line, SHAPES.melee, "melee", viewpoint, trusted) end
end
local function SpellLine(viewpoint, trusted)
    return function(line) return TryShapes(line, SHAPES.spell, "spell", viewpoint, trusted) end
end
local function PeriodicLine(line)
    return TryPair(line, PERIODIC, "periodic", "mine")
        or TryPair(line, PERIODIC, "periodic", "theirs")
end
local function ShieldLine(line)
    return TryPair(line, SHIELD, "shield", "mine")
        or TryPair(line, SHIELD, "shield", "theirs")
        or TryShapes(line, SHAPES.spell, "spell", "mine")
        or TryShapes(line, SHAPES.spell, "spell", "theirs")
end

-- One entry per chat event; the keys also tell callers what to register for.
local READERS = {
    CHAT_MSG_COMBAT_SELF_HITS                     = MeleeLine("mine"),
    CHAT_MSG_COMBAT_PET_HITS                      = MeleeLine("theirs", true),
    CHAT_MSG_SPELL_SELF_DAMAGE                    = SpellLine("mine"),
    CHAT_MSG_SPELL_PET_DAMAGE                     = SpellLine("theirs", true),
    CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE       = PeriodicLine,
    CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE  = PeriodicLine,
    CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE = PeriodicLine,
    CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE          = PeriodicLine,
    CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF          = ShieldLine,
    CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS        = ShieldLine,
}

K.tools.CombatEvents = READERS

-- Returns a damage record for a damage line of the given chat event, otherwise nil.
function K.tools.ParseCombatLine(eventName, line)
    if type(line) ~= "string" or line == "" then return nil end
    local reader = READERS[eventName]
    if reader then return reader(line) end
    return nil
end
