-- The schedule supplies spawn times and states, but no historical death times.
-- Capture live state transitions using the game's pause-aware run clock.
local K=KeijinUI
local times,lastTime,lastReported={},nil,nil
K.BossTimes={}
local function Key(boss)
    return tostring(boss.index or "").."\031"..tostring(boss.name or "").."\031"..tostring(boss.at or "")
end
local function Reset() times={}; lastTime=nil; lastReported=nil end
local function RunLength()
    local length=AZS_GetRunLength and AZS_GetRunLength()
    if not K.Number(length) or length<=0 then length=type(AZS_RUN)=="table" and AZS_RUN.fin end
    return K.Number(length) and length>0 and length or nil
end
-- ReloadUI builds a fresh API state with an empty AZS_SCHEDULE, and the game sends AZSBOSSES only when
-- the list changes. The last list is therefore kept across the reload (written at PLAYER_LOGOUT) and
-- used while the game has not sent a new one, as long as it belongs to the same run.
local function Snapshot()
    local s=K.DB().bossSnapshot
    if type(s)~="table" or type(s.list)~="table" or table.getn(s.list)==0 then return nil end
    local now=AZS_GetRunTime and AZS_GetRunTime()
    if not K.Number(now) or not K.Number(s.runTime) then return nil end
    if now<s.runTime-1 or now-s.runTime>120 then return nil end
    local length=RunLength()
    if length and K.Number(s.length) and math.abs(length-s.length)>1 then return nil end
    return s
end
function K.Schedule()
    if type(AZS_SCHEDULE)=="table" and table.getn(AZS_SCHEDULE)>0 then return AZS_SCHEDULE end
    local s=Snapshot()
    return s and s.list or {}
end
local function Observe()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local now=AZS_GetRunTime and AZS_GetRunTime()
    if not phase or not K.Number(now) then return end
    local reported=K.ReportedRunTime()
    if reported and lastReported and reported<lastReported-K.RUN_BACK then Reset() end
    if not lastTime then
        local s=Snapshot()
        if s and type(s.times)=="table" then times=s.times end
    end
    lastTime=now
    if reported then lastReported=reported end
    for _,boss in ipairs(K.Schedule()) do
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
-- Start of the current run as GetTime(). "Again" after a death starts a new run without a reload, and the game sends
-- AZS_UNITS and AZS_LAIRS only on change: until then they still hold the run before (a boss bar of the old fight).
-- K.Fresh(updated) is false for a table whose *_UPDATED is older than this start. Unknown times count as fresh.
local lastPhase,lastClock
local function MarkStart() K.runStart=GetTime and GetTime() or nil end
function K.Fresh(updated)
    return not (K.Number(K.runStart) and K.Number(updated) and updated<K.runStart)
end
local function WatchStart()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local now=K.ReportedRunTime()
    if (phase=="ready" and lastPhase and lastPhase~="ready") or (K.Number(now) and K.Number(lastClock) and now<lastClock-K.RUN_BACK) then MarkStart() end
    lastPhase=phase
    if K.Number(now) then lastClock=now end
end
table.insert(K.updates,WatchStart)
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then Reset(); K.DB().bossSnapshot=nil; MarkStart()
    elseif prefix=="AZSBOSSES" then Observe() end
end)
K.On("PLAYER_LOGOUT",function()
    local list=K.Schedule()
    local now=AZS_GetRunTime and AZS_GetRunTime()
    if table.getn(list)==0 or not K.Number(now) then K.DB().bossSnapshot=nil; return end
    local copy={}
    for i,boss in ipairs(list) do
        copy[i]={index=boss.index,at=boss.at,name=boss.name,final=boss.final,state=boss.state}
    end
    K.DB().bossSnapshot={list=copy,runTime=now,length=RunLength(),times=times}
end)
table.insert(K.updates,Observe)
Observe()
