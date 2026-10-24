-- WoW 1.12 API. Only AZS_SPELLS decides which spells belong to this run.
local function SetFont(fs,size)
    fs:SetFont(KeijinUI.font,size,"OUTLINE")
    KeijinUI.fontStrings=KeijinUI.fontStrings or {}; table.insert(KeijinUI.fontStrings,{fs,size})
end
local FLAT = "Interface\\ChatFrame\\ChatFrameBackground"
local ICON, PITCH, COLUMNS, WIDTH, ROWSTART = 28, 30, 11, 400, 58
-- Action bar (cooldown display only), one row: normal skills, then the racial ability at the far right.
-- Source: AZS_SPELLS is "your spells, your racial last" (addon_docs.md:240), so the last list entry is the
-- racial and all entries before it are normal skills. The game exposes no maximum for normal skills; the
-- stock interface fills native slots 1-6 plus the permanent slot 12. NORMAL_SLOTS
-- is that assumption: a longer list makes the bar grow, no spell is ever hidden.
local NORMAL_SLOTS, ACTION_ICON, ACTION_PITCH = 6, 38, 42
local JEWELRY = { 2, 11, 12, 13, 14 }
-- Client assets: analysis/patch_list.txt, Interface\PaperDoll\UI-PaperDoll-Slot-*.blp.
local EMPTY_JEWELRY = {
	[2] = {"Neck", "Freier Halsplatz"},
	[11] = {"Finger", "Freier Ringplatz"}, [12] = {"Finger", "Freier Ringplatz"},
	[13] = {"Trinket", "Freier Schmuckplatz"}, [14] = {"Trinket", "Freier Schmuckplatz"}
}
local function EmptyItem(slot)
	local info = EMPTY_JEWELRY[slot]
	return {kind="emptyItem", identity="emptyItem:"..slot, slot=slot, name=info[2],
		icon="Interface\\PaperDoll\\UI-PaperDoll-Slot-"..info[1]}
end
-- Keep placeholders out of the advisor and the action bar's native spell list.
local function SpellSlots(spells)
	local rows, total = {}, table.getn(spells)
	local normal = math.max(0, total - 1)
	local count = math.max(NORMAL_SLOTS, normal) + 1
	for index = 1, count do
		local row
		if index == count then row = spells[total] elseif index <= normal then row = spells[index] end
		rows[index] = row or {kind="emptySpell", identity="emptySpell:"..index}
	end
	return rows
end
local PHASES = { ready = true, playing = true, choosing = true, paused = true }
local QUALITY = { [0] = {0.62,0.62,0.62}, [1] = {0.85,0.85,0.85},
	[2] = {0.12,1,0}, [3] = {0,0.44,0.87}, [4] = {0.64,0.21,0.93},
	[5] = {1,0.5,0} }
local owned, previousShown = false, nil
local function T(text, a1, a2) return KeijinUI.T(text, a1, a2) end
-- Ability name in the interface language (German or English), falling back to the spell book name.
local function Display(row)
	if KeijinBuildAdvisor and KeijinBuildAdvisor.Label then return KeijinBuildAdvisor.Label(row) or row.name end
	return row.name
end
local elapsed, hovered = 0, nil
local panel = CreateFrame("Frame", "KeijinBuildBarFrame", UIParent)
panel:SetWidth(WIDTH)
panel:SetHeight(82)
panel:SetMovable(true)
panel:SetClampedToScreen(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:Hide()
local skills=CreateFrame("Frame","KeijinUISkills",UIParent)
skills:SetWidth(306); skills:SetHeight(54); skills:SetFrameStrata("LOW")
skills:SetScale(KeijinUI.CombatScale()); KeijinUI.Skin(skills)
KeijinUI.layout.Register("skills",skills,"Aktionsleiste",function(f)
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"BOTTOM",0,KeijinUI.UIHeight()*0.4*UIParent:GetEffectiveScale()/f:GetEffectiveScale())
end,{scale=KeijinUI.CombatScale})

local function Fill(parent, layer, r, g, b, a)
	local texture = parent:CreateTexture(nil, layer)
	texture:SetTexture(FLAT)
	texture:SetVertexColor(r, g, b, a or 1)
	return texture
end
KeijinUI.Skin(panel)
local divider = Fill(panel, "ARTWORK", 0.4, 0.4, 0.42, 0.5)
divider:SetHeight(1)
divider:SetWidth(WIDTH - 12)

local function Label(text, r, g, b)
	local label = panel:CreateFontString(nil, "OVERLAY")
	SetFont(label,9)
	label:SetText(text)
	label:SetTextColor(r, g, b)
	return label
end
local spellsLabel = Label("", 0.8, 0.8, 0.82)
local itemsLabel = Label("", 0.8, 0.8, 0.82)
KeijinUI.Live(spellsLabel, function() return T("Spells") end)
KeijinUI.Live(itemsLabel, function() return T("Items") end)

