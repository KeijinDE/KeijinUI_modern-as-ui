-- 4.7.0: outgoing damage numbers from the game's own combat text feed (game 0.138/0.139, addon_docs section
-- "World-anchored combat text"). AZS_GetCombatTextEvents gives every own hit exactly as the game knows it (target,
-- amount, crit, school, spell, source incl. pets, summons and totems) with an anchor handle; no chat parsing, no
-- guessing the target by name. Works with the game's own numbers off and without nameplates.
-- Position "Am Gegner" (plate): each number is a label on the hit's anchor. AZS_ProjectCombatTextAnchors("follow")
-- turns the anchors into screen offsets from WorldFrame once per frame: over the living enemy, after its death over
-- the place it died, hidden while the spot is outside the view, text size scaled by distance. The labels are moved in
-- AZS_RegisterCombatTextFrameHandler (after the camera moved, before the paint), not in OnUpdate.
-- Position "Feste Stelle" and "Liste": same feed, shown by DamageText.lua / DamageTextList.lua as before.
-- Without the three functions (older game) nothing here is active and DamageText.lua keeps reading the chat lines.
-- Never both: while Active() is true, DamageText.lua ignores the combat messages.
-- Errors: reading, projecting and the handler body are guarded and counted separately. The documented temporary
-- answers (NOT_READY, NOT_IN_WORLD, STREAM_CHANGED) are no errors. After W.LIMIT failures in a row the module falls
-- back to the chat lines at once (Active() turns false, labels are dropped) and stays there until the next reload.
-- meterSource / meterSourceKey (0.139) are not part of the documentation we have; not used.
local K=KeijinUI
local W={}
K.damageText.world=W
W.MAX=60            -- labels at once; the oldest goes first
W.MAX_AGE=1.5       -- seconds: a hit older than this when it is read (delayed batch) is not shown
W.MAX_READS=4       -- batches read per frame (256 events each)
W.MERGE=0.12        -- seconds in which equal hits are one number
W.LIMIT=3           -- consecutive failures of one kind before falling back to the chat lines
W.REF_UPY=40        -- UI units per yard at which the text keeps its size (about 30 yards away); sqrt eases the change
W.MIN_SCALE=0.6
W.MAX_SCALE=1.4
W.HEAD_YARDS=0      -- extra height above the anchor in yards, to tune in the game
local ICON_GAP=2
local OWN={compact=true,scroll=true,rise=true}
local TEMPORARY={NOT_READY=true,NOT_IN_WORLD=true,STREAM_CHANGED=true}
local SCHOOLS={{1,"Physical"},{2,"Holy"},{4,"Fire"},{8,"Nature"},{16,"Frost"},{32,"Shadow"},{64,"Arcane"}}
local host=CreateFrame("Frame","KeijinUIDamageTextWorld",UIParent)
host:SetFrameStrata("BACKGROUND"); host:SetWidth(1); host:SetHeight(1)
host:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0); host:EnableMouse(false)
local labels={}       -- active labels, oldest first
local spare={}        -- label records that can be reused (their FontStrings and icons stay)
local ids={}          -- anchor ids handed to the projection; reused every frame
local idCount=0
local icons={}        -- ability name -> icon path or false, so a hit does not search the spell book again
local cursor,lastTime,lastError
local readFailures,projectFailures,frameFailures=0,0,0
local flip=1
local textSize=1      -- K.damageText.TextSize(), read at most once per frame and only when a number needs it
local frameNo,sizeFrame=0,-1
local wasActive=false
W.broken=false
W.labels=labels

function W.Available()
    return not W.broken and type(AZS_GetCombatTextEvents)=="function" and type(AZS_ProjectCombatTextAnchors)=="function"
        and type(AZS_RegisterCombatTextFrameHandler)=="function"
end
-- True while the feed supplies the numbers (own styles, module on). Then the chat lines are not read for numbers.
function W.Active()
    return W.Available() and K.ModuleOn("combatText") and OWN[K.CombatTextMode()] and true or false
end

