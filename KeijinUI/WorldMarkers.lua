-- 5.0.0 (packages D and E): world markers over chests, guardian lairs, guardians and downed party members.
-- Data: AZS_GetWorldAnchors (catalog of the run: kinds cache, guardianLair, guardian, downedPartyMember; entries with
-- anchorId, attachments, x/y/z, state) and AZS_ProjectWorldAnchors (anchor -> screen offset from WorldFrame, state,
-- entityState, playerDistance in yards), both measured with /kui probe in game 0.139.2. The compass arrows
-- (GuardianNavigation.lua, Caches.lua, Navigation.lua) are not touched.
-- Reading: the anchor list is read at most every M.REFRESH seconds (pages by nextCursor/hasMore, 256 entries per call as
-- the capabilities say). Projecting: once per world frame (AZS_RegisterWorldAnchorFrameHandler), all candidates in ONE call,
-- like DamageTextWorld.lua. The marker frames are written only where a value changed (point, text, symbol, alpha, shown).
-- At most M.MAX markers, downed party members first, then the nearest. Not shown: entries that are not onScreen, opened
-- or empty chests (entityState empty), targets beyond the maximum distance (not for downed party members).
-- Everything is off while the options are off: the handler is not even registered then, so there are no API calls.
-- Package E, assumptions the game test has to prove (the probe ran alone, so downedPartyMember entries were never seen):
--  * entries of kind downedPartyMember carry the same fields as the other kinds; a name (entry.name / entry.memberName) is
--    used only when it is a non empty string, otherwise the name comes from AZS_GetDownedPartyMembers (matched by anchorId
--    or memberId = id), otherwise the marker shows only the symbol and the yards.
--  * entityState "empty" on a downed entry means revived / gone and hides the marker (a revived hero also leaves the list).
--  * AZS_GetDownedPartyMembers() (no arguments) lists the downed heroes of the current map and run, with name in
--    d.name. tostring(nil) would give "nil", so that string is never taken for a name.
--  * Party units party1..party4 may not exist for co-op heroes: "in a group" is only decided negatively when party
--    units were seen once before (K.party.Roster); otherwise the downed list decides.
local K=KeijinUI
local M={}
K.worldMarkers=M
M.MAX=8              -- markers at once
M.REFRESH=0.5        -- seconds between two reads of the anchor list
M.PAGES=4            -- pages per refresh; unfinished scans continue at their saved cursor
M.PAGE_SIZE=256      -- maxEntriesPerCall of the capabilities (probe 0.139.2)
M.CANDIDATES=48      -- anchors projected per frame: retained visible markers plus rotating discovery
M.MARGIN=25          -- yards: the pre selection at the refresh keeps a margin because the hero moves on
M.LIMIT=5            -- consecutive failures of one kind before the module stops until the next reload
M.LIFT=30            -- UI units from the anchor point up to the symbol
M.MIN_DISTANCE=20
M.MAX_DISTANCE=300
M.DEFAULT_DISTANCE=100
local TEMPORARY={NOT_READY=true,NOT_IN_WORLD=true,STREAM_CHANGED=true,CATALOG_CHANGED=true}
local GONE={expired=true,unknownAnchor=true,worldChanged=true}
local DOWNED="downedPartyMember"
local ATLAS="Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local CHEST="Interface\\AddOns\\KeijinUI\\media\\caches\\Chest.tga"
-- Per kind: option switch (part), symbol (chest picture or cell 1..8 of the raid marker sheet), text colour.
local KINDS={
    cache={part="caches",cell=nil,r=1,g=0.82,b=0.28},
    guardianLair={part="lairs",cell=8,r=1,g=0.5,b=0.3},
    guardian={part="guardians",cell=3,r=1,g=0.5,b=0.3},
    [DOWNED]={part="downed",cell=7,r=1,g=0.3,b=0.25},
}
local PARTS={{"caches","cache","worldMarkerCaches"},{"lairs","guardianLair","worldMarkerLairs"},{"guardians","guardian","worldMarkerGuardians"}}

-- Options ---------------------------------------------------------------------------------------------------
function M.On() return K.DB().worldMarkers==true end
function M.Set(on)
    K.DB().worldMarkers=on and true or nil
    M.Apply()
end
-- Chests, lairs and guardians each default on (once the main switch is on).
function M.Part(part)
    for i=1,3 do
        if PARTS[i][1]==part then return K.DB()[PARTS[i][3]]~=false end
    end
    return false
