-- Floating damage numbers with three own styles (Core.lua, K.CombatTextMode). compact: the Survivor UI
-- style, normal hits very small and white, only critical hits large and yellow, rising straight up.
-- scroll: numbers rise with ease out and drift to the left or right, coloured by damage school, with the
-- spell icon on the left; small normal hits are grey, crits are large; crits and misses start with a pop,
-- they follow the target's nameplate and misses are shown too.
-- rise: like scroll, but straight up (no drift), shorter way and smaller (RISE table).
-- off and native draw nothing here. The native floating text (cvar CombatDamage) cannot do this:
-- one colour per source, no size for crits (benilla combat_text/mod.rs), so Core.lua keeps it off
-- and this module draws from the same native combat messages the parser reads (CombatParser.lua).
-- Position: above the visible nameplate of the hit enemy (Nameplates.lua, K.PlateAnchor). Without
-- a plate (nameplates off, plate not on screen) the numbers rise over the screen centre, the
-- player's usual place. There is no world position in the addon API.
-- 2.1.0: that start point is the movable layout element KeijinUICombatTextAnchor (Alt to move, Alt and
-- mouse wheel to scale). Option "Position" (K.DB().combatTextPosition): plate (default) or fixed, where
-- every number starts in the anchor and follows no plate.
local K=KeijinUI
local NORMAL={size=10,r=1,g=1,b=1,life=0.8,rise=26,fade=0.6}
local CRIT={size=26,r=1,g=0.82,b=0.1,life=1.3,rise=44,fade=0.6}
-- scroll style: size, life (s) and rise per kind; colours per school key (CombatParser.lua SchoolKey).
-- pop: crits and misses start small and swell to double size, then settle (see PopFactor).
-- small: normal hits under half of the running average are grey and small.
local SCROLL={normal={size=12,life=1.1,rise=60,fade=0.7},crit={size=30,life=1.5,rise=45,fade=0.7,pop=true},
    periodic={size=11,life=1.1,rise=60,fade=0.7,alpha=0.85},small={size=11,life=1.1,rise=60,fade=0.7},
    miss={size=13,life=1.2,rise=60,fade=0.7,pop=true}}
-- rise style: straight up with ease out, fades slowly (full opacity for the first 30 %, then evenly to 0).
-- straight marks the style for the update loop and the preview; same fields as SCROLL.
local RISE={normal={size=11,life=1.6,rise=34,straight=true,fade=0.3},crit={size=22,life=1.8,rise=40,pop=true,straight=true,fade=0.3},
    periodic={size=10,life=1.6,rise=34,alpha=0.85,straight=true,fade=0.3},small={size=10,life=1.6,rise=34,straight=true,fade=0.3},
    miss={size=12,life=1.6,rise=34,pop=true,straight=true,fade=0.3}}
-- Quieter variants apply only to the explicitly selected fixed window. The ordinary
-- nameplate mode (including its no-plate fallback) retains the original presentation.
local FIXED={}
local function FixedStyle(base,life,rise,fade)
    local s={}
    for k,v in pairs(base) do s[k]=v end
    s.life,s.rise,s.fade=life,rise,fade; FIXED[base]=s
end
FixedStyle(NORMAL,.55,20,.15)
FixedStyle(SCROLL.normal,.65,34,.18); FixedStyle(SCROLL.periodic,.6,28,.15)
FixedStyle(SCROLL.small,.55,26,.15); FixedStyle(SCROLL.miss,.8,30,.2)
FixedStyle(RISE.normal,.65,24,.15); FixedStyle(RISE.periodic,.6,20,.15)
FixedStyle(RISE.small,.55,20,.15); FixedStyle(RISE.miss,.8,24,.2)
local function Presentation(s)
    if K.DB().combatTextPosition=="fixed" then return FIXED[s] or s end
    return s
end
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
host:SetFrameStrata("BACKGROUND"); host:SetWidth(1); host:SetHeight(1)
host:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0); host:EnableMouse(false)
local active,pool,iconPool={}, {}, {}
K.damageText={active=active}
local function Take()
    local fs=table.remove(pool)
    -- Game 0.101 refuses SetText before a font is set; SetSize sets the real size afterwards.
    if not fs then fs=host:CreateFontString(nil,"OVERLAY"); fs:SetFont(K.font,14,"OUTLINE") end
    return fs
end
local function Give(item)
    item.fs:Hide(); table.insert(pool,item.fs)
    if item.icon then item.icon:Hide(); table.insert(iconPool,item.icon) end
