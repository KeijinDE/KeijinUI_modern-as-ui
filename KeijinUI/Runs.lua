-- Run overview (0.9.0): per zone and character the number of runs, wins, last time, fastest win and longest survival.
-- Data: AZS_ZONE (sent at the start of a run: zone, zname, class, cname), AZS_RUN (phase, t, won), AZS_GetPhase(), AZS_GetRunTime().
-- The game knows only the current run, so counting starts with the installation of this version.
-- Storage in the account wide KeijinUIDB.runs[zone][heroKey] = {class, cname, race, rname, name, runs, wins, lastTime, lastDate,
-- bestWin, longest}. Every hero of an account carries the account name and class and race change from run to run, so
-- heroKey is "CLASS-Race" (since 1.0.1); the name is only kept for the tooltip. The 0.9 and 1.0.0 data mixed all classes in
-- one row and cannot be split, so it is cleared once (KeijinUIDB.runs.keys=3).
-- KeijinUIDB.runs.names[zone] keeps the zone name, KeijinUIDB.runs.open the run in progress:
-- {zone, char, name, class, cname, start (time()), last (last seen run time), won, winTime, counted}.
-- A run counts only from MIN_TIME seconds of run time (or a win); until then it leaves no trace in the data.
-- KeijinUIDB.runs.announced={zone,char}: the start message of a run that has not begun yet (phase ready) was already sent.
-- It is consumed by the start of the run, so a reload in ready does not repeat the line.
-- The open run survives a reload: a run counts as new only when no open run exists for the same character and zone, when the
-- run time is smaller than the last one seen, or when the phase went through ready or dead in between. Otherwise it goes on.
local K=KeijinUI
local R={}
K.runs=R
local ORDER={"elwynn","duskwood","wsg","ab","feralas","arena","av","brm","aq"}
local RUNNING={playing=true,choosing=true,paused=true,victory=true}
local WAIT=2          -- seconds to wait for the first run line after a zone line
local BACK=3          -- seconds the run time may fall back before it counts as a restart
local needZone=false  -- the last run ended, the zone line of the next one is still to come
local zoneAt,gotRun,pendingZone -- wait for matching run data; never read the previous run on a new zone event
local MAX_ROWS=10
local MIN_TIME=90    -- seconds of run time before a run counts
local ZONE_NAMES={   -- English names from the game, used while no name was received or stored
    elwynn="Elwynn Forest",duskwood="Duskwood",wsg="Warsong Gulch",ab="Arathi Basin",feralas="Feralas",
    arena="Gurubashi Arena",av="Alterac Valley",brm="Blackrock Mountain",aq="Gates of Ahn'Qiraj"
}
local page,sorted=nil,{}
-- The client names the race in English even in a German client: German source texts by token, translated by K.T.
local RACES={Human="Mensch",Dwarf="Zwerg",NightElf="Nachtelf",Gnome="Gnom",Orc="Orc",Scourge="Untoter",Tauren="Tauren",Troll="Troll"}
local offset=0

-- Storage ----------------------------------------------------------------------------------------------
local function Store()
    local db=K.DB()
    if type(db.runs)~="table" or db.runs.keys~=3 then db.runs={keys=3} end
    if type(db.runs.names)~="table" then db.runs.names={} end
    return db.runs
end
local function ClassToken(z)
    z=z or AZS_ZONE
    if type(z)=="table" and type(z.class)=="string" and z.class~="" then return string.upper(z.class) end
    if UnitClass then local _,token=UnitClass("player"); if type(token)=="string" and token~="" then return token end end
    return nil
end
-- Race of the hero: localized name and token (UnitRace), "?" when the client gives none.
local function Race(z)
    if type(z)=="table" and type(z.race)=="string" and z.race~="" then
        return z.race,type(z.rname)=="string" and z.rname~="" and z.rname or z.race
    end
    if type(UnitRace)~="function" then return "?",nil end
    local localized,token=UnitRace("player")
    if type(token)~="string" or token=="" then token=nil end
    if type(localized)~="string" or localized=="" then localized=nil end
    return token or localized or "?",localized
