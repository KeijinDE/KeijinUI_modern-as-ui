-- Rolling ten-second damage, measured from cumulative native meter reports.
-- Keep sampling while another meter tab is shown; pauses use no run seconds.
local K=KeijinUI
local D={window=10}
K.liveDPS=D
local samples,last,origin={},nil,nil
function D.Reset() samples={}; last=nil; origin=nil end
function D.Observe(now,lines)
    if not K.Number(now) or type(lines)~="table" then return end
    local values={}
    for _,v in ipairs(lines) do
        if type(v.name)~="string" or not K.Number(v.dmg) then return end
        values[v.name]=(values[v.name] or 0)+v.dmg
    end
    if last and now<last.t-(K.RUN_BACK or 3) then D.Reset() end
    if last and now<last.t then return end
    if last and now-last.t>2 then D.Reset() end
    if last then
        for name,value in pairs(values) do
            if last.values[name] and value<last.values[name] then D.Reset(); break end
        end
    end
    if not origin then origin=now end
    if last and now==last.t then last.values=values; return end
    if last and now-last.t<.2 then return end
    last={t=now,values=values}; table.insert(samples,last)
    while table.getn(samples)>2 and samples[2].t<=now-D.window do table.remove(samples,1) end
end
function D.Rate(name)
    if not last or table.getn(samples)<2 then return nil end
    local target=math.max(origin,last.t-D.window)
    local left,right=samples[1],nil
    for _,s in ipairs(samples) do
        if s.t<=target then left=s else right=s; break end
    end
    local base=left.values[name] or 0
    if right and right.t>left.t then
        base=base+((right.values[name] or 0)-base)*(target-left.t)/(right.t-left.t)
    end
    local elapsed=last.t-target
    if elapsed<=0 then return nil end
    return math.max(0,((last.values[name] or 0)-base)/elapsed)
end