local function Settings()
	KeijinUIBuildDB = KeijinUIBuildDB or {}
	if KeijinUIBuildDB.enabled == nil then KeijinUIBuildDB.enabled = true end
	if KeijinUIBuildDB.advisor == nil then KeijinUIBuildDB.advisor = true end
	-- 3.4.0: the action bar has its own switch. Until it is set it follows the old shared one.
	if KeijinUIBuildDB.actionBar == nil then KeijinUIBuildDB.actionBar = KeijinUIBuildDB.enabled and true or false end
	local focus = KeijinUIBuildDB.focus
	if focus ~= "balanced" and focus ~= "damage" and focus ~= "boss" and focus ~= "survival" then KeijinUIBuildDB.focus = "balanced" end
	return KeijinUIBuildDB
end
local function ApplyPosition()
    if KeijinUI.layout.entries.build then KeijinUI.layout.Place("build")
    else panel:ClearAllPoints(); panel:SetPoint("BOTTOM",UIParent,"BOTTOM",0,42) end
end
local function DragStart()
	if IsAltKeyDown() then
		if hovered then GameTooltip:Hide(); hovered = nil end
		KeijinUI.layout.BeginMove("build")
	end
end
local function DragStop()
	KeijinUI.layout.EndMove("build")
end
panel:SetScript("OnDragStart", DragStart)
panel:SetScript("OnDragStop", DragStop)

local function Supported()
	return type(AZS_SetHudShown) == "function" and type(AZS_IsHudShown) == "function"
		and type(AZS_HUD_CVARS) == "table" and AZS_HUD_CVARS.build
end
local function Release()
	panel:Hide()
	skills:Hide()
	if KeijinBuildAdvisor then KeijinBuildAdvisor.Reset() end
	if hovered then GameTooltip:Hide(); hovered = nil end
	-- Ours off, the game's on: the game's spell and jewelry rows come back.
	if Supported() and not AZS_IsHudShown("build") then AZS_SetHudShown("build", true) end
	owned, previousShown = false, nil
	Settings().originalShown = nil
end
local function ShowNative()
	owned, previousShown = false, nil
	Settings().originalShown = nil
	if Supported() and not AZS_IsHudShown("build") then AZS_SetHudShown("build", true) end
end
-- The game's action bar follows our action bar the same way: ours on, the game's hidden; ours off, the game's back.
local function StockBar(show)
	local bar = MainMenuBar
	if not bar then return end
	if show then
		if not bar:IsShown() then bar:SetAlpha(1); bar:EnableMouse(true); bar:Show() end
	elseif bar:IsShown() then bar:SetAlpha(0); bar:EnableMouse(false); bar:Hide() end
end
-- During an active run, the native spell bar stays hidden while "Spells & jewelry" is switched on. The game may
-- switch it back on by itself, so every update checks it again.
local function HideNative()
	if not Supported() then return end
	if not owned then
		previousShown = Settings().originalShown
		if previousShown == nil then previousShown = AZS_IsHudShown("build") and true or false end
		Settings().originalShown = previousShown
		owned = true
	end
	if AZS_IsHudShown("build") then AZS_SetHudShown("build", false) end
end
local function Number(value)
	return type(value) == "number" and value == value and value >= 0 and value < 1e15
end
-- Height of the cooldown number strip above each spell row; 0 when the option is off.
local function CooldownStrip()
	return KeijinUI.DB().buildCooldownText ~= false and 14 or 0
end
-- Cooldown of the ability in this run, docked above the spell icon: two decimals below 1 s, one below 10 s, then whole seconds.
local function CooldownText(value)
	if not Number(value) or value <= 0 then return "" end
	local text
	if value < 1 then
		text = string.format("%.2f", value)
		if text == "1.00" then text = "1.0" end
	elseif value < 10 then
		text = string.format("%.1f", value)
		if text == "10.0" then text = "10" end
	else text = string.format("%.0f", value) end
	return text
end
local function Normalize(name)
	name = string.gsub(name or "", "|c%x%x%x%x%x%x%x%x", "")
	name = string.gsub(name, "|r", "")
	return string.gsub(string.lower(name), "[%s%p]", "")
end
local function NameFromLink(link)
	local _, _, name = string.find(link or "", "|h%[(.-)%]|h")
	return name
end
local function Items()
	local items = {}
	local available = type(GetInventoryItemLink) == "function" and type(GetInventoryItemTexture) == "function"
	for index = 1, table.getn(JEWELRY) do
		local slot = JEWELRY[index]
		local link = available and GetInventoryItemLink("player", slot)
		if link then
			local icon = GetInventoryItemTexture("player", slot)
			-- Do not conceal a real item whose visual data has not arrived yet.
			if not icon then return nil end
			local quality = type(GetInventoryItemQuality) == "function" and GetInventoryItemQuality("player", slot) or 1
			table.insert(items, {kind="item", identity=link, name=NameFromLink(link) or T("Item"),
				link=link, slot=slot, icon=icon, quality=quality})
		else
			table.insert(items, EmptyItem(slot))
		end
	end
	return items