end
local function CharKey(z)
    local name=type(z)=="table" and z.hero or (UnitName and UnitName("player"))
    if type(name)~="string" or name=="" then name=nil end
    local class=ClassToken(z)
    if not class then return nil,nil end
    local race=Race(z)
    return class.."-"..race,name
end
local function Now() return type(time)=="function" and time() or 0 end
local function Today()
    if type(date)~="function" then return nil end
    local ok,value=pcall(date,"%Y-%m-%d")
    return ok and value or nil
end
-- A short diagnostic trail survives reloads, without adding chat spam or a run per tick.
local function Trace(kind,open,detail)
    local db=K.DB()
    if type(db.runTrace)~="table" then db.runTrace={} end
    table.insert(db.runTrace,{kind=kind,date=Today(),at=Now(),zone=open and open.zone,
        char=open and open.char,t=open and open.last,detail=detail})
    while table.getn(db.runTrace)>24 do table.remove(db.runTrace,1) end
end
-- GetTime() of the last zone line (AZS_ZONE_UPDATED). The game sends the zone line again when the new run's world
-- entry reloads the interface, and that reload wipes the chat: a message from the session before must not count.
local function ZoneStamp()
    if zoneAt then return zoneAt end
    local at=AZS_ZONE_UPDATED
    if type(at)=="number" then return at end
    return nil
end
local function Entry(zone,char)
    local zones=Store()[zone]
    return type(zones)=="table" and zones[char] or nil
end

-- Stored name, else the name of the current zone data, else the fixed table, else the key.
function R.ZoneName(zone)
    local stored=Store().names[zone]
    if type(stored)=="string" and stored~="" then return stored end
    local z=AZS_ZONE
    if type(z)=="table" and z.zone==zone and type(z.zname)=="string" and z.zname~="" then return z.zname end
    return ZONE_NAMES[zone] or zone
end

function R.MessageOn() return K.DB().runsMessage~=false end
function R.SetMessage(on) K.DB().runsMessage=on and true or false end

-- Message ----------------------------------------------------------------------------------------------
-- English ordinal numbers: 1st, 2nd, 3rd, 4th, 11th to 13th.
function R.Ordinal(n)
    if K.lang=="de" then return n.."." end
    local rest=math.mod(n,100)
    local last=math.mod(n,10)
    local suffix="th"
    if rest<11 or rest>13 then
        if last==1 then suffix="st" elseif last==2 then suffix="nd" elseif last==3 then suffix="rd" end
    end
    return n..suffix
end
local function ClassColor(class)
    local r,g,b=K.ClassColor(class)
    if r then return r,g,b end
    return 1,1,1
end
local function Hex(r,g,b) return string.format("|cff%02x%02x%02x",math.floor(r*255+0.5),math.floor(g*255+0.5),math.floor(b*255+0.5)) end
-- n: number of this run, best and longest: values before this run (or nil).
function R.Message(zname,cname,class,n,best,longest)
    if K.DB().compactMessages==true then
        return K.T("%s · %s · Runde %s",zname,cname,n)..(K.Number(best) and best>0 and (" · "..K.T("Bestzeit %s",K.Clock(best))) or "")
    end
    local red,green,blue=ClassColor(class)
    local colored=Hex(red,green,blue)..cname.."|r"
    if n<=1 then return K.T("%s, %s: Das ist dein erster Lauf hier.",zname,colored) end
    local text=K.T("%s, %s: Das ist dein %s Lauf.",zname,colored,R.Ordinal(n))
    local hasBest,hasLong=K.Number(best) and best>0,K.Number(longest) and longest>0
    if hasBest and hasLong then text=text..K.T(" Schnellster Sieg %s, längstes Überleben %s.",K.Clock(best),K.Clock(longest))
    elseif hasBest then text=text..K.T(" Schnellster Sieg %s.",K.Clock(best))
    elseif hasLong then text=text..K.T(" Längstes Überleben %s.",K.Clock(longest)) end
    return text
end

