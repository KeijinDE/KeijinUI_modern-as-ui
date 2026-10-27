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
local HOLDER_W,HOLDER_H=FRAME_W-48,30
local S=K.UnitFrameShapes
local CLEAN_H=K.PortraitFree.H
local DEBUFF_X,DEBUFF_Y=4,-2
-- portraits==false selects the compact frame without portrait; nil and true keep the portrait style.
local function CleanStyle() return K.DB().portraits==false end
-- Native 1.12 atlas and getter: FrameXML/TargetFrame.lua, UpdateRaidTargetIcon.
-- Only real unit tokens are queried; never infer marks from names or AZS unit rows.
local function UpdateRaidMarker(f)
    local index=GetRaidTargetIndex and UnitExists(f.unit) and GetRaidTargetIndex(f.unit)
    if not K.Number(index) or index<1 or index>8 or index~=math.floor(index) then f.raidMarker:Hide(); return end
    local n=index-1
    local left=math.mod(n,4)/4
    local top=math.floor(n/4)/4
    f.raidMarker:SetTexCoord(left,left+0.25,top,top+0.25)
    f.raidMarker:Show()
end
-- Distance from the frame's left and top edge to the corner of its health bar that stays put when the style changes:
-- top right corner for the player (portrait on the left), top left corner for the target (portrait on the right).
-- The bar top sits 29 points below the frame top in the portrait style and HEAD (20) in the compact one.
local BAR_TOP=29
local function EdgeOffset(unit,clean)
    if clean then return unit=="player" and K.PortraitFree.W or 0,K.PortraitFree.HEAD end
    if unit=="player" then return 44-17+HOLDER_W+16,BAR_TOP end
    return 4+1,BAR_TOP
end
local FIELDS={"label","level","health","percent","bar","rim","body"}
-- Both geometries are built once under the stable outer frame and only shown or hidden here.
-- The active one is mirrored into f.label, f.level, f.health, f.percent, f.bar, f.rim and f.body.
local function ApplyStyle(f,clean)
    if f.clean==clean then return end
    local set=clean and f.sets.clean or f.sets.classic
    f.clean=clean
    if clean then f.sets.classic.root:Hide(); f.sets.clean.root:Show()
    else f.sets.clean.root:Hide(); f.sets.classic.root:Show() end
    for _,key in ipairs(FIELDS) do f[key]=set[key] end
    f:SetWidth(clean and K.PortraitFree.W or FRAME_W); f:SetHeight(clean and CLEAN_H or FRAME_H)
    f.raidMarker:ClearAllPoints()
    if clean then f.raidMarker:SetPoint("BOTTOM",f,"TOP",0,2)
    else f.raidMarker:SetPoint("BOTTOM",f,"TOPLEFT",f.unit=="player" and BOX/2 or FRAME_W-BOX/2,2) end
    if f.debuffs then f.debuffs:ClearAllPoints(); f.debuffs:SetPoint("TOPLEFT",f,"BOTTOMLEFT",DEBUFF_X,DEBUFF_Y) end
    local entry=K.layout.entries[f.unit]
    if entry and entry.handle and entry.handle.outline then
        local outline=entry.handle.outline
        if clean then outline:SetTexture("Interface\\AddOns\\KeijinUI\\media\\portraitfree\\Rim.tga"); outline:SetTexCoord(0,1,0,1)
        else
            outline:SetTexture("Interface\\AddOns\\KeijinUI\\media\\soft\\FrameRim.tga")
            if f.unit=="target" then outline:SetTexCoord(1,0,0,1) else outline:SetTexCoord(0,1,0,1) end
        end
    end
    -- Same saved edge and scale, new height: re-apply once (no compensation), then pull dependants along.
    K.layout.Place(f.unit)
    K.layout.SyncFollowers()
