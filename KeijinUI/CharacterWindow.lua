-- Restyle the native paper doll; do not replace equipment or model scripts.
-- Evidence: FrameXML CharacterFrame/PaperDollFrame; AZS_UpdateMore creates
-- AZSMoreStats lazily (analysis/exe_strings.txt). Other character tabs stay native.
local K=KeijinUI
local W=K.windowTools
local C={}
K.characterWindow=C
local frame,panel,morePanel,statsPanel,drag,nativeWindow,active=false
local changed={}
-- Label and value as last fitted per row; an unchanged row is not written again (no layout writes at idle).
local fitted={}
local LEFT={"Head","Neck","Shoulder","Back","Chest","Shirt","Tabard","Wrist"}
local RIGHT={"Hands","Waist","Legs","Feet","Finger0","Finger1","Trinket0","Trinket1"}
local function Point(name,parent,point,relative,x,y,width,height)
    W.Anchor(changed,getglobal(name),parent,point,relative,x,y,width,height)
end
local function Slot(name,x,y)
    local full="Character"..name.."Slot"
    local slot=getglobal(full)
    if not slot then return end
    Point(full,frame,"TOPLEFT","TOPLEFT",x,y,32,32)
    -- The stock normal texture is explicitly 64px (ItemButtonTemplate.xml),
    -- so changing only the button size would leave the old oversized rim.
    local rim=getglobal(full.."NormalTexture")
    if rim then
        W.Remember(changed,rim)
        local size=changed[slot].width
        if size and size>0 then
            rim:SetWidth(changed[rim].width*32/size)
            rim:SetHeight(changed[rim].height*32/size)
        end
    end
    W.Slot(changed,slot)
end
function C.On() return K.ModuleOn("characterWindow") and K.DB().characterWindowStyle~=false end
local function Restore()
    if not active then return end
    K.layout.EndMove("characterwindow")
    local s=AZSMoreStats and changed[AZSMoreStats]
    if s then
        -- Native bonuses can change the height immediately before closing.
        s.height=AZSMoreStats:GetHeight()
        AZSMoreStats:SetBackdrop(s.backdrop or {})
        if s.backdropColor then AZSMoreStats:SetBackdropColor(unpack(s.backdropColor)) end
        if s.borderColor then AZSMoreStats:SetBackdropBorderColor(unpack(s.borderColor)) end
    end
    W.Restore(changed); changed={}; fitted={}
    if panel then panel:Hide() end
    if morePanel then morePanel:Hide() end
    if statsPanel then statsPanel:Hide() end
    if drag then drag:Hide() end
    if nativeWindow and frame then
        frame:SetScale(nativeWindow.scale); W.Place(frame,nativeWindow.points)
    end
    active=false
end
local function FontTree(f)
    if not f or not f.GetRegions then return end
    for _,r in ipairs({f:GetRegions()}) do
        if r.GetObjectType and r:GetObjectType()=="FontString" and not r.keijinFitted then W.Font(changed,r) end
    end
    for _,child in ipairs({f:GetChildren()}) do if not child.keijinWindowArt then FontTree(child) end end
end
local STAT_ROWS={
    {"CharacterStatFrame1","CharacterStatFrame2","CharacterStatFrame3","CharacterStatFrame4","CharacterStatFrame5","CharacterArmorFrame"},
    {"CharacterAttackFrame","CharacterAttackPowerFrame","CharacterDamageFrame","CharacterRangedAttackFrame","CharacterRangedAttackPowerFrame","CharacterRangedDamageFrame"}
}
local CLASSES={WARRIOR="Krieger",PALADIN="Paladin",HUNTER="Jäger",ROGUE="Schurke",PRIEST="Priester",SHAMAN="Schamane",MAGE="Magier",WARLOCK="Hexenmeister",DRUID="Druide"}
local RACES={Human="Mensch",Dwarf="Zwerg",NightElf="Nachtelf",Gnome="Gnom",Orc="Orc",Scourge="Untoter",Tauren="Tauren",Troll="Troll"}
local STOCK_LABELS={{"Stärke","Beweglichkeit","Ausdauer","Intelligenz","Willenskraft","Rüstung"},{"Nahkampfangriff","Angriffskraft","Schaden","Fernkampfangriff","Angriffskraft","Schaden"}}
local RUN_LABELS={{"Leben","Schaden","Tempo","Kritchance","Krit-Schaden","Schadensreduktion"},{"Fläche","Ziele","Echochance","Bewegungstempo","Regeneration","Sammelreichweite"}}
-- Row geometry in the 232 wide panel: 8 padding at both sides, divider at 116, 4 clear of it on each side.
local ROW_X,ROW_WIDTH,ROW_GAP,ROW_STEP,VALUE_MIN=8,104,6,112,20
-- A label keeps at least this much; only an extreme value is bound in width to leave it.
local LABEL_MIN=24
-- Shorter wording, used only where the full label does not fit the row at the minimum font size 8.
local SHORT_LABELS={Schadensreduktion="Schadensred."}
local function Text(fs,text)
    if not fs then return end
    W.Remember(changed,fs)
    local state=changed[fs]
    if fs:GetText()~=state.appliedText then state.nativeText=fs:GetText() end
    state.appliedText=text; fs:SetText(text)
