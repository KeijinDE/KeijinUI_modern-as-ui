-- 5.0.5: Run logger for performance reports. Off by default (KeijinUIDB.perfLogOn). While on, every run is summed up
-- over its whole length in KeijinUIDB.perfLog.runs (the last MAXRUNS runs, a new run pushes out the oldest), so a report
-- can say how FPS, memory and garbage developed with enemies and combat density.
-- Run record: start (date(), else GetTime), zone, level, class, version, ended, dur (seconds), result (if the game sent it),
-- snap (snapshot after SNAP seconds), res (minutes per bucket), buckets.
-- Bucket (one minute, at most MAXBUCKETS per run; beyond that neighbours merge, 2 min, then 4 min and so on, bucket 1
-- always stays the start of the run): m (start minute, 1 based), cover (minutes), n (samples), span (seconds),
-- fps (mean), fpsMin, mem (gcinfo at the end, KB), garbage (KB/s, positive gcinfo steps over time), gcs (gcinfo falls),
-- plates (mean visible), platesMax, labels (mean active damage numbers), lines (parsed combat log lines per second),
-- units (#AZS_UNITS), chests (#AZS_CHESTS).
-- gcinfo is the only memory measurement of the client. The 0.1 s update sums it with GetFramerate and the counters into
-- the preallocated table acc: no table and no string per tick. Only a minute change builds one bucket table.
-- Off, or without a run (city, menu), nothing is registered work: the update returns before it reads anything.
-- Command (from Perf.lua): /kui perf log on, off, clear, show [n], or without argument the status.
local K=KeijinUI
local P={}
K.perfLog=P
K.PerfLog=P
local MAXRUNS,MAXBUCKETS,SNAP,MINUTE,GROUP=5,180,30,60,3
local on,registered=false,false
local run                 -- record of the run being recorded
local acc={}              -- running sums of the current bucket
local ResetBucket

local function Store()
    local db=K.DB()
    local log=db.perfLog
    if type(log)~="table" then log={}; db.perfLog=log end
    if log.head~=nil or log.count~=nil then
        -- Slots of the first 5.0.5 draft (ring buffer of 10 s entries) are dropped.
        for i=table.getn(log),1,-1 do log[i]=nil end
        log.head=nil; log.count=nil
    end
    if type(log.runs)~="table" then log.runs={} end
    return log
end
local function Now() return GetTime() end
local function Date()
    if type(date)=="function" then return date("%Y-%m-%d %H:%M:%S") end
    return GetTime()
end
local function Round(x) return math.floor(x*10+0.5)/10 end
local function Size(t) return type(t)=="table" and table.getn(t) or nil end
local function Plates()
    local list,n=K.nameplates,0
    if type(list)~="table" then return 0 end
    for i=1,table.getn(list) do
        local p=list[i]
        if type(p)=="table" and p.visible then n=n+1 end
    end
    return n
end
local function Labels()
    local w=K.damageText and K.damageText.world
    if w and type(w.labels)=="table" then return table.getn(w.labels) end
    return 0
end
local function Lines()
    local f=K.tools and K.tools.ParsedLines
    return f and f() or 0
end
local function Fps() return type(GetFramerate)=="function" and (GetFramerate() or 0) or 0 end

-- Sums b into a (a is the earlier part). Means and rates are weighted by elapsed seconds.
local function Merge(a,b)
    local n,span=a.n+b.n,a.span+b.span
    if span>0 then
        a.fps=Round((a.fps*a.span+b.fps*b.span)/span)
        a.plates=Round((a.plates*a.span+b.plates*b.span)/span)
        a.labels=Round((a.labels*a.span+b.labels*b.span)/span)
        a.garbage=Round((a.garbage*a.span+b.garbage*b.span)/span)
        a.lines=Round((a.lines*a.span+b.lines*b.span)/span)
    end
    if b.fpsMin<a.fpsMin then a.fpsMin=b.fpsMin end
    if b.platesMax>a.platesMax then a.platesMax=b.platesMax end
    a.mem=b.mem; a.units=b.units; a.chests=b.chests
    a.gcs=a.gcs+b.gcs; a.cover=a.cover+b.cover; a.n=n; a.span=span
end
local function Compact()
    local list,out={}, run.buckets
    for i=1,table.getn(out),2 do
        local a,b=out[i],out[i+1]
        if b then Merge(a,b) end
        table.insert(list,a)
    end
    run.buckets=list; run.res=run.res*2
end
local function Append(b)
    local list=run.buckets
    local last=list[table.getn(list)]
    if last and last.cover<run.res then Merge(last,b) else table.insert(list,b) end
    if table.getn(list)>MAXBUCKETS then Compact() end
end
local function Snapshot()
    run.snap={t=math.floor(acc.clock),fps=Round(Fps()),mem=acc.mem,plates=Plates(),labels=Labels(),
        units=Size(AZS_UNITS),chests=Size(AZS_CHESTS)}
end
local function Close()
    local span=acc.clock-acc.t0
    local n=acc.n
    if n<1 or span<=0 then return end
    Append({m=math.floor(acc.t0/MINUTE)+1,cover=1,n=n,span=span,
        fps=Round(acc.fps/span),fpsMin=Round(acc.fpsMin),mem=acc.mem,garbage=Round(acc.grow/span),gcs=acc.gcs,
        plates=Round(acc.plates/span),platesMax=acc.platesMax,labels=Round(acc.labels/span),
        lines=Round(acc.lineCount/span),units=Size(AZS_UNITS),chests=Size(AZS_CHESTS)})
    ResetBucket(acc.clock)
end
function ResetBucket(t0)
    acc.t0=t0; acc.n=0; acc.fps=0; acc.fpsMin=0; acc.grow=0; acc.gcs=0
    acc.plates=0; acc.platesMax=0; acc.labels=0; acc.lineLast=Lines(); acc.lineCount=0
end
local function Begin(now)
    local runs=Store().runs
    local zone=type(AZS_ZONE)=="table" and AZS_ZONE or nil
    local rec={start=Date(),zone=zone and (zone.zname or zone.zone) or nil,
        level=type(AZS_RUN)=="table" and type(AZS_RUN.lvl)=="number" and AZS_RUN.lvl or nil,
        class=K.PlayerClass and K.PlayerClass() or nil,version=K.version,res=1,buckets={}}
    table.insert(runs,rec)
    while table.getn(runs)>MAXRUNS do table.remove(runs,1) end
    run=rec
    acc.last=now; acc.clock=0; acc.mem=nil; acc.baseline=nil; acc.rt=nil
    ResetBucket(0)
end
local function Finish()
    if not run then return end
    if acc.clock>acc.t0 then Close() end
    run.ended=Date(); run.dur=math.floor(acc.clock)
    local phase=AZS_GetPhase and AZS_GetPhase()
    if phase=="dead" then run.result="dead"
    elseif phase=="victory" or (type(AZS_RUN)=="table" and AZS_RUN.won==1) then run.result="victory" end
    run=nil
end
local function Tick()
    if not on then return end
    local phase=AZS_GetPhase and AZS_GetPhase()
    local running=phase=="playing" or phase=="choosing" or phase=="paused" or
        (phase=="victory" and type(AZS_RUN)=="table" and AZS_RUN.endl==1)
    if not running then
        if run then Finish() end
        return
    end
    local now=Now()
    local rt=AZS_GetRunTime and AZS_GetRunTime()
    -- A run time that fell back means the next run began without a pause in between.
    if run and type(rt)=="number" and type(acc.rt)=="number" and rt+5<acc.rt then Finish() end
    if not run then Begin(now) end
    if type(rt)=="number" then acc.rt=rt end
    local dt=now-acc.last
    acc.last=now
    if phase=="paused" then acc.baseline=nil; acc.lineLast=Lines(); return end
    acc.clock=acc.clock+dt
    local lines=Lines()
    acc.lineCount=acc.lineCount+math.max(0,lines-acc.lineLast); acc.lineLast=lines
    local mem=gcinfo()
    if acc.baseline then
        if mem>acc.baseline then acc.grow=acc.grow+(mem-acc.baseline) elseif mem<acc.baseline then acc.gcs=acc.gcs+1 end
    end
    acc.mem=mem; acc.baseline=mem
    local fps=Fps()
    local plates=Plates()
    acc.n=acc.n+1
    acc.fps=acc.fps+fps*dt
    if acc.n==1 or fps<acc.fpsMin then acc.fpsMin=fps end
    acc.plates=acc.plates+plates*dt
    if plates>acc.platesMax then acc.platesMax=plates end
    acc.labels=acc.labels+Labels()*dt
    if not run.snap and acc.clock>=SNAP then Snapshot() end
    if math.floor(acc.clock/MINUTE)>math.floor(acc.t0/MINUTE) then Close() end
end
local function Start()
    on=true
    if not registered then registered=true; K.Update("perflog",Tick) end
end
function P.On() return on end
function P.Set(value)
    value=value and true or false
    K.DB().perfLogOn=value
    if value then Start() else on=false; Finish() end
end
function P.Clear()
    Store().runs={}
    run=nil
end
function P.Count() return table.getn(Store().runs) end

local function Mmss(s) s=math.floor(s or 0); return string.format("%d:%02d",math.floor(s/60),math.mod(s,60)) end
-- One line per GROUP minutes: buckets are summed up until they cover that long.
function P.Lines(rec)
    local out={}
    local g
    local function Flush()
        if not g then return end
        local span=g.span>0 and g.span or 1
        table.insert(out,string.format("min %d  fps %.0f/%.0f  mem %dK  garbage %.0f KB/s  gc %.1f/min  plates %.0f  lines/s %.0f",
            g.m,g.fps,g.fpsMin,g.mem or 0,g.garbage,g.gcs*60/span,g.plates,g.lines))
        g=nil
    end
    for i=1,table.getn(rec.buckets) do
        local b=rec.buckets[i]
        if not g then
            g={}
            for k,v in pairs(b) do g[k]=v end
        else
            Merge(g,b)
        end
        if g.cover>=GROUP then Flush() end
    end
    Flush()
    return out
end
function P.Header(rec,index,total)
    local text=string.format("run %d/%d: %s, %s%s, %s, v%s, %s%s, %d buckets (%d min each)",
        index,total,tostring(rec.start),tostring(rec.zone),rec.level and (" L"..rec.level) or "",tostring(rec.class),
        tostring(rec.version),rec.ended and ("length "..Mmss(rec.dur)) or "running",rec.result and (", result "..rec.result) or "",
        table.getn(rec.buckets),rec.res or 1)
    local s=rec.snap
    if s then
        text=text..string.format("; 30 s: fps %.0f mem %sK plates %s units %s",s.fps,tostring(s.mem),tostring(s.plates),tostring(s.units))
    end
    return text
end
function P.Show(index)
    local runs=Store().runs
    local total=table.getn(runs)
    if total==0 then K.Say("perf log: no runs saved"); return end
    index=index or total
    local rec=runs[index]
    if not rec then K.Say("perf log: no run "..tostring(index).." (1 to "..total..")"); return end
    K.Say("perf log: "..P.Header(rec,index,total))
    for _,line in ipairs(P.Lines(rec)) do K.Say(line) end
end
function P.Command(rest)
    local _,_,word,arg=string.find(rest or "","^%s*(%S*)%s*(%S*)")
    word=string.lower(word or "")
    if word=="on" then P.Set(true); K.Say("perf log: on (one overview per run in the saved variables, last "..MAXRUNS..")")
    elseif word=="off" then P.Set(false); K.Say("perf log: off ("..P.Count().." runs kept, /kui perf log clear empties them)")
    elseif word=="clear" then P.Clear(); K.Say("perf log: cleared")
    elseif word=="show" then P.Show(tonumber(arg))
    else
        K.Say("perf log: "..(on and "on" or "off")..", "..P.Count().." runs saved. /kui perf log on, off, clear, show [n]")
    end
end
K.On("PLAYER_ENTERING_WORLD",function()
    if K.DB().perfLogOn==true and not on then Start() end
end)
K.On("PLAYER_LOGOUT",function() Finish() end)
-- Zone packets are run boundaries, including an immediate restart in the same map.
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if not on then return end
    if prefix=="AZSZONE" then Finish()
    elseif prefix=="AZSRUN" then Tick() end
end)
