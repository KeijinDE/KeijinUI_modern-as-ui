-- WoW 1.12 API. Only AZS_SPELLS decides which spells belong to this run.
local FONT = "Fonts\\FRIZQT__.TTF"
local FLAT = "Interface\\ChatFrame\\ChatFrameBackground"
local ICON, PITCH, COLUMNS, WIDTH, ROWSTART = 28, 30, 11, 400, 58
-- Action bar (cooldown display only), one row: normal skills, then the racial ability at the far right.
-- Source: AZS_SPELLS is "your spells, your racial last" (addon_docs.md:240), so the last list entry is the
-- racial and all entries before it are normal skills. The game exposes no maximum for normal skills; the
-- stock interface fills native slots 1-6 plus the permanent slot 12. NORMAL_SLOTS
-- is that assumption: a longer list makes the bar grow, no spell is ever hidden.
local NORMAL_SLOTS, ACTION_ICON, ACTION_PITCH = 6, 38, 42
local JEWELRY = { 2, 11, 12, 13, 14 }
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
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"BOTTOM",0,UIParent:GetHeight()*0.4*UIParent:GetEffectiveScale()/f:GetEffectiveScale())
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
	label:SetFont(FONT, 9, "OUTLINE")
	label:SetText(text)
	label:SetTextColor(r, g, b)
	return label
end
local spellsLabel = Label("", 0.8, 0.8, 0.82)
local itemsLabel = Label("", 0.8, 0.8, 0.82)
local emptyItems = Label("", 0.5, 0.5, 0.52)
KeijinUI.Live(spellsLabel, function() return T("Spells") end)
KeijinUI.Live(itemsLabel, function() return T("Items") end)
KeijinUI.Live(emptyItems, function() return T("Keine Items") end)

local function Settings()
	KeijinUIBuildDB = KeijinUIBuildDB or {}
	if KeijinUIBuildDB.enabled == nil then KeijinUIBuildDB.enabled = true end
	if KeijinUIBuildDB.advisor == nil then KeijinUIBuildDB.advisor = true end
	local focus = KeijinUIBuildDB.focus
	if focus ~= "balanced" and focus ~= "damage" and focus ~= "boss" and focus ~= "survival" then KeijinUIBuildDB.focus = "balanced" end
	return KeijinUIBuildDB
end
local POINTS = { TOP=true, TOPLEFT=true, TOPRIGHT=true, CENTER=true,
	LEFT=true, RIGHT=true, BOTTOM=true, BOTTOMLEFT=true, BOTTOMRIGHT=true }
local function Coordinate(value)
	return type(value) == "number" and value == value and math.abs(value) <= 100000
end
local function ApplyPosition()
    if KeijinUI.layout.entries.build then KeijinUI.layout.Place("build")
    else panel:ClearAllPoints(); panel:SetPoint("BOTTOM",UIParent,"BOTTOM",0,42) end
end
local function SavePosition()
	local point, relative, relativePoint, x, y = panel:GetPoint()
	if (not relative or relative == UIParent) and POINTS[point] and POINTS[relativePoint]
		and Coordinate(x) and Coordinate(y) then
		Settings().position = {point=point, relativePoint=relativePoint, x=x, y=y}
	end
end
local function DragStart()
	if IsAltKeyDown() then
		if hovered then GameTooltip:Hide(); hovered = nil end
		panel:StartMoving()
	end
end
local function DragStop()
	panel:StopMovingOrSizing()
	SavePosition()
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
	local settings = Settings()
	local restore = previousShown
	if restore == nil then restore = settings.originalShown end
	if restore ~= nil and Supported() then AZS_SetHudShown("build", restore) end
	owned, previousShown = false, nil
	settings.originalShown = nil
end
-- The native spell bar stays hidden while this bar is switched on, data or not. The game may switch it
-- back on by itself, so every update checks it again. The original state is saved only once.
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
local function Normalize(name)
	return string.gsub(string.lower(name or ""), "[%s%p]", "")