end
local function Book()
	local out = {}
	if type(GetNumSpellTabs) ~= "function" or type(GetSpellTabInfo) ~= "function"
		or type(GetSpellName) ~= "function" or type(GetSpellTexture) ~= "function" then return out end
	for tab = 1, math.min(16, GetNumSpellTabs()) do
		local _, _, offset, count = GetSpellTabInfo(tab)
		if type(offset) == "number" and type(count) == "number" then
			for index = math.max(1, offset + 1), math.min(1023, offset + count) do
				local name = GetSpellName(index, "spell")
				if name then
					out[Normalize(name)] = {slot=index, name=name, icon=GetSpellTexture(index, "spell")}
				end
			end
		end
	end
	return out
end

local advice = CreateFrame("Frame", "KeijinBuildAdviceFrame", panel)
advice:SetWidth(116)
advice:SetHeight(32)
advice:EnableMouse(true)
advice:RegisterForDrag("LeftButton")
advice:SetScript("OnDragStart", DragStart)
advice:SetScript("OnDragStop", DragStop)
advice.heading = advice:CreateFontString(nil, "OVERLAY")
SetFont(advice.heading,9)
advice.heading:SetPoint("TOPLEFT", advice, "TOPLEFT", 0, -2)
advice.heading:SetWidth(116)
advice.heading:SetHeight(12)
advice.heading:SetJustifyH("LEFT")
advice.heading:SetTextColor(0.75, 0.75, 0.78)
advice.title = advice:CreateFontString(nil, "OVERLAY")
SetFont(advice.title,10)
advice.title:SetPoint("TOPLEFT", advice, "TOPLEFT", 0, -17)
advice.title:SetWidth(116)
advice.title:SetHeight(13)
advice.title:SetJustifyH("LEFT")
advice.title:SetTextColor(1, 0.82, 0)
advice:SetScript("OnEnter", function()
	local result = this.result
	if not result then return end
	hovered = this
	GameTooltip:SetOwner(this, "ANCHOR_TOP")
	GameTooltip:SetText(T("Buildempfehlung"), 1, 0.82, 0)
	GameTooltip:AddLine(result.heading..": "..result.title, 1, 1, 1, true)
	for index = 1, table.getn(result.reasons) do
		GameTooltip:AddLine(result.reasons[index], 0.83, 0.83, 0.86, true)
	end
	if result.seconds then GameTooltip:AddLine(T("Grundlage: jüngstes Kampffenster, nicht der gesamte Run."), 0.6, 0.6, 0.63, true) end
	GameTooltip:AddLine(T("Einordnung")..": "..result.confidence, 0.7, 0.7, 0.73, true)
	GameTooltip:AddLine(T("Angebotene Karten werden nicht ausgelesen."), 0.6, 0.6, 0.63, true)
	GameTooltip:AddLine(T("/kbb fokus schaden, boss, ueberleben oder ausgewogen"), 0.6, 0.6, 0.63, true)
	GameTooltip:Show()
end)
advice:SetScript("OnLeave", function() if hovered == this then hovered = nil; GameTooltip:Hide() end end)

local spellCells, itemCells, actionCells = {}, {}, {}
-- Abilities whose 1.12 spell is not in the spell book (Call of Flame): GameTooltip:SetAction builds
-- the tooltip from the action slot's spell id, where the game writes its own ability text. The slot
-- is found by the tooltip's first line and remembered per ability until it no longer matches.
local actionSlot = {}
local function TipTitle()
	local line = getglobal("GameTooltipTextLeft1")
	return line and line.GetText and Normalize(line:GetText()) or ""
end
-- Normalized name -> ability key, or false when one translation names two abilities
-- (Romanian and Ukrainian Blood Fury/Bloodrage, Portuguese Shred/Slice and Dice).
local owners
local function Owners()
	if owners then return owners end
	owners = {}
	local tables = {KeijinBuildBarAliases or {}, KeijinGameAbilityNames or {}}
	for list = 1, 2 do
		for key, names in pairs(tables[list]) do
			for index = 1, table.getn(names) do
				local name = Normalize(names[index])
				if owners[name] == nil or owners[name] == key then owners[name] = key else owners[name] = false end
			end
		end
	end
	return owners
end
local function Texture(path)
	return string.lower(string.gsub(path or "", "/", "\\"))
end
local function Matches(row, title, slot)
	if title == "" then return false end
	local hit = title == Normalize(row.name) or title == Normalize(row.key)
	-- Hand made aliases and the game's own names in all 14 languages (GameText.lua).
	local lists = {(KeijinBuildBarAliases or {})[row.key] or {}, (KeijinGameAbilityNames or {})[row.key] or {}}
	for list = 1, 2 do
		for index = 1, table.getn(lists[list]) do
			if not hit and title == Normalize(lists[list][index]) then hit = true end
		end
	end
	if not hit then return false end
	if Owners()[title] ~= false then return true end
	-- An ambiguous title only counts when the slot also shows this ability's icon.
	return row.icon ~= nil and type(GetActionTexture) == "function"
		and Texture(GetActionTexture(slot)) == Texture(row.icon)
end
-- Cleared first, so a slot that writes nothing cannot pass with the previous tooltip's title.
local function ShowAction(slot)
	GameTooltip:ClearLines()
	GameTooltip:SetAction(slot)
