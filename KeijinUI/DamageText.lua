-- Floating damage numbers with two own styles (Core.lua, K.CombatTextMode). compact: the Survivor UI
-- style, normal hits very small and white, only critical hits large and yellow, rising straight up.
-- scroll: numbers rise with ease out and drift to the left or right, coloured by damage school, with the
-- spell icon on the left; small normal hits are grey, crits are large; crits and misses start with a pop,
-- they follow the target's nameplate and misses are shown too.
-- off and native draw nothing here. The native floating text (cvar CombatDamage) cannot do this:
-- one colour per source, no size for crits (benilla combat_text/mod.rs), so Core.lua keeps it off
-- and this module draws from the same native combat messages the parser reads (CombatParser.lua).
-- Position: above the visible nameplate of the hit enemy (Nameplates.lua, K.PlateAnchor). Without
-- a plate (nameplates off, plate not on screen) the numbers rise over the screen centre, the
-- player's usual place. There is no world position in the addon API.
local K=KeijinUI
local NORMAL={size=10,r=1,g=1,b=1,life=0.8,rise=26}
local CRIT={size=26,r=1,g=0.82,b=0.1,life=1.3,rise=44}
-- scroll style: size, life (s) and rise per kind; colours per school key (CombatParser.lua SchoolKey).
-- pop: crits and misses start small and swell to double size, then settle (see PopFactor).
-- small: normal hits under half of the running average are grey and small.
local SCROLL={normal={size=12,life=1.1,rise=60},crit={size=30,life=1.5,rise=45,pop=true},
    periodic={size=11,life=1.1,rise=60,alpha=0.85},small={size=11,life=1.1,rise=60},
    miss={size=13,life=1.2,rise=60,pop=true}}
local SCHOOL={Physical={1,0.95,0.85},Holy={1,0.85,0.35},Fire={1,0.5,0.15},Nature={0.45,0.9,0.3},
    Frost={0.45,0.8,1},Shadow={0.75,0.45,1},Arcane={1,0.55,0.95}}
local MISS_TEXT={miss="Verfehlt",dodge="Ausgewichen",parry="Pariert",block="Geblockt",evade="Entkommen",
    immune="Immun",resist="Widerstanden"}
local FOLLOW_JUMP=80   -- a plate further from the last anchor is another mob; keep the old anchor
local flip=1           -- strictly alternates the drift side
local ICON_GAP=2
local average          -- running average of the own normal hits (scroll style)
local MAX=60
local host=CreateFrame("Frame","KeijinUIDamageText",UIParent)
host:SetFrameStrata("HIGH"); host:SetWidth(1); host:SetHeight(1)
host:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0); host:EnableMouse(false)
local active,pool,iconPool={}, {}, {}
K.damageText={active=active}
local function Take()
    local fs=table.remove(pool)
    if not fs then fs=host:CreateFontString(nil,"OVERLAY") end
    return fs
end
local function Give(item)
    item.fs:Hide(); table.insert(pool,item.fs)
    if item.icon then item.icon:Hide(); table.insert(iconPool,item.icon) end
end
-- Spell book as name -> texture, rebuilt on SPELLS_CHANGED and at the first need (same calls as KeijinBuildBar.lua).
local book
local function SpellIcon(name)
    if not name then return nil end
    if not book then
        book={}
        if type(GetNumSpellTabs)=="function" and type(GetSpellTabInfo)=="function"
            and type(GetSpellName)=="function" and type(GetSpellTexture)=="function" then
            for tab=1,math.min(16,GetNumSpellTabs()) do
                local _,_,offset,count=GetSpellTabInfo(tab)
                if type(offset)=="number" and type(count)=="number" then
                    for index=math.max(1,offset+1),math.min(1023,offset+count) do
                        local spell=GetSpellName(index,"spell")
                        if spell then book[spell]=GetSpellTexture(index,"spell") end
                    end
                end
            end
        end
    end
    return book[name]
end
K.On("SPELLS_CHANGED",function() book=nil end)
-- Weapon icon for melee hits (no spell name).
local function MeleeIcon()
    if type(GetInventoryItemTexture)=="function" then return GetInventoryItemTexture("player",16) end
