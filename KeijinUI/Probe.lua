-- Diagnosis for game tests (/kui probe): reads the unproven fields of the client API 0.139.2 once, on command,
-- and writes them as flat text lines to K.DB().probe. No events, no OnUpdate, no influence on other modules.
local K=KeijinUI
local P={LIMIT=40,CHAT=30,MAXPAGES=4}
K.probe=P
local PARTS={"damageText","position","capabilities","worldAnchors","projection","downed","combatText","combatProjection","distance"}
local function Say(text)
    DEFAULT_CHAT_FRAME:AddMessage("[KUI Probe] "..text)
end
local function Short(value)
    return string.sub(string.gsub(tostring(value),"[\r\n]"," "),1,120)
end
local function SortKeys(a,b)
    return tostring(a)<tostring(b)
end
local function Add(lines,text)
    if table.getn(lines)<P.LIMIT then table.insert(lines,text)
    else lines.dropped=(lines.dropped or 0)+1 end
end
-- A part that hit the limit says so in its last line.
local function Finish(lines)
    if lines.dropped then
        lines[P.LIMIT]="... gekuerzt: ausgegeben "..(P.LIMIT-1).." Zeilen, "..(lines.dropped+1).." weitere verworfen"
        lines.dropped=nil
    end
end
-- Flat serialization: path=value (type), tables recursively (depth 3).
local function Dump(lines,path,value,depth)
    if type(value)~="table" then
        Add(lines,path.."="..Short(value).." ("..type(value)..")")
    elseif depth>=3 then
        Add(lines,path.." = table (depth limit)")
    else
        local keys={}
        for key in pairs(value) do table.insert(keys,key) end
        table.sort(keys,SortKeys)
        if table.getn(keys)==0 then Add(lines,path.." = {} (empty)") end
        for i=1,table.getn(keys) do
            Dump(lines,path.."."..tostring(keys[i]),value[keys[i]],depth+1)
        end
    end
end
-- Missing function: "fehlt". pcall error: the message. API error (nil,err): code and message.
-- The client checks the exact argument count, so the call passes exactly `count` arguments.
local function Call(lines,name,count,a,b,c)
    local fn=getglobal(name)
    if type(fn)~="function" then Add(lines,name..": fehlt"); return nil end
    local ok,result,err
    if count==0 then ok,result,err=pcall(fn)
    elseif count==1 then ok,result,err=pcall(fn,a)
    elseif count==2 then ok,result,err=pcall(fn,a,b)
    else ok,result,err=pcall(fn,a,b,c) end
    if not ok then Add(lines,name..": Fehler "..Short(result)); return nil end
    if result==nil then
        Add(lines,name..": nil, Fehler "..(type(err)=="table" and (tostring(err.code).." / "..tostring(err.message)) or Short(err)))
        return nil
    end
    return result
end
local function DumpEach(lines,label,list,limit)
    if type(list)~="table" then return end
    local count=table.getn(list)
    Add(lines,label..": "..count.." Eintraege, ausgegeben "..math.min(count,limit))
    for i=1,math.min(count,limit) do Dump(lines,label.."["..i.."]",list[i],0) end
end
local function IdOf(entry)
    if type(entry)~="table" then return nil end
    return entry.anchorId or entry.id
end
local function Scalars(lines,prefix,batch)
    for key,value in pairs(batch) do
        if type(value)~="table" then Dump(lines,prefix.."."..tostring(key),value,0)
        else Add(lines,prefix.."."..tostring(key).." = table, "..table.getn(value).." Eintraege") end
    end
end

-- World position of a catalog entry or event: x,y,z directly or in a position/world sub table.
local function WorldPos(t)
    if type(t)~="table" then return nil end
    local c=t
    if type(t.position)=="table" then c=t.position elseif type(t.world)=="table" then c=t.world
    elseif type(t.worldPosition)=="table" then c=t.worldPosition end
    if type(c.x)=="number" and type(c.y)=="number" then return c,(c.spaceId or t.spaceId),(c.mapId or t.mapId) end
    return nil
end
-- Own part with its own limit: catalog/event position against the player, next to the client's playerDistance.
-- 3D only with both heights, nothing is computed across spaces or maps.
local function Distance(label,src,playerDistance)
    local lines=P.distance
    local a,space,map=WorldPos(src)
    local p=P.player
    if not a then Add(lines,label..": keine Weltposition im Eintrag, playerDistance="..tostring(playerDistance)); return end
    if not p then Add(lines,label..": ohne Spielerposition, playerDistance="..tostring(playerDistance)); return end
    if (space~=nil and p.spaceId~=nil and space~=p.spaceId) or (map~=nil and p.mapId~=nil and map~=p.mapId) then
        Add(lines,label..": anderer Raum (Anker space="..tostring(space).." map="..tostring(map)..", Spieler space="
            ..tostring(p.spaceId).." map="..tostring(p.mapId).."), playerDistance="..tostring(playerDistance))
        return
    end
    local dx,dy=a.x-p.x,a.y-p.y
    local text=string.format("2D=%.2f",math.sqrt(dx*dx+dy*dy))
    if type(a.z)=="number" and type(p.z)=="number" then
        local dz=a.z-p.z
        text=string.format("3D=%.2f ",math.sqrt(dx*dx+dy*dy+dz*dz))..text
    end
    Add(lines,string.format("%s: Anker %.2f,%.2f,%s Spieler %.2f,%.2f,%s %s playerDistance=%s",label,a.x,a.y,tostring(a.z),
        p.x,p.y,tostring(p.z),text,tostring(playerDistance)))