end
local function ActionTooltip(row)
	if type(GameTooltip.SetAction) ~= "function" or type(HasAction) ~= "function" then return false end
	local slot = actionSlot[row.key]
	if slot and HasAction(slot) then
		ShowAction(slot)
		if Matches(row, TipTitle(), slot) then return true end
	end
	actionSlot[row.key] = nil
	for index = 1, 120 do
		if HasAction(index) then
			ShowAction(index)
			if Matches(row, TipTitle(), index) then actionSlot[row.key] = index; return true end
		end
	end
	GameTooltip:ClearLines()
	return false
end
-- /kbb slots: every filled action slot with the first tooltip line the client writes for it.
local function SlotDebug()
	if type(HasAction) ~= "function" or type(GameTooltip.SetAction) ~= "function" then
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: HasAction/SetAction fehlen."); return
	end
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	local found = 0
	for index = 1, 120 do
		if HasAction(index) then
			ShowAction(index)
			local line = getglobal("GameTooltipTextLeft1")
			local second = getglobal("GameTooltipTextLeft2")
			DEFAULT_CHAT_FRAME:AddMessage(string.format("Slot %d: %s | %s | %s", index,
				tostring(line and line:GetText()), tostring(second and second:GetText()),
				tostring(GetActionTexture and GetActionTexture(index))))
			found = found + 1
		end
	end
	GameTooltip:Hide()
	DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..found.." belegte Aktionsplätze.")
end
local function Tooltip(cell)
	local row = cell.row
	if not row then return end
	if row.kind == "emptySpell" then return end
	GameTooltip:SetOwner(cell, "ANCHOR_TOP")
	if row.kind == "emptyItem" then
		GameTooltip:SetText(T(row.name), 0.65, 0.65, 0.68)
		GameTooltip:Show(); return
	end
	if row.kind=="slot" then GameTooltip:SetText(T("Zauber"),1,0.82,0); GameTooltip:AddLine(T("Warte auf die Zauberdaten des Spiels.")); GameTooltip:Show(); return end
	if row.kind == "item" then
		local link = GetInventoryItemLink("player", row.slot)
		if not link then GameTooltip:Hide(); return end
		local shown
		if type(GameTooltip.SetInventoryItem) == "function" then
			shown = GameTooltip:SetInventoryItem("player", row.slot)
		end
		if not shown then GameTooltip:SetText(NameFromLink(link) or row.name, 1, 0.82, 0) end
	else
		if row.book and type(GameTooltip.SetSpell) == "function" then
			GameTooltip:SetSpell(row.book, "spell")
		elseif row.key and ActionTooltip(row) then
			-- the game's own ability tooltip from its action slot
		else
			GameTooltip:SetText(Display(row), 1, 0.82, 0)
		end
		GameTooltip:AddLine(T("Rang im Run: %.0f", row.rank), 1, 0.82, 0)
		if Number(row.cdmax) and row.cdmax > 0 then
			GameTooltip:AddLine(T("Abklingzeit im Run: %.1fs", row.cdmax), 0.85, 0.85, 0.87)
		end
		if row.recommended then GameTooltip:AddLine(T("Buildtipp")..": "..row.adviceHeading, 1, 0.82, 0, true) end
	end
	GameTooltip:AddLine(T("Alt gedrückt halten und ziehen zum Verschieben."), 0.6, 0.6, 0.62)
	GameTooltip:Show()
end
local function Cell(pool, index)
	if pool[index] then return pool[index] end
	local cell = CreateFrame("Frame", nil, panel)
	cell:SetWidth(ICON)
	cell:SetHeight(ICON)
	cell:EnableMouse(true)
	cell:RegisterForDrag("LeftButton")
	cell:SetScript("OnDragStart", DragStart)
	cell:SetScript("OnDragStop", DragStop)
	KeijinUI.Chamfer(cell,2,{0.02,0.02,0.025,0.95})
	cell.border = cell
	cell.icon = cell:CreateTexture(nil, "ARTWORK")
	cell.icon:SetWidth(ICON - 4)
	cell.icon:SetHeight(ICON - 4)
	cell.icon:SetPoint("CENTER", cell, "CENTER", 0, 0)
	cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	cell.rankBackground = Fill(cell, "OVERLAY", 0, 0, 0, 0.9)
	cell.rankBackground:SetWidth(14)
	cell.rankBackground:SetHeight(13)
	cell.rankBackground:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
    cell.rank = cell:CreateFontString(nil, "OVERLAY")
	SetFont(cell.rank,10)
	cell.rank:SetTextColor(1, 0.82, 0)
	cell.rank:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -3, 2)
	-- A dark chamfered tab docks into the icon rim; the strip reserves its height.
	local cooltext = CreateFrame("Frame", nil, cell)
	cooltext:SetWidth(ICON); cooltext:SetHeight(14)
	cooltext:SetPoint("BOTTOM", cell, "TOP", 0, -1)
	cooltext:SetFrameLevel(cell:GetFrameLevel() + 2)
	cooltext:EnableMouse(false)
	KeijinUI.Chamfer(cooltext,2,{0.025,0.025,0.03,0.98},{0.48,0.44,0.34,1})
	cell.cooldownPlate = cooltext
	cell.runCooldown = cooltext:CreateFontString(nil, "OVERLAY")
	SetFont(cell.runCooldown,9)
	cell.runCooldown:SetPoint("CENTER", cooltext, "CENTER", 0, 0)
	cooltext:Hide()
	cell:SetScript("OnEnter", function()
		if not this.row or this.row.kind == "emptySpell" then return end
		hovered = this
		if this.row.kind ~= "emptyItem" then this.border:SetBackdropBorderColor(1, 0.82, 0, 1) end
		Tooltip(this)
	end)
	cell:SetScript("OnLeave", function()
		if hovered == this then hovered = nil; GameTooltip:Hide() end
		local color = this.color or QUALITY[1]
		this.border:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
	end)
	pool[index] = cell
	return cell