end
-- Shared, side-effect-free presentation for live hits and the settings preview.
-- The preview never spawns world hits or updates the running damage average.
function K.damageText.Describe(mode,crit,school,periodic,spell,small)
    if mode=="compact" then
        local s=crit and CRIT or NORMAL
        return Presentation(s),s.r,s.g,s.b,nil,false,false
    end
    if mode~="scroll" and mode~="rise" then return end
    local T=mode=="rise" and RISE or SCROLL
    local s=crit and T.crit or (periodic and T.periodic or T.normal)
    local c=SCHOOL[school] or SCHOOL.Physical
    local r,g,b=c[1],c[2],c[3]
    if crit then r,g,b=r+(1-r)*.35,g+(1-g)*.35,b+(1-b)*.35 end
    if small and not crit and not periodic then s=T.small; r,g,b=.62,.62,.62 end
    local icon
    if K.DB().combatTextIcons~=false then icon=K.SpellIcon(spell) end
    return Presentation(s),r,g,b,icon,true,crit and true or false
end
-- Font size and icon side always match.
local function SetSize(item,size)
    item.size=size
    local shown=math.max(1,math.floor(size*(item.scale or 1)*K.damageText.TextSize()+0.5))
    item.fs:SetFont(K.font,shown,"OUTLINE")
    if item.icon then item.icon:SetWidth(shown); item.icon:SetHeight(shown) end
end
-- Invisible layout anchor: the centre is the start point of the numbers. Without a saved layout it sits
-- where Start() always started (screen centre, 50 above), so nothing changes until the player moves it.
local anchor=CreateFrame("Frame","KeijinUICombatTextAnchor",UIParent)
anchor:SetWidth(200); anchor:SetHeight(120); anchor:SetFrameStrata("BACKGROUND"); anchor:EnableMouse(false)
K.layout.Register("combattext",anchor,"Kampftext",function(f)
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",0,50)
end,{hidden=true})
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.layout.Place("combattext") end end,"combatText")
K.damageText.anchor=anchor
-- Centre of the anchor in UIParent units and its scale factor against the interface (1 = unscaled).
local function AnchorCentre()
    local w,h=K.UIWidth() or 1024,K.UIHeight() or 768
    local l,b=anchor:GetLeft(),anchor:GetBottom()
    local ratio=anchor:GetEffectiveScale()/UIParent:GetEffectiveScale()
    if not K.Number(l) or not K.Number(b) or not K.Number(ratio) or ratio<=0 then return w/2,h/2+50,1 end
    return (l+anchor:GetWidth()/2)*ratio,(b+anchor:GetHeight()/2)*ratio,ratio
end
function K.damageText.Position() return K.DB().combatTextPosition=="fixed" and "fixed" or "plate" end
function K.damageText.SetPosition(value) K.DB().combatTextPosition=value=="fixed" and "fixed" or nil end
-- Font size of the numbers as a factor (0.5 to 2, K.DB().combatTextSize, settings slider). Only the text
-- grows; the anchor and its Alt mouse wheel scale stay as they are.
function K.damageText.TextSize()
    local value=K.DB().combatTextSize
    if not K.Number(value) then return 1 end
    return math.max(0.5,math.min(2,value))
end
function K.damageText.SetTextSize(value)
    value=tonumber(value)
    if not K.Number(value) then return end
    value=math.max(0.5,math.min(2,value))
    K.DB().combatTextSize=math.abs(value-1)>0.001 and value or nil
end
local function Start()
    local x,y,ratio=AnchorCentre()
    return x+math.random(-50,50),y-10+math.random(0,20),ratio
end
-- Numbers never cover the unit frames, the skill bar or the counter row: a start point inside such
-- a frame (an enemy standing behind it) is moved up to just above its top edge, the numbers only rise.
local tickRects
local function Rectangles()
    local result={}
    local frames={K.units and K.units.player,K.units and K.units.target,
        getglobal("KeijinUISkills"),getglobal("KeijinUITally"),getglobal("KeijinUIResources"),getglobal("KeijinUIStoredLevels")}
    local ui=UIParent:GetEffectiveScale()
    for _,f in pairs(frames) do
        if f.IsShown and f:IsShown() and f.GetLeft and f:GetAlpha()>0 then
            local l,b,r,t=f:GetLeft(),f:GetBottom(),f:GetRight(),f:GetTop()
            local ratio=f:GetEffectiveScale()/ui
            if K.Number(l) and K.Number(b) and K.Number(r) and K.Number(t) then
                table.insert(result,{l*ratio,b*ratio,r*ratio,t*ratio})
            end
        end
    end
    return result