end
local function Identity()
    if not CharacterLevelText or not UnitLevel then return end
    local class,token
    if UnitClass then class,token=UnitClass("player") end
    class=CLASSES[token] and K.T(CLASSES[token]) or class
    local race,raceToken
    if UnitRace then race,raceToken=UnitRace("player") end
    local source=RACES[raceToken] or RACES[race]
    if not source and race=="Night Elf" then source="Nachtelf" end
    if not source and race=="Undead" then source="Untoter" end
    race=source and K.T(source) or race
    local parts={K.T("Stufe %d",UnitLevel("player") or 0)}
    if race then table.insert(parts,race) end
    if class then table.insert(parts,class) end
    Text(CharacterLevelText,table.concat(parts," · "))
end
-- Refit one row: anchor, translated label, value and label size; stores the size the label needs on its own.
local function FitRow(name,column,index,labels,want,valueText)
    local P=K.panelSizing
    local row=getglobal(name)
    local label,value=getglobal(name.."Label"),getglobal(name.."StatText")
    -- Layout goes through K.Anchor/K.SetW/K.SetH: written only when it differs from the last value set.
    W.Remember(changed,row); W.Remember(changed,label); W.Remember(changed,value)
    K.Anchor(row,"TOPLEFT",CharacterAttributesFrame,"TOPLEFT",ROW_X+(column-1)*ROW_STEP,-8-(index-1)*12)
    K.SetW(row,ROW_WIDTH); K.SetH(row,12)
    label.keijinFitted=true
    if value then value.keijinFitted=true end
    Text(label,want)
    W.Font(changed,label,10); W.Font(changed,value,10)
    -- The value is not bounded in width (0 = size of its text), so it cannot be cut whatever the font measures.
    -- Only a value wider than the row minus the minimum label is bound, so it never reaches the next column.
    -- The label gets what remains; one pixel is reserved for the outline.
    local valueWidth=VALUE_MIN
    if value then
        K.Anchor(value,"RIGHT",row,"RIGHT",0,0)
        K.SetW(value,0); K.SetH(value,12)
        valueWidth=math.max(VALUE_MIN,P.Measure(value,valueText),value:GetStringWidth() or 0)+1
        local cap=ROW_WIDTH-LABEL_MIN-ROW_GAP
        if valueWidth>cap then valueWidth=cap; K.SetW(value,cap) end
    end
    local available=math.max(LABEL_MIN,ROW_WIDTH-valueWidth-ROW_GAP)
    local path,base,flags=label:GetFont()
    local shown=want
    local measured=P.Measure(label,shown)
    local short=SHORT_LABELS[labels[column][index]]
    if short and base and measured*8/base>available then
        shown=K.T(short)..":"; Text(label,shown); measured=P.Measure(label,shown)
    end
    -- One pixel of reserve; the final width is measured again and corrected once.
    for _=1,2 do
        local _,current=label:GetFont()
        if not current or measured<=available-1 or current<=8 then break end
        label:SetFont(path,math.max(8,current*(available-1)/measured),flags)
        measured=P.Measure(label,shown)
    end
    K.Anchor(label,"LEFT",row,"LEFT",0,0)
    K.SetW(label,available); K.SetH(label,12)
    local _,final=label:GetFont()
    fitted[name]={text=shown,value=valueText,size=final,need=final,want=want,font=K.font,base=K.FontSize(10)}