end
local function Paint(pool, rows, top, pitch)
	for index = 1, table.getn(rows) do
		local row = rows[index]
		local cell = Cell(pool, index)
		local changed = not cell.row or cell.row.identity ~= row.identity or cell.row.rank ~= row.rank
			or cell.row.recommended ~= row.recommended
		local empty = row.kind == "emptySpell" or row.kind == "emptyItem"
		if row.kind == "emptySpell" and hovered == cell then hovered = nil; GameTooltip:Hide() end
		cell.row = row
		cell.color = row.kind == "item" and (QUALITY[row.quality] or QUALITY[1]) or {0.4,0.4,0.43}
		if empty then cell.color = {0.2,0.2,0.23} end
		cell:EnableMouse(true)
		cell:SetScript("OnDragStart", DragStart)
		cell:SetScript("OnDragStop", DragStop)
		if row.recommended then cell.color = row.safety and {0.35,0.9,0.5} or {0.9,0.75,0.2} end
		cell:ClearAllPoints()
		local columns = pool == spellCells and COLUMNS or 5
		local start = ROWSTART
		cell:SetPoint("TOPLEFT",panel,"TOPLEFT",start+math.mod(index-1,columns)*PITCH,-top-math.floor((index-1)/columns)*(pitch or PITCH))
		if row.kind == "emptySpell" then
			cell.icon:SetTexture(nil); cell.icon:Hide()
		else
			cell.icon:SetTexture(row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			cell.icon:SetVertexColor(1, 1, 1, 1)
			cell.icon:SetWidth(ICON - 4); cell.icon:SetHeight(ICON - 4)
			cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			-- Empty jewelry slots: the full-size paperdoll silhouette, cropped like an item icon, slightly greyed.
			if row.kind == "emptyItem" then cell.icon:SetVertexColor(0.85, 0.85, 0.85, 1) end
			cell.icon:Show()
		end
        if row.kind=="item" and KeijinUI.collection and KeijinUI.collection.CooldownsOn() then
            if not cell.nativeCooldown then cell.nativeCooldown=KeijinUI.Text(cell,"",9,"BOTTOM",0,1) end
            local left=KeijinUI.collection.Cooldown(row.slot)
            cell.nativeCooldown:SetText(left and left>0 and KeijinUI.Clock(math.ceil(left)) or "")
            cell.nativeCooldown:Show()
        elseif cell.nativeCooldown then cell.nativeCooldown:Hide() end
		if row.kind == "spell" then
			cell.rank:SetText(string.format("%.0f", row.rank))
			cell.rank:Show(); cell.rankBackground:Show()
		else
			cell.rank:Hide(); cell.rankBackground:Hide()
		end
		local cooldown = row.kind == "spell" and CooldownStrip() > 0 and CooldownText(row.cdmax) or ""
		cell.runCooldown:SetText(cooldown)
		if cooldown ~= "" then cell.cooldownPlate:Show() else cell.cooldownPlate:Hide() end
		-- Gold below one second: about where more cooldown reduction stops paying off.
		if Number(row.cdmax) and row.cdmax < 1 then cell.runCooldown:SetTextColor(1, 0.82, 0)
		else cell.runCooldown:SetTextColor(0.86, 0.86, 0.88) end
		if hovered == cell and not empty then
			cell.border:SetBackdropBorderColor(1, 0.82, 0, 1)
		else
			cell.border:SetBackdropBorderColor(cell.color[1], cell.color[2], cell.color[3], 0.8)
		end
		if hovered == cell and changed then Tooltip(cell) end
		cell:Show()
	end
	for index = table.getn(rows) + 1, table.getn(pool) do
		local cell = pool[index]
		if hovered == cell then hovered = nil; GameTooltip:Hide() end
		cell.row = nil
		cell:Hide()
	end
end
local function BuildLayout(spells)
	local spellRows = math.max(1, math.ceil(table.getn(spells) / COLUMNS))
	-- Each spell row gets a strip above it for the cooldown numbers; without them the original size.
	local strip = CooldownStrip()
	local spellTop, itemTop = 8 + strip, 8 + spellRows * (PITCH + strip) + 6
	panel:SetHeight(itemTop + ICON + 10)
	spellsLabel:ClearAllPoints(); spellsLabel:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-(spellTop+10)); spellsLabel:Show()
	itemsLabel:ClearAllPoints(); itemsLabel:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-(itemTop+10)); itemsLabel:Show()
	divider:ClearAllPoints(); divider:SetPoint("TOPLEFT",panel,"TOPLEFT",6,-(itemTop-3)); divider:Show()
	return spellTop, itemTop, PITCH + strip