-- Single bit of the school mask (the highest one for mixed schools) -> the key DamageText.lua colours by.
local function SchoolOf(mask)
    if not K.Number(mask) or mask<=0 then return "Physical" end
    local key="Physical"
    for i=1,7 do
        if math.mod(math.floor(mask/SCHOOLS[i][1]),2)==1 then key=SCHOOLS[i][2] end
    end
    return key
end
W.SchoolOf=SchoolOf

-- Cut the id list to n entries (entries above n are nil, from the end so the length stays right).
local function TrimIds(n)
    for j=idCount,n+1,-1 do ids[j]=nil end
    idCount=n
end
local function Release(label)
    label.fs:Hide(); label.fs:SetAlpha(1)
    if label.icon then label.icon:Hide() end
    label.shown=false; label.hasIcon=false
    table.insert(spare,label)
end
function W.Clear()
    while table.getn(labels)>0 do Release(table.remove(labels)) end
    TrimIds(0)
end
-- Forget the stream: the next read subscribes at the current tail (no history, so no old numbers).
function W.Reset()
    W.Clear(); cursor=nil; lastTime=nil
end
-- Too many failures in a row: stop using the feed. The chat lines are free again at once.
local function Fallback()
    W.broken=true
    W.Reset()
end
local function Count(kind)
    if kind=="read" then readFailures=readFailures+1
    elseif kind=="project" then projectFailures=projectFailures+1
    else frameFailures=frameFailures+1 end
    if readFailures>=W.LIMIT or projectFailures>=W.LIMIT or frameFailures>=W.LIMIT then Fallback() end
end

local function NewLabel()
    local label=table.remove(spare)
    if not label then
        local fs=host:CreateFontString(nil,"OVERLAY")
        label={fs=fs}
    end
    return label
end
local function Size()
    if sizeFrame~=frameNo then sizeFrame=frameNo; textSize=K.damageText.TextSize() end
    return textSize
end
local function SetSize(label,size)
    -- Ordinary camera scaling uses 2 px steps. The short pop gets bounded 1 px steps.
    local step=label.pop and label.age<0.24 and 1 or 2
    local shown=math.max(step,math.floor(size*(label.scale or 1)*Size()/step+0.5)*step)
    if shown~=label.fontSize or label.font~=K.font then
        label.fontSize=shown; label.font=K.font
        label.fs:SetFont(K.font,shown,"OUTLINE")
        if label.hasIcon then label.icon:SetWidth(shown); label.icon:SetHeight(shown) end
    end
end

-- Icon of an ability, false when there is none or icons are off. Only found icons are cached, per ability name:
-- no weapon/melee icon (no name; it changes with the gear) and no failure (the spell book may be late).
-- The cache is emptied on SPELLS_CHANGED, PLAYER_ENTERING_WORLD, UNIT_INVENTORY_CHANGED (player), STREAM_CHANGED and
-- when the module is switched on again; those hooks are registered without an owner so they run while the module is off.
function W.IconOf(name)
    if K.DB().combatTextIcons==false then return false end
    if not name or name=="" then return K.SpellIcon(name) or false end
    local icon=icons[name]
    if icon==nil then
        icon=K.SpellIcon(name)
        if icon then icons[name]=icon else icon=false end
    end
    return icon
end
function W.ForgetIcons() for k in pairs(icons) do icons[k]=nil end end
-- The icon the event documents (checked with K.RealIcon, the result cached per path), else the ability's own.
local function IconFor(ev)
    if K.DB().combatTextIcons==false then return false end
    local given=ev.icon
    if type(given)=="string" and given~="" then
        local ok=icons[given]
        if ok==nil then ok=K.RealIcon(given); icons[given]=ok or false end
        if ok then return ok end
    end
    return W.IconOf(ev.abilityName)
end

