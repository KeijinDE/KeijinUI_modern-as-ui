-- Own progress comparison: kill progress and recent damage, aligned to the native run clock.
local K=KeijinUI
local P={}
K.pace=P
function P.On() return K.ModuleOn("analysis") and K.DB().pace~=false end
function P.Set(on) K.DB().pace=on and true or false end
function P.AccountOn() return P.On() and K.DB().paceAccount~=false end
function P.SetAccount(on) K.DB().paceAccount=on and true or false end
local function AccountKey(key)
    if type(key)~="string" then return nil end
    return string.gsub(key,"^([^:]*):[^:]*:","%1:all:")
end
local function Key(z,class)
    z=z or {}
    return tostring(z.zone)..":"..tostring(class)..":"..tostring(z.diff or "?")..":"..tostring(z.mods or "?")
end
function P.Observe(open,r,z)
    if open.won or not K.Number(r.t) or not K.Number(r.kills) then return end
    open.paceKey=open.paceKey or Key(z,open.class)
    open.paceSamples=open.paceSamples or {}
    -- Only actual received reports, never interpolated kills or filled gaps.
    local bucket=tostring(math.floor(r.t/15))
    if not open.paceSamples[bucket] then
        open.paceSamples[bucket]={t=r.t,kills=r.kills,dealt=K.Number(r.dealt) and r.dealt or nil}
    end
end
function P.Record(open)
    if open.paceRecorded or not open.counted or not open.paceKey or not open.paceSamples then return end
    local samples={}; for key,v in pairs(open.paceSamples) do samples[key]={t=v.t,kills=v.kills,dealt=v.dealt} end
    local db=K.DB(); if type(db.paceHistory)~="table" then db.paceHistory={} end
    table.insert(db.paceHistory,{key=open.paceKey,samples=samples,won=open.won and true or false,snapshotId=open.snapshotId})
    while table.getn(db.paceHistory)>120 do table.remove(db.paceHistory,1) end
    open.paceRecorded=true
end
local function Reference(samples,t,field)
    if type(samples)~="table" then return end
    field=field or "kills"
    local bucket=math.floor(t/15)
    local left,right=samples[tostring(bucket)],samples[tostring(bucket+1)]
    if type(left)=="table" and left.t>t then right=left; left=samples[tostring(bucket-1)] end
    if type(left)~="table" or not K.Number(left.t) or not K.Number(left[field]) or t<left.t then return end
    if t==left.t then return left[field] end
    if type(right)=="table" and K.Number(right.t) and K.Number(right[field]) and right.t>left.t and right.t-left.t<=20 and t<=right.t and right[field]>=left[field] then
        return left[field]+(right[field]-left[field])*(t-left.t)/(right.t-left.t)
    end
    if field=="kills" and t-left.t<=2 then return left[field] end
end
local function Median(values)
    local n=table.getn(values)
    if n==0 then return end
    table.sort(values)
    local middle=math.floor((n+1)/2)
    return math.mod(n,2)==1 and values[middle] or (values[middle]+values[middle+1])/2
end
local function DamageRate(samples,t,total)
    local first=Reference(samples,t-30,"dealt")
    local last=total or Reference(samples,t,"dealt")
    -- A full 30 seconds of reports is required, including the middle of the window.
    local middle=Reference(samples,t-15,"dealt")
    if K.Number(first) and K.Number(middle) and K.Number(last) and last>=middle and middle>=first then return (last-first)/30 end
end
function P.Details(account)
    local out={status="Wird erfasst",refs=0,mode="kills"}
    local r=AZS_RUN or {}; local phase=AZS_GetPhase and AZS_GetPhase()
    if r.endl==1 then out.status="Endlos"; return out end
    if phase=="ready" or not K.Number(r.t) or not K.Number(r.kills) or r.t<60 then return out end
    local z=AZS_ZONE or {}; local class=type(z.class)=="string" and string.upper(z.class) or nil
    if not class and UnitClass then local _,token=UnitClass("player"); class=token end
    local key=Key(z,class); local values,paired,damage={},{},{}
    local open=type(K.DB().runs)=="table" and K.DB().runs.open
    -- The game sends AZS_ZONE once per run, so after a reload it can be empty; the open run keeps its key.
    if type(z.zone)~="string" and type(open)=="table" and type(open.paceKey)=="string" then key=open.paceKey end
    out.key=key
    -- Never use the open run of another hero or stale damage-meter totals.
    if type(open)=="table" and open.paceKey==key and K.Number(r.dealt) then out.dps=DamageRate(open.paceSamples,r.t,r.dealt) end
    for _,entry in ipairs(K.DB().paceHistory or {}) do
        local self=type(open)=="table" and open.snapshotId and entry.snapshotId==open.snapshotId
        local matches=entry.key==key
        if account then matches=AccountKey(entry.key)==AccountKey(key) end
        local value=not self and matches and Reference(entry.samples,r.t)
        if K.Number(value) and value>0 then
            table.insert(values,value)
            local rate=out.dps and DamageRate(entry.samples,r.t)
            if K.Number(rate) and rate>0 then table.insert(paired,value); table.insert(damage,rate) end
        end
    end
    -- Both components must use the very same reference runs, not separate pools.
    if table.getn(paired)>0 then values=paired; out.mode="combined"; out.refDps=Median(damage); out.dpsRatio=out.dps/out.refDps end
    out.refs=table.getn(values); out.refKills=Median(values)
    if not out.refKills then out.status="Noch kein Vergleich"; return out end
    out.killRatio=r.kills/out.refKills; out.kills=r.kills
    out.ratio=out.killRatio
    if out.dpsRatio then
        -- Limit the damage contribution so a single burst cannot hide a large kill deficit.
        out.ratio=.7*out.killRatio+.3*math.min(out.dpsRatio,1.5)
    end
    out.status=out.ratio>=.9 and "Gut" or (out.ratio>=.7 and "Langsam" or "Sehr langsam")
    return out
end
-- /kui pace debug: the key of this run, the stored keys and the result.
function P.Debug()
    local d=P.Details()
    local open=type(K.DB().runs)=="table" and K.DB().runs.open
    K.Say("Pace: "..tostring(d.status)..", key "..tostring(d.key or "n/a")..", references "..tostring(d.refs)..", mode "..tostring(d.mode))
    K.Say("Pace open run key: "..tostring(type(open)=="table" and open.paceKey or "n/a"))
    local count={}
    for _,entry in ipairs(K.DB().paceHistory or {}) do
        local n,last=0,0
        for _,s in pairs(entry.samples or {}) do n=n+1; if K.Number(s.t) and s.t>last then last=s.t end end
        K.Say(string.format("Pace history: %s, %d samples up to %s%s",tostring(entry.key),n,K.Clock(last),entry.won and ", won" or ""))
    end
end
function P.Status()
    local d=P.Details()
    return d.status,d.ratio,d.refs
end
function P.Color(status)
    if status=="Gut" then return .45,.9,.5 end
    if status=="Langsam" then return 1,.8,.25 end
    if status=="Sehr langsam" then return 1,.3,.25 end
    return .65,.65,.62
end
function P.BossGrade(seconds,final)
    if not K.Number(seconds) then return nil end
    local factor=final and 1.5 or 1
    return seconds<90*factor and "Gut" or (seconds<=180*factor and "Langsam" or "Sehr langsam")
end