end
-- Cooldown style of the action bar: clockwise sweep (default, like stock action buttons) or the
-- older shade that shrinks from top to bottom.
function KeijinUI.CooldownClockwise() return KeijinUI.DB().cooldownStyle ~= "down" end
function KeijinUI.SetCooldownStyle(style) KeijinUI.DB().cooldownStyle = style == "down" and "down" or nil end
local function StopClock(cell)
	if cell.clockStart then CooldownFrame_SetTimer(cell.clock, 0, 0, 0) end
	cell.clock:Hide(); cell.clockStart, cell.clockFull = nil, nil
end
-- Game 0.115: use the run-clock based API directly, never estimate talent intervals.
local function TalentTimers()
	if type(AZS_GetTimers)~="function" or type(AZS_GetPhase)~="function" then return {} end
	local okPhase,phase=pcall(AZS_GetPhase)
	if not okPhase or (phase~="playing" and phase~="choosing" and phase~="paused") then return {} end
	local ok,values=pcall(AZS_GetTimers)
	if not ok or type(values)~="table" then return {} end
	local rows={}
	for _,v in ipairs(values) do
		if type(v)=="table" and type(v.name)=="string" and v.name~="" and Number(v.remaining)
			and (v.kind=="summon" or v.kind=="cooldown") then
			table.insert(rows,{kind="talentTimer",name=v.name,timerKind=v.kind,cd=v.remaining,
				cdmax=Number(v.duration) and v.duration or nil,frozen=phase~="playing",
				icon=type(v.icon)=="string" and v.icon~="" and v.icon or KeijinUI.SpellIcon(v.name)})
		end
	end
	return rows
end
local function TimerTip(cell)
	local row=cell.row
	if not row or row.kind~="talentTimer" then return end
	GameTooltip:SetOwner(cell,"ANCHOR_TOP")
	GameTooltip:SetText(KeijinUI.DisplayName(row.name),1,.82,.28)
	GameTooltip:AddLine(row.cd>0 and (T(row.timerKind=="summon" and "Beschwörungen" or "Abklingzeit")..": "..math.ceil(row.cd).." s") or T("Bereit"),1,1,1)
	GameTooltip:Show()
end
-- Action bar slot: classic quickslot look, not clickable, shows only icon and real cooldown data.
local function ActionCell(index)
	if actionCells[index] then return actionCells[index] end
	local cell = CreateFrame("Frame", nil, skills)
	cell:SetWidth(ACTION_ICON); cell:SetHeight(ACTION_ICON)
	cell:EnableMouse(false)
	cell:SetScript("OnEnter",function() this.timerHover=true; TimerTip(this) end)
	cell:SetScript("OnLeave",function() this.timerHover=nil; GameTooltip:Hide() end)
	cell:SetScript("OnHide",function() if this.timerHover then this.timerHover=nil; GameTooltip:Hide() end end)
	KeijinUI.Chamfer(cell,2,{0.02,0.02,0.025,0.85})
	cell.icon = cell:CreateTexture(nil, "ARTWORK")
	cell.icon:SetWidth(ACTION_ICON - 4); cell.icon:SetHeight(ACTION_ICON - 4)
	cell.icon:SetPoint("CENTER", cell, "CENTER", 0, 0)
	cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	cell.sweep = Fill(cell, "OVERLAY", 0, 0, 0, 0.6)
	cell.sweep:SetPoint("BOTTOMLEFT", cell.icon, "BOTTOMLEFT", 0, 0)
	cell.sweep:SetPoint("BOTTOMRIGHT", cell.icon, "BOTTOMRIGHT", 0, 0)
	cell.sweep:SetHeight(1); cell.sweep:Hide()
	cell.frame = cell
	-- Clockwise sweep: the game's own cooldown model (CooldownFrameTemplate, as on every stock action
	-- button). Template frames need a name in this client. The number sits on a layer above the model.
	if CooldownFrame_SetTimer then
		cell.clock = CreateFrame("Model", "KeijinUISkillsCooldown"..index, cell, "CooldownFrameTemplate")
		cell.clock:SetAllPoints(cell.icon)
		cell.clock:SetFrameLevel(cell:GetFrameLevel() + 1)
		cell.clock:Hide()
	end
	local text = CreateFrame("Frame", nil, cell)
	text:SetAllPoints(cell); text:SetFrameLevel(cell:GetFrameLevel() + 2)
	cell.cooldown = text:CreateFontString(nil, "OVERLAY")
	SetFont(cell.cooldown,14)
	cell.cooldown:SetPoint("CENTER", cell, "CENTER", 0, 0)
	actionCells[index] = cell
	return cell