end
-- Font size and icon side always match.
local function SetSize(item,size)
    item.size=size
    item.fs:SetFont(K.font,size,"OUTLINE")
    if item.icon then item.icon:SetWidth(size); item.icon:SetHeight(size) end
end
local function Start()
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    return (w or 1024)/2+math.random(-50,50),(h or 768)/2+40+math.random(0,20)
end
-- Numbers never cover the unit frames, the skill bar or the counter row: a start point inside such
-- a frame (an enemy standing behind it) is moved up to just above its top edge, the numbers only rise.
local function KeepClear(x,y)
    local names={"KeijinUISkills","KeijinUITally"}
    local frames={K.units and K.units.player,K.units and K.units.target,getglobal(names[1]),getglobal(names[2])}
    local ui=UIParent:GetEffectiveScale()
    for _=1,3 do
        local moved
        for _,f in pairs(frames) do
            if f.IsShown and f:IsShown() and f.GetLeft and f:GetAlpha()>0 then
                local l,b,r,t=f:GetLeft(),f:GetBottom(),f:GetRight(),f:GetTop()
                local ratio=(f:GetEffectiveScale() or 1)/(ui or 1)
                if K.Number(l) and K.Number(b) and K.Number(r) and K.Number(t) then
                    l,b,r,t=l*ratio,b*ratio,r*ratio,t*ratio
                    if x>=l-12 and x<=r+12 and y>=b-14 and y<=t then y=t+6; moved=true end
                end
            end
        end
        if not moved then break end
    end
    return x,y
end
K.damageText.KeepClear=KeepClear
-- Size factor of the pop: 0.5 to 2.0 in 0.12 s (ease out), back to 1.0 by 0.24 s.
local function PopFactor(age)
    if age>=0.24 then return 1 end
    if age<0.12 then local u=1-age/0.12; return 0.5+1.5*(1-u*u*u) end
    local v=(age-0.12)/0.12
    return 2-v*v
end
-- Common part: place, style and register one number (scroll: rising, otherwise compact).
-- icon: texture path shown left of a scroll number (nil: none, the text stays centred).
local function Add(text,style,r,g,b,targetName,scroll,pop,icon)
    local x,y,px,py
    if K.PlateAnchor and targetName then px,py=K.PlateAnchor(targetName) end
    if px then x,y=px+math.random(-14,14),py else x,y=Start() end
    x,y=KeepClear(x,y)
    if table.getn(active)>=MAX then Give(table.remove(active,1)) end
    local fs=Take()
    local size=style.size
    if pop then size=math.floor(size*PopFactor(0)+0.5) end
    fs:SetTextColor(r,g,b)
    fs:SetText(text)
    fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",x,y)
    fs:SetAlpha(1); fs:Show()
    local item={fs=fs,x=x,y=y,x0=x,y0=y,age=0,style=style,scroll=scroll,pop=pop}
    if icon then
        local tex=table.remove(iconPool) or host:CreateTexture(nil,"OVERLAY")
        tex:SetTexture(icon); tex:SetTexCoord(0.08,0.92,0.08,0.92)
        tex:ClearAllPoints(); tex:SetPoint("RIGHT",fs,"LEFT",-ICON_GAP,0)
        tex:SetAlpha(1); tex:Show()
        item.icon=tex
    end
    SetSize(item,size)
    if scroll then
        flip=-flip
        item.dir=flip; item.drift=math.random(10,22)
        -- Follow the plate: the start point stays at a fixed offset from the anchor.
        if px then item.name=targetName; item.ax=px; item.ay=py; item.ox=x-px; item.oy=y-py end
    end
    table.insert(active,item)
    return item
