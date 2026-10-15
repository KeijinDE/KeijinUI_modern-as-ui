local K=KeijinUI
K.units={}
local function HideStock()
    for _,key in ipairs({"PlayerFrame","TargetFrame"}) do
        local f=getglobal(key)
        if f then f:SetAlpha(0); f:EnableMouse(false); if f:IsShown() then f:Hide() end end
    end
end
-- Debuff icons of one unit, only what UnitDebuff returns (texture, stack count): no durations are
-- invented, the client gives none for other units. Rows are shared with the target nameplate.
local DEBUFF_MAX=8
function K.DebuffRow(parent,size,centered)
    local row=CreateFrame("Frame",nil,parent)
    row:SetWidth(DEBUFF_MAX*(size+1)); row:SetHeight(size); row:EnableMouse(false)
    row.icons={}; row.size=size; row.centered=centered; row.shown=0
    for i=1,DEBUFF_MAX do
        local icon=CreateFrame("Frame",nil,row)
        icon:SetWidth(size); icon:SetHeight(size); icon:EnableMouse(false)
        icon.back=icon:CreateTexture(nil,"BACKGROUND")
        icon.back:SetTexture(K.flat); icon.back:SetVertexColor(0.02,0.02,0.025,0.95); icon.back:SetAllPoints(icon)
        icon.tex=icon:CreateTexture(nil,"ARTWORK")
        icon.tex:SetPoint("TOPLEFT",icon,"TOPLEFT",1,-1); icon.tex:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",-1,1)
        icon.tex:SetTexCoord(0.08,0.92,0.08,0.92)
        icon.count=K.Text(icon,"",8,"BOTTOMRIGHT",0,1)
        icon.count:ClearAllPoints(); icon.count:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",1,0)
        icon:Hide()
        row.icons[i]=icon
    end
    return row
end
function K.UpdateDebuffRow(row,unit)
    local n=0
    if unit and UnitExists(unit) and UnitDebuff then
        for i=1,DEBUFF_MAX do
            local texture,count=UnitDebuff(unit,i)
            if not texture then break end
            n=n+1
            local icon=row.icons[n]
            icon.tex:SetTexture(texture)
            icon.count:SetText(K.Number(count) and count>1 and tostring(count) or "")
        end
    end
    local step=row.size+1
    for i=1,DEBUFF_MAX do
        local icon=row.icons[i]
        if i<=n then
            icon:ClearAllPoints()
            if row.centered then icon:SetPoint("LEFT",row,"CENTER",-n*step/2+(i-1)*step,0)
            else icon:SetPoint("LEFT",row,"LEFT",(i-1)*step,0) end
            icon:Show()
        else icon:Hide() end
    end
    row.shown=n
    return n