-- Recording --------------------------------------------------------------------------------------------
local Render
-- Counts the open run once: entry, class data and runs+1. Reload safe, the flag is part of the open run.
local function Count(open)
    if open.counted then return end
    local runs=Store()
    if type(runs[open.zone])~="table" then runs[open.zone]={} end
    local e=runs[open.zone][open.char]
    if type(e)~="table" then e={runs=0,wins=0}; runs[open.zone][open.char]=e end
    e.name=open.name; e.class=open.class; e.cname=open.cname
    e.race,e.rname=open.race,open.rname
    if not e.race then e.race,e.rname=Race() end
    e.runs=(K.Number(e.runs) and e.runs or 0)+1
    open.counted=true
    Trace("count",open)
    if Render then Render() end
end
-- Writes last time, date and longest survival of the open run into the totals. Safe to repeat.
local function Commit(open)
    if not open.counted then return false end
    local e=Entry(open.zone,open.char)
    if type(e)~="table" or not K.Number(open.last) or open.last<=0 then return false end
    local recorded=open.won and not open.endless and open.winTime or open.last
    if not K.Number(recorded) then return false end
    e.lastTime=recorded; e.lastDate=Today()
    if not K.Number(e.longest) or recorded>e.longest then e.longest=recorded end
    if open.won then K.runSnapshots.Capture(open); K.runSnapshots.Extend(open) end
    -- Confirm the same stored entry the overview reads, not merely a received packet.
    local stored=Entry(open.zone,open.char)
    return stored==e and K.Number(stored.runs) and stored.runs>=1 and stored.lastTime==recorded
        and (not open.won or (K.Number(stored.wins) and stored.wins>=1 and K.Number(stored.bestWin)
            and K.Number(open.winTime) and stored.bestWin<=open.winTime))
end
local function Feedback(open,kind)
    if kind=="win" then
        if open.winFeedback then return end
        open.winFeedback=true
    else
        if open.finishFeedback then return end
        open.finishFeedback=true
        -- Victory was already confirmed; only report again if continued play changed the time.
        if kind=="saved" and open.winFeedback then
            if open.last<=(open.winTime or open.last) then return end
            kind="updated"
        end
    end
    if not R.MessageOn() then return end
    local label=open.cname or open.class or "?"
    local race=RACES[open.race] and K.T(RACES[open.race]) or open.rname or open.race
    if race and race~="?" then label=label..", "..race end
    local zone,duration=R.ZoneName(open.zone),K.Clock(kind=="win" and open.winTime or open.last or 0)
    if kind=="win" then
        K.Say(K.T("Sieg in Rundenübersicht gespeichert: %s · %s · %s.",zone,label,duration))
    elseif kind=="saved" then
        K.Say(K.T("In Rundenübersicht gespeichert: %s · %s · %s.",zone,label,duration))
    elseif kind=="updated" then
        K.Say(K.T("Run in Rundenübersicht aktualisiert: %s · %s · %s (Siegzeit %s).",zone,label,duration,K.Clock(open.winTime)))
    elseif kind=="short" then
        K.Say(K.T("Run nicht gespeichert: %s · %s · %s. Mindestdauer ohne Sieg: %s.",zone,label,duration,K.Clock(MIN_TIME)))
    else
        K.Say(K.T("Rundeneintrag konnte nicht bestätigt werden: %s · %s. Bitte /kui runs debug prüfen.",zone,label))
    end
end
local function Finish(open)
    if not open.counted and K.Number(open.last) and open.last>=MIN_TIME then Count(open) end
    local committed=Commit(open)
    K.pace.Record(open)
    Trace("finish",open,open.won and "won" or "not won")
    Store().open=nil
    if committed then
        Feedback(open,"saved")
    elseif not open.counted and not open.won and K.Number(open.last) and open.last<MIN_TIME then
        Feedback(open,"short")
    else Feedback(open,"failed") end
    if Render then Render() end
