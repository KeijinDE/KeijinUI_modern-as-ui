-- Immutable victory receipts, with a separate extension only for confirmed endless play.
local K=KeijinUI
local S={loaded={}}
K.runSnapshots=S
local function Copy(value)
    if type(value)~="table" then return value end
    local out={}; for key,v in pairs(value) do out[key]=Copy(v) end; return out
end
local function Store()
    local db=K.DB()
    if not K.ModuleOn("history") then return type(db.runSnapshots)=="table" and db.runSnapshots or {} end
    if type(db.runSnapshots)~="table" then db.runSnapshots={} end
    return db.runSnapshots
end
function S.Find(open)
    if not open or not open.snapshotId then return end
    for _,v in ipairs(Store()) do if v.id==open.snapshotId then return v end end
end
function S.Capture(open,packet)
    if not K.ModuleOn("history") or type(open)~="table" then return end
    local prior=S.Find(open)
    if prior then return prior end
    if not open.won or not K.Number(open.winTime) or open.winTime<=0 then return end
    local db=K.DB(); db.snapshotSerial=(tonumber(db.snapshotSerial) or 0)+1
    local id=tostring(type(time)=="function" and time() or 0)..":"..db.snapshotSerial
    local r=packet or AZS_RUN or {}
    local result={id=id,version=K.version,zone=open.zone,char=open.char,class=open.class,race=open.race,
        name=open.name,victoryTime=open.winTime,duration=open.winTime,endless=false,
        capturedAt=type(time)=="function" and time() or 0,stats={}}
    result.statsKnown=K.Number(r.t) and math.abs(r.t-open.winTime)<1 and r.endl~=1
    for _,key in ipairs({"lvl","kills","dealt","taken","ge","bk","gk","ek","ck"}) do
        if result.statsKnown and K.Number(r[key]) then result.stats[key]=r[key] end
    end
    result.paceSamples=Copy(open.paceSamples or {})
    table.insert(Store(),result); open.snapshotId=id
    while table.getn(Store())>40 do table.remove(Store(),1) end
    return result
end
function S.Extend(open)
    if not K.ModuleOn("history") then return end
    local v=S.Find(open)
    if not v or not open.endless or not K.Number(open.last) then return end
    if open.last>v.duration then v.duration=open.last; v.endless=true end
end
function S.Loaded()
    if not K.ModuleOn("history") then return end
    -- Called only after the client has executed this addon's saved-variable file.
    if S.loadedOnce then return end
    S.loadedOnce=true
    for _,v in ipairs(Store()) do if type(v)=="table" and v.id and K.Number(v.victoryTime) then S.loaded[v.id]=true end end
end
function S.Check()
    if not K.ModuleOn("history") then return end
    local list=Store(); local v=list[table.getn(list)]
    if not v then K.Say(K.T("Noch kein Sieg Snapshot vorhanden.")); return end
    local status=S.loaded[v.id] and K.T("Nach Neuladen aus gespeicherten Daten bestätigt") or K.T("In dieser Sitzung erfasst; Datenträgerprüfung nach Neuladen")
    K.Say(K.T("Sieg Snapshot: %s · %s · Sieg %s · Gesamt %s · %s",v.char,v.zone,K.Clock(v.victoryTime),K.Clock(v.duration),status))
end