end
local function Create(unit,mirror)
    local name=unit=="player" and "KeijinUIPlayer" or "KeijinUITarget"
    local f=CreateFrame("Button",name,UIParent)
    f:SetWidth(FRAME_W); f:SetHeight(FRAME_H); f:SetFrameStrata("LOW")
    f:SetScale(K.CombatScale()); f:EnableMouse(true); f:RegisterForClicks("LeftButtonUp","RightButtonUp")
    -- Everything of the portrait style lives under this container so it can be hidden as a whole.
    local old=CreateFrame("Frame",nil,f)
    old:SetAllPoints(f)
    local clean=K.PortraitFree.Build(f,name,mirror)
    -- Transparent click and layout container. It has no backdrop.
    local contentLeft=mirror and 4 or 44
    local boxLeft=mirror and FRAME_W-BOX or 0
    local holder=CreateFrame("Frame",nil,old)
    holder:SetWidth(HOLDER_W); holder:SetHeight(HOLDER_H)
    holder:SetPoint("TOPLEFT",f,"TOPLEFT",contentLeft,-28)
    local body=S.Housing(old,"BACKGROUND","FrameBack.tga",FRAME_W,FRAME_H,mirror)
    -- The alpha-shaped fill follows the portrait edge and the lower connector.
    local bar=S.ConnectedFill(holder,name.."Health",mirror)
    bar:SetPoint("TOPLEFT",holder,"TOPLEFT",mirror and 1 or -17,-1)
    -- Absorb shield layer on the player's health bar (both geometries); the target frame has none.
    if not mirror then
        S.AddShield(bar,"Interface\\AddOns\\KeijinUI\\media\\soft\\ConnectedHealth.tga")
        S.AddShield(clean.bar,"Interface\\AddOns\\KeijinUI\\media\\portraitfree\\Health.tga")
    end
    local rimLayer=CreateFrame("Frame",nil,old)
    rimLayer:SetAllPoints(f); rimLayer:SetFrameLevel(bar:GetFrameLevel()+2)
    body:SetVertexColor(1,1,1,K.BackgroundAlpha()/K.BG_ALPHA)
    local rim=S.Housing(rimLayer,"OVERLAY","FrameRim.tga",FRAME_W,FRAME_H,mirror)
    local box=CreateFrame("Frame",nil,old)
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
    local layer=CreateFrame("Frame",nil,old)
    layer:SetAllPoints(f); layer:SetFrameLevel(rimLayer:GetFrameLevel()+1)
    -- Reflect each text box, including its alignment. Text stays readable:
    -- target percent/level on the left, health/name next to its portrait.
    local function TextLeft(left,width) return mirror and FRAME_W-left-width or left end
    f.health=K.Text(layer,"?",10,"TOPLEFT",TextLeft(59,FRAME_W-126),-36,FRAME_W-126)
    f.health:SetHeight(14); f.health:SetJustifyH(mirror and "RIGHT" or "LEFT")
    f.percent=K.Text(layer,"?%",10,"TOPLEFT",TextLeft(FRAME_W-50,36),-36,36)
    f.percent:SetHeight(14); f.percent:SetJustifyH(mirror and "LEFT" or "RIGHT")
    f.label=K.Text(layer,unit=="player" and K.T("Spieler") or K.T("Kein Ziel"),11,"TOPLEFT",TextLeft(58,FRAME_W-116),-13,FRAME_W-116)
    f.label:SetHeight(14); f.label:SetJustifyH(mirror and "RIGHT" or "LEFT"); f.label:SetTextColor(1,0.82,0.28)
    -- Leave room inside the chamfered outer end.
    f.level=K.Text(layer,"",10,"TOPLEFT",TextLeft(FRAME_W-53,31),-14,31)
    f.level:SetHeight(12); f.level:SetJustifyH(mirror and "LEFT" or "RIGHT"); f.level:SetTextColor(1,0.82,0.28)
    f.unit,f.portrait,f.bar,f.box,f.ring,f.rim,f.body=unit,portrait,bar,box,ring,rim,body
    clean.label:SetText(f.label:GetText())
    f.clean=false
    f.sets={classic={root=old,label=f.label,level=f.level,health=f.health,percent=f.percent,bar=bar,rim=rim,body=body},clean=clean}
    f.raidMarker=f:CreateTexture(nil,"OVERLAY")
    f.raidMarker:SetWidth(18); f.raidMarker:SetHeight(18)
    f.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    f.raidMarker:SetPoint("BOTTOM",f,"TOPLEFT",mirror and FRAME_W-BOX/2 or BOX/2,2)
    f.raidMarker:Hide()
    f:SetScript("OnClick",function()
        if arg1=="RightButton" then K.marks.Open(unit,this)
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
        -- The health bar edge sits 12 points from the skill bar in both styles; the frame edge moves instead.
        local clean=CleanStyle()
        local off,top=EdgeOffset(unit,clean)
        local x=mirror and 12-off or -12+((clean and K.PortraitFree.W or FRAME_W)-off)
        -- The frame is centred on the skill bar: the bar top moves with the frame height, so shift it back.
        local y=top-(clean and CLEAN_H or FRAME_H)/2
        frame:SetPoint(mirror and "LEFT" or "RIGHT",KeijinUISkills,mirror and "RIGHT" or "LEFT",x,y)
    end,{scale=K.CombatScale,hidden=mirror,edge=function() return EdgeOffset(unit,CleanStyle()) end})
    if mirror then
        f.debuffs=K.DebuffRow(f,18,false)
        f.debuffs:SetPoint("TOPLEFT",f,"BOTTOMLEFT",DEBUFF_X,DEBUFF_Y)
    end
    K.units[unit]=f