end
local function KeepClear(x,y,halfWidth,height)
    local bounded=halfWidth~=nil
    halfWidth,height=halfWidth or 12,height or 14
    local width,screenHeight=K.UIWidth(),K.UIHeight()
    if bounded then
        x=math.max(halfWidth+4,math.min(width-halfWidth-4,x))
        y=math.max(4,math.min(screenHeight-height-4,y))
    end
    local rectangles=tickRects or Rectangles()
    for _=1,8 do
        local moved=false
        for _,rect in ipairs(rectangles) do
            local l,b,r,t=unpack(rect)
            if x+halfWidth>=l-4 and x-halfWidth<=r+4 and y+height>=b-4 and y<=t+4 then
                if not bounded or t+8+height<screenHeight-4 then y=t+8
                elseif b-height-8>4 then y=b-height-8
                elseif l-halfWidth-8>halfWidth then x=l-halfWidth-8
                else x=r+halfWidth+8 end
                moved=true
            end
        end
        if not moved then break end
    end
    local clear=true
    if bounded then
        if x-halfWidth<0 or x+halfWidth>width or y<0 or y+height>screenHeight then clear=false end
        for _,rect in ipairs(rectangles) do
            local l,b,r,t=unpack(rect)
            if x+halfWidth>=l-4 and x-halfWidth<=r+4 and y+height>=b-4 and y<=t+4 then clear=false end
        end
    end
    return x,y,clear
end
K.damageText.KeepClear=KeepClear
local function Footprint(item)
    -- Include the largest pop, the whole label and its left-hand icon. A plate
    -- can move into a unit frame after spawn, so this is checked every tick.
    local scale=item.scale or 1
    local size=item.style.size*scale*K.damageText.TextSize()*(item.pop and 2 or 1)
    local measured=item.fs.GetStringWidth and item.fs:GetStringWidth()
    local width=type(measured)=="number" and measured>0 and measured or string.len(item.fs:GetText() or "")*size*.65
    if type(measured)=="number" and measured>0 and item.size and item.size>0 then width=measured*size/(item.size*scale*K.damageText.TextSize()) end
    return width/2+(item.icon and size+ICON_GAP or 0)+4,size*1.3
end
local function Place(item,x,y)
    local half,height=Footprint(item)
    local clear
    x,y,clear=KeepClear(x,y,half,height)
    item.screenX,item.screenY,item.halfWidth,item.textHeight=x,y,half,height
    item.fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",x,y)
    item.blocked=not clear
    if not clear then item.fs:SetAlpha(0); if item.icon then item.icon:SetAlpha(0) end end
end
-- Size factor of the pop: 0.5 to 2.0 in 0.12 s (ease out), back to 1.0 by 0.24 s.
local function PopFactor(age)
    if age>=0.24 then return 1 end
    if age<0.12 then local u=1-age/0.12; return 0.5+1.5*(1-u*u*u) end
    local v=(age-0.12)/0.12
    return 2-v*v
end
K.damageText.PopFactor=PopFactor
-- One fade curve for live numbers, their icons and the isolated settings preview.
function K.damageText.Opacity(s,t)
    local hold=s.fade or 0.6
    return (s.alpha or 1)*math.max(0,math.min(1,(1-t)/(1-hold)))
end
-- Rise and fade of the rise style: lift in pixels and opacity at the share t of the life.
function K.damageText.RiseMotion(s,t)
    local lift=s.rise*(1-(1-t)*(1-t))
    local alpha=K.damageText.Opacity(s,t)
    return lift,alpha
end
-- Common part: place, style and register one number (scroll and rise: rising, otherwise compact).
-- icon: texture path shown left of a scroll number (nil: none, the text stays centred).
local function Add(text,style,r,g,b,targetName,scroll,pop,icon)
    local x,y,px,py,scale
    if K.damageText.Position()~="fixed" and K.PlateAnchor and targetName then px,py=K.PlateAnchor(targetName) end
    if px then
        local _,_,ratio=AnchorCentre()
        x,y,scale=px+math.random(-14,14),py,ratio
    else x,y,scale=Start() end
    if style.straight then
        -- A new number of the same target starts one line higher while the previous one is still in the
        -- lower third of its way, so they do not cover each other.
        local lift=0
        for i=1,table.getn(active) do
            local prior=active[i]
            if prior.style.straight and prior.tn==targetName and prior.age<prior.style.life/3
                and math.abs(prior.x0-x)<40 then
                lift=math.max(lift,prior.y0-y+style.size*K.damageText.TextSize()*1.2)
            end
        end
        -- Do not let a burst recursively stack new hits toward the screen edge.
        y=y+(K.damageText.Position()=="fixed" and math.min(lift,28*(scale or 1)) or lift)
    end
    x,y=KeepClear(x,y)
    if table.getn(active)>=MAX then
        -- Heavy ordinary bursts must not evict a still readable critical hit first.
        local oldest=1
        if K.damageText.Position()=="fixed" then
            for i,prior in ipairs(active) do if not prior.crit then oldest=i; break end end
        end
        Give(table.remove(active,oldest))
    end
    local fs=Take()
    local size=style.size
    if pop then size=math.floor(size*PopFactor(0)+0.5) end
    fs:SetTextColor(r,g,b)
    fs:SetText(text)
    fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",x,y)
    fs:SetAlpha(1); fs:Show()
    local item={fs=fs,x=x,y=y,x0=x,y0=y,age=0,style=style,scroll=scroll,pop=pop,scale=scale,tn=targetName}
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
    fs:ClearAllPoints(); Place(item,x,y)
    return item
