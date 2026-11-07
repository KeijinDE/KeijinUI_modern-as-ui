-- Build guidance, not recognition of the cards currently offered.
-- No CVar writes, network, probe addon or background process.
KeijinBuildAdvisor = {}
local A = KeijinBuildAdvisor
local WINDOW, MINIMUM, LIMIT = 30, 8, 40
local history, lastTime, lastTotal, identity = {}, nil, nil, nil
local tip, tipCache, textCache = nil, {}, {}
-- Tooltip data is entered anew only after a relevant event (spells, talents, action bar, AZSSPELLS), not on a timer.
-- generation counts those events; a scan budget spreads the rescan over several evaluations.
local generation, slotGeneration, scanBudget, scanPending = 0, 0, 0, false
local SCANS_PER_EVALUATION = 4
local cache, used = {at = -100}, false

-- Texts are German sources translated by KeijinUI.T; without KeijinUI they stay German.
local function T(text, a1, a2, a3)
	if KeijinUI and KeijinUI.T then return KeijinUI.T(text, a1, a2, a3) end
	if a1 ~= nil then return string.format(text, a1, a2, a3) end
	return text
end
local function Number(value)
	return type(value) == "number" and value == value and value >= 0 and value < 1e15
end
local function Normalize(value)
	return string.gsub(string.lower(value or ""), "[%s%p]", "")
end
-- The meter reports names in the game's language (German), the spell book may use another one.
-- Both are reduced to the stable ability key through the Names and Aliases tables; unknown names
-- fall back to their normalized text.
local byName
local function Canonical(name)
	if not byName then
		byName = {}
		for key, label in pairs(KeijinBuildBarNames or {}) do byName[Normalize(label)] = key; byName[Normalize(key)] = key end
		for key, list in pairs(KeijinBuildBarAliases or {}) do
			for index = 1, table.getn(list) do byName[Normalize(list[index])] = key end
		end
		for key, label in pairs(KeijinBuildBarGerman or {}) do byName[Normalize(label)] = key end
	end
	local plain = Normalize(name)
	return byName[plain] or plain
end
A.Canonical = Canonical
-- Recommendation titles in the interface language: the spell book may report names of another language.
local function Label(row)
    if KeijinUI and KeijinUI.AbilityName then
        local label=KeijinUI.AbilityName(row.key or Canonical(row.name or ""))
        if label then return label end
    end
	local german = KeijinUI and KeijinUI.lang ~= "de" and KeijinBuildBarNames or KeijinBuildBarGerman or {}
	return german[row.key or ""] or german[Canonical(row.name or "")] or row.name
end
A.Label = Label
local function Copy(value)
	local out = {}
	for key, item in pairs(value or {}) do out[key] = item end
	return out
end
local function Keys(text)
	local out = {}
	for key in string.gfind(text, "%S+") do out[key] = true end
	return out
end
local RACIAL = Keys("perception blood_fury stoneform shadowmeld will_of_the_forsaken war_stomp escape_artist berserking")
local HEAL = Keys("holy_light healing_wave renew rejuvenation regrowth lightwell")
local SHIELD = Keys("holy_shield divine_shield pw_shield ice_barrier")
local CONTROL = Keys("hammer_of_justice frost_nova psychic_scream fear polymorph entangling_roots gouge kidney_shot")
local SINGLE = Keys("exorcism hammer_of_wrath holy_shock judgement arcane_shot aimed_shot sinister_strike eviscerate backstab ghostly_strike smite mind_blast holy_fire lightning_bolt earth_shock frost_shock fireball frostbolt arcane_missiles fire_blast pyroblast shadow_bolt searing_pain soul_fire wrath starfire rend serpent_sting rupture sw_pain devouring_plague flame_shock corruption immolate curse_of_agony moonfire insect_swarm")

function A.Reset()
	-- Called every tick while the advisor is off: nothing to clear unless it was used since the last reset.
	if not used then return end
	used = false
	history, lastTime, lastTotal, identity = {}, nil, nil, nil
	tipCache = {}; generation = generation + 1
	cache.at, cache.result = -100, nil
end
-- A spell, talent or action bar change entwerts the tooltip texts; they are read again a few at a time.
function A.Invalidate()
	generation = generation + 1
	cache.at = -100
end