end
local function PaintActions(rows)
	local total = table.getn(rows)
	local racial = total > 0 and rows[total] or nil
	local normal = total > 0 and total - 1 or 0
	local timers=TalentTimers()
	local count = math.max(NORMAL_SLOTS, normal+table.getn(timers)) + 1
	for index = 1, count do
		local row, cell = nil, ActionCell(index)
		if index == count then row = racial elseif index <= normal then row = rows[index] else row=timers[index-normal] end
		cell.racial = index == count
		cell:ClearAllPoints()
		cell:SetPoint("TOPLEFT", skills, "TOPLEFT", 8 + (index-1) * ACTION_PITCH, -8)
		cell.row = row
		cell:EnableMouse(row and row.kind=="talentTimer" and true or false)
		if cell.timerHover and (not row or row.kind~="talentTimer") then cell.timerHover=nil; GameTooltip:Hide() end
		if row then
			cell.icon:SetTexture(row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			cell.icon:Show()
			cell.frame:SetBackdropBorderColor(0.62,0.57,0.43,1)
			local left = Number(row.cd) and row.cd > 0 and row.cd or nil
			cell.cooldown:SetText(left and string.format("%.0f", math.ceil(left)) or "")
			local full = Number(row.cdmax) and row.cdmax > 0 and row.cdmax or nil
			if left and cell.clock and KeijinUI.CooldownClockwise() and full and not row.frozen then
				-- Only a new or shifted cooldown restarts the model; the game data counts down in steps.
				local start = GetTime() - (full - math.min(left, full))
				if not cell.clockStart or math.abs(start - cell.clockStart) > 0.5 or cell.clockFull ~= full then
					cell.clockStart, cell.clockFull = start, full
					CooldownFrame_SetTimer(cell.clock, start, full, 1)
				end
				cell.sweep:Hide()
			elseif left then
				if cell.clock then StopClock(cell) end
				local fraction = full and math.min(1, left / full) or 1
				cell.sweep:SetHeight(math.max(1, (ACTION_ICON - 4) * fraction)); cell.sweep:Show()
			else cell.sweep:Hide(); if cell.clock then StopClock(cell) end end
		else
			cell.icon:Hide(); cell.sweep:Hide(); cell.cooldown:SetText("")
			if cell.clock then StopClock(cell) end
			cell.frame:SetBackdropBorderColor(0.35,0.33,0.28,0.8)
		end
		cell:Show()
		if cell.timerHover then TimerTip(cell) end
	end
	for index = count + 1, table.getn(actionCells) do actionCells[index]:Hide() end
	skills:SetWidth(16 + math.max(0,count - 1) * ACTION_PITCH + ACTION_ICON)
	skills:SetHeight(16 + ACTION_ICON)
end
local function Update()
	local settings, run = Settings(), AZS_RUN
	local panelOn, actionOn = settings.enabled and true or false, settings.actionBar and true or false
	StockBar(not actionOn)
	if not panelOn and not actionOn then Release(); return end
	if not Supported() or type(run) ~= "table" or (run.ph and not PHASES[run.ph])
		or type(GetInventoryItemLink) ~= "function" or type(GetInventoryItemTexture) ~= "function" then
		panel:Hide(); skills:Hide()
		if KeijinBuildAdvisor then KeijinBuildAdvisor.Reset() end
		if hovered then GameTooltip:Hide(); hovered = nil end
		if panelOn then HideNative() else ShowNative() end
		PaintActions({}); if actionOn then skills:Show() end
		local spells, items = SpellSlots({}), Items()
		if not items then Release(); return end
		local spellTop, itemTop, spellPitch = BuildLayout(spells)
		Paint(spellCells,spells,spellTop,spellPitch); Paint(itemCells,items,itemTop)
		advice:Hide(); if panelOn then panel:Show() end; return
	end
	local book, spells, items = Book(), {}, {}
	local nativeSpells = type(AZS_SPELLS) == "table" and AZS_SPELLS or {}
	for index = 1, table.getn(nativeSpells) do
		local value = nativeSpells[index]
		if type(value) ~= "table" or type(value.key) ~= "string" or not Number(value.rank)
			or not Number(value.spell) then Release(); return end
		local name = (KeijinBuildBarNames or {})[value.key] or string.gsub(value.key, "_", " ")
		local entry = book[Normalize(name)] or book[Normalize(value.key)]
		local aliases = (KeijinBuildBarAliases or {})[value.key]
		if not entry and aliases then
			for alias = 1, table.getn(aliases) do
				if book[Normalize(aliases[alias])] then entry = book[Normalize(aliases[alias])]; break end
			end
		end
		-- The game casts another 1.12 spell for some abilities (Demonic Empowerment is Fel Domination):
		-- its book entry gives the tooltip, the name and the icon stay the ability's.
		local other = (KeijinBuildBarBook or {})[value.key]
		local display, icon = entry and entry.name or name, entry and entry.icon
		if not entry and other and book[Normalize(other)] then
			entry = book[Normalize(other)]
			icon = (KeijinBuildBarIcons or {})[value.key] or entry.icon
		end
		table.insert(spells, {kind="spell", key=value.key, identity=value.key..":"..value.spell,
			name=display, rank=value.rank, cd=value.cd, cdmax=value.cdmax,
			book=entry and entry.slot,
			icon=icon or (KeijinBuildBarIcons or {})[value.key]})
	end
	items = Items()
	if not items then Release(); return end
	local displaySpells = SpellSlots(spells)
	local spellTop, itemTop, spellPitch = BuildLayout(displaySpells)
	advice:ClearAllPoints()
	advice:SetPoint("TOPLEFT", panel, "TOPLEFT", 248, -itemTop)
	if KeijinUI.ModuleOn("advisor") and KeijinBuildAdvisor then
		local result = KeijinBuildAdvisor.Get(spells, run, AZS_STATS, AZS_ZONE, settings.focus)
		advice.result = result
		advice.heading:SetText(result.heading)
		advice.title:SetText(result.title)
		if result.safety then advice.title:SetTextColor(0.4,1,0.6)
		else advice.title:SetTextColor(1,0.82,0) end
		advice:Show()
		for index = 1, table.getn(spells) do
			local row = spells[index]
			row.recommended = row.key == result.key
			row.adviceHeading, row.safety = result.heading, result.safety
		end
	else
		advice.result = nil
		if hovered == advice then hovered = nil; GameTooltip:Hide() end
		advice:Hide()
	end
	Paint(spellCells, displaySpells, spellTop, spellPitch)
	Paint(itemCells, items, itemTop)
	PaintActions(spells)
	if panelOn then HideNative() else ShowNative() end
	-- Both parts stay built when hidden, so frames anchored to the action bar keep their place.
	if panelOn then panel:Show() else panel:Hide(); if hovered then GameTooltip:Hide(); hovered = nil end end
	if actionOn then skills:Show() else skills:Hide() end
end

-- One setting shared by the menu and /kbb; restore the native HUD on disable.
KeijinUI.buildBar={}
KeijinUI.buildBar.CooldownText=CooldownText
-- "Zauber & Schmuck" (panel) and "Aktionsleiste" (skills) are independent since 3.4.0. The native build bar returns
-- only when both are off.
function KeijinUI.buildBar.On() return Settings().enabled and true or false end
function KeijinUI.buildBar.Set(on) Settings().enabled=on and true or false; Update() end
function KeijinUI.buildBar.ActionOn() return Settings().actionBar and true or false end
function KeijinUI.buildBar.SetAction(on) Settings().actionBar=on and true or false; Update() end
function KeijinUI.buildBar.Refresh() if KeijinBuildAdvisor then KeijinBuildAdvisor.Reset() end; Update() end

SLASH_KEIJINBUILDBAR1 = "/kbb"
SlashCmdList["KEIJINBUILDBAR"] = function(msg)
	local command = string.gsub(string.lower(msg or ""), "^%s*(.-)%s*$", "%1")
	local _, _, focus = string.find(command, "^fokus%s+(%S+)$")
	if not focus then _, _, focus = string.find(command, "^focus%s+(%S+)$") end
	local modes = {schaden="damage", damage="damage", boss="boss", ueberleben="survival", survival="survival", ausgewogen="balanced", balanced="balanced"}
	local modeNames = {damage="Schaden", boss="Boss", survival="Überleben", balanced="Ausgewogen"}
	if focus and modes[focus] then
		Settings().focus = modes[focus]
		Update()
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..T("Fokus").." "..T(modeNames[modes[focus]])..".")
	elseif command == "tipps" or command == "tips" or command == "advisor" then
		KeijinUI.modules.Set("advisor", not KeijinUI.ModuleOn("advisor"))
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..T("Buildtipps").." "..(KeijinUI.ModuleOn("advisor") and T("an.") or T("aus.")))
	elseif command == "" or command == "toggle" then
		-- Both parts together: any shown part goes off, otherwise both come on.
		local on = not (Settings().enabled or Settings().actionBar)
		Settings().enabled, Settings().actionBar = on, on
		Update()
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..(on and T("Leiste eingeschaltet.") or T("Leiste ausgeschaltet.")))
	elseif command == "slots" then
		SlotDebug()
	elseif command == "reset" then
		Settings().position = nil; KeijinUI.DB().layout.build=nil; KeijinUI.layout.ResetKey("skills")
		ApplyPosition()
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..T("Position zurückgesetzt. Alt halten und ziehen zum Verschieben."))
	else
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..T("/kbb, /kbb reset, /kbb tipps; /kbb fokus schaden|boss|ueberleben|ausgewogen (englisch: tips, focus damage|boss|survival|balanced). Alt halten und ziehen zum Verschieben."))
	end
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_LOGOUT")
watcher:RegisterEvent("CHAT_MSG_ADDON")
watcher:SetScript("OnEvent", function()
	if event == "PLAYER_LOGOUT" then Release()
	elseif event == "PLAYER_ENTERING_WORLD" then
		ApplyPosition()
		Update()
	elseif arg1 == "AZSSPELLS" or arg1 == "AZSRUN" or arg1 == "AZSTIMERS" then elapsed = 0.2 end
end)
watcher:SetScript("OnUpdate", function()
	elapsed = elapsed + arg1
	if elapsed < 0.2 then return end
	elapsed = 0
	Update()
end)
ApplyPosition()
Update()