-- One hit with a ready anchor, shown over the enemy.
local function AddLabel(ev,text,style,r,g,b,iconPath,scroll,pop,mode,spell,school,crit,periodic,noMerge)
    -- A new number of the same target starts a line higher while the previous one is still low, so they do not cover each other.
    local oy=0
    if style.straight then
        for i=1,table.getn(labels) do
            local prior=labels[i]
            if prior.style.straight and prior.targetId==ev.targetId and prior.age<prior.style.life/3 then
                oy=math.max(oy,prior.oy+style.size*Size()*1.2)
            end
        end
    end
    -- Full: the oldest ordinary number goes first, a critical hit is kept longer.
    if table.getn(labels)>=W.MAX then
        local oldest=1
        for i=1,table.getn(labels) do if not labels[i].crit then oldest=i; break end end
        Release(table.remove(labels,oldest))
    end
    local label=NewLabel()
    label.anchorId=ev.anchorId; label.targetId=ev.targetId; label.targetName=ev.targetName
    label.age=0; label.style=style; label.scroll=scroll; label.pop=pop
    -- Bundling fields; a miss has none (noMerge: its mode is cleared so no hit matches it).
    label.mode=not noMerge and mode or nil; label.spell=spell; label.school=school; label.critical=crit; label.periodic=periodic
    label.amount=ev.amount; label.hits=1; label.crit=ev.critical and true or false
    label.jx=math.random(-14,14); label.oy=oy; label.scale=1
    flip=-flip; label.dir=flip; label.drift=math.random(10,22)
    label.shown=false; label.alpha=nil; label.fontSize=nil
    label.x=nil; label.y=nil
    local fs=label.fs
    fs:ClearAllPoints()
    fs:SetTextColor(r,g,b)
    -- SetSize supplies the font before SetText, including newly created FontStrings.
    fs:Hide()
    -- hasIcon is decided per use: a reused label never shows the icon of its previous number.
    label.hasIcon=iconPath and true or false
    if iconPath then
        local tex=label.icon
        if not tex then tex=host:CreateTexture(nil,"OVERLAY"); label.icon=tex end
        tex:SetTexture(iconPath); tex:SetTexCoord(0.08,0.92,0.08,0.92)
        tex:ClearAllPoints(); tex:SetPoint("RIGHT",fs,"LEFT",-ICON_GAP,0)
        tex:Hide()
    elseif label.icon then label.icon:Hide() end
    SetSize(label,pop and math.floor(style.size*K.damageText.PopFactor(0)+0.5) or style.size)
    fs:SetText(text)
    table.insert(labels,label)
end

local function Handle(ev,now)
    if type(ev)~="table" then return end
    if ev.presentedAt and now-ev.presentedAt>W.MAX_AGE then return end
    local mode=K.CombatTextMode()
    local world=K.damageText.Position()=="plate" and ev.anchorStatus=="ready" and ev.anchorId
    if ev.kind=="damage" then
        local amount=ev.amount
        if not K.Number(amount) or amount<=0 then return end
        local school=SchoolOf(ev.schoolMask)
        local crit=ev.critical and true or false
        local periodic=ev.periodic and true or false
        if not world then
            K.damageText.Spawn(amount,crit,ev.targetName,school,periodic,ev.abilityName)
            return
        end
        -- "Flächentreffer bündeln" on: equal hits (same ability, school and kind) within a short burst are one number
        -- ("123 x2") over all targets, shown at the anchor of the first hit. Off: one bundle per target.
        -- Compared field by field: no key string is built per hit.
        local merge=K.DB().combatTextMerge~=false
        local spell=ev.abilityName
        for i=table.getn(labels),1,-1 do
            local prior=labels[i]
            if prior.age<=W.MERGE and prior.mode==mode and prior.spell==spell and prior.school==school and prior.critical==crit
                and prior.periodic==periodic and (merge or prior.targetId==ev.targetId) then
                prior.amount=prior.amount+amount; prior.hits=prior.hits+1
                prior.fs:SetText(string.format("%.0f",prior.amount).." x"..prior.hits)
                return
            end
        end
        local small=K.damageText.Small(mode,amount,crit,periodic)
        local icon=false
        if mode~="compact" then icon=IconFor(ev) end
        local style,r,g,b,iconPath,scroll,pop=K.damageText.Describe(mode,crit,school,periodic,ev.abilityName,small,icon)
        AddLabel(ev,string.format("%.0f",amount),style,r,g,b,iconPath,scroll,pop,mode,spell,school,crit,periodic)
    elseif ev.kind=="miss" then
        if mode~="scroll" and mode~="rise" then return end
        local key=type(ev.result)=="table" and ev.result.key
        local word=key and K.damageText.MissText[key]
        local text=word and K.T(word)
        -- A key we have no word for: the game's own word, when it gives one.
        if not text and type(ev.result)=="table" and type(ev.result.text)=="string" and ev.result.text~="" then text=ev.result.text end
        if not text then return end
        if not world then
            K.damageText.SpawnMiss(key,ev.targetName,ev.abilityName,not word and text or nil)
            return
        end
        local icon=false
        if ev.abilityName then icon=IconFor(ev) end
        AddLabel(ev,text,K.damageText.MissStyle(mode),1,0.82,0.1,icon,true,true,mode,nil,nil,nil,nil,true)
    end