-- Pure observation of cumulative counters using active run seconds, never wall time.
function A.Observe(seconds, meter, runIdentity)
	if not Number(seconds) or type(meter) ~= "table" then return false end
	local damage, total = {}, 0
	for index = 1, table.getn(meter) do
		local row = meter[index]
		if type(row) == "table" and type(row.name) == "string" and Number(row.dmg) then
			local key = Canonical(row.name)
			damage[key] = (damage[key] or 0) + row.dmg
			total = total + row.dmg
		end
	end
	local reset = identity ~= runIdentity or (lastTime and seconds < lastTime - 0.01)
		or (lastTotal and total < lastTotal - 0.01)
	local last = history[table.getn(history)]
	if last and seconds - last.time > WINDOW then reset = true end
	if last and not reset then
		for key, value in pairs(last.damage) do
			if (damage[key] or 0) < value - 0.01 then reset = true end
		end
	end
	if reset then history, tipCache = {}, {}; generation = generation + 1 end
	identity, lastTime, lastTotal = runIdentity, seconds, total
	last = history[table.getn(history)]
	if last and seconds == last.time then
		-- Preserve the earlier baseline while a card or pause freezes the clock.
		return true
	end
	if last and seconds - last.time < 0.9 then return true end
	table.insert(history, {time=seconds, damage=damage, total=total})
	while table.getn(history) > LIMIT do table.remove(history, 1) end
	while table.getn(history) > 2 and history[2].time <= seconds - WINDOW do table.remove(history, 1) end
	return true
end

function A.Window()
	local first, last = history[1], history[table.getn(history)]
	if not first or not last then return nil end
	local duration = last.time - first.time
	local total = last.total - first.total
	if duration < MINIMUM or total <= 0 then return nil end
	local damage = {}
	for key, value in pairs(last.damage) do damage[key] = math.max(0, value - (first.damage[key] or 0)) end
	return {seconds=duration, total=total, damage=damage}
end