end
local function Start(z,key,name,t)
    local runs=Store()
    local zone=z.zone
    local e=Entry(zone,key)
    local classKey=type(z.class)=="string" and string.upper(z.class) or nil
    local cname=type(z.cname)=="string" and z.cname~="" and z.cname or nil
    if not classKey or not cname then
        local localized,token
        if UnitClass then localized,token=UnitClass("player") end
        classKey=classKey or token
        cname=cname or localized
    end
    if type(z.zname)=="string" and z.zname~="" then runs.names[zone]=z.zname end
    local zname=R.ZoneName(zone)
    local best,longest,done
    if e then best,longest,done=e.bestWin,e.longest,e.runs end
    local n=(K.Number(done) and done or 0)+1
    runs.open={zone=zone,char=key,name=name,class=classKey,cname=cname,start=Now(),last=t or 0,won=false,counted=false}
    runs.open.race,runs.open.rname=Race(z)
    Trace("start",runs.open)
    local a=runs.announced
    runs.announced=nil
    local told=type(a)=="table" and a.zone==zone and a.char==key and a.at==ZoneStamp()
    if R.MessageOn() and not told then K.Say(R.Message(zname,cname or "?",classKey,n,best,longest)) end
    return runs.open
end
-- Start message as soon as the zone of a new run is known (phase ready); the count itself stays with the start of the run.
local function Announce(z,key,name)
    if not R.MessageOn() then return end
    local runs=Store()
    local zone=z.zone
    local a=runs.announced
    if type(a)=="table" and a.zone==zone and a.char==key and a.at==ZoneStamp() then return end
    local e=Entry(zone,key)
    if type(e)~="table" then e={} end
    local classKey=type(z.class)=="string" and string.upper(z.class) or nil
    local cname=type(z.cname)=="string" and z.cname~="" and z.cname or nil
    if not classKey or not cname then
        local localized,token
        if UnitClass then localized,token=UnitClass("player") end
        classKey=classKey or token
        cname=cname or localized
    end
    local n=(K.Number(e.runs) and e.runs or 0)+1
    runs.announced={zone=zone,char=key,at=ZoneStamp()}
    K.Say(R.Message(R.ZoneName(zone),cname or "?",classKey,n,e.bestWin,e.longest))
end
local function Win(open,t,packet)
    if open.won then return end
    Count(open)
    local e=Entry(open.zone,open.char)
    open.won=true; open.winTime=t
    if not e then return end
    e.wins=(K.Number(e.wins) and e.wins or 0)+1
    if K.Number(t) and (not K.Number(e.bestWin) or t<e.bestWin) then e.bestWin=t end
    K.runSnapshots.Capture(open,packet)
    K.pace.Record(open)
    local committed=Commit(open)
    Trace("win",open)
    if committed then Feedback(open,"win") end
    if Render then Render() end
end

local function IsWin(run,phase)
    local won=type(run)=="table" and run.won
    return phase=="victory" or won==1 or won=="1" or won==true or won=="true"
end
local function Update(packet,zone)
    if zoneAt and not gotRun then
        if GetTime()-zoneAt<WAIT then return end
        zoneAt=nil
    end
    local z=zone or pendingZone or AZS_ZONE
    if type(z)~="table" or type(z.zone)~="string" or z.zone=="" then return end
    local phase=packet and packet.ph or (AZS_GetPhase and AZS_GetPhase())
    if type(phase)~="string" then return end
    -- Totals and restart detection use the reported clock. Interpolation is only for
    -- visible clocks: a delayed packet after a long frame must not invent a restart.
    local t=packet and packet.t or (type(AZS_RUN)=="table" and AZS_RUN.t)
    if not K.Number(t) then t=AZS_GetRunTime and AZS_GetRunTime() end
    if not K.Number(t) then t=nil end
    local key,name=CharKey(z)
    if not key then return end
    local runs=Store()
    local open=runs.open
    if phase=="ready" then
        if open then Finish(open) end
        if type(z.zname)=="string" and z.zname~="" then runs.names[z.zone]=z.zname end
        if not needZone then Announce(z,key,name) end
        return
    end
    if phase=="dead" then
        if open then
            local report=packet or AZS_RUN or {}
            if open.won and report.endl==1 then open.endless=true end
            if t and t>open.last and (not open.won or open.endless) then open.last=t end
            if open.char==key and open.zone==z.zone and IsWin(report,phase) then Win(open,t or open.last,report) end
            Finish(open); needZone=true
        end
        return
    end
    if not RUNNING[phase] then return end
    if open and (open.char~=key or open.zone~=z.zone) then Finish(open); open=nil end
    if open and t and t<open.last-BACK then Finish(open); open=nil end
    if not open then
        if needZone then return end
        open=Start(z,key,name,t)
    end
    local report=packet or AZS_RUN or {}
    K.pace.Observe(open,report,z)
    if open.won and report.endl==1 then open.endless=true end
    if t and t>open.last and (not open.won or open.endless) then open.last=t end
    if not open.counted and open.last>=MIN_TIME then Count(open) end
    if IsWin(report,phase) and not open.won then Win(open,t or open.last,report) end
    if open.won and report.endl==1 then open.endless=true; if t and t>open.last then open.last=t end end
    if open.won then Commit(open) end