end
-- Refits only rows whose label, value, size or language differ from the real FontString texts, so a rewrite by
-- the game script is noticed at once. All labels of a column share the smallest size any of them needs.
local function Stats()
    local labels=type(AZS_STATS)=="table" and RUN_LABELS or STOCK_LABELS
    for column,rows in ipairs(STAT_ROWS) do
        local target
        for index,name in ipairs(rows) do
            local row=getglobal(name)
            local label,value=getglobal(name.."Label"),getglobal(name.."StatText")
            if row and label then
                local want=K.T(labels[column][index])..":"
                local valueText=value and value:GetText() or ""
                local done=fitted[name]
                local _,size=label:GetFont()
                if not (done and valueText==done.value and size==done.size
                    and want==done.want and K.font==done.font and K.FontSize(10)==done.base) then
                    FitRow(name,column,index,labels,want,valueText)
                    done=fitted[name]
                elseif label:GetText()~=done.text then
                    -- Only the text was rewritten: put the translation back, no layout.
                    Text(label,done.text)
                end
                if not target or done.need<target then target=done.need end
            end
        end
        if target then
            for _,name in ipairs(rows) do
                local done=fitted[name]
                local label=getglobal(name.."Label")
                if done and label and done.size~=target then
                    local path,_,flags=label:GetFont()
                    label:SetFont(path,target,flags)
                    done.size=target
                end
            end
        end
    end
end
-- The game script rewrites labels and values (AZS_Row, stock setters) on every statistics message or event;
-- refit right behind it so no German text stays visible until the next tick.
local HOOKED={"AZS_Update","PaperDollFrame_SetStats","PaperDollFrame_SetArmor","PaperDollFrame_SetDamage",
    "PaperDollFrame_SetAttackPower","PaperDollFrame_SetAttackBothHands","PaperDollFrame_SetRangedAttack",
    "PaperDollFrame_SetRangedDamage","PaperDollFrame_SetRangedAttackPower"}
local wrapped={}
local function Wrap(name)
    local old=getglobal(name)
    if type(old)~="function" or wrapped[name]==old then return end
    local new=function(a,b)
        old(a,b)
        if active then Stats() end
    end
    wrapped[name]=new; setglobal(name,new)
end
local function Hooks()
    for _,name in ipairs(HOOKED) do Wrap(name) end
end
local function Apply()
    if not frame or not PaperDollFrame then return end
    if not C.On() or not frame:IsVisible() or not PaperDollFrame:IsVisible() then
        if active then Restore() end
        return
    end
    if not active then nativeWindow={points=W.Points(frame),scale=frame:GetScale()} end
    active=true
    K.layout.Place("characterwindow")
    W.Art(changed,PaperDollFrame,"interface\\paperdollinfoframe\\ui-character-charactertab-")
    W.Art(changed,CharacterAttributesFrame,"interface\\paperdollinfoframe\\ui-character-statbackground")
    if CharacterFramePortrait then W.Remember(changed,CharacterFramePortrait); CharacterFramePortrait:SetAlpha(0) end
    -- A smaller visible housing, while the manager keeps its original frame size.
    -- This avoids breaking the other native pages and the two-panel manager.
    panel:Show()
    drag:Show()
    Point("CharacterNameFrame",frame,"TOPLEFT","TOPLEFT",64,-18,224,16)
    Point("CharacterNameText",frame,"TOPLEFT","TOPLEFT",64,-18,224,16)
    Point("CharacterLevelText",frame,"TOPLEFT","TOPLEFT",64,-38,224,14)
    Point("CharacterModelFrame",frame,"TOPLEFT","TOPLEFT",60,-66,224,196)
    Point("CharacterAttributesFrame",frame,"TOPLEFT","TOPLEFT",64,-270,232,88)
    if CharacterAttributesFrame then
        if not statsPanel then
            statsPanel=K.Panel("KeijinUICharacterValues","",232,88)
            statsPanel.keijinWindowArt=true; statsPanel:SetParent(CharacterAttributesFrame)
            statsPanel:SetAllPoints(CharacterAttributesFrame)
            statsPanel:SetFrameLevel(math.max(0,CharacterAttributesFrame:GetFrameLevel()-1))
            statsPanel:SetFrameStrata(frame:GetFrameStrata()); statsPanel.title:Hide(); statsPanel.strip:Hide()
            local rule=statsPanel:CreateTexture(nil,"OVERLAY")
            rule:SetTexture(K.flat); rule:SetVertexColor(.62,.57,.43,.45)
            rule:SetWidth(1); rule:SetPoint("TOP",statsPanel,"TOP",0,-5); rule:SetPoint("BOTTOM",statsPanel,"BOTTOM",0,5)
        end
        statsPanel:Show()
    end
    Point("CharacterFrameCloseButton",frame,"TOPRIGHT","TOPLEFT",342,-13)
    for i,name in ipairs(LEFT) do Slot(name,18,-66-(i-1)*36) end
    for i,name in ipairs(RIGHT) do Slot(name,300,-66-(i-1)*36) end
    Slot("MainHand",112,-368); Slot("SecondaryHand",149,-368); Slot("Ranged",186,-368)
    Point("CharacterAmmoSlot",frame,"TOPLEFT","TOPLEFT",230,-370,27,27)
    -- These pages contain no run information; keep their original visibility
    -- for restoring the native window, including tabs already hidden by the game.
    for i=1,5 do
        local tab=getglobal("CharacterFrameTab"..i)
        if tab then
            W.Remember(changed,tab)
            if changed[tab].restoreShown==nil then changed[tab].restoreShown=tab:IsShown() and true or false end
            tab:Hide()
        end
    end
    W.Button(changed,CharacterFrameCloseButton,"x")
    Point("CharacterModelFrameRotateLeftButton",CharacterModelFrame,"BOTTOMLEFT","BOTTOMLEFT",0,2,24,22)
    Point("CharacterModelFrameRotateRightButton",CharacterModelFrame,"BOTTOMLEFT","BOTTOMLEFT",28,2,24,22)
    W.Button(changed,CharacterModelFrameRotateLeftButton,"<")
    W.Button(changed,CharacterModelFrameRotateRightButton,">")
    Identity()
    FontTree(CharacterNameFrame)
    W.Font(changed,CharacterNameText,12); W.Font(changed,CharacterLevelText,10)
    FontTree(CharacterAttributesFrame)
    Stats()
    if AZSMoreStats then
        if not morePanel then
            morePanel=K.Panel("KeijinUICharacterMore","",180,100)
            morePanel:SetParent(AZSMoreStats); morePanel.title:Hide(); morePanel.strip:Hide()
            morePanel:SetAllPoints(AZSMoreStats); morePanel:SetFrameLevel(math.max(0,AZSMoreStats:GetFrameLevel()-1))
            morePanel:SetFrameStrata(frame:GetFrameStrata())
        end
        -- Cover only the native backdrop, not any text or tooltip hit areas.
        if not changed[AZSMoreStats] then
            W.Remember(changed,AZSMoreStats)
            changed[AZSMoreStats].backdrop=AZSMoreStats.GetBackdrop and AZSMoreStats:GetBackdrop()
            if AZSMoreStats.GetBackdropColor then changed[AZSMoreStats].backdropColor={AZSMoreStats:GetBackdropColor()} end
            if AZSMoreStats.GetBackdropBorderColor then changed[AZSMoreStats].borderColor={AZSMoreStats:GetBackdropBorderColor()} end
        end
        AZSMoreStats:SetBackdrop({})
        -- Its native height changes when more conditional run bonuses appear.
        changed[AZSMoreStats].height=AZSMoreStats:GetHeight()
        Point("AZSMoreStats",frame,"TOPLEFT","TOPLEFT",350,-12)
        FontTree(AZSMoreStats)
        morePanel:Show()
    end
