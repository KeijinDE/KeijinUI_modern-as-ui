-- Short, opt-in allocation sampling. gcinfo is integer KB, not an allocation counter:
-- GC inside a callback makes its delta unknowable; those samples are counted separately.
local K=KeijinUI
local P={stats={},updates={},events={},bindings={},labels={}}
K.Perf=P
local driver=CreateFrame("Frame","KeijinUIPerf")
P.driver=driver
driver:Hide()
local duration,elapsed,lastKB,totalKB,gcRuns=0,0,0,0,0
local fpsSum,fpsWeight,fpsMin,fpsMax=0,0,0,0
local generation=0

local function Stat(label)
    local s=P.stats[label]
    if not s then s={label=label,calls=0,kb=0,gcHits=0}; P.stats[label]=s end
    return s
end
function P.RegisterUpdate(fn)
    P.updates[fn]=Stat("Update/"..(K.updateLabels[fn] or K.callbackOwners[fn] or "shared"))
end
function P.RegisterEvent(ev,fn)
    if not P.events[ev] then P.events[ev]={} end
    P.events[ev][fn]=Stat("Event/"..ev.."/"..(K.callbackOwners[fn] or "shared"))
end
local function Record(s,a,b)
    s.calls=s.calls+1
    if b<a then s.gcHits=s.gcHits+1 else s.kb=s.kb+b-a end
end
function P.Update(fn)
    local s=P.updates[fn]
    -- A callback can end a measurement (for example during a world change).
    if not K.perfActive then fn(); return end
    local run=generation
    local a=gcinfo(); fn()
    if K.perfActive and run==generation then Record(s,a,gcinfo()) end
end
function P.Event(ev,fn,a1,a2)
    if not K.perfActive then fn(ev,a1,a2); return end
    local s=P.events[ev][fn]
    local run=generation
    local a=gcinfo(); fn(ev,a1,a2)
    if K.perfActive and run==generation then Record(s,a,gcinfo()) end
end
-- Register driver labels at load time, before sampling. Fixed argument slots avoid
-- Lua 5.0's implicit vararg table on every call; this/arg1..argN stay untouched.
function K.PerfLabel(label)
    P.labels[label]=true
    if K.perfActive then Stat(label) end
end
function K.PerfRun(label,fn,a1,a2,a3,a4,a5,a6,a7,a8,a9)
    if not K.perfActive then return fn(a1,a2,a3,a4,a5,a6,a7,a8,a9) end
    local s=P.stats[label]
    local run=generation
    local a=gcinfo()
    local r1,r2,r3,r4=fn(a1,a2,a3,a4,a5,a6,a7,a8,a9)
    if K.perfActive and run==generation then Record(s,a,gcinfo()) end
    return r1,r2,r3,r4
end
-- Swap only a local function reference, never the registered AZS callback or a
-- frame script. Module switches therefore keep their original behavior. Normal
-- frames execute the original body without an extra branch or wrapper call.
function K.PerfBind(label,fn,setter)
    K.PerfLabel(label)
    local binding={label=label,fn=fn,set=setter}
    binding.measured=function() K.PerfRun(label,fn) end
    table.insert(P.bindings,binding)
    if K.perfActive then Stat(label); setter(binding.measured) end
end

local function Before(a,b)
    if a.kb==b.kb then return a.label<b.label end
    return a.kb>b.kb
end
function P.Finish(reason)
    if not K.perfActive then return false end
    K.perfActive=nil
    driver:SetScript("OnUpdate",nil); driver:Hide()
    for _,binding in ipairs(P.bindings) do binding.set(binding.fn) end
    local seconds=math.max(elapsed,0.001)
    P.seconds=seconds
    local ranking={}
    for _,s in pairs(P.stats) do if s.calls>0 then table.insert(ranking,s) end end
    table.sort(ranking,Before); P.ranking=ranking
    if reason then K.Say("Perf: aborted ("..reason.."). Partial results:") end
    K.Say(string.format("Perf %.1fs: FPS %.1f/%.1f/%.1f (avg/min/max), total garbage %.1f KB/s, GC %.1f/min",
        elapsed,fpsWeight>0 and fpsSum/fpsWeight or 0,fpsMin,fpsMax,totalKB/seconds,gcRuns*60/seconds))
    for i=1,math.min(12,table.getn(ranking)) do
        local s=ranking[i]
        K.Say(string.format("%d. %s: %.1f calls/s, %.1f KB/s, GC hits %.1f%%",
            i,s.label,s.calls/seconds,s.kb/seconds,s.gcHits*100/s.calls))
    end
    return true
end
local function Tick()
    local dt=tonumber(arg1) or 0
    local kb=gcinfo()
    if kb<lastKB then gcRuns=gcRuns+1 else totalKB=totalKB+kb-lastKB end
    lastKB=kb
    elapsed=elapsed+dt
    local fps=GetFramerate()
    fpsSum=fpsSum+fps*dt; fpsWeight=fpsWeight+dt
    if fpsMin==0 or fps<fpsMin then fpsMin=fps end
    if fps>fpsMax then fpsMax=fps end
    if elapsed>=duration then P.Finish() end
end
function P.Start(seconds)
    if K.perfActive then K.Say("Perf: measurement already running."); return false end
    seconds=tonumber(seconds) or 10
    if seconds~=seconds then seconds=10 end
    duration=math.max(3,math.min(60,seconds))
    generation=generation+1
    P.stats={}; P.updates={}; P.events={}; P.ranking=nil
    for _,fn in ipairs(K.updates) do P.RegisterUpdate(fn) end
    for ev,list in pairs(K.events) do for _,fn in ipairs(list) do P.RegisterEvent(ev,fn) end end
    for label in pairs(P.labels) do Stat(label) end
    for _,binding in ipairs(P.bindings) do binding.set(binding.measured) end
    elapsed,totalKB,gcRuns=0,0,0
    fpsSum,fpsWeight,fpsMin,fpsMax=0,0,0,0
    K.Say(string.format("Perf: measuring %.1f seconds. GC-crossing samples excluded; deltas are approximate.",duration))
    lastKB=gcinfo()
    K.perfActive=true
    driver:SetScript("OnUpdate",Tick); driver:Show()
    return true
end
function P.Command(rest)
    rest=string.lower(string.gsub(rest or "","^%s*(.-)%s*$","%1"))
    if rest=="log" or string.find(rest,"^log%s") then
        local _,_,args=string.find(rest,"^log%s+(.-)$")
        if K.PerfLog and K.PerfLog.Command then K.PerfLog.Command(args or "")
        else K.Say("Perf log: unavailable.") end
        return
    end
    if rest~="" and not tonumber(rest) then K.Say("Perf: /kui perf [3..60] | /kui perf log ..."); return end
    P.Start(rest~="" and tonumber(rest) or 10)
end
K.On("PLAYER_LEAVING_WORLD",function() P.Finish("world change") end)
K.On("PLAYER_ENTERING_WORLD",function() P.Finish("world change") end)