end
R.Update=Update

local lastSignal
local function Receive(prefix,message)
    if prefix=="AZSZONE" then
        needZone=false; zoneAt=GetTime(); gotRun=false
        pendingZone=type(AZS_Fields)=="function" and type(message)=="string" and AZS_Fields(message) or nil
    elseif prefix=="AZSRUN" then
        local packet=type(AZS_Fields)=="function" and type(message)=="string" and AZS_Fields(message)
        if packet and type(packet.ph)=="string" then
            local z=pendingZone or AZS_ZONE
            local signature=tostring(z and z.zone)..":"..tostring(CharKey(z))..":"..packet.ph..":"..tostring(packet.won)
            if signature~=lastSignal then
                Trace("signal",{zone=z and z.zone,char=CharKey(z),last=packet.t},packet.ph.." won="..tostring(packet.won).." ("..type(packet.won)..")")
                lastSignal=signature
            end
            gotRun=true; Update(packet,pendingZone)
        end
    end
end
local function Save(reason)
    Update()
    local open=type(KeijinUIDB)=="table" and type(KeijinUIDB.runs)=="table" and KeijinUIDB.runs.open
    if type(open)=="table" then Commit(open) end
    Trace("shutdown",open,reason)
end
-- Recording is independent of HUD updates and their errors or visibility.
local recorder=CreateFrame("Frame","KeijinUIRunRecorder",UIParent)
R.recorder=recorder
recorder:RegisterEvent("CHAT_MSG_ADDON"); recorder:RegisterEvent("PLAYER_LOGOUT"); recorder:RegisterEvent("PLAYER_LEAVING_WORLD")
recorder:RegisterEvent("ADDON_LOADED")
recorder:SetScript("OnEvent",function()
    if event=="CHAT_MSG_ADDON" then Receive(arg1,arg2)
    elseif event=="ADDON_LOADED" then if arg1=="KeijinUI" then K.runSnapshots.Loaded(); Trace("snapshots_loaded",nil,K.version) end
    else Save(event) end
end)
local elapsed=0
recorder:SetScript("OnUpdate",function()
    elapsed=elapsed+(tonumber(arg1) or 0)
    if elapsed>=.1 then elapsed=0; Update() end
end)

-- Window -----------------------------------------------------------------------------------------------
local WIDTH=560
local COLUMNS={   -- key, caption, x, width, justify
    {"name","Klasse und Volk",5,135,"LEFT"},{"runs","Runs",145,40,"RIGHT"},{"wins","Siege",190,40,"RIGHT"},
    {"lastTime","Letzte Zeit",235,75,"RIGHT"},{"bestWin","Schnellster Sieg",315,105,"RIGHT"},
    {"longest","Längstes Überleben",425,110,"RIGHT"}
}
local panel=K.Panel("KeijinUIRuns","Rundenübersicht",WIDTH,33+(MAX_ROWS+2)*21+44)
panel:SetFrameStrata("DIALOG")
panel:SetPoint("CENTER",UIParent,"CENTER",0,40)
panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart",function() this:StartMoving() end)
panel:SetScript("OnDragStop",function() this:StopMovingOrSizing(); R.moved=true end)
panel:EnableMouseWheel(true)
panel:SetScript("OnMouseWheel",function() offset=math.max(0,offset+(arg1>0 and -1 or 1)); Render() end)
local function NavButton(text,x,fn)
    local b=CreateFrame("Button",nil,panel)
    b:SetWidth(30); b:SetHeight(20); b:SetPoint("TOPLEFT",panel,"TOPLEFT",x,-34)
    K.Skin(b,7); b.text=K.Text(b,text,12,"CENTER",0,0)
    b:SetScript("OnClick",fn)
    return b