end
-- Unit frames in the language of the panels: flat dark fill with tooltip border (K.Skin), the name
-- in a heading strip like the panel titles, the health bar in the metal frame of K.MetalBar (fill
-- inset 1 px like K.Row), the portrait in a square box with the same border. The client cuts
-- portraits to a circle itself, so the portrait is round inside its square box.
local BORDER={0.62,0.57,0.43}
local FRAME_W,FRAME_H=206,58
local BOX=46
local HOLDER_W,HOLDER_H=136,24
local function Create(unit,mirror)
    local name=unit=="player" and "KeijinUIPlayer" or "KeijinUITarget"
    local f=CreateFrame("Button",name,UIParent)
    f:SetWidth(FRAME_W); f:SetHeight(FRAME_H); f:SetFrameStrata("LOW")
    f:SetScale(K.CombatScale()); f:EnableMouse(true); f:RegisterForClicks("LeftButtonUp","RightButtonUp")
    K.Skin(f)
    -- Content column (strip, health bar) and portrait box sit on opposite sides for player and target.
    local contentLeft=mirror and 8 or 62
    local boxLeft=mirror and (FRAME_W-6-BOX) or 6
    local strip=f:CreateTexture(nil,"BORDER")
    strip:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
    strip:SetVertexColor(0.6,0.53,0.36,0.55)
    strip:SetPoint("TOPLEFT",f,"TOPLEFT",contentLeft,-6)
    strip:SetWidth(HOLDER_W); strip:SetHeight(16)
    -- Health bar: holder with metal frame, fill inset like K.Row.
    local holder=CreateFrame("Frame",nil,f)
    holder:SetWidth(HOLDER_W); holder:SetHeight(HOLDER_H)
    holder:SetPoint("TOPLEFT",f,"TOPLEFT",contentLeft,-28)
    local back=holder:CreateTexture(nil,"BACKGROUND")
    back:SetTexture(K.flat); back:SetVertexColor(0.04,0.04,0.05,0.6)
    back:SetPoint("TOPLEFT",holder,"TOPLEFT",1,-1); back:SetPoint("BOTTOMRIGHT",holder,"BOTTOMRIGHT",-1,1)
    local bar=CreateFrame("StatusBar",name.."Health",holder)
    bar:SetPoint("TOPLEFT",holder,"TOPLEFT",1,-1); bar:SetPoint("BOTTOMRIGHT",holder,"BOTTOMRIGHT",-1,1)
    bar:SetMinMaxValues(0,1); bar:SetValue(0)
    bar:SetStatusBarColor(unit=="player" and 0.12 or 0.85,unit=="player" and 0.88 or 0.08,0.08)
    K.MetalBar(holder,bar)
    -- Portrait: box with the panel border, round portrait in it.
    local box=CreateFrame("Frame",nil,f)
    box:SetWidth(BOX); box:SetHeight(BOX); box:SetPoint("TOPLEFT",f,"TOPLEFT",boxLeft,-6)
    K.Skin(box)
    local picture=CreateFrame("Frame",nil,f); picture:SetAllPoints(f); picture:SetFrameLevel(box:GetFrameLevel()+1)
    local portrait=picture:CreateTexture(name.."Portrait","ARTWORK")
    portrait:SetWidth(BOX-6); portrait:SetHeight(BOX-6)
    portrait:SetPoint("TOPLEFT",f,"TOPLEFT",boxLeft+3,-9)
    -- Text has its own layer on top of bar and portrait.
    local layer=CreateFrame("Frame",nil,f); layer:SetAllPoints(f); layer:SetFrameLevel(bar:GetFrameLevel()+3)
    f.health=K.Text(layer,"? / ?",10,"CENTER",0,0)
    f.health:ClearAllPoints(); f.health:SetPoint("CENTER",holder,"CENTER",0,0)
    f.health:SetWidth(HOLDER_W-10); f.health:SetHeight(14); f.health:SetJustifyH("CENTER")
    f.label=K.Text(layer,unit=="player" and K.T("Spieler") or K.T("Kein Ziel"),11,"TOPLEFT",contentLeft+5,-7,HOLDER_W-44)
    f.label:SetHeight(14)
    f.label:SetTextColor(1,0.82,0.28)
    f.level=K.Text(layer,"",10,"TOPLEFT",contentLeft+HOLDER_W-36,-8,31)
    f.level:SetHeight(12); f.level:SetJustifyH("RIGHT")
    f.level:SetTextColor(1,0.82,0.28)
    f.unit,f.portrait,f.bar,f.box=unit,portrait,bar,box
    f:SetScript("OnClick",function()
        if arg1=="RightButton" then if ToggleGameMenu then ToggleGameMenu() end
        elseif UnitExists(unit) and TargetUnit then TargetUnit(unit) end
    end)
    f:SetScript("OnEnter",function()
        if not UnitExists(unit) then return end
        GameTooltip:SetOwner(this,"ANCHOR_TOP")
        GameTooltip:SetText(UnitName(unit) or "?",1,0.82,0.28)
        GameTooltip:AddLine(K.T("Leben")..": "..(this.exact or "?"),1,1,1); GameTooltip:Show()
    end)
    f:SetScript("OnLeave",function() GameTooltip:Hide() end)
    K.layout.Register(unit,f,unit=="player" and "Spieler" or "Ziel",function(frame)
        frame:ClearAllPoints()
        frame:SetPoint(mirror and "LEFT" or "RIGHT",KeijinUISkills,mirror and "RIGHT" or "LEFT",mirror and 12 or -12,0)
    end,{scale=K.CombatScale,hidden=mirror})
    if mirror then
        f.debuffs=K.DebuffRow(f,18,false)
        f.debuffs:SetPoint("TOPLEFT",f,"BOTTOMLEFT",contentLeft,-2)
    end
    K.units[unit]=f