end
function M.SetPart(part,on)
    for i=1,3 do
        if PARTS[i][1]==part then
            if on then K.DB()[PARTS[i][3]]=nil else K.DB()[PARTS[i][3]]=false end
        end
    end
    M.Apply()
end
function M.Distance()
    local value=K.DB().worldMarkerDistance
    if type(value)~="number" or value~=value then return M.DEFAULT_DISTANCE end
    return math.max(M.MIN_DISTANCE,math.min(M.MAX_DISTANCE,value))
end
function M.SetDistance(value)
    value=tonumber(value)
    if not value or value~=value then return end
    value=math.floor(math.max(M.MIN_DISTANCE,math.min(M.MAX_DISTANCE,value))+0.5)
    K.DB().worldMarkerDistance=value~=M.DEFAULT_DISTANCE and value or nil
end
-- Package E: default on, because it only does something in a group.
function M.DownedOn() return K.DB().worldMarkerDowned~=false end
function M.SetDownedOn(on)
    if on then K.DB().worldMarkerDowned=nil else K.DB().worldMarkerDowned=false end
    M.Apply()
end
local function AnyPart()
    return M.Part("caches") or M.Part("lairs") or M.Part("guardians")
end

-- State -----------------------------------------------------------------------------------------------------
local host=CreateFrame("Frame","KeijinUIWorldMarkers",UIParent)
host:SetFrameStrata("BACKGROUND"); host:SetWidth(1); host:SetHeight(1)
host:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0); host:EnableMouse(false)
local markers={}       -- the pool of M.MAX frames, built on first use
local recs={}          -- all eligible catalog records; projected in bounded rotating batches
local recCount=0
local byId={}          -- anchorId -> record (reused across refreshes so the request tables stay)
local requests={}      -- request tables of recs[1..recCount], handed to the projection
local vis={}           -- visible records of the frame, sorted
local visCount=0
local downedNames,downedById,downedByAnchor={},{},{}
local registered=false
local broken=false
local dirty=true
local lastRefresh
local listWorld,worldKey,playerKey
local readFailures,projectFailures,frameFailures,downedFailures=0,0,0,0
local lastError
local framePlayer,playerFrame,frameNo=nil,-1,0
M.projected={}
M.selected={}
M.requestCount=0
M.sweep=0

M.markers=markers
function M.Available()
    return not broken and type(AZS_GetWorldAnchors)=="function" and type(AZS_ProjectWorldAnchors)=="function"
        and type(AZS_RegisterWorldAnchorFrameHandler)=="function"
end
function M.Wanted()
    return M.Available() and ((M.On() and AnyPart()) or M.DownedOn())
end
-- True when the name belongs to a downed party member (package E, used by Party.lua). A table lookup, no API call.
function M.IsDowned(name)
    return type(name)=="string" and downedNames[name]==true
end

local function Finite(n) return type(n)=="number" and n==n and n>-1e15 and n<1e15 end

-- Marker frames ---------------------------------------------------------------------------------------------
local function Build(i)
    local m=CreateFrame("Frame","KeijinUIWorldMarker"..i,host)
    m:SetWidth(16); m:SetHeight(16); m:EnableMouse(false); m:Hide()
    m.tex=m:CreateTexture(nil,"OVERLAY")
    m.tex:SetWidth(16); m.tex:SetHeight(16); m.tex:SetPoint("TOP",m,"TOP",0,0)
    m.fs=m:CreateFontString(nil,"OVERLAY")
    m.fs:SetFont(K.font,10,"OUTLINE")   -- game 0.101 refuses SetText before a font is set
    m.fs:SetWidth(120); m.fs:SetJustifyH("CENTER"); m.fs:SetPoint("TOP",m,"BOTTOM",0,-1)
    m.font=K.font; m.shown=false
    markers[i]=m
    return m
end
local function Hide(m)
    if m.shown then m:Hide(); m.shown=false end
end
local function HideFrom(first)
    for i=first,table.getn(markers) do Hide(markers[i]) end
