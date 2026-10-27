-- Restyle the native paper doll; do not replace equipment or model scripts.
-- Evidence: FrameXML CharacterFrame/PaperDollFrame; AZS_UpdateMore creates
-- AZSMoreStats lazily (analysis/exe_strings.txt). Other character tabs stay native.
local K=KeijinUI
local W=K.windowTools
local C={}
K.characterWindow=C
local frame,panel,morePanel,statsPanel,drag,nativeWindow,active=false
local changed={}
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
    W.Restore(changed); changed={}
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
        if r.GetObjectType and r:GetObjectType()=="FontString" then W.Font(changed,r) end
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
local RUN_LABELS={{"Leben","Schaden","Tempo","Kritchance","Krit-Schaden","Rüstung"},{"Fläche","Ziele","Echochance","Bewegungstempo","Regeneration","Sammelreichweite"}}
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
local function Stats()
    for column,rows in ipairs(STAT_ROWS) do
        for index,name in ipairs(rows) do
            local row=getglobal(name)
            if row then
                W.Anchor(changed,row,CharacterAttributesFrame,"TOPLEFT","TOPLEFT",8+(column-1)*116,-8-(index-1)*12,100,12)
                local label,value=getglobal(name.."Label"),getglobal(name.."StatText")
                local labels=type(AZS_STATS)=="table" and RUN_LABELS or STOCK_LABELS
                Text(label,K.T(labels[column][index])..":")
                W.Font(changed,label,10); W.Font(changed,value,10)
                if value then
                    W.Anchor(changed,value,row,"RIGHT","RIGHT",0,0,math.max(28,value:GetStringWidth()),12)
                end
                if label then
                    local available=100-(value and value:GetWidth() or 28)-6
                    local measured=label:GetStringWidth()
                    if measured>available then
                        local path,size,flags=label:GetFont()
                        label:SetFont(path,math.max(8,size*available/measured),flags)
                    end
                    W.Anchor(changed,label,row,"LEFT","LEFT",0,0,available,12)
                end
            end
        end
    end
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