end
local function Position(lines)
    local p=Call(lines,"AZS_GetPlayerPosition",0)
    if p then
        Dump(lines,"position",p,0)
        if type(p.x)=="number" and type(p.y)=="number" then P.player=p end
    end
end
-- Written on every call. A failed or empty answer keeps the last good one (marked) so the part is never blank.
local function Capabilities(lines)
    local caps=Call(lines,"AZS_GetWorldAnchorCapabilities",0)
    if type(caps)=="table" and next(caps)~=nil then P.caps=caps
    elseif P.caps then
        Add(lines,"worldAnchorCaps: leer oder Fehler, letzte gueltige Antwort")
        caps=P.caps
    end
    if caps then Dump(lines,"worldAnchorCaps",caps,0) end
    local ct=Call(lines,"AZS_GetCombatTextCapabilities",0)
    if type(ct)=="table" and next(ct)~=nil then P.ctCaps=ct
    elseif P.ctCaps then
        Add(lines,"combatTextCaps: leer oder Fehler, letzte gueltige Antwort")
        ct=P.ctCaps
    end
    if ct then Dump(lines,"combatTextCaps",ct,0) end
    return caps
end
-- One line per kind (count, count with playerDistance), so rare kinds stay visible despite the line limit.
local function KindSummary(lines,list)
    local kinds,names={},{}
    for i=1,table.getn(list) do
        local a=list[i]
        local kind=type(a)=="table" and tostring(a.kind) or "?"
        if not kinds[kind] then kinds[kind]={0,0}; table.insert(names,kind) end
        kinds[kind][1]=kinds[kind][1]+1
        if type(a)=="table" and a.playerDistance~=nil then kinds[kind][2]=kinds[kind][2]+1 end
    end
    table.sort(names)
    for i=1,table.getn(names) do
        Add(lines,"kind["..names[i].."]: "..kinds[names[i]][1].." Anker, "..kinds[names[i]][2].." mit playerDistance")
    end
end
local function ListOf(batch)
    local list=batch.anchors or batch.entries or batch.items
    if type(list)~="table" then
        for _,value in pairs(batch) do
            if type(value)=="table" and value[1]~=nil then list=value; break end
        end
    end
    return list
end
-- The summary reads up to MAXPAGES pages (nextCursor/hasMore, limit up to maxEntriesPerCall); single lines and projection keep the first 20.
local function Anchors(lines,caps)
    local query=nil
    local limit=20
    if type(caps)=="table" then
        if type(caps.kinds)=="table" then query={kinds=caps.kinds} end
        if type(caps.maxEntriesPerCall)=="number" and caps.maxEntriesPerCall>=1 then limit=math.min(256,math.floor(caps.maxEntriesPerCall)) end
    end
    local batch=Call(lines,"AZS_GetWorldAnchors",3,query,nil,limit)
    if not batch then
        query=nil
        batch=Call(lines,"AZS_GetWorldAnchors",3,nil,nil,limit)
    end
    if type(batch)~="table" then return nil end
    Scalars(lines,"batch",batch)
    local list=ListOf(batch)
    local all={}
    local page,pages=batch,1
    while true do
        local items=ListOf(page)
        if type(items)=="table" then
            for i=1,table.getn(items) do table.insert(all,items[i]) end
        end
        if pages>=P.MAXPAGES or not (page.hasMore==true and page.nextCursor~=nil) then break end
        page=Call(lines,"AZS_GetWorldAnchors",3,query,page.nextCursor,limit)
        if type(page)~="table" then break end
        pages=pages+1
    end
    Add(lines,"anchors gesamt: "..table.getn(all).." in "..pages.." Aufrufen")
    KindSummary(lines,all)
    DumpEach(lines,"anchor",list,20)
    return list