end
-- Writes only what differs from what the marker holds.
local function Show(m,rec,x,y,k)
    local style=KINDS[rec.kind]
    if m.kind~=rec.kind then
        m.kind=rec.kind
        if style.cell then
            local column=math.mod(style.cell-1,4)*0.25
            local row=math.floor((style.cell-1)/4)*0.25
            m.tex:SetTexture(ATLAS); m.tex:SetTexCoord(column,column+0.25,row,row+0.25)
        else
            m.tex:SetTexture(CHEST); m.tex:SetTexCoord(0,1,0,1)
        end
        m.fs:SetTextColor(style.r,style.g,style.b)
    end
    if m.font~=K.font then m.font=K.font; m.fs:SetFont(K.font,10,"OUTLINE") end
    local text
    if rec.dist then text=string.format("%d yd",math.floor(rec.dist+0.5)) else text="" end
    if rec.name then text=rec.name.."\n"..text end
    if m.text~=text then m.text=text; m.fs:SetText(text) end
    local alpha=rec.dim and 0.5 or 1
    if m.alpha~=alpha then m.alpha=alpha; m:SetAlpha(alpha) end
    local px,py=math.floor(x*k*2+0.5)/2,math.floor((y*k+M.LIFT)*2+0.5)/2
    if m.px~=px or m.py~=py then
        m.px,m.py=px,py
        m:ClearAllPoints(); m:SetPoint("BOTTOM",WorldFrame,"BOTTOMLEFT",px,py)
    end
    if not m.shown then m:Show(); m.shown=true end
end

-- Data ------------------------------------------------------------------------------------------------------
local function Count(kind)
    if kind=="read" then readFailures=readFailures+1
    elseif kind=="downed" then downedFailures=downedFailures+1
    elseif kind=="project" then projectFailures=projectFailures+1
    else frameFailures=frameFailures+1 end
    if readFailures>=M.LIMIT or downedFailures>=M.LIMIT or projectFailures>=M.LIMIT or frameFailures>=M.LIMIT then
        broken=true; M.Clear(); M.Apply()
    end
end
-- Forget the list and hide everything (map change, module off, failure). Names of downed members go too.
-- keepRefresh: hide and forget, but the next read of the catalog still waits for M.REFRESH (used when the projection
-- reports another world: the catalog must not be asked on every frame).
function M.Clear(keepRefresh)
    HideFrom(1)
    for id in pairs(byId) do byId[id]=nil end
    for i=recCount,1,-1 do recs[i]=nil; requests[i]=nil end
    recCount=0
    M.scan=nil; M.sweep=0
    for i=M.requestCount,1,-1 do M.projected[i]=nil; requests[i]=nil end
    for id in pairs(M.selected) do M.selected[id]=nil end
    M.requestCount=0
    for i=visCount,1,-1 do vis[i]=nil end
    visCount=0
    for k in pairs(downedNames) do downedNames[k]=nil end
    for k in pairs(downedById) do downedById[k]=nil end
    for k in pairs(downedByAnchor) do downedByAnchor[k]=nil end
    listWorld,worldKey,playerKey=nil,nil,nil
    dirty=true
    if not keepRefresh then lastRefresh=nil end
end
local function Player()
    if type(AZS_GetPlayerPosition)~="function" then return nil end
    local ok,p=pcall(AZS_GetPlayerPosition)
    if ok and type(p)=="table" and Finite(p.x) and Finite(p.y) then return p end
    return nil
end
-- Yards between a record and the hero: 3D with both heights, 2D otherwise; nothing across spaces.
local function Compute(rec,p)
    if not p or not Finite(rec.x) or not Finite(rec.y) then return nil end
    if rec.spaceId~=nil and p.spaceId~=nil and rec.spaceId~=p.spaceId then return nil end
    local dx,dy=rec.x-p.x,rec.y-p.y
    if Finite(rec.z) and Finite(p.z) then
        local dz=rec.z-p.z
        return math.sqrt(dx*dx+dy*dy+dz*dz)
    end
    return math.sqrt(dx*dx+dy*dy)
end
local function InGroup()
    if K.party and K.party.Roster then
        local roster,known=K.party.Roster()
        if known then return roster~=nil end
    end
    return true
end
-- AZS_GetDownedPartyMembers() has no arguments. Names for the markers and the party window; nil without a list.
local function ReadDowned()
    for k in pairs(downedNames) do downedNames[k]=nil end
    for k in pairs(downedById) do downedById[k]=nil end
    for k in pairs(downedByAnchor) do downedByAnchor[k]=nil end
    if not M.DownedOn() or not InGroup() then return false end
    if type(AZS_GetDownedPartyMembers)~="function" then return true end
    local ok,list,err=pcall(AZS_GetDownedPartyMembers)
    if not ok then Count("downed"); return true end
    if type(list)~="table" then
        if not (type(err)=="table" and TEMPORARY[err.code]) then Count("downed") end
        return true   -- unknown: the anchor list decides
    end
    downedFailures=0
    local n=0
    for i=1,table.getn(list) do
        local d=list[i]
        if type(d)=="table" then
            n=n+1
            if type(d.name)=="string" and d.name~="" and d.name~="nil" then downedNames[d.name]=true end
            if d.id~=nil then downedById[d.id]=d end
            if d.anchorId~=nil then downedByAnchor[d.anchorId]=d end
        end
    end
    return n>0