end
-- school and periodic only matter for the scroll style; spell gives the icon.
function K.damageText.Spawn(amount,crit,targetName,school,periodic,spell)
    local mode=K.CombatTextMode()
    if mode=="off" or mode=="native" or not K.Number(amount) or amount<=0 then return end
    if K.damageText.list and K.damageText.list.On() then return K.damageText.list.PushDamage(amount,crit,targetName,school,periodic,spell) end
    local text=string.format("%.0f",amount)
    -- Merge a short burst of the same ability/kind, including area hits on
    -- several enemies. Critical and ordinary hits always stay separate.
    local mergeKey=mode..":"..tostring(spell or "melee")..":"..tostring(school)..":"..tostring(crit and true or false)..":"..tostring(periodic and true or false)
    if K.DB().combatTextMerge~=false then
        for i=table.getn(active),1,-1 do
            local prior=active[i]
            if prior.mergeKey==mergeKey and prior.age<=0.12 then
                prior.amount=prior.amount+amount; prior.hits=(prior.hits or 1)+1
                prior.fs:SetText(string.format("%.0f",prior.amount).." x"..prior.hits)
                if prior.targetName~=targetName then prior.name=nil end
                prior.fs:ClearAllPoints(); Place(prior,prior.screenX or prior.x,prior.screenY or prior.y)
                return
            end
        end
    end
    local small
    if (mode=="scroll" or mode=="rise") and not crit and not periodic then
        small=average and amount<average*.5
        average=average and (average*.9+amount*.1) or amount
    end
    local style,r,g,b,icon,scroll,pop=K.damageText.Describe(mode,crit,school,periodic,spell,small)
    local item=Add(text,style,r,g,b,targetName,scroll,pop,icon)
    item.crit=crit and true or false; item.amount=amount
    if scroll then item.periodic=periodic and true or false; item.school=school end
    item.mergeKey=mergeKey; item.targetName=targetName; item.hits=1
end
-- A miss, dodge, parry ... of the player; only the scroll style shows these.
function K.damageText.SpawnMiss(missType,targetName,spell)
    local mode=K.CombatTextMode()
    if (mode~="scroll" and mode~="rise") or not MISS_TEXT[missType] then return end
    if K.damageText.list and K.damageText.list.On() then return K.damageText.list.PushMiss(K.T(MISS_TEXT[missType]),targetName,spell,missType) end
    local icon
    if spell and K.DB().combatTextIcons~=false then icon=K.SpellIcon(spell) end
    local item=Add(K.T(MISS_TEXT[missType]),Presentation((mode=="rise" and RISE or SCROLL).miss),1,0.82,0.1,targetName,true,true,icon)
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
    if table.getn(active)==0 then return end
    local dt=tonumber(arg1) or 0
    tickRects=Rectangles()
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
                local alpha
                if s.straight then
                    local lift
                    lift,alpha=K.damageText.RiseMotion(s,t)
                    item.x,item.y=item.x0,item.y0+lift
                else
                    local e=1-(1-t)*(1-t)
                    item.x,item.y=item.x0+item.dir*item.drift*e,item.y0+s.rise*(2.4*t-1.9*t*t)
                    alpha=K.damageText.Opacity(s,t)
                end
                item.fs:SetAlpha(alpha)
                if item.icon then item.icon:SetAlpha(alpha) end
                if item.pop then
                    local size=math.floor(s.size*PopFactor(item.age)+0.5)
                    if size~=item.size then SetSize(item,size) end
                end
                Place(item,item.x,item.y)
            else
                Place(item,item.x,item.y+s.rise*t)
                item.fs:SetAlpha(K.damageText.Opacity(s,t))
            end
            i=i+1
        end
    end
    tickRects=nil
end)
K.On("PLAYER_ENTERING_WORLD",function() average=nil end,"combatText")
K.On("PLAYER_LEAVING_WORLD",function() while table.getn(active)>0 do Give(table.remove(active)) end end,"combatText")
K.damageText.drivers={combat,host}
function K.damageText.Stop()
    while table.getn(active)>0 do Give(table.remove(active)) end
    if K.resourceText then K.resourceText.Clear() end
    local db=K.DB()
    if db.originalCombatDamage~=nil then SetCVar("CombatDamage",db.originalCombatDamage) end
    if db.originalShowCombatText~=nil then SHOW_COMBAT_TEXT=db.originalShowCombatText end
    if CombatText_UpdateDisplayedMessages then CombatText_UpdateDisplayedMessages() end
end
