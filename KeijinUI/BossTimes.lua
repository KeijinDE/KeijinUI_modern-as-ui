-- The schedule supplies spawn times and states, but no historical death times.
-- Capture live state transitions using the game's pause-aware run clock.
local K=KeijinUI
local times,lastTime={},nil
K.BossTimes={}
local function Key(boss)
    return tostring(boss.index or "").."\031"..tostring(boss.name or "").."\031"..tostring(boss.at or "")
end
local function Reset() times={}; lastTime=nil end
local function Observe()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local now=AZS_GetRunTime and AZS_GetRunTime()
    if not phase or not K.Number(now) then return end
    if lastTime and now<lastTime-1 then Reset() end
    lastTime=now
    for _,boss in ipairs(AZS_SCHEDULE or {}) do
        local key=Key(boss)
        local entry=times[key]
        if not entry then entry={}; times[key]=entry end
        if boss.state=="dead" and (entry.state=="up" or entry.state=="due") and phase~="ready" then
            if K.Number(boss.at) and now>=boss.at then
                entry.killedAt=now; entry.duration=now-boss.at
            end
        end
        entry.state=boss.state
    end
end
function K.BossTimes.Get(boss) return times[Key(boss)] end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then Reset()
    elseif prefix=="AZSBOSSES" then Observe() end
end)
table.insert(K.updates,Observe)
Observe()
