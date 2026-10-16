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
        K.Chamfer(icon,2,{0.02,0.02,0.025,0.95})
        icon.tex=icon:CreateTexture(nil,"ARTWORK")
        icon.tex:SetPoint("TOPLEFT",icon,"TOPLEFT",2,-2); icon.tex:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",-2,2)
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
-- One sculpted housing: portrait bezel, dark name shoulder, tapered health rail.
-- All artwork is original and uses ordinary 1.12 textures, including the mirror.
local BORDER={0.78,0.69,0.50}
local FRAME_W,FRAME_H=206,58
local BOX=54
local HOLDER_W,HOLDER_H=158,30
local S=K.UnitFrameShapes
local function Create(unit,mirror)
    local name=unit=="player" and "KeijinUIPlayer" or "KeijinUITarget"
    local f=CreateFrame("Button",name,UIParent)
    f:SetWidth(FRAME_W); f:SetHeight(FRAME_H); f:SetFrameStrata("LOW")
    f:SetScale(K.CombatScale()); f:EnableMouse(true); f:RegisterForClicks("LeftButtonUp","RightButtonUp")
    -- Transparent click and layout container. It has no backdrop.
    local contentLeft=mirror and 4 or 44
    local boxLeft=mirror and 152 or 0
    local holder=CreateFrame("Frame",nil,f)
    holder:SetWidth(HOLDER_W); holder:SetHeight(HOLDER_H)
    holder:SetPoint("TOPLEFT",f,"TOPLEFT",contentLeft,-28)
    local body=S.Texture(f,"BACKGROUND","FrameBack.tga",206,58,0,0)
    if mirror then body:SetTexCoord(1,0,0,1) end
    -- The alpha-shaped fill follows the portrait edge and the lower connector.
    local bar=S.ConnectedFill(holder,name.."Health",mirror)
    bar:SetPoint("TOPLEFT",holder,"TOPLEFT",mirror and 1 or -17,-1)
    local rimLayer=CreateFrame("Frame",nil,f)
    rimLayer:SetAllPoints(f); rimLayer:SetFrameLevel(bar:GetFrameLevel()+2)
    local rim=S.Texture(rimLayer,"OVERLAY","FrameRim.tga",206,58,0,0)
    if mirror then rim:SetTexCoord(1,0,0,1) end
    local box=CreateFrame("Frame",nil,f)
    box:SetWidth(BOX); box:SetHeight(BOX)
    box:SetPoint("TOPLEFT",f,"TOPLEFT",boxLeft,-4)
    box:SetFrameLevel(bar:GetFrameLevel()+1)
    local portrait=box:CreateTexture(name.."Portrait","ARTWORK")
    portrait:SetWidth(48); portrait:SetHeight(48)
    portrait:SetPoint("TOPLEFT",box,"TOPLEFT",3,-3)
    -- The shared metal texture sits above both portrait and fill, keeping the
    -- circular bevel intact at the join. No square portrait backdrop is added.
    local ring=rim
    rim:SetVertexColor(BORDER[1],BORDER[2],BORDER[3],1)
    local layer=CreateFrame("Frame",nil,f)
    layer:SetAllPoints(f); layer:SetFrameLevel(rimLayer:GetFrameLevel()+1)
    -- Reflect each text box, including its alignment. Text stays readable:
    -- target percent/level on the left, health/name next to its portrait.
    local function TextLeft(left,width) return mirror and FRAME_W-left-width or left end
    f.health=K.Text(layer,"?",10,"TOPLEFT",TextLeft(59,80),-36,80)
    f.health:SetHeight(14); f.health:SetJustifyH(mirror and "RIGHT" or "LEFT")
    f.percent=K.Text(layer,"?%",10,"TOPLEFT",TextLeft(156,36),-36,36)
    f.percent:SetHeight(14); f.percent:SetJustifyH(mirror and "LEFT" or "RIGHT")
    f.label=K.Text(layer,unit=="player" and K.T("Spieler") or K.T("Kein Ziel"),11,"TOPLEFT",TextLeft(58,90),-13,90)
    f.label:SetHeight(14); f.label:SetJustifyH(mirror and "RIGHT" or "LEFT"); f.label:SetTextColor(1,0.82,0.28)
    -- End at x=184: keep the text safely inside the chamfered outer end.
    f.level=K.Text(layer,"",10,"TOPLEFT",TextLeft(153,31),-14,31)
    f.level:SetHeight(12); f.level:SetJustifyH(mirror and "LEFT" or "RIGHT"); f.level:SetTextColor(1,0.82,0.28)
    f.unit,f.portrait,f.bar,f.box,f.ring,f.rim=unit,portrait,bar,box,ring,rim
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
-- from the second UnitClass return); /kui switches back to green and red. The 1.12 table gives
-- shamans the paladin pink, so they get the later dark blue instead.
local CLASS_OVERRIDE={SHAMAN={r=0.00,g=0.44,b=0.87}}
local function HealthColor(unit)
    if K.DB().classHealth~=false and (unit=="player" or UnitIsPlayer(unit)) then
        local _,token=UnitClass(unit)
        local c=token and (CLASS_OVERRIDE[token] or RAID_CLASS_COLORS and RAID_CLASS_COLORS[token])
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
            f.rim:SetVertexColor(border[1],border[2],border[3],1)
            if K.Number(hp) and K.Number(max) and max>0 then
                local pct=math.max(0,math.min(1,hp/max))
                f.bar:SetValue(pct); f.health:SetText(K.Short(hp))
                f.percent:SetText(string.format("%.0f%%",math.floor(pct*100)))
                f.exact=string.format("%.0f / %.0f",hp,max)
            else f.bar:SetValue(0); f.health:SetText("?"); f.percent:SetText("?%"); f.exact=nil end
            f.bar:SetStatusBarColor(HealthColor(unit))
            SetPortraitTexture(f.portrait,unit)
            f.portrait:Show()
        else
            f.label:SetText(unit=="target" and K.T("Kein Ziel") or K.T("Spieler"))
            f.health:SetText("?"); f.percent:SetText("?%"); f.level:SetText(""); f.bar:SetValue(0); f.exact=nil
            f.rim:SetVertexColor(BORDER[1],BORDER[2],BORDER[3],1)
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