end
local function NameOf(entry)
    local name=entry.name
    if type(name)~="string" or name=="" then name=entry.memberName end
    if type(name)=="string" and name~="" and name~="nil" then return name end
    local d=downedByAnchor[entry.anchorId]
    if not d and entry.memberId~=nil then d=downedById[entry.memberId] end
    if d and type(d.name)=="string" and d.name~="" and d.name~="nil" then return d.name end
    return nil
end
-- First offered attachment, "position" preferred (overhead was refused for chests: unsupportedAttachment).
local function AttachmentOf(entry)
    local offered=entry.attachments
    if type(offered)~="table" or offered[1]==nil then return "position" end
    for i=1,table.getn(offered) do
        if offered[i]=="position" then return "position" end
    end
    return offered[1]
end
local function Before(a,b)
    local da,db=a.kind==DOWNED,b.kind==DOWNED
    if da~=db then return da end
    local xa,xb=a.sort or 1e9,b.sort or 1e9
    if xa~=xb then return xa<xb end
    return tostring(a.id)<tostring(b.id)
end
local function Query(wantDowned)
    local kinds={}
    if M.On() then
        for i=1,3 do
            if M.Part(PARTS[i][1]) then table.insert(kinds,PARTS[i][2]) end
        end
    end
    if wantDowned then table.insert(kinds,DOWNED) end
    return kinds
end
-- Reads the pages of the list. Returns the entries or nil (nothing usable, the old list stays), plus the first batch.
local function ReadPages(query)
    local key=table.concat(query.kinds,",")
    local scan=M.scan
    if not scan or scan.key~=key then
        scan={key=key,entries={}}; M.scan=scan
    end
    for page=1,M.PAGES do
        -- exactly three arguments: a trailing nil would still count, a missing one is refused
        local ok,batch,err=pcall(AZS_GetWorldAnchors,query,scan.cursor,M.PAGE_SIZE)
        if not ok then M.scan=nil; Count("read"); return nil end
        if type(batch)~="table" then
            M.scan=nil
            if not (type(err)=="table" and TEMPORARY[err.code]) then Count("read") end
            return nil
        end
        if not scan.first then scan.first=batch
        elseif batch.catalogId~=scan.first.catalogId or batch.worldId~=scan.first.worldId then
            M.scan=nil; return nil
        end
        local entries=batch.entries
        if type(entries)=="table" then
            for i=1,table.getn(entries) do table.insert(scan.entries,entries[i]) end
        end
        -- hasMore is not documented: a new nextCursor (different from the last one) is enough to go on.
        if batch.nextCursor==nil or batch.nextCursor==scan.cursor or batch.hasMore==false then
            M.scan=nil; readFailures=0
            return scan.entries,scan.first,true
        end
        scan.cursor=batch.nextCursor
    end
    -- Continue this exact query next refresh instead of restarting at page one.
    -- Only a completed catalog clears failures; good prefixes must not mask a broken later page.
    return scan.entries,scan.first,false