end
local function Projection(lines,list)
    if type(list)~="table" then Add(lines,"keine Anker zum Projizieren"); return end
    local requests,sources={},{}
    for i=1,math.min(5,table.getn(list)) do
        local id=IdOf(list[i])
        if id~=nil then
            table.insert(sources,list[i])
            -- First offered attachment ("position" preferred); without a list the old "overhead" guess.
            local attach,offsetZ="overhead",2
            local offered=list[i].attachments
            if type(offered)=="table" and offered[1]~=nil then
                attach=offered[1]
                for j=1,table.getn(offered) do
                    if offered[j]=="position" then attach="position"; break end
                end
                offsetZ=0
            end
            table.insert(requests,{anchorId=id,attachment=attach,offset={x=0,y=0,z=offsetZ}})
        end
    end
    if table.getn(requests)==0 then Add(lines,"Anker ohne id/anchorId"); return end
    local result=Call(lines,"AZS_ProjectWorldAnchors",1,requests)
    if type(result)~="table" then return end
    Scalars(lines,"result",result)
    local entries=result.entries or result.projections or result
    DumpEach(lines,"projection",entries,5)
    -- For the distance check: the catalog point itself (attachment position, no offset), not the overhead point.
    local flat={}
    for i=1,table.getn(requests) do
        flat[i]={anchorId=requests[i].anchorId,attachment="position",offset={x=0,y=0,z=0}}
    end
    local at=Call(P.distance,"AZS_ProjectWorldAnchors",1,flat)
    local atEntries=type(at)=="table" and (at.entries or at.projections or at)
    for i=1,table.getn(sources) do
        local entry=type(atEntries)=="table" and atEntries[i]
        Distance("worldDistance["..i.."]",sources[i],type(entry)=="table" and entry.playerDistance or nil)
    end
end
local function Downed(lines)
    local list=Call(lines,"AZS_GetDownedPartyMembers",0)
    if type(list)~="table" then return end
    if table.getn(list)==0 then Add(lines,"keine gefallenen Gruppenmitglieder") end
    DumpEach(lines,"downed",list,P.LIMIT)
end
-- Own cursor: the first run subscribes at the tail, later runs read from there. The damage text module's cursor stays untouched.
local function CombatText(lines)
    local batch=Call(lines,"AZS_GetCombatTextEvents",2,P.cursor,10)
    if not batch and P.cursor then
        P.cursor=nil
        batch=Call(lines,"AZS_GetCombatTextEvents",2,nil,10)
    end
    local ids,events
    if type(batch)=="table" then
        P.cursor=batch.cursor
        Scalars(lines,"batch",batch)
        events=batch.events
        if type(events)=="table" then
            ids={}
            DumpEach(lines,"event",events,10)
            for i=1,table.getn(events) do
                if type(events[i])=="table" and events[i].anchorId~=nil then table.insert(ids,events[i].anchorId) end
            end
        end
    end
    return ids,events
end
local function CombatProjection(lines,ids,events)
    if type(ids)~="table" or table.getn(ids)==0 then
        Add(lines,"keine Ereignisse mit anchorId: Befehl nach einem Treffer erneut")
        return
    end
    local request={}
    for i=1,math.min(5,table.getn(ids)) do request[i]=ids[i] end
    local result=Call(lines,"AZS_ProjectCombatTextAnchors",2,request,"follow")
    if type(result)~="table" then return end
    Scalars(lines,"result",result)
    DumpEach(lines,"entry",result.entries,5)
    if type(result.entries)=="table" then
        for i=1,table.getn(request) do
            local src
            for j=1,table.getn(events or {}) do
                if events[j].anchorId==request[i] then src=events[j]; break end
            end
            local entry=result.entries[i]
            Distance("textDistance["..i.."]",src,type(entry)=="table" and entry.playerDistance or nil)
        end
    end
end

local function Guard(lines,fn,a,b)
    local ok,r1,r2=pcall(fn,lines,a,b)
    if not ok then Add(lines,"unerwarteter Fehler: "..Short(r1)); return nil end
    return r1,r2
end
function P.Run(verbose)
    local parts={}
    for i=1,table.getn(PARTS) do parts[PARTS[i]]={} end
    P.player=nil; P.distance=parts.distance
    Guard(parts.position,Position)
    local caps=Guard(parts.capabilities,Capabilities)
    local list=Guard(parts.worldAnchors,Anchors,caps)
    Guard(parts.projection,Projection,list)
    Guard(parts.downed,Downed)
    local ids,events=Guard(parts.combatText,CombatText)
    Guard(parts.combatProjection,CombatProjection,ids,events)
    for i=1,table.getn(PARTS) do Finish(parts[PARTS[i]]) end
    parts.time=GetTime()
    -- Raw loot events of the loot module (collection note diagnosis), outside PARTS.
    local rawLines={}
    local events=K.loot and K.loot.RawEvents and K.loot.RawEvents() or {}
    for i=1,table.getn(events) do
        local e=events[i]
        table.insert(rawLines,string.format("%.1f %s",e.time or 0,tostring(e.event)))
        for j=1,9 do table.insert(rawLines,"  arg"..j.."="..Short(e[j])) end
    end
    parts.loot=rawLines
    K.DB().probe=parts
    local summary=""
    for i=1,table.getn(PARTS) do
        summary=summary..PARTS[i].."="..table.getn(parts[PARTS[i]]).." "
    end
    Say(summary.."Beute-Rohereignisse="..table.getn(events).." (Zeilen, gespeichert unter probe)")
    if verbose then
        local shown=0
        for i=2,table.getn(PARTS) do
            local lines=parts[PARTS[i]]
            for j=1,table.getn(lines) do
                if shown<P.CHAT then Say(PARTS[i]..": "..lines[j]); shown=shown+1 end
            end
        end
        if shown>=P.CHAT then Say("... weitere Zeilen in den SavedVariables") end
    end
end