end
-- school and periodic only matter for the scroll style; spell gives the icon.
function K.damageText.Spawn(amount,crit,targetName,school,periodic,spell)
    local mode=K.CombatTextMode()
    if (mode~="compact" and mode~="scroll") or not K.Number(amount) or amount<=0 then return end
    local text=string.format("%.0f",amount)
    if mode=="scroll" then
        local style=crit and SCROLL.crit or (periodic and SCROLL.periodic or SCROLL.normal)
        local c=SCHOOL[school] or SCHOOL.Physical
        local r,g,b=c[1],c[2],c[3]
        if crit then r,g,b=r+(1-r)*0.35,g+(1-g)*0.35,b+(1-b)*0.35 end
        if not crit and not periodic then
            -- Running average of the normal hits; a hit under half of it is grey and small.
            if average and amount<average*0.5 then style=SCROLL.small; r,g,b=0.62,0.62,0.62 end
            average=average and (average*0.9+amount*0.1) or amount
        end
        local icon
        if K.DB().combatTextIcons~=false then
            if spell then icon=SpellIcon(spell) else icon=MeleeIcon() end
        end
        local item=Add(text,style,r,g,b,targetName,true,crit and true or false,icon)
        item.crit=crit and true or false; item.periodic=periodic and true or false
        item.school=school; item.amount=amount
    else
        local style=crit and CRIT or NORMAL
        local item=Add(text,style,style.r,style.g,style.b,targetName,false,false)
        item.crit=crit and true or false; item.amount=amount
    end
end
-- A miss, dodge, parry ... of the player; only the scroll style shows these.
function K.damageText.SpawnMiss(missType,targetName,spell)
    if K.CombatTextMode()~="scroll" or not MISS_TEXT[missType] then return end
    local icon
    if spell and K.DB().combatTextIcons~=false then icon=SpellIcon(spell) end
    local item=Add(K.T(MISS_TEXT[missType]),SCROLL.miss,1,0.82,0.1,targetName,true,true,icon)
    item.miss=missType
end
local combat=CreateFrame("Frame",nil,UIParent)
for ev in pairs(K.tools.CombatEvents) do combat:RegisterEvent(ev) end
combat:SetScript("OnEvent",function()
    local hit=K.tools.ParseCombatLine(event,arg1)
    if not hit then return end
    if hit.kind=="damage" then K.damageText.Spawn(hit.amount,hit.critical,hit.targetName,hit.school,hit.periodic,hit.spell)
    elseif hit.kind=="miss" then K.damageText.SpawnMiss(hit.missType,hit.targetName,hit.spell) end
end)
host:SetScript("OnUpdate",function()
    local dt=tonumber(arg1) or 0
    local anchors={}   -- plate anchor per name, asked once per tick
    local i=1
    while i<=table.getn(active) do
        local item=active[i]
        item.age=item.age+dt
        local s=item.style
        local life=s.life
        if item.age>=life then Give(table.remove(active,i))
        else
            local t=item.age/life
            item.fs:ClearAllPoints()
            if item.scroll then
                if item.name then
                    local a=anchors[item.name]
                    if a==nil then
                        local ax,ay=K.PlateAnchor(item.name)
                        a=ax and {ax,ay} or false; anchors[item.name]=a
                    end
                    if a then
                        local dx,dy=a[1]-item.ax,a[2]-item.ay
                        if dx*dx+dy*dy<=FOLLOW_JUMP*FOLLOW_JUMP then
                            item.ax,item.ay=a[1],a[2]
                            item.x0,item.y0=a[1]+item.ox,a[2]+item.oy
                        end
                    end
                end
                -- Rise, drift to one side and fall back slightly at the end: peak at t~0.63
                -- (0.76 rise), ending at half the rise.
                local e=1-(1-t)*(1-t)
                item.x,item.y=item.x0+item.dir*item.drift*e,item.y0+s.rise*(2.4*t-1.9*t*t)
                item.fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",item.x,item.y)
                local alpha=(s.alpha or 1)*(t<0.7 and 1 or (1-t)/0.3)
                item.fs:SetAlpha(alpha)
                if item.icon then item.icon:SetAlpha(alpha) end
                if item.pop then
                    local size=math.floor(s.size*PopFactor(item.age)+0.5)
                    if size~=item.size then SetSize(item,size) end
                end
            else
                item.fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",item.x,item.y+s.rise*t)
                item.fs:SetAlpha(t<0.6 and 1 or (1-t)/0.4)
            end
            i=i+1
        end
    end
end)
K.On("PLAYER_ENTERING_WORLD",function() average=nil end)
K.On("PLAYER_LEAVING_WORLD",function() while table.getn(active)>0 do Give(table.remove(active)) end end)