end
local function Refresh(now)
    lastRefresh=now; dirty=false
    local wantDowned=ReadDowned()
    if broken then return end   -- ReadDowned may have stopped the module: nothing more to ask or project
    local kinds=Query(wantDowned)
    if table.getn(kinds)==0 then
        for i=recCount,1,-1 do recs[i]=nil; requests[i]=nil end
        recCount=0
        HideFrom(1)
        return
    end
    -- A new map, space or run (position data): the old records and markers go at once.
    local player=Player()
    if player then
        local key=tostring(player.mapId)..":"..tostring(player.spaceId)..":"..tostring(player.runId)
        if playerKey~=nil and key~=playerKey then
            M.Clear(); lastRefresh=now; dirty=false
            wantDowned=ReadDowned()
            if broken then return end
        end
        playerKey=key
    end
    local entries,first,complete=ReadPages({kinds=kinds})
    if broken or not entries then return end
    -- The dedicated downed API supplies ready anchors independently of catalog order.
    -- Keep these separate: never append to the persistent pagination buffer.
    local extra={}
    for _,d in pairs(downedByAnchor) do
        if d.anchorStatus=="ready" and d.positionAvailable~=false then
            table.insert(extra,{anchorId=d.anchorId,kind=DOWNED,name=d.name,x=d.x,y=d.y,z=d.z,spaceId=d.spaceId})
        end
    end
    -- A new world or space: the old records and markers go at once, whatever the list says.
    local key=tostring(first.worldId)..":"..tostring(first.spaceId)
    if worldKey~=nil and key~=worldKey then
        HideFrom(1)
        for id in pairs(byId) do byId[id]=nil end
    end
    worldKey=key; listWorld=first.worldId
    local limit=M.Distance()+M.MARGIN
    local fresh,count={},0
    local old=byId
    byId={}
    local allowed={}
    for _,kind in ipairs(kinds) do allowed[kind]=true end
    for i=1,table.getn(entries)+table.getn(extra) do
        local e=entries[i] or extra[i-table.getn(entries)]
        local style=type(e)=="table" and e.anchorId~=nil and KINDS[e.kind]
        if style and e.positionAvailable~=false and not (e.state=="empty" and (e.kind=="cache" or e.kind==DOWNED)) then
            local rec=old[e.anchorId] or byId[e.anchorId]
            if not rec then
                rec={id=e.anchorId,req={anchorId=e.anchorId,attachment="position",offset={x=0,y=0,z=0}}}
            end
            rec.kind=e.kind; rec.gone=nil
            rec.x,rec.y,rec.z,rec.spaceId=e.x,e.y,e.z,e.spaceId
            rec.sort=Compute(rec,player)
            if rec.kind==DOWNED then rec.name=NameOf(e) else rec.name=nil end
            local attachment=AttachmentOf(e)
            if rec.req.attachment~=attachment then rec.req.attachment=attachment end
            if rec.kind==DOWNED or rec.sort==nil or rec.sort<=limit then
                if not byId[rec.id] then count=count+1; fresh[count]=rec end
                byId[rec.id]=rec
            end
        end
    end
    -- Keep the previous completed catalog while a large new scan is still in flight.
    -- Disabled kinds and revived party members never survive this merge.
    if not complete then
        for id,rec in pairs(old) do
            if not byId[id] and allowed[rec.kind] and not rec.gone
                and (rec.kind~=DOWNED or downedByAnchor[id] or rec.name and downedNames[rec.name]) then
                rec.sort=Compute(rec,player)
                if rec.kind==DOWNED or rec.sort==nil or rec.sort<=limit then
                    count=count+1; fresh[count]=rec; byId[id]=rec
                end
            end
        end
    end
    table.sort(fresh,Before)
    for i=recCount,1,-1 do recs[i]=nil end
    for i=1,count do recs[i]=fresh[i] end
    recCount=count
end

-- Per frame --------------------------------------------------------------------------------------------------
local function SelectRequests()
    for id in pairs(M.selected) do M.selected[id]=nil end
    local n=0
    -- Downed friends first, then reproject current visible markers every frame.
    for i=1,math.min(recCount,M.MAX) do
        local rec=recs[i]
        if rec.kind==DOWNED and not rec.gone then
            n=n+1; M.projected[n]=rec; requests[n]=rec.req; M.selected[rec.id]=true
        end
    end
    for i=1,math.min(visCount,M.MAX) do
        local rec=byId[vis[i].id]
        if rec and not rec.gone and not M.selected[rec.id] then
            n=n+1; M.projected[n]=rec; requests[n]=rec.req; M.selected[rec.id]=true
        end
    end
    -- Probe the remainder fairly. Offscreen anchors cannot permanently exclude later ones.
    local seen=0
    while n<M.CANDIDATES and seen<recCount do
        M.sweep=math.mod(M.sweep,recCount)+1; seen=seen+1
        local rec=recs[M.sweep]
        if not rec.gone and not M.selected[rec.id] then
            n=n+1; M.projected[n]=rec; requests[n]=rec.req; M.selected[rec.id]=true
        end
    end
    for i=M.requestCount,n+1,-1 do requests[i]=nil; M.projected[i]=nil end
    M.requestCount=n
end
local function FramePlayer()
    if playerFrame~=frameNo then playerFrame=frameNo; framePlayer=Player() end
    return framePlayer