end
Create("player",false); Create("target",true)
-- Health colour: class colour by default (RAID_CLASS_COLORS from FrameXML Fonts.xml, token
-- from the second UnitClass return); /kui switches back to green and red.
local function HealthColor(unit)
    if K.DB().classHealth~=false and (unit=="player" or UnitIsPlayer(unit)) then
        local _,token=UnitClass(unit)
        local c=token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
        if c then return c.r,c.g,c.b end
    end
    if unit=="player" then return 0.12,0.88,0.08 end
    return 0.85,0.08,0.08
end
-- Under the target frame only while no nameplate shows the target's debuffs.
function K.RefreshTargetDebuffs()
    local f=K.units and K.units.target
    if not f or not f.debuffs then return end
    if UnitExists("target") and not K.targetPlateShown then K.UpdateDebuffRow(f.debuffs,"target")
    else K.UpdateDebuffRow(f.debuffs,nil) end
end
local function Update()
    HideStock()
    for unit,f in pairs(K.units) do
        if UnitExists(unit) then
            local hp,max=UnitHealth(unit),UnitHealthMax(unit)
            local r=unit=="player" and AZS_RUN or AZS_TARGET
            if (not K.Number(hp) or not K.Number(max) or max<=0 or (unit=="target" and max<=100))
                and type(r)=="table" and K.Number(r.hp) and K.Number(r.hpm) and r.hpm>0
                and (unit=="player" or r.name==UnitName(unit)) then hp,max=r.hp,r.hpm end
            f.label:SetText(UnitName(unit) or "?")
            local lvl=UnitLevel(unit)
            -- Elite and rare targets: marker behind the level and a border in the matching colour.
            local class=unit=="target" and UnitClassification and UnitClassification(unit) or "normal"
            local mark=(class=="elite" and "+") or (class=="rareelite" and "R+") or (class=="rare" and "R") or (class=="worldboss" and "+") or ""
            f.level:SetText((lvl and lvl>0 and tostring(lvl) or "??")..mark)
            local border=(class=="elite" or class=="worldboss") and {1,0.82,0.28} or ((class=="rare" or class=="rareelite") and {0.78,0.84,0.95}) or BORDER
            f:SetBackdropBorderColor(border[1],border[2],border[3],1)
            if K.Number(hp) and K.Number(max) and max>0 then
                local pct=math.max(0,math.min(1,hp/max))
                f.bar:SetValue(pct); f.health:SetText(string.format("%.0f%% / %.0f",math.floor(pct*100),hp))
                f.exact=string.format("%.0f / %.0f",hp,max)
            else f.bar:SetValue(0); f.health:SetText("? / ?"); f.exact=nil end
            f.bar:SetStatusBarColor(HealthColor(unit))
            SetPortraitTexture(f.portrait,unit)
            f.portrait:Show()
        else
            f.label:SetText(unit=="target" and K.T("Kein Ziel") or K.T("Spieler"))
            f.health:SetText("? / ?"); f.level:SetText(""); f.bar:SetValue(0); f.exact=nil
            f:SetBackdropBorderColor(BORDER[1],BORDER[2],BORDER[3],1)
            f.portrait:SetTexture(nil); f.portrait:Hide()
        end
        if unit=="target" and not UnitExists(unit) then
            -- No target: the whole frame is gone. Alt or layout editing keeps an invisible,
            -- movable frame so the position can still be set.
            if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(f) then GameTooltip:Hide() end
            if IsAltKeyDown() or (K.layout.IsEditing and K.layout.IsEditing()) then f:SetAlpha(0); f:Show()
            else f:SetAlpha(1); f:Hide() end
        else f:SetAlpha(1); f:Show() end
        if f.debuffs then K.RefreshTargetDebuffs() end
    end
end
for _,ev in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_LEVEL","UNIT_PORTRAIT_UPDATE"}) do K.On(ev,Update) end
table.insert(K.updates,Update)
Update()