end
Create("player",false); Create("target",true)
-- Class colours remain optional; other targets follow the native relationship.
local function HealthColor(unit)
    if K.DB().classHealth~=false and (unit=="player" or UnitIsPlayer(unit)) then
        local _,token=UnitClass(unit)
        local r,g,b=K.ClassColor(token)
        if r then return r,g,b end
    end
    if unit=="player" then return 0.12,0.88,0.08 end
    if UnitIsFriend and UnitIsFriend("player",unit) then return 0.12,0.88,0.08 end
    local reaction=UnitReaction and UnitReaction(unit,"player")
    if K.Number(reaction) then
        if reaction>=5 then return 0.12,0.88,0.08 end
        if reaction==4 then return 1,1,0 end
        if reaction==3 then return 1,0.5,0 end
    end
    return 0.85,0.08,0.08
end
-- Under the target frame only while no nameplate shows the target's debuffs.
function K.RefreshTargetDebuffs()
    local f=K.units and K.units.target
    if not f or not f.debuffs then return end
    if UnitExists("target") and (K.DB().targetDebuffsBoth~=false or not K.targetPlateShown) then K.UpdateDebuffRow(f.debuffs,"target")
    else K.UpdateDebuffRow(f.debuffs,nil) end
end
local function Update()
    HideStock()
    for unit,f in pairs(K.units) do
        ApplyStyle(f,CleanStyle())
        UpdateRaidMarker(f)
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
                -- Absorb shield (AZS_RUN.sh, game 0.110): only the player; missing, zero or not a number shows nothing.
                -- The shield is in the run's units (AZS_RUN.hpm); the frame may show UnitHealth's, so it is scaled to max.
                local shield=unit=="player" and type(AZS_RUN)=="table" and AZS_RUN.sh
                if not K.Number(shield) or shield<=0 then shield=nil
                elseif K.Number(AZS_RUN.hpm) and AZS_RUN.hpm>0 then shield=shield*max/AZS_RUN.hpm end
                f.bar:SetValue(pct); f.health:SetText(K.Short(hp)..(shield and " +"..K.Short(shield) or ""))
                if f.bar.SetShield then f.bar:SetShield(hp/max,shield and shield/max) end
                f.percent:SetText(string.format("%.0f%%",math.floor(pct*100)))
                f.exact=string.format("%.0f / %.0f",hp,max)..(shield and string.format(" (+%.0f)",shield) or "")
                if unit=="target" then K.combatDetails.Execute(f,f.bar,pct,true) end
            else
                if f.bar.SetShield then f.bar:SetShield(0,nil) end
                f.bar:SetValue(0); f.health:SetText("?"); f.percent:SetText("?%"); f.exact=nil; K.combatDetails.Execute(f,f.bar,nil,true) end
            f.bar:SetStatusBarColor(HealthColor(unit))
            -- The compact style has no portrait; the pointer is not touched there.
            if not f.clean and f.portrait then SetPortraitTexture(f.portrait,unit); f.portrait:Show() end
        else
            f.label:SetText(unit=="target" and K.T("Kein Ziel") or K.T("Spieler"))
            f.health:SetText("?"); f.percent:SetText("?%"); f.level:SetText(""); f.bar:SetValue(0); f.exact=nil
            if f.bar.SetShield then f.bar:SetShield(0,nil) end
            f.rim:SetVertexColor(BORDER[1],BORDER[2],BORDER[3],1)
            if not f.clean and f.portrait then f.portrait:SetTexture(nil); f.portrait:Hide() end
        end
        if unit=="target" and not UnitExists(unit) then
            -- No target: the whole frame is gone. Alt or layout editing keeps an invisible,
            -- movable frame so the position can still be set.
            if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(f) then GameTooltip:Hide() end
            if K.layout.Active() then f:SetAlpha(0); f:Show()
            else f:SetAlpha(1); f:Hide() end
        else f:SetAlpha(1); f:Show() end
        if unit=="target" and not UnitExists(unit) then K.combatDetails.Execute(f,f.bar,nil,true) end
        if f.debuffs then K.RefreshTargetDebuffs() end
    end
end
function K.ApplyUnitBackground()
    local alpha=K.BackgroundAlpha()/K.BG_ALPHA
    -- Only the backgrounds of both geometries; fill, text and rim keep their own alpha.
    for _,f in pairs(K.units) do
        f.sets.classic.body:SetVertexColor(1,1,1,math.min(1,alpha))
        f.sets.clean.body:SetVertexColor(1,1,1,math.min(1,alpha))
    end
end
K.UpdateUnits=function() Update(); K.ApplyUnitBackground() end
for _,ev in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_LEVEL","UNIT_PORTRAIT_UPDATE","RAID_TARGET_UPDATE","UNIT_FACTION"}) do K.On(ev,Update) end
table.insert(K.updates,Update)
K.On("PLAYER_ENTERING_WORLD",K.ApplyBackground)
-- Saved variables arrive after the files: switch to a saved compact style as soon as they exist.
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.UpdateUnits() end end)
Update()
