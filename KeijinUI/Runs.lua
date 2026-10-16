-- Run overview (0.9.0): per zone and character the number of runs, wins, last time, fastest win and longest survival.
-- Data: AZS_ZONE (sent at the start of a run: zone, zname, class, cname), AZS_RUN (phase, t, won), AZS_GetPhase(), AZS_GetRunTime().
-- The game knows only the current run, so counting starts with the installation of this version.
-- Storage in the account wide KeijinUIDB.runs[zone][charKey] = {name, class, runs, wins, lastTime, lastDate, bestWin, longest}.
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
local zoneAt,gotRun   -- a zone line arrived at this time; has a run line followed?
local MAX_ROWS=10
local MIN_TIME=90    -- seconds of run time before a run counts
local ZONE_NAMES={   -- English names from the game, used while no name was received or stored
    elwynn="Elwynn Forest",duskwood="Duskwood",wsg="Warsong Gulch",ab="Arathi Basin",feralas="Feralas",
    arena="Gurubashi Arena",av="Alterac Valley",brm="Blackrock Mountain",aq="Gates of Ahn'Qiraj"
}
local page,sorted=nil,{}
local offset=0

-- Storage ----------------------------------------------------------------------------------------------
local function Store()
    local db=K.DB()
    if type(db.runs)~="table" then db.runs={} end
    if type(db.runs.names)~="table" then db.runs.names={} end
    return db.runs
end
local function CharKey()
    local name=UnitName and UnitName("player")
    if type(name)~="string" or name=="" then return nil,nil end
    local realm=GetRealmName and GetRealmName()
    if type(realm)=="string" and realm~="" then return name.."-"..realm,name end
    return name,name
end
local function Now() return type(time)=="function" and time() or 0 end
local function Today()
    if type(date)~="function" then return nil end
    local ok,value=pcall(date,"%Y-%m-%d")
    return ok and value or nil
end
-- GetTime() of the last zone line (AZS_ZONE_UPDATED). The game sends the zone line again when the new run's world
-- entry reloads the interface, and that reload wipes the chat: a message from the session before must not count.
local function ZoneStamp()
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
    local c=type(RAID_CLASS_COLORS)=="table" and class and RAID_CLASS_COLORS[class]
    if type(c)=="table" and type(c.r)=="number" then return c.r,c.g,c.b end
    return 1,1,1
end
local function Hex(r,g,b) return string.format("|cff%02x%02x%02x",math.floor(r*255+0.5),math.floor(g*255+0.5),math.floor(b*255+0.5)) end
-- n: number of this run, best and longest: values before this run (or nil).
function R.Message(zname,cname,class,n,best,longest)
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
    e.runs=(K.Number(e.runs) and e.runs or 0)+1
    open.counted=true
    if Render then Render() end
end
-- Writes last time, date and longest survival of the open run into the totals. Safe to repeat.
local function Commit(open)
    if not open.counted then return end
    local e=Entry(open.zone,open.char)
    if not e or not K.Number(open.last) or open.last<=0 then return end
    e.lastTime=open.last; e.lastDate=Today()
    if not K.Number(e.longest) or open.last>e.longest then e.longest=open.last end
end
local function Finish(open)
    if not open.counted and K.Number(open.last) and open.last>=MIN_TIME then Count(open) end
    Commit(open)
    Store().open=nil
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
local function Win(open,t)
    Count(open)
    local e=Entry(open.zone,open.char)
    open.won=true; open.winTime=t
    if not e then return end
    e.wins=(K.Number(e.wins) and e.wins or 0)+1
    if K.Number(t) and (not K.Number(e.bestWin) or t<e.bestWin) then e.bestWin=t end
    if Render then Render() end
end

local function Update()
    if zoneAt and not gotRun then
        if GetTime()-zoneAt<WAIT then return end
        zoneAt=nil
    end
    local z=AZS_ZONE
    if type(z)~="table" or type(z.zone)~="string" or z.zone=="" then return end
    local phase=AZS_GetPhase and AZS_GetPhase()
    if type(phase)~="string" then return end
    local t=AZS_GetRunTime and AZS_GetRunTime()
    if not K.Number(t) then t=nil end
    local key,name=CharKey()
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
            if t and t>open.last then open.last=t end
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
    if t and t>open.last then open.last=t end
    if not open.counted and open.last>=MIN_TIME then Count(open) end
    if type(AZS_RUN)=="table" and AZS_RUN.won==1 and not open.won then Win(open,t or open.last) end
end
R.Update=Update

K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then needZone=false; zoneAt=GetTime(); gotRun=false; Update()
    elseif prefix=="AZSRUN" then gotRun=true; Update() end
end)
local function Save()
    local open=type(KeijinUIDB)=="table" and type(KeijinUIDB.runs)=="table" and KeijinUIDB.runs.open
    if type(open)=="table" then Commit(open) end
end
K.On("PLAYER_LOGOUT",Save)
K.On("PLAYER_LEAVING_WORLD",Save)
table.insert(K.updates,Update)

-- Window -----------------------------------------------------------------------------------------------
local WIDTH=560
local COLUMNS={   -- key, caption, x, width, justify
    {"name","Charakter",5,135,"LEFT"},{"runs","Runs",145,40,"RIGHT"},{"wins","Siege",190,40,"RIGHT"},
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
    K.Live(fs,function() return K.T(c[2]) end)
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
    table.sort(sorted,function(a,b)
        local x,y=string.lower(tostring(a.e.name or a.key)),string.lower(tostring(b.e.name or b.key))
        if x==y then return a.key<b.key end
        return x<y
    end)
    offset=math.min(offset,math.max(0,table.getn(sorted)-MAX_ROWS))
    for i,row in ipairs(rows) do
        local item=sorted[i+offset]
        if item then
            local e=item.e
            local red,green,blue=ClassColor(e.class)
            row.cells.name:SetText(tostring(e.name or item.key)); row.cells.name:SetTextColor(red,green,blue)
            row.cells.runs:SetText(Count(e.runs)); row.cells.wins:SetText(Count(e.wins))
            row.cells.lastTime:SetText(Dash(e.lastTime)); row.cells.bestWin:SetText(Dash(e.bestWin))
            row.cells.longest:SetText(Dash(e.longest))
            row.tip=tostring(e.name or item.key)
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
    if arg=="debug" then
        local z,runs=AZS_ZONE,Store()
        local open,a=runs.open,runs.announced
        local function S(v) return v==nil and "nil" or tostring(v) end
        K.Say("runs debug: phase="..S(AZS_GetPhase and AZS_GetPhase()).." t="..S(AZS_GetRunTime and AZS_GetRunTime())
            .." zone="..(type(z)=="table" and S(z.zone).."/"..S(z.zname).."/"..S(z.class) or "nil")
            .." zoneUpdated="..S(AZS_ZONE_UPDATED).." runUpdated="..S(AZS_RUN_UPDATED).." now="..S(GetTime()))
        K.Say("runs debug: char="..S(CharKey()).." open="..(type(open)=="table" and S(open.zone).."/"..S(open.char).."/"..S(open.last) or "nil")
            .." announced="..(type(a)=="table" and S(a.zone).."/"..S(a.char) or "nil").." needZone="..S(needZone).." msg="..S(R.MessageOn()))
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