end
function C.Set(on)
    if active then Restore() end
    K.DB().characterWindowStyle=on and true or false
    K.layout.Place("characterwindow")
    Apply()
end
function C.Refresh()
    Hooks()
    if not frame and CharacterFrame and PaperDollFrame then
        frame=CharacterFrame
        nativeWindow={points=W.Points(frame),scale=frame:GetScale()}
        panel=K.Panel("KeijinUICharacterWindow","",336,410)
        panel:SetParent(frame); panel:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-8)
        panel:SetFrameLevel(frame:GetFrameLevel()); panel:SetFrameStrata(frame:GetFrameStrata())
        panel.title:Hide(); panel.strip:Hide(); panel:Hide()
        K.layout.Register("characterwindow",frame,"Charakter",function(f)
            f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"CENTER",-270,230)
        end,{inactive=function() return not C.On() or not active end,titleDrag=true,right=function()
            return AZSMoreStats and AZSMoreStats:IsVisible() and math.max(0,350+AZSMoreStats:GetWidth()-frame:GetWidth()) or 0
        end,release=function(f)
            if active then Restore() end
        end})
        drag=CreateFrame("Frame","KeijinUICharacterDrag",frame)
        drag:SetWidth(284); drag:SetHeight(48); drag:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-10)
        drag:SetFrameLevel(frame:GetFrameLevel()+30)
        W.Drag(drag,"characterwindow",frame); drag:Hide()
        W.Hook(frame,"OnShow",Apply)
        W.Hook(frame,"OnHide",Restore)
        W.Hook(PaperDollFrame,"OnShow",Apply)
        W.Hook(PaperDollFrame,"OnHide",Restore)
    end
    Apply()
end
K.On("ADDON_LOADED",C.Refresh)
K.On("PLAYER_ENTERING_WORLD",C.Refresh)
K.OnLang(C.Refresh)
K.Update("characterwindow",function()
    -- Shared updates are throttled by Core; apply only while the native window is visible.
    C.Refresh()
end)
C.Refresh()

K.moduleRefresh.characterWindow=C.Refresh