end
local function NameFromLink(link)
	local _, _, name = string.find(link or "", "|h%[(.-)%]|h")
	return name
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
advice.heading:SetFont(FONT, 9, "OUTLINE")
advice.heading:SetPoint("TOPLEFT", advice, "TOPLEFT", 0, -2)
advice.heading:SetWidth(116)
advice.heading:SetHeight(12)
advice.heading:SetJustifyH("LEFT")
advice.heading:SetTextColor(0.75, 0.75, 0.78)
advice.title = advice:CreateFontString(nil, "OVERLAY")
advice.title:SetFont(FONT, 10, "OUTLINE")
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
local function Tooltip(cell)
	local row = cell.row
	if not row then return end
	GameTooltip:SetOwner(cell, "ANCHOR_TOP")
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
	cell.rank:SetFont(FONT, 10, "OUTLINE")
	cell.rank:SetTextColor(1, 0.82, 0)
	cell.rank:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -3, 2)
	cell:SetScript("OnEnter", function()
		hovered = this
		this.border:SetBackdropBorderColor(1, 0.82, 0, 1)
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
local function Paint(pool, rows, top)
	for index = 1, table.getn(rows) do
		local row = rows[index]
		local cell = Cell(pool, index)
		local changed = not cell.row or cell.row.identity ~= row.identity or cell.row.rank ~= row.rank
			or cell.row.recommended ~= row.recommended
		cell.row = row
		cell.color = row.kind == "item" and (QUALITY[row.quality] or QUALITY[1]) or {0.4,0.4,0.43}
		if row.recommended then cell.color = row.safety and {0.35,0.9,0.5} or {0.9,0.75,0.2} end
		cell:ClearAllPoints()
		local columns = pool == spellCells and COLUMNS or 5
		local start = ROWSTART
		cell:SetPoint("TOPLEFT",panel,"TOPLEFT",start+math.mod(index-1,columns)*PITCH,-top-math.floor((index-1)/columns)*PITCH)
		cell.icon:SetTexture(row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        if row.kind=="item" and KeijinUI.collection and KeijinUI.ModuleOn("jewelry") then
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
		if hovered ~= cell then
			cell.border:SetBackdropBorderColor(cell.color[1], cell.color[2], cell.color[3], 0.8)
		elseif changed then Tooltip(cell) end
		cell:Show()
	end
	for index = table.getn(rows) + 1, table.getn(pool) do
		local cell = pool[index]
		if hovered == cell then hovered = nil; GameTooltip:Hide() end
		cell.row = nil
		cell:Hide()
	end
end
-- Action bar slot: classic quickslot look, not clickable, shows only icon and real cooldown data.
local function ActionCell(index)
	if actionCells[index] then return actionCells[index] end
	local cell = CreateFrame("Frame", nil, skills)
	cell:SetWidth(ACTION_ICON); cell:SetHeight(ACTION_ICON)
	cell:EnableMouse(false)
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
	cell.cooldown = cell:CreateFontString(nil, "OVERLAY")
	cell.cooldown:SetFont(FONT, 14, "OUTLINE")
	cell.cooldown:SetPoint("CENTER", cell, "CENTER", 0, 0)
	actionCells[index] = cell
	return cell
end
local function PaintActions(rows)
	local total = table.getn(rows)
	local racial = total > 0 and rows[total] or nil
	local normal = total > 0 and total - 1 or 0
	local count = math.max(NORMAL_SLOTS, normal) + 1
	for index = 1, count do
		local row, cell = nil, ActionCell(index)
		if index == count then row = racial elseif index <= normal then row = rows[index] end
		cell.racial = index == count
		cell:ClearAllPoints()
		cell:SetPoint("TOPLEFT", skills, "TOPLEFT", 8 + (index-1) * ACTION_PITCH, -8)
		cell.row = row
		if row then
			cell.icon:SetTexture(row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			cell.icon:Show()
			cell.frame:SetBackdropBorderColor(0.62,0.57,0.43,1)
			local left = Number(row.cd) and row.cd > 0 and row.cd or nil
			cell.cooldown:SetText(left and string.format("%.0f", math.ceil(left)) or "")
			if left then
				local fraction = Number(row.cdmax) and row.cdmax > 0 and math.min(1, left / row.cdmax) or 1
				cell.sweep:SetHeight(math.max(1, (ACTION_ICON - 4) * fraction)); cell.sweep:Show()
			else cell.sweep:Hide() end
		else
			cell.icon:Hide(); cell.sweep:Hide(); cell.cooldown:SetText("")
			cell.frame:SetBackdropBorderColor(0.35,0.33,0.28,0.8)
		end
		cell:Show()
	end
	for index = count + 1, table.getn(actionCells) do actionCells[index]:Hide() end
	skills:SetWidth(16 + (count - 1) * ACTION_PITCH + ACTION_ICON)
	skills:SetHeight(16 + ACTION_ICON)
end
local function Update()
	local settings, run = Settings(), AZS_RUN
	if not settings.enabled then Release(); return end
	if not Supported() or type(run) ~= "table" or (run.ph and not PHASES[run.ph])
		or type(AZS_SPELLS) ~= "table" or table.getn(AZS_SPELLS) == 0
		or type(GetInventoryItemLink) ~= "function" or type(GetInventoryItemTexture) ~= "function" then
		panel:Hide(); skills:Hide()
		if KeijinBuildAdvisor then KeijinBuildAdvisor.Reset() end
		if hovered then GameTooltip:Hide(); hovered = nil end
		HideNative()
		PaintActions({}); skills:Show()
		Paint(spellCells,{},8); spellsLabel:Hide()
		Paint(itemCells,{},8); emptyItems:ClearAllPoints(); emptyItems:SetPoint("LEFT",panel,"LEFT",ROWSTART,0); emptyItems:Show()
		itemsLabel:ClearAllPoints(); itemsLabel:SetPoint("LEFT",panel,"LEFT",10,0)
		advice:Hide(); divider:Hide(); panel:SetHeight(48); panel:Show(); return
	end
	if not run.ph then Release() end
	local book, spells, items = Book(), {}, {}
	for index = 1, table.getn(AZS_SPELLS) do
		local value = AZS_SPELLS[index]
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
		table.insert(spells, {kind="spell", key=value.key, identity=value.key..":"..value.spell,
			name=entry and entry.name or name, rank=value.rank, cd=value.cd, cdmax=value.cdmax,
			book=entry and entry.slot,
			icon=(entry and entry.icon) or (KeijinBuildBarIcons or {})[value.key]})
	end
	for index = 1, table.getn(JEWELRY) do
		local slot = JEWELRY[index]
		local link = GetInventoryItemLink("player", slot)
		if link then
			local icon = GetInventoryItemTexture("player", slot)
			-- Do not conceal a real item whose visual data has not arrived yet.
			if not icon then Release(); return end
			local quality = type(GetInventoryItemQuality) == "function" and GetInventoryItemQuality("player", slot) or 1
			table.insert(items, {kind="item", identity=link, name=NameFromLink(link) or T("Item"),
				link=link, slot=slot, icon=icon, quality=quality})
		end
	end
	local spellRows = math.max(1, math.ceil(table.getn(spells) / COLUMNS))
	local spellTop = 8
	local itemTop = spellTop + spellRows * PITCH + 6
	panel:SetHeight(itemTop + ICON + 10)
	advice:ClearAllPoints()
	advice:SetPoint("TOPLEFT", panel, "TOPLEFT", 248, -itemTop)
	if settings.advisor and KeijinBuildAdvisor then
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
	spellsLabel:ClearAllPoints(); spellsLabel:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-(spellTop+10)); spellsLabel:Show()
	itemsLabel:ClearAllPoints(); itemsLabel:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-(itemTop+10))
	divider:ClearAllPoints(); divider:SetPoint("TOPLEFT",panel,"TOPLEFT",6,-(itemTop-3)); divider:Show()
	emptyItems:ClearAllPoints(); emptyItems:SetPoint("TOPLEFT",panel,"TOPLEFT",ROWSTART,-(itemTop+10))
	if table.getn(items) == 0 then emptyItems:Show() else emptyItems:Hide() end
	Paint(spellCells, spells, spellTop)
	Paint(itemCells, items, itemTop)
	PaintActions(spells)
	if PHASES[run.ph] then HideNative() end
	panel:Show()
	skills:Show()
end

-- One setting shared by the menu and /kbb; restore the native HUD on disable.
KeijinUI.buildBar={}
function KeijinUI.buildBar.On() return Settings().enabled end
function KeijinUI.buildBar.Set(on) Settings().enabled=on and true or false; Update() end

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
		Settings().advisor = not Settings().advisor
		if KeijinBuildAdvisor then KeijinBuildAdvisor.Reset() end
		Update()
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..T("Buildtipps").." "..(Settings().advisor and T("an.") or T("aus.")))
	elseif command == "" or command == "toggle" then
		KeijinUI.buildBar.Set(not Settings().enabled)
		DEFAULT_CHAT_FRAME:AddMessage("KeijinBuildBar: "..(Settings().enabled and T("Leiste eingeschaltet.") or T("Leiste ausgeschaltet.")))
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
	elseif arg1 == "AZSSPELLS" or arg1 == "AZSRUN" then elapsed = 0.2 end
end)
watcher:SetScript("OnUpdate", function()
	elapsed = elapsed + arg1
	if elapsed < 0.2 then return end
	elapsed = 0
	Update()
end)
ApplyPosition()
Update()