end

-- Read what the game gathered since the last frame.
local function Read(now)
    for _=1,W.MAX_READS do
        local ok,batch,err=pcall(AZS_GetCombatTextEvents,cursor)
        if not ok then Count("read"); return end
        if not batch and err and err.code=="STREAM_CHANGED" then
            W.Clear(); cursor=nil; W.ForgetIcons()
            ok,batch,err=pcall(AZS_GetCombatTextEvents,nil)
            if not ok then Count("read"); return end
        end
        if type(batch)~="table" then
            -- NOT_READY (first frame after /reload), NOT_IN_WORLD: temporary, no error. Anything else counts.
            if type(err)=="table" and TEMPORARY[err.code] then return end
            Count("read"); return
        end
        readFailures=0
        local first=cursor==nil
        cursor=batch.cursor
        if first then return end   -- subscribed at the tail; the game gives no history
        local events=batch.events
        if type(events)=="table" then
            for i=1,table.getn(events) do Handle(events[i],now) end
        end
        if not batch.hasMore then return end
    end
end

local function Hide(label)
    if label.shown then label.fs:Hide(); if label.hasIcon then label.icon:Hide() end; label.shown=false end
end
local function HideAll()
    for j=1,table.getn(labels) do Hide(labels[j]) end
end
-- Age the labels, project the live ones and place them. One projection call per frame, only for labels still alive.
local function Place(dt)
    local i=1
    while i<=table.getn(labels) do
        local label=labels[i]
        label.age=label.age+dt
        if label.age>=label.style.life then Release(table.remove(labels,i)) else i=i+1 end
    end
    local count=table.getn(labels)
    if count==0 then TrimIds(0); return end
    for j=1,count do ids[j]=labels[j].anchorId end
    TrimIds(count)
    local ok,projection,err=pcall(AZS_ProjectCombatTextAnchors,ids,"follow")
    -- No valid projection: the numbers have no place this frame, so they are hidden (their lifetime keeps running).
    if not ok then HideAll(); Count("project"); return end
    if type(projection)~="table" or type(projection.entries)~="table" then
        HideAll()
        if not (type(err)=="table" and TEMPORARY[err.code]) then Count("project") end
        return
    end
    projectFailures=0
    local entries=projection.entries
    local ui=K.damageText
    local dead=false
    -- The projection is in WorldFrame units, SetPoint offsets are in the label's own units (host, under UIParent's scale):
    -- k turns the first into the second. One pair of scale reads per frame; unknown or 0 means 1.
    local k=1
    local ws=WorldFrame and WorldFrame.GetEffectiveScale and WorldFrame:GetEffectiveScale()
    local hs=host:GetEffectiveScale()
    if K.Number(ws) and K.Number(hs) and ws>0 and hs>0 then k=ws/hs end
    for j=1,count do
        local label,entry=labels[j],entries[j]
        if not entry then Hide(label)
        else
            local state=entry.state
            local upy=entry.uiUnitsPerYard
            if state=="onScreen" and K.Number(entry.x) and K.Number(entry.y) then
                local s=label.style
                local t=label.age/s.life
                if not K.Number(upy) then upy=W.REF_UPY end
                -- upy is WorldFrame units per yard; REF_UPY is in host (UI) units, so compare upy*k.
                local factor=math.max(W.MIN_SCALE,math.min(W.MAX_SCALE,math.sqrt(upy*k/W.REF_UPY)))
                label.scale=factor
                local dx,lift,alpha=0,0,1
                if s.straight then lift,alpha=ui.RiseMotion(s,t)
                elseif label.scroll then
                    local e=1-(1-t)*(1-t)
                    dx=label.dir*label.drift*e; lift=s.rise*(2.4*t-1.9*t*t); alpha=ui.Opacity(s,t)
                else lift=s.rise*t; alpha=ui.Opacity(s,t) end
                SetSize(label,label.pop and math.floor(s.size*ui.PopFactor(label.age)+0.5) or s.size)
                local fs=label.fs
                -- Projection x/y and the head height are WorldFrame units (game doc) and get k; the extras (jitter, drift,
                -- rise) are already host units and do not.
                local x=math.floor(entry.x*k+(label.jx+dx)*factor+0.5)
                local y=math.floor((entry.y+W.HEAD_YARDS*upy)*k+(label.oy+lift)*factor+0.5)
                if label.x~=x or label.y~=y then
                    label.x=x; label.y=y
                    fs:ClearAllPoints()
                    fs:SetPoint("BOTTOM",WorldFrame,"BOTTOMLEFT",x,y)
                end
                if label.alpha~=alpha then
                    label.alpha=alpha; fs:SetAlpha(alpha)
                    if label.hasIcon then label.icon:SetAlpha(alpha) end
                end
                if not label.shown then
                    fs:Show(); if label.hasIcon then label.icon:Show() end
                    label.shown=true
                end
            elseif state=="expired" or state=="unknownAnchor" or state=="worldChanged" then
                label.age=label.style.life; dead=true
            else Hide(label) end   -- offscreen, behind the camera, clipped, notReady: hidden, the lifetime keeps running
        end
    end
    if dead then
        local k=1
        while k<=table.getn(labels) do
            if labels[k].age>=labels[k].style.life then Release(table.remove(labels,k)) else k=k+1 end
        end
    end