end
local function Step()
    frameNo=frameNo+1
    local now=GetTime()
    if lastRefresh==nil or now<lastRefresh or now-lastRefresh>=M.REFRESH then Refresh(now) end
    if broken then HideFrom(1); return end
    if recCount==0 then HideFrom(1); return end
    SelectRequests()
    local ok,result,err=pcall(AZS_ProjectWorldAnchors,requests)
    if not ok then HideFrom(1); Count("project"); return end
    if type(result)~="table" or type(result.entries)~="table" then
        HideFrom(1)
        if not (type(err)=="table" and TEMPORARY[err.code]) then Count("project") end
        return
    end
    projectFailures=0
    if result.worldId~=nil and listWorld~=nil and result.worldId~=listWorld then
        M.Clear(true); return
    end
    local entries=result.entries
    local maxDistance=M.Distance()
    local n=0
    for j=1,M.requestCount do
        local entry=entries[j]
        local rec=M.projected[j]
        if type(entry)=="table" and entry.anchorId~=nil and entry.anchorId~=rec.id then rec=byId[entry.anchorId] end
        if rec and not rec.gone and type(entry)=="table" then
            local state=entry.state
            if state=="onScreen" and Finite(entry.x) and Finite(entry.y) then
                local empty=entry.entityState=="empty"
                if not (empty and (rec.kind=="cache" or rec.kind==DOWNED)) then
                    local dist=entry.playerDistance
                    if not (Finite(dist) and dist>=0) then
                        dist=Compute(rec,FramePlayer())
                        if dist==nil then dist=rec.sort end
                    end
                    if rec.kind==DOWNED or dist==nil or dist<=maxDistance then
                        n=n+1
                        vis[n]=rec
                        rec.px,rec.py,rec.dist,rec.sort=entry.x,entry.y,dist,dist or rec.sort
                        rec.dim=empty
                    end
                end
            elseif GONE[state] then rec.gone=true end   -- hidden now, the catalog is read again at the next M.REFRESH
        end
    end
    for i=visCount,n+1,-1 do vis[i]=nil end
    visCount=n
    table.sort(vis,Before)
    -- Projection x/y are WorldFrame units, SetPoint offsets are in the marker's own units: k converts (as in DamageTextWorld).
    local k=1
    local ws=WorldFrame and WorldFrame.GetEffectiveScale and WorldFrame:GetEffectiveScale()
    local hs=host:GetEffectiveScale()
    if Finite(ws) and Finite(hs) and ws>0 and hs>0 then k=ws/hs end
    local shown=math.min(n,M.MAX)
    for i=1,shown do
        local rec=vis[i]
        Show(markers[i] or Build(i),rec,rec.px,rec.py,k)
    end
    HideFrom(shown+1)
end
-- Called once per world frame after the camera moved. Guarded: an error is reported once per message, counted, and
-- never leaves old markers frozen on the screen.
function M.Frame()
    if not M.Wanted() then return end
    local ok,err=pcall(Step)
    if ok then frameFailures=0; return end
    if err~=lastError then
        lastError=err
        if type(geterrorhandler)=="function" then geterrorhandler()(err) end
    end
    HideFrom(1)
    Count("frame")
end

-- Switching ---------------------------------------------------------------------------------------------------
-- Registers the frame handler while something is wanted and takes it off (and clears) otherwise: with every option off
-- the module makes no API call at all.
function M.Apply()
    if M.Wanted() then
        if not registered and type(AZS_RegisterWorldAnchorFrameHandler)=="function" then
            local ok,result=pcall(AZS_RegisterWorldAnchorFrameHandler,M.Frame)
            registered=ok and result~=nil and result~=false
            dirty=true
        end
    else
        if registered and type(AZS_UnregisterWorldAnchorFrameHandler)=="function" then
            pcall(AZS_UnregisterWorldAnchorFrameHandler,M.Frame)
        end
        registered=false
        M.Clear()
    end
end
-- A new world frame handler list after loading: register again (a second registration is ignored by the game).
local function Enter()
    M.Clear(); registered=false; M.Apply()
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then Enter() end end)
K.On("PLAYER_ENTERING_WORLD",Enter)
K.On("PLAYER_LEAVING_WORLD",function()
    if registered and type(AZS_UnregisterWorldAnchorFrameHandler)=="function" then pcall(AZS_UnregisterWorldAnchorFrameHandler,M.Frame) end
    registered=false
    M.Clear()
end)
-- Leaving or changing the group: downed markers go at once, not after the next refresh.
K.On("PARTY_MEMBERS_CHANGED",function() dirty=true; if not InGroup() then M.Clear() end end)