local function ClearColor(text)
	return string.gsub(string.gsub(text or "", "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
end
local function Decimal(text)
	if not text then return nil end
	local value = string.gsub(text, ",", ".")
	return tonumber(value)
end
-- Only interpret the game's explicit local upgrade line. Global bonuses are not counted twice.
function A.ParseBonus(text, rank)
	text = ClearColor(text)
	-- The game's words in all its languages (GameText.lua), English and German as before if it is missing.
	local words = KeijinGameText or {}
	local upgrades
	for _, prefix in ipairs(words.upgrades or {"Upgrades:", "Verbesserungen:"}) do
		local _, last = string.find(text, prefix, 1, true)
		if last then _, _, upgrades = string.find(string.sub(text, last + 1), "^[ \t]*([^ \t\n][^\n]*)"); break end
	end
	if upgrades then
		-- A whole bonus only: "+5% damage reduction" is not damage, so the match must end the line
		-- or be followed by a list separator.
		local value
		for _, pattern in ipairs(words.damage or {"%+([%d%.,]+)%% damage", "%+([%d%.,]+)%% Schaden"}) do
			local init = 1
			while not value do
				local first, last, found = string.find(upgrades, pattern, init)
				if not first then break end
				local after = string.sub(upgrades, last + 1, last + 3)
				if after == "" or string.find(after, "^[,;%)]") or string.find(after, "^\239\188\140")
					or string.find(after, "^\227\128\129") then value = found end
				init = last + 1
			end
			if value then break end
		end
		return (Decimal(value) or 0) / 100
	end
	if rank == 1 then
		for _, prefix in ipairs(words.bonuses or {"Your bonuses:", "Deine Boni:"}) do
			if string.find(text, prefix, 1, true) then return 0 end
		end
		if string.find(text, "Eure Boni:", 1, true) then return 0 end
	end
	return nil
end

-- The spell's tooltip text from the hidden tooltip, one scan per ability and rank (a new rank or spell book slot
-- scans again) and at most one per maxAge seconds. Returns the text (false if it cannot be read) and the cache entry,
-- a new table for every scan.
local function TipLines()
	local lines = {}
	for index = 1, math.min(40, tip:NumLines()) do
		local region = getglobal("KeijinBuildAdvisorTooltipTextLeft"..index)
		if region and type(region.GetText) == "function" then table.insert(lines, region:GetText() or "") end
	end
	return table.concat(lines, "\n")
end
-- Ability names compared byte-safe (A-Z only, no locale classes: UTF-8 names such as "Felsbeißers" stay intact).
local function Fold(name)
	name = ClearColor(name)
	name = string.gsub(name, "[A-Z]", function(c) return string.char(string.byte(c) + 32) end)
	return (string.gsub(name, "[ \009-\013!-/:-@[-`{-~]", ""))
end
-- Abilities that are not in the spell book (the game writes their text for an action slot only): one shared index of
-- the action slots (first tooltip line and icon), built a few slots per frame and started again when a slot changes.
local SLOTS_PER_FRAME = 12
local slotIndex = {slots = {}, pending = {}, ready = false, cursor = 1, frame = -1, used = 0, at = 0}
local function RestartSlots()
	-- Keep the published snapshot readable until its replacement is complete.
	if not slotIndex.ready and slotIndex.cursor > 1 then
		slotIndex.slots, slotIndex.ready = slotIndex.pending, true
	end
	slotIndex.pending = {}
	slotIndex.cursor = 1
	slotIndex.at = GetTime()
end
local slotWatcher = CreateFrame("Frame")
slotWatcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
slotWatcher:SetScript("OnEvent", function() slotGeneration = slotGeneration + 1; RestartSlots() end)
local function Icon(path) return (string.gsub(string.lower(path or ""), "/", "\\")) end
-- Folded name -> ability key, or false when one name belongs to two abilities (Portuguese Shred / Slice and Dice).
local owners
local function Owners()
	if owners then return owners end
	owners = {}
	for _, source in ipairs({KeijinBuildBarAliases or {}, KeijinGameAbilityNames or {}}) do
		for key, names in pairs(source) do
			for index = 1, table.getn(names) do
				local name = Fold(names[index])
				if owners[name] == nil or owners[name] == key then owners[name] = key else owners[name] = false end
			end
		end
	end
	return owners
end
-- Returns the text (false if none), and whether the index was complete when looking.
local function ActionText(row)
	if type(HasAction) ~= "function" or type(tip.SetAction) ~= "function" then return false, true end
	local now = GetTime()
	if now - slotIndex.at > 30 then RestartSlots() end
	if slotIndex.frame ~= now then slotIndex.frame, slotIndex.used = now, 0 end
	local function Title(slot)
		if type(tip.ClearLines) == "function" then tip:ClearLines() end
		tip:SetOwner(UIParent, "ANCHOR_NONE")
		tip:SetAction(slot)
		if tip:NumLines() < 1 then return "" end
		local first = getglobal("KeijinBuildAdvisorTooltipTextLeft1")
		return first and type(first.GetText) == "function" and Fold(first:GetText()) or ""
	end
	while slotIndex.cursor <= 120 and slotIndex.used < SLOTS_PER_FRAME do
		local slot = slotIndex.cursor
		slotIndex.used = slotIndex.used + 1
		if HasAction(slot) then
			slotIndex.pending[slot] = {title = Title(slot),
				icon = Icon(type(GetActionTexture) == "function" and GetActionTexture(slot) or nil), text = TipLines()}
		else slotIndex.pending[slot] = false end
		slotIndex.cursor = slot + 1
	end
	if slotIndex.cursor > 120 and slotIndex.pending then
		slotIndex.slots, slotIndex.pending, slotIndex.ready = slotIndex.pending, nil, true
	end
	local names = {}
	local lists = {{row.name, row.key}, (KeijinBuildBarAliases or {})[row.key] or {}, (KeijinGameAbilityNames or {})[row.key] or {}}
	for list = 1, 3 do
		for index = 1, table.getn(lists[list]) do names[Fold(lists[list][index])] = true end
	end
	names[""] = nil
	local known = Owners()
	for slot = 1, 120 do
		local entry = (slotIndex.ready and slotIndex.slots or slotIndex.pending)[slot]
		-- An ambiguous name only counts when the slot also shows this ability's icon.
		if entry and names[entry.title] and (known[entry.title] == row.key or known[entry.title] == nil
			or (known[entry.title] == false and row.icon and Icon(row.icon) == entry.icon)) then
			return entry.text, true
		end
	end
	return false, slotIndex.cursor > 120
end
local function SpellText(row, maxAge)
	local now = GetTime()
	local entry = textCache[row.key]
	if not row.book and entry and entry.rank ~= row.rank then RestartSlots() end
	-- A cached text is only reused while nothing relevant happened (generation) and it is younger than maxAge; an
	-- action slot text also needs a finished slot index, since a half built index may still hold the old text.
	if entry and entry.gen == generation and entry.slotGen == slotGeneration and entry.rank == row.rank
		and entry.book == row.book and now - entry.at <= maxAge
		and (row.book or (entry.settled and slotIndex.pending == nil)) then
		return entry.text, entry
	end
	local text, complete = false, true
	if not tip then
		tip = CreateFrame("GameTooltip", "KeijinBuildAdvisorTooltip", UIParent, "GameTooltipTemplate")
		tip:Hide()
	end
	if type(tip.SetOwner) == "function" and type(tip.NumLines) == "function" then
		tip:SetOwner(UIParent, "ANCHOR_NONE")
		if row.book and type(tip.SetSpell) == "function" then
			tip:SetSpell(row.book, "spell")
			text = TipLines()
		elseif not row.book then
			text, complete = ActionText(row)
		end
		tip:Hide()
	end
	-- An unfinished slot index may still find it: look again next frame.
	if not row.book and entry and entry.rank == row.rank and entry.book == row.book and entry.text == text then return text, entry end
	entry = {rank = row.rank, book = row.book, text = text, gen = generation, slotGen = slotGeneration, settled = complete and slotIndex.pending == nil, at = complete and now or now - maxAge - 1}
	textCache[row.key] = entry
	return text, entry
end

local BONUS_AGE = 30
local function NativeBonus(row)
	if not row.book then return nil end
	local key = row.key..":"..tostring(row.rank)..":"..row.book
	local hit = tipCache[key]
	local now = GetTime()
	-- A value is reused while nothing relevant happened and it is younger than BONUS_AGE (a tooltip can change without an event).
	if hit and hit.generation == generation and now >= hit.at and now - hit.at <= BONUS_AGE then return hit.value or nil end
	-- Out of budget (expired values count too): keep the previous value (if any) and finish on a later evaluation.
	if scanBudget <= 0 then scanPending = true; return hit and hit.value or nil end
	scanBudget = scanBudget - 1
	local text = SpellText(row, 5)
	local bonus = text and A.ParseBonus(text, row.rank) or false
	if hit then hit.generation, hit.value, hit.at = generation, bonus, now
	else tipCache[key] = {generation = generation, value = bonus, at = now} end
	return bonus or nil
end

-- Number of targets of a spell, read from its tooltip: "the nearest enemy" 1, "the 3 nearest enemies" 3,
-- "up to 4 enemies" 4, "nearest enemy, then jumps to up to 3 more" 4. Patterns per language in TargetText.lua.
-- Nothing recognised returns nil (better blank than wrong). Digits only; the game writes the number as a digit.
local foundLanguage
local function TargetLanguages()
	local order, seen = {}, {}
	local function Add(code)
		if code and not seen[code] and KeijinTargetText and KeijinTargetText[code] then
			seen[code] = true; table.insert(order, code)
		end
	end
	-- The tooltip language is not detectable (GetLocale is fixed): the language that matched last time, the interface
	-- language and English go first, every other game language follows.
	Add(foundLanguage); Add(KeijinUI and KeijinUI.lang); Add("en")
	local rest = {}
	for code in pairs(KeijinTargetText or {}) do if not seen[code] then table.insert(rest, code) end end
	table.sort(rest)
	for index = 1, table.getn(rest) do Add(rest[index]) end
	return order
end
function A.ParseTargets(text)
	if type(text) ~= "string" or not KeijinTargetText then return nil end
	text = ClearColor(text)
	-- Only the description counts: the upgrade and bonus lines list other targets ("+1 target").
	local words, cut = KeijinGameText or {}, nil
	for _, list in ipairs({words.upgrades or {"Upgrades:", "Verbesserungen:"}, words.bonuses or {"Your bonuses:", "Deine Boni:"}}) do
		for _, prefix in ipairs(list) do
			local first = string.find(text, prefix, 1, true)
			if first and (not cut or first < cut) then cut = first end
		end
	end
	if cut then text = string.sub(text, 1, cut - 1) end
	local order = TargetLanguages()
	for index = 1, table.getn(order) do
		local list = KeijinTargetText[order[index]]
		for entry = 1, table.getn(list) do
			local first, _, found = string.find(text, list[entry][2])
			if first then
				local amount = found and tonumber(found) or 1
				if amount and amount >= 1 and amount < 100 then
					foundLanguage = order[index]
					return list[entry][1] == "chain" and amount + 1 or amount
				end
			end
		end
	end
	return nil
end
local targetCache = {}
function A.TargetCount(row)
	if type(row) ~= "table" or type(row.key) ~= "string" then return nil end
	local text, scan = SpellText(row, 30)
	if not text then return nil end
	local entry = targetCache[row.key]
	if not entry or entry.scan ~= scan then
		entry = {scan = scan, count = A.ParseTargets(text) or false}
		targetCache[row.key] = entry
	end
	return entry.count or nil
end

function A.DamageGain(share, localBonus)
	if not Number(share) or share > 1 or not Number(localBonus) then return nil end
	-- Hypothetical +10 percentage points of additive local damage, not an offered card.
	return share * 0.10 / (1 + localBonus)
end

local function Support(spells, preferHeal)
	local heal, shield, control
	for index = 1, table.getn(spells) do
		local row = spells[index]
		if HEAL[row.key] and not heal then heal = row end
		if SHIELD[row.key] and not shield then shield = row end
		if CONTROL[row.key] and not control then control = row end
	end
	if preferHeal then return heal or shield or control end
	return shield or heal or control
end

function A.Evaluate(spells, run, stats, focus, window)
	local result = {heading=T("Tipp"), title=T("Sammle Daten"), confidence=T("Noch keine Messung"), reasons={}, alternatives={}}
	if type(stats) ~= "table" then stats = {} end
	focus = focus or "balanced"
	local health = Number(run.hp) and Number(run.hpm) and run.hpm > 0 and run.hp / run.hpm or nil
	local protection = health and (run.hp + (Number(run.sh) and run.sh or 0)) / run.hpm or nil
	local urgent = protection and protection < 0.35
	if focus == "survival" or (focus == "balanced" and urgent) then
		local row = Support(spells, health and health < 0.5)
		result.heading, result.title = T("Schutz"), row and Label(row) or T("Defensive stärken")
		result.key, result.confidence, result.safety = row and row.key, T("Regelhinweis"), true
		table.insert(result.reasons, urgent and T("Wenig Leben: Schutz und Heilung haben Vorrang.") or T("Fokus Überleben: Schutz und Heilung bevorzugen."))
		if row then table.insert(result.reasons, T("Diese Fähigkeit kann den Schutz deines Builds unterstützen.")) end
		if Number(stats.shd) and stats.shd > 0 then table.insert(result.reasons, T("Dein Build hat zusätzlichen Schaden, solange ein Schild aktiv ist.")) end
		return result
	end
	if not window then
		table.insert(result.reasons, T("Mindestens 8 aktive Kampfsekunden mit Schaden nötig. Das Fenster wächst bis etwa 30 Sekunden."))
		return result
	end
	local candidates, modeled = {}, false
	for index = 1, table.getn(spells) do
		local row = spells[index]
		if not RACIAL[row.key] then
			local amount = window.damage[Canonical(row.name)] or window.damage[row.key] or 0
			local share = amount / window.total
			if share > 0 then
				local bonus = row.damageBonus
				local gain = A.DamageGain(share, bonus)
				table.insert(candidates, {key=row.key, name=row.name, share=share, bonus=bonus,
					gain=gain, single=SINGLE[row.key] and true or false})
			end
		end
	end
	local eligible = {}
	local hasSingle = false
	for index = 1, table.getn(candidates) do if candidates[index].single then hasSingle = true end end
	for index = 1, table.getn(candidates) do
		local row = candidates[index]
		if (focus ~= "boss" or not hasSingle or row.single) and row.gain then modeled = true end
	end
	for index = 1, table.getn(candidates) do
		local row = candidates[index]
		if (focus ~= "boss" or not hasSingle or row.single) and (not modeled or row.gain) then
			table.insert(eligible, row)
		end
	end
	table.sort(eligible, function(a,b)
		local left, right = a.gain or a.share, b.gain or b.share
		if left == right then return a.key < b.key end
		return left > right
	end)
	local best = eligible[1]
	result.seconds = window.seconds
	if not best then
		result.title, result.confidence = T("Keine Zuordnung"), T("Daten reichen nicht")
		table.insert(result.reasons, T("Für erlernte Spells wurde noch kein passender Schadenseintrag gemessen."))
		return result
	end
	result.key, result.title, result.share, result.gain = best.key, Label(best), best.share, best.gain
	result.heading = best.gain and T("Schaden ausbauen") or T("Schaden prüfen")
	result.confidence = best.gain and T("Modellschätzung") or T("Vorläufig nach Anteil")
	result.alternatives = eligible
	table.insert(result.reasons, T("%.0f%% des Gesamtschadens in den letzten %.0f Kampfsekunden.", best.share*100, window.seconds))
	if best.gain then
		table.insert(result.reasons, T("Vergleichsmodell: +10 Prozentpunkte lokaler Schadensbonus ergibt etwa +%.1f%% Gesamtschaden.", best.gain*100))
		table.insert(result.reasons, T("Das ist ein hypothetischer Vergleich, keine erkannte Karte."))
		if table.getn(eligible) < table.getn(candidates) and focus ~= "boss" then
			result.heading, result.confidence = T("Modellhinweis"), T("Teilmodell")
			table.insert(result.reasons, T("Für einzelne Spells fehlen Bonusdaten; sie wurden im Modell nicht mitverglichen."))
		end
	else
		table.insert(result.reasons, T("Lokaler Aufwertungsbonus nicht lesbar. Priorität nur nach jüngstem Schadensanteil."))
	end
	if Number(stats.lch) and stats.lch > 0 then
		table.insert(result.reasons, T("Lebensraub: zusätzlicher Schaden kann gleichzeitig heilen, solange Leben fehlt."))
	end
	if Number(stats.shd) and stats.shd > 0 then
		table.insert(result.reasons, T("Schildsynergie: aktiven Schild erhalten, damit dein Schadensbonus wirkt."))
	end
	if focus == "boss" then
		table.insert(result.reasons, T("Bossfokus bevorzugt bekannte Einzelzielzauber. Die Messung enthält auch Schaden an anderen Gegnern."))
	elseif Number(run.nb) and run.nb <= 30 then
		table.insert(result.reasons, T("Der nächste Boss kommt bald: Einzelzielschaden und Schutz mitprüfen."))
	end
	if urgent then table.insert(result.reasons, T("Wenig Leben: bei der nächsten Wahl auch Schutz oder Heilung prüfen.")) end
	table.insert(result.reasons, T("Abklingzeit, Ziele, Dauer und Grenzen können eine konkrete Wahl anders gewichten."))
	table.insert(result.reasons, T("Frisch gelernte Spells können im Kampffenster noch unterrepräsentiert sein."))
	return result
end

local function ZoneField(zone, field) return zone and zone[field] end
function A.Get(spells, run, stats, zone, focus)
	used = true
	local now = GetTime()
	local meter = AZS_METER
	local hasMeter = type(meter) == "table"
	-- At most once per second, or at once when an input changed; tables are not rebuilt in between.
	if cache.result and now >= cache.at and now - cache.at < 1 and not scanPending
		and cache.spells == spells and cache.focus == focus and cache.stats == stats and cache.zone == zone
		and cache.zoneName == ZoneField(zone, "zone") and cache.hero == ZoneField(zone, "hero")
		and cache.class == ZoneField(zone, "class") and cache.hasMeter == hasMeter then
		return cache.result
	end
	local seconds = type(AZS_GetRunTime) == "function" and AZS_GetRunTime() or run.t
	local id = tostring(zone and zone.zone)..":"..tostring(zone and zone.hero)..":"..tostring(zone and zone.class)
	if hasMeter then A.Observe(seconds, meter, id) end
	scanBudget, scanPending = SCANS_PER_EVALUATION, false
	local models = {}
	for index = 1, table.getn(spells) do
		local row = Copy(spells[index])
		row.damageBonus = NativeBonus(row)
		table.insert(models, row)
	end
	local result = A.Evaluate(models, run, stats, focus, hasMeter and A.Window() or nil)
	if not hasMeter and not result.safety then
		result.title, result.confidence = T("Keine Schadensdaten"), T("Daten fehlen")
		result.reasons = {T("Der Client liefert noch keine Schadensliste.")}
	end
	cache.at, cache.result, cache.spells, cache.focus, cache.stats, cache.zone = now, result, spells, focus, stats, zone
	cache.zoneName, cache.hero, cache.class = ZoneField(zone, "zone"), ZoneField(zone, "hero"), ZoneField(zone, "class")
	cache.hasMeter = hasMeter
	return result
end

local events = CreateFrame("Frame")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("LEARNED_SPELL_IN_TAB")
events:RegisterEvent("CHARACTER_POINTS_CHANGED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function() A.Invalidate() end)