end
local zoneText=K.Text(panel,"",12,"TOPLEFT",200,-38,160)
zoneText:SetJustifyH("CENTER"); zoneText:SetTextColor(1,0.82,0.28)
local emptyText
local head=K.ValueRow(panel,2,19)
for _,c in ipairs(COLUMNS) do
    local fs=K.Text(head,"",10,"LEFT",c[3],0,c[4])
    fs:SetJustifyH(c[5]); fs:SetTextColor(1,0.82,0.28)
    local key=c[2]   -- body local for the closure (see Statistics.lua)
    K.Live(fs,function() return K.T(key) end)
end
local rows={}
for i=1,MAX_ROWS do
    local row=K.ValueRow(panel,i+2,19)
    row.cells={}
    for _,c in ipairs(COLUMNS) do
        local fs=K.Text(row,"",10,"LEFT",c[3],0,c[4])
        fs:SetJustifyH(c[5])
        row.cells[c[1]]=fs
    end
    rows[i]=row
end
emptyText=K.LText(panel,"Noch keine Runs in dieser Zone",10,"TOPLEFT",WIDTH/2-120,-33-2*21-4,240)
emptyText:SetJustifyH("CENTER"); emptyText:SetTextColor(0.6,0.6,0.62)

-- Zones in the order of the game, followed by unknown ones found in the data.
function R.ZoneList()
    local list,seen={},{}
    for _,zone in ipairs(ORDER) do list[table.getn(list)+1]=zone; seen[zone]=true end
    local extra={}
    for zone,v in pairs(Store()) do
        if type(v)=="table" and zone~="names" and zone~="open" and zone~="announced" and not seen[zone] then extra[table.getn(extra)+1]=zone end
    end
    table.sort(extra)
    for _,zone in ipairs(extra) do list[table.getn(list)+1]=zone end
    return list
end
local function Dash(value) return K.Number(value) and value>0 and K.Clock(value) or "-" end
local function Count(value) return K.Number(value) and tostring(math.floor(value)) or "-" end
function Render()
    local list=R.ZoneList()
    local count=table.getn(list)
    if not page then
        local z=type(AZS_ZONE)=="table" and AZS_ZONE.zone
        -- The zone of the run in progress, else the first zone that has data.
        local store=Store()
        for i=table.getn(list),1,-1 do if type(store[list[i]])=="table" and next(store[list[i]]) then page=i end end
        for i,zone in ipairs(list) do if zone==z then page=i end end
        page=page or 1
    end
    if page<1 then page=count end
    if page>count then page=1 end
    local zone=list[page]
    local store=Store()
    zoneText:SetText(R.ZoneName(zone))
    sorted={}
    for key,e in pairs(type(store[zone])=="table" and store[zone] or {}) do
        if type(e)=="table" then table.insert(sorted,{key=key,e=e}) end
    end
    -- Sorted by class, then race; the name only breaks ties.
    local function Order(e,key) return string.lower(tostring(e.cname or e.class or key)..""..tostring(e.rname or e.race or "")..""..tostring(e.name or "")) end
    table.sort(sorted,function(a,b)
        local x,y=Order(a.e,a.key),Order(b.e,b.key)
        if x==y then return a.key<b.key end
        return x<y
    end)
    offset=math.min(offset,math.max(0,table.getn(sorted)-MAX_ROWS))
    for i,row in ipairs(rows) do
        local item=sorted[i+offset]
        if item then
            local e=item.e
            local red,green,blue=ClassColor(e.class)
            -- Class and race tell the rows apart; the name is in the tooltip.
            local label=tostring(e.cname or e.class or item.key)
            local race=RACES[e.race] and K.T(RACES[e.race]) or e.rname or (e.race~="?" and e.race) or nil
            if race then label=label..", "..tostring(race) end
            row.cells.name:SetText(label); row.cells.name:SetTextColor(red,green,blue)
            row.cells.runs:SetText(Count(e.runs)); row.cells.wins:SetText(Count(e.wins))
            row.cells.lastTime:SetText(Dash(e.lastTime)); row.cells.bestWin:SetText(Dash(e.bestWin))
            row.cells.longest:SetText(Dash(e.longest))
            row.tip=label..(e.name and (" ("..e.name..")") or "")
            row.detail=e.lastDate and K.T("Letzter Run: %s",e.lastDate) or nil
            row:Show()
        else row:Hide() end
    end
    if table.getn(sorted)>0 then emptyText:Hide() else emptyText:Show() end