end

local function Step()
    if not W.Active() then
        wasActive=false
        if cursor~=nil or table.getn(labels)>0 then W.Reset() end
        return
    end
    if not wasActive then wasActive=true; W.ForgetIcons() end   -- switched on again: fresh values
    frameNo=frameNo+1
    local now=GetTime()
    local dt=lastTime and now-lastTime or 0
    lastTime=now
    if dt<0 then dt=0 elseif dt>0.25 then dt=0.25 end
    Read(now)
    if not W.broken then Place(dt) end
end
-- Called once per world frame after the camera moved (AZS_RegisterCombatTextFrameHandler). The body is guarded:
-- an error is reported once per message, counted, and never leaves old numbers frozen on the screen.
function W.Frame()
    local ok,err=pcall(Step)
    if ok then frameFailures=0; return end
    if err~=lastError then
        lastError=err
        if type(geterrorhandler)=="function" then geterrorhandler()(err) end
    end
    HideAll()
    Count("frame")
end

function W.Register()
    if W.Available() then AZS_RegisterCombatTextFrameHandler(W.Frame) end
end
W.Register()
K.On("PLAYER_ENTERING_WORLD",W.Register,"combatText")
K.On("PLAYER_ENTERING_WORLD",W.ForgetIcons)
K.On("SPELLS_CHANGED",W.ForgetIcons)
K.On("UNIT_INVENTORY_CHANGED",function(_,unit) if unit=="player" then W.ForgetIcons() end end)
K.On("PLAYER_LEAVING_WORLD",function() W.Reset() end,"combatText")
local stop=K.damageText.Stop
function K.damageText.Stop() W.Reset(); stop() end