end
local prev=NavButton("<",160,function() page=(page or 1)-1; offset=0; Render() end)
local nextButton=NavButton(">",370,function() page=(page or 1)+1; offset=0; Render() end)
local close=CreateFrame("Button",nil,panel)
close:SetWidth(100); close:SetHeight(26); close:SetPoint("BOTTOM",panel,"BOTTOM",0,10)
K.Skin(close,7); close.text=K.Text(close,"",10,"CENTER",0,0)
K.Live(close.text,function() return K.T("Schließen") end)
close:SetScript("OnClick",function() panel:Hide() end)
-- Next to the options window (8 pixels left of it) while that is open and the player has not moved this window.
local function Place()
    if R.moved then return end
    local options=KeijinUIOptions
    panel:ClearAllPoints()
    if type(options)=="table" and options:IsShown() then panel:SetPoint("TOPRIGHT",options,"TOPLEFT",-8,0)
    else panel:SetPoint("CENTER",UIParent,"CENTER",0,40) end
end
R.Place=Place
panel:SetScript("OnShow",function() Place(); page=nil; Render() end)
K.OnLang(Render)
R.panel,R.rows,R.zoneText=panel,rows,zoneText
R.prev,R.next=prev,nextButton

function R.Toggle()
    if panel:IsShown() then panel:Hide() else Place(); page=nil; panel:Show(); Render() end
end
function R.Page() return page end

-- /kui runs and /kui runs msg [on|off]
function K.RunsCommand(arg)
    arg=arg or ""
    if arg=="" then R.Toggle(); return end
    if arg=="check" then K.runSnapshots.Check(); return end
    if arg=="debug" then
        local z,runs=AZS_ZONE,Store()
        local open,a=runs.open,runs.announced
        local function S(v) return v==nil and "nil" or tostring(v) end
        K.Say("runs debug: phase="..S(AZS_GetPhase and AZS_GetPhase()).." t="..S(AZS_GetRunTime and AZS_GetRunTime())
            .." won="..S(type(AZS_RUN)=="table" and AZS_RUN.won).." ("..type(type(AZS_RUN)=="table" and AZS_RUN.won)..")"
            .." zone="..(type(z)=="table" and S(z.zone).."/"..S(z.zname).."/"..S(z.class) or "nil")
            .." zoneUpdated="..S(AZS_ZONE_UPDATED).." runUpdated="..S(AZS_RUN_UPDATED).." now="..S(GetTime()))
        K.Say("runs debug: char="..S(CharKey()).." open="..(type(open)=="table" and S(open.zone).."/"..S(open.char).."/"..S(open.last) or "nil")
            .." announced="..(type(a)=="table" and S(a.zone).."/"..S(a.char) or "nil").." needZone="..S(needZone).." msg="..S(R.MessageOn()))
        local trail=K.DB().runTrace or {}
        for i=math.max(1,table.getn(trail)-7),table.getn(trail) do
            local v=trail[i]
            K.Say("runs trace: "..S(v.kind).." "..S(v.zone).."/"..S(v.char).." t="..S(v.t).." "..S(v.detail))
        end
        return
    end
    local _,_,word=string.find(arg,"^msg%s*(%S*)$")
    if word then
        if word=="on" then R.SetMessage(true) elseif word=="off" then R.SetMessage(false) else R.SetMessage(not R.MessageOn()) end
        K.Say(K.T("Run Meldung")..": "..(R.MessageOn() and K.T("An") or K.T("Aus")))
        return
    end
    K.Say(K.T("/kui runs, /kui runs msg"))
end
