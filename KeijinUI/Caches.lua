-- Caches on the minimap (0.8.0): chest symbols, an arrow at the minimap edge and an optional arrow on the screen.
-- Data: AZS_CHESTS (id, x, y, z world position, mx and my on the zone map, -1 without map data), AZS_LAIRS (same
-- position fields), AZS_RUN.chest (price of the next cache) and GetPlayerMapPosition("player").
-- Native px/py/pf are preferred, including instances. Older clients use a map scale measured from
-- pairs of points that have both a world and a map position (caches and lairs): for two points the world distance
-- squared equals (sx*dmx)^2+(sy*dmy)^2, solved by least squares over all pairs. Without a measurement nothing is drawn.
-- The minimap view diameter per zoom level is the client's own table (outdoors 14, 12, 10, 8, 6, 4 chunks of
-- 33.33 yards, indoors twice the radii 150, 120, 90, 60, 40, 25), the minimap is north up.
-- 1.12 has no texture rotation: the arrow sheet holds 32 turned copies and a cell is picked by angle.
local K=KeijinUI
local C={}
K.caches=C
local PATH="Interface\\AddOns\\KeijinUI\\media\\caches\\"
local OUTDOOR={[0]=466.67,400,333.33,266.67,200,133.33}
local INDOOR={[0]=300,240,180,120,80,50}
local PHASES={playing=true,choosing=true,paused=true}
local MERGE=10        -- caches closer than this (yards) share one symbol
local MAX_ICONS=24
local MAX_POINTS=60
local EDGE_INSET=8
local SOURCES={"facing","model","move","north"}
local inWorld=true
local arrowModuleOn
local known,baseline,lastRun={},false,nil
local meas={}
local lastX,lastY,moveHeading
local overlay,edge,icons
local lastMapTry=0
local function Finite(n) return type(n)=="number" and n==n and n>-1e15 and n<1e15 end
local function MapPos(mx,my) return Finite(mx) and Finite(my) and mx>=0 and mx<=1 and my>=0 and my<=1 and (mx>0 or my>0) end
local function Hypot(a,b) return math.sqrt(a*a+b*b) end

-- Settings: symbols and edge arrow default on, screen arrow and chat message default off.
function C.IconsOn() return K.DB().cachesIcons~=false end
function C.EdgeOn() return K.DB().cachesEdge~=false end
function C.ArrowOn() return K.DB().cachesArrow==true end
function C.MessageOn() return K.DB().cachesMessage==true end
local FLAGS={icons="cachesIcons",edge="cachesEdge",arrow="cachesArrow",msg="cachesMessage"}
local LABELS={icons="Cache Symbole",edge="Cache Randpfeil",arrow="Cache Bildschirmpfeil",msg="Cache Meldung"}
local DEFAULT_ON={icons=true,edge=true}
function C.Get(part)
    local value=K.DB()[FLAGS[part]]
    if value==nil then return DEFAULT_ON[part] and true or false end
    return value and true or false
end
function C.Set(part,on)
    if not FLAGS[part] then return end
    K.DB()[FLAGS[part]]=on and true or false
    C.Update()
end
-- Size of the chest symbols on the minimap, 0.5 to 2 times the base 16 points, default 1.
local ICON_SIZE=16
function C.IconScale()
    local value=tonumber(K.DB().cachesIconScale)
    if not Finite(value) then return 1 end
    return math.max(0.5,math.min(2,value))
end
local function Resize()
    if not icons then return end
    local size=math.floor(ICON_SIZE*C.IconScale()+0.5)
    for _,b in ipairs(icons) do b:SetWidth(size); b:SetHeight(size); b.glideX=nil end
end
function C.SetIconScale(value)
    value=tonumber(value)
    if not Finite(value) then return end
    K.DB().cachesIconScale=math.max(0.5,math.min(2,value))
    Resize(); C.Update()
end

-- Scale measurement ----------------------------------------------------------------------------------
local function MapKey()
    local zone=type(AZS_ZONE)=="table" and AZS_ZONE or nil
    local key=zone and (zone.map or zone.zone)
    if key==nil and GetRealZoneText then key=GetRealZoneText() end
    return tostring(key or "?")
end
local function Measurement(key)
    local m=meas[key]
    if not m then
        m={pts={},seen={},count=0,n=0,suu=0,suv=0,svv=0,suw=0,svw=0,sw=0,sm=0,dirty=false}
        meas[key]=m
    end
    return m
end
local function AddPoint(m,x,y,mx,my)
    local id=math.floor(x*2+0.5)..":"..math.floor(y*2+0.5)
    if m.seen[id] or m.count>=MAX_POINTS then return end
    m.seen[id]=true; m.count=m.count+1
    for _,p in ipairs(m.pts) do
        local wx,wy=x-p.x,y-p.y
        local world=wx*wx+wy*wy
        local dmx,dmy=mx-p.mx,my-p.my
        local u,v=dmx*dmx,dmy*dmy
        if world>=MERGE*MERGE and u+v>=1e-6 then
            m.suu=m.suu+u*u; m.suv=m.suv+u*v; m.svv=m.svv+v*v
            m.suw=m.suw+u*world; m.svw=m.svw+v*world
            m.sw=m.sw+world; m.sm=m.sm+u+v
            m.n=m.n+1; m.dirty=true
        end
    end
    table.insert(m.pts,{x=x,y=y,mx=mx,my=my})
end
-- Yards per map unit along x and y; two scales when the pairs allow it, else one for both.
local function Solve(m)
    if m.n<1 or m.sm<=0 then return nil end
    if m.n>=3 then
        local det=m.suu*m.svv-m.suv*m.suv
        if det>1e-3*m.suu*m.svv then
            local a=(m.suw*m.svv-m.svw*m.suv)/det
            local b=(m.suu*m.svw-m.suv*m.suw)/det
            if a>0 and b>0 then
                local sx,sy=math.sqrt(a),math.sqrt(b)
                if sx/sy>1/3 and sx/sy<3 then return sx,sy end
            end
        end
    end
    local s=math.sqrt(m.sw/m.sm)
    if Finite(s) and s>0 then return s,s end
end
local function Saved(key)
    local db=K.DB().cacheScale
    local s=type(db)=="table" and db[key] or nil
    if type(s)=="table" and Finite(s.sx) and Finite(s.sy) and s.sx>0 and s.sy>0 and Finite(s.n) then return s end
end
local function Resolve(key)
    local m=meas[key]
    local saved=Saved(key)
    if m and m.dirty then
        m.dirty=false; m.sx,m.sy=Solve(m)
        if m.sx and (not saved or m.n>=10 or m.n>=saved.n) then
            if type(K.DB().cacheScale)~="table" then K.DB().cacheScale={} end
            K.DB().cacheScale[key]={sx=m.sx,sy=m.sy,n=m.n}
            saved=Saved(key)
        end
    end
    if m and m.sx and (not saved or m.n>=10 or m.n>=saved.n) then return m.sx,m.sy,m.n,"measured" end
    if saved then return saved.sx,saved.sy,saved.n,"saved" end
    if m and m.sx then return m.sx,m.sy,m.n,"measured" end
end
function C.Scale(key) return Resolve(key or MapKey()) end

-- Minimap ----------------------------------------------------------------------------------------------
-- Diameter of the view in yards for the current zoom; nil when the client does not report the zoom.
function C.Diameter()
    if not Minimap or not Minimap.GetZoom then return nil end
    local zoom=tonumber(Minimap:GetZoom())
    if not zoom then return nil end
    zoom=math.max(0,math.min(5,math.floor(zoom+0.5)))
    -- GetZoom returns the indoor index inside buildings, the outdoor one elsewhere. Only a clear match with the
    -- indoor setting counts as indoors.
    local inside=false
    if GetCVar then
        local out,into=tonumber(GetCVar("minimapZoom")),tonumber(GetCVar("minimapInsideZoom"))
        if out and into and zoom==into and zoom~=out then inside=true end
    end
    return (inside and INDOOR or OUTDOOR)[zoom],inside,zoom
end
local function Square() return K.MinimapStyled and K.MinimapStyled() and true or false end

-- Direction the player faces, radians, 0 north, counterclockwise (the game's own convention).
local GETTERS={}
function GETTERS.facing()
    local reported=K.navigation.WorldFacing()
    if reported~=nil then return reported end
    if type(GetPlayerFacing)~="function" then return nil end
    local value=GetPlayerFacing()
    if Finite(value) then return value end
end
function GETTERS.model()
    if not Minimap or not Minimap.GetChildren then return nil end
    local list={Minimap:GetChildren()}
    local model=list[9]
    if model and model.GetFacing then
        local value=model:GetFacing()
        if Finite(value) then return value end
    end
end
function GETTERS.move() return moveHeading end
function GETTERS.north() return 0 end
function C.Facing()
    local mode=K.DB().cachesSource
    if mode and mode~="auto" and GETTERS[mode] then
        local value=GETTERS[mode]()
        if value then return value,mode end
        return 0,"north"
    end
    for _,name in ipairs(SOURCES) do
        local value=GETTERS[name]()
        if value then return value,name end
    end
    return 0,"north"
end

-- Cell of the arrow sheet: 8 columns by 4 rows, 32 steps clockwise from "up".
local function Cell(texture,angle)
    local step=math.floor(angle/(2*math.pi)*32+0.5)
    step=math.mod(step,32)
    if step<0 then step=step+32 end
    local col,row=math.mod(step,8),math.floor(step/8)
    texture:SetTexCoord(col/8,(col+1)/8,row/4,(row+1)/4)
    return step
end

-- Data --------------------------------------------------------------------------------------------------
local function RunPhase() return AZS_GetPhase and AZS_GetPhase() or (type(AZS_RUN)=="table" and AZS_RUN.ph) end
local function RunTime()
    local t=AZS_GetRunTime and AZS_GetRunTime() or (type(AZS_RUN)=="table" and AZS_RUN.t)
    if Finite(t) then return t end
end
local function PlayerPos()
    if not GetPlayerMapPosition then return nil end
    local x,y=GetPlayerMapPosition("player")
    if not MapPos(x,y) then
        -- 1.12 only reports a position while the map is set to the current zone.
        local now=GetTime()
        if SetMapToCurrentZone and (not WorldMapFrame or not WorldMapFrame:IsShown()) and now-lastMapTry>=1 then
            lastMapTry=now; SetMapToCurrentZone()
            x,y=GetPlayerMapPosition("player")
        end
        if not MapPos(x,y) then return nil end
    end
    return x,y
end
local function Lairs()
    local list={}
    if type(AZS_LAIRS)=="table" then
        for _,e in ipairs(AZS_LAIRS) do
            if type(e)=="table" and Finite(e.x) and Finite(e.y) and MapPos(e.mx,e.my) then table.insert(list,e) end
        end
    end
    return list
end
-- Open caches. all counts every entry, valid those that carry both positions.
local function Chests()
    local all,valid=0,{}
    if type(AZS_CHESTS)=="table" then
        for _,e in ipairs(AZS_CHESTS) do
            if type(e)=="table" then
                all=all+1
                if Finite(e.x) and Finite(e.y) then table.insert(valid,e) end
            end
        end
    end
    return all,valid
end
local function Reset()
    known,baseline,lastRun={},false,nil
    meas={}
    lastX,lastY,moveHeading=nil,nil,nil
end

-- Frames --------------------------------------------------------------------------------------------------
local arrow=CreateFrame("Frame","KeijinUICachesArrow",UIParent)
K.navigation.Hex(arrow,"Cache")
local arrowOptions={hidden=false}
K.layout.Register("cachearrow",arrow,"Cache Pfeil",function(f)
    f:ClearAllPoints(); f:SetPoint("TOP",UIParent,"TOP",0,-170)
end,arrowOptions)
C.arrow=arrow

local function Wheel()
    local f=Minimap and Minimap.GetScript and Minimap:GetScript("OnMouseWheel")
    if f then f() end
end
local function ShowTip(button)
    local info=button.info
    if not info then return end
    GameTooltip:SetOwner(button,"ANCHOR_LEFT")
    if button.isEdge then GameTooltip:SetText(K.T("Nächste Cache"),1,0.82,0.28)
    elseif info.count>1 then GameTooltip:SetText(K.T("%d Caches",info.count),1,0.82,0.28)
    else GameTooltip:SetText(K.T("Cache"),1,0.82,0.28) end
    GameTooltip:AddLine(K.T("Entfernung: %d Yards",math.floor(info.dist+0.5)))
    local price=type(AZS_RUN)=="table" and AZS_RUN.chest
    if Finite(price) then GameTooltip:AddLine(K.T("Die nächste Cache kostet %d Gold",math.floor(price+0.5))) end
    GameTooltip:Show()
end
local function NewButton(width,height)
    local b=CreateFrame("Button",nil,overlay)
    b:SetWidth(width); b:SetHeight(height)
    b:SetFrameLevel(overlay:GetFrameLevel()+1)
    b.tex=b:CreateTexture(nil,"ARTWORK"); b.tex:SetAllPoints(b)
    b:EnableMouse(true); b:EnableMouseWheel(true)
    b:SetScript("OnEnter",function() ShowTip(this) end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel",Wheel)
    b:Hide()
    return b
end
-- The overlay hangs on the minimap cluster, not on the minimap: the engine models are the first children of the
-- minimap and the facing is read from the ninth.
local function Build()
    if overlay or not MinimapCluster or not Minimap then return overlay and true or false end
    overlay=CreateFrame("Frame","KeijinUICaches",MinimapCluster)
    overlay:SetAllPoints(Minimap); overlay:EnableMouse(false)
    overlay:SetFrameLevel(Minimap:GetFrameLevel()+3)
    icons={}
    for i=1,MAX_ICONS do
        local b=NewButton(ICON_SIZE,ICON_SIZE)
        b.tex:SetTexture(PATH.."Chest.tga")
        b.count=K.Text(b,"",9,"BOTTOMRIGHT",4,-3)
        icons[i]=b
    end
    Resize()
    edge=NewButton(14,14)
    edge.tex:SetTexture(PATH.."Arrow.tga"); Cell(edge.tex,0)
    edge.isEdge=true
    C.overlay,C.icons,C.edge=overlay,icons,edge
    return true
end
local function HideDraw()
    if icons then for _,b in ipairs(icons) do b:Hide() end end
    if edge then edge:Hide() end
    arrow:Hide()
end
local function Clear(reason)
    C.reason=reason; C.clusters=nil; C.nearest=nil
    if GameTooltip and GameTooltip.GetOwner then
        local owner=GameTooltip:GetOwner()
        if owner and owner.info then GameTooltip:Hide() end
    end
    HideDraw()
end

-- Update --------------------------------------------------------------------------------------------------
local function Notice(total,nearest)
    local fresh=0
    local absorb=not baseline
    local t=RunTime()
    if t and t<5 then absorb=true end
    if t and lastRun and t+5<lastRun then Reset(); absorb=true end
    if t then lastRun=t end
    if type(AZS_CHESTS)=="table" then
        for _,e in ipairs(AZS_CHESTS) do
            if type(e)=="table" and Finite(e.id) and not known[e.id] then
                known[e.id]=true
                if not absorb then fresh=fresh+1 end
            end
        end
    end
    baseline=true
    if fresh>0 and C.MessageOn() then
        if nearest then K.Say(K.T("Neue Cache auf der Karte, offen: %d, nächste %d Yards.",total,math.floor(nearest+0.5)))
        else K.Say(K.T("Neue Cache auf der Karte, offen: %d.",total)) end
    end
    C.fresh=fresh
end
local function Collect(key,valid)
    local m=Measurement(key)
    for _,e in ipairs(valid) do if MapPos(e.mx,e.my) then AddPoint(m,e.x,e.y,e.mx,e.my) end end
    for _,e in ipairs(Lairs()) do AddPoint(m,e.x,e.y,e.mx,e.my) end
end
local function Clusters(valid,px,py,sx,sy,world)
    local list={}
    for _,e in ipairs(valid) do
        local east,north
        if world then east,north=py-e.y,e.x-px
        elseif MapPos(e.mx,e.my) then east,north=(e.mx-px)*sx,-(e.my-py)*sy end
        if east~=nil then
        local into
        for _,c in ipairs(list) do
            if Hypot(c.wx-e.x,c.wy-e.y)<MERGE then into=c; break end
        end
        if into then
            into.east=(into.east*into.count+east)/(into.count+1)
            into.north=(into.north*into.count+north)/(into.count+1)
            into.count=into.count+1
            into.ids[e.id or false]=true
        else table.insert(list,{wx=e.x,wy=e.y,east=east,north=north,count=1,ids={[e.id or false]=true}}) end
        end
    end
    for _,c in ipairs(list) do c.dist=Hypot(c.east,c.north) end
    table.sort(list,function(a,b) return a.dist<b.dist end)
    return list
end
-- A symbol counts as inside while all of it stays on the map, at least EDGE_INSET from the border.
local function Place(east,north,ppy,width,height,round,inset)
    local ox,oy=east*ppy,north*ppy
    local half,halfH=width/2,height/2
    local inside
    if round then inside=Hypot(ox,oy)<=half-inset
    else inside=math.abs(ox)<=half-inset and math.abs(oy)<=halfH-inset end
    return ox,oy,inside
end
-- Point on the minimap border (inset) in the direction of ox, oy: square clamp or circle.
local function EdgePoint(ox,oy,width,height,round,inset)
    inset=inset or EDGE_INSET
    local r=Hypot(ox,oy)
    if r<1e-6 then return 0,0 end
    local t
    if round then t=(width/2-inset)/r
    else
        local tx=math.abs(ox)>1e-6 and (width/2-inset)/math.abs(ox) or 1e9
        local ty=math.abs(oy)>1e-6 and (height/2-inset)/math.abs(oy) or 1e9
        t=math.min(tx,ty)
    end
    return ox*t,oy*t
end
-- Placing at the border or moving a symbol in between: skip when it has not moved.
local function Move(f,x,y)
    if f.glideX and math.abs(f.glideX-x)<0.01 and math.abs(f.glideY-y)<0.01 then return end
    f.glideX,f.glideY=x,y
    f:ClearAllPoints(); f:SetPoint("CENTER",Minimap,"CENTER",x,y)
    -- Symbols under the player arrow fade so the arrow stays visible; the edge arrow sits at the border anyway.
    if not f.isEdge then
        local alpha=K.navigation.CenterFade(x,y,f:GetWidth()/2)
        if alpha~=f.fade then f.fade=alpha; f:SetAlpha(alpha) end
    end
end
-- Every frame: the visible symbols follow the smooth player position (sx, sy). They stay where the tick put them
-- relative to the world; a symbol that would leave the border is clamped to it until the next tick decides.
function C.Glide(sx,sy)
    local px,py=C.glideX,C.glideY
    if not px or not icons or not Minimap or not K.ModuleOn("caches") then return end
    local count=C.shown or 0
    local arrowShown=edge and edge:IsShown() and edge.info
    if count<1 and not arrowShown then return end
    local diameter=C.Diameter()
    if not diameter or diameter<=0 then return end
    local width,height=Minimap:GetWidth(),Minimap:GetHeight()
    local ppy=width/diameter
    local round=not Square()
    local dx,dy=sx-px,sy-py
    local inset=math.max(EDGE_INSET,math.floor(ICON_SIZE*C.IconScale()+0.5)/2)
    for i=1,count do
        local b=icons[i]
        local c=b and b.info
        if c and b:IsShown() then
            local ox,oy,inside=Place(c.east+dy,c.north-dx,ppy,width,height,round,inset)
            if not inside then ox,oy=EdgePoint(ox,oy,width,height,round,inset) end
            Move(b,ox,oy)
        end
    end
    if arrowShown then
        local c=edge.info
        local ex,ey=EdgePoint((c.east+dy)*ppy,(c.north-dx)*ppy,width,height,round)
        Move(edge,ex,ey)
    end
end
local function Track(px,py,sx,sy)
    if not px or not sx then return end
    if not lastX then lastX,lastY=px,py; return end
    local east,north=(px-lastX)*sx,-(py-lastY)*sy
    if east*east+north*north>=2.25 then
        moveHeading=math.atan2(-east,north)
        lastX,lastY=px,py
    end
end
function C.Update()
    C.glideX,C.glideY=nil,nil
    if not K.ModuleOn("caches") then if C.Stop then C.Stop() end; return end
    if not arrowModuleOn then arrowModuleOn=true; K.layout.Place("cachearrow") end
    if not inWorld then Clear("outside world"); return end
    local phase=RunPhase()
    if not PHASES[phase] or not K.navigation.Active() then Clear("inactive phase"); return end
    arrowOptions.hidden=C.ArrowOn()
    local key=MapKey()
    local total,valid=Chests()
    local px,py=K.navigation.WorldPosition()
    local world=px~=nil
    local sx,sy,pairs_,source
    if world then source="world"
    else
        Collect(key,valid); px,py=PlayerPos(); sx,sy,pairs_,source=Resolve(key)
        Track(px,py,sx,sy)
    end
    C.coordinateSource=world and "world" or "map"
    C.key,C.total,C.valid,C.px,C.py,C.sx,C.sy,C.pairs,C.scaleSource=key,total,table.getn(valid),px,py,sx,sy,pairs_,source
    if px==nil then Notice(total,nil); Clear("no player map position"); return end
    if not world and not sx then Notice(total,nil); Clear("no scale measured"); return end
    local clusters=Clusters(valid,px,py,sx,sy,world)
    C.clusters=clusters
    local nearest=clusters[1]
    if C.selectedId then
        local selected
        for _,cluster in ipairs(clusters) do if cluster.ids[C.selectedId] then selected=cluster; break end end
        if selected then nearest=selected else C.selectedId=nil end
    end
    C.nearest=nearest
    Notice(total,nearest and nearest.dist or nil)
    C.reason=nil
    -- Screen arrow.
    if C.ArrowOn() and nearest and K.navigation.ScreenFresh() and K.Fresh(AZS_CHESTS_UPDATED) then
        local facing,from=C.Facing()
        C.facing,C.facingSource=facing,from
        C.step=K.navigation.HexDirection(arrow,nearest.east,nearest.north,facing,from)
        arrow.distance:SetText(K.T("%d Yards",math.floor(nearest.dist+0.5)))
        local price=type(AZS_RUN)=="table" and AZS_RUN.chest
        arrow.price:SetText(Finite(price) and K.T("%d Gold",math.floor(price+0.5)) or "")
        arrow:Show()
    else arrow:Hide() end
    -- Minimap symbols and edge arrow.
    local built=Build()
    local diameter=C.Diameter()
    local wantIcons,wantEdge=C.IconsOn(),C.EdgeOn()
    if not built or not diameter or not nearest or not Minimap or not (wantIcons or wantEdge) then
        if icons then for _,b in ipairs(icons) do b:Hide() end end
        if edge then edge:Hide() end
        if built and nearest and not diameter then C.reason="no minimap zoom" end
        return
    end
    local width,height=Minimap:GetWidth(),Minimap:GetHeight()
    local ppy=width/diameter
    local round=not Square()
    local inset=math.max(EDGE_INSET,math.floor(ICON_SIZE*C.IconScale()+0.5)/2)
    local shown=0
    for i,c in ipairs(clusters) do
        local ox,oy,inside=Place(c.east,c.north,ppy,width,height,round,inset)
        if i==1 then
            if inside or not wantEdge then edge:Hide()
            else
                local ex,ey=EdgePoint(ox,oy,width,height,round)
                edge:ClearAllPoints(); edge:SetPoint("CENTER",Minimap,"CENTER",ex,ey)
                edge.glideX=nil
                edge.info=c
                Cell(edge.tex,math.atan2(ox,oy))
                edge:Show()
            end
        end
        if inside and wantIcons and shown<MAX_ICONS then
            shown=shown+1
            local b=icons[shown]
            b.glideX=nil
            Move(b,ox,oy); b.glideX=nil
            b.info=c
            b.count:SetText(c.count>1 and tostring(c.count) or "")
            b:Show()
        end
    end
    for i=shown+1,MAX_ICONS do icons[i]:Hide() end
    C.shown=shown
    -- Raw position of this tick: the offsets in the clusters are relative to it, the per frame glide shifts them.
    if world then
        C.glideX,C.glideY=px,py
        local sx,sy=K.navigation.SmoothPosition()
        if sx then C.Glide(sx,sy) end
    end
end

-- Shared map fallback for older builds. A lair may supply the calibration points even without caches.
function K.navigation.mapOffset(point)
    if not MapPos(point.mx,point.my) then return end
    local key=MapKey(); local _,valid=Chests(); Collect(key,valid)
    local px,py=PlayerPos(); local sx,sy=Resolve(key)
    if px==nil or not sx then return end
    return (point.mx-px)*sx,-(point.my-py)*sy,"map"
end

-- Debug and commands ------------------------------------------------------------------------------------
local function Num(v,format)
    if v==nil then return "n/a" end
    if type(v)=="number" and format then return string.format(format,v) end
    return tostring(v)
end
function C.DebugLines()
    C.Update()
    local lines={}
    local function Add(text) table.insert(lines,text) end
    local lairs=0
    if type(AZS_LAIRS)=="table" then lairs=table.getn(AZS_LAIRS) end
    Add(string.format("Caches: phase %s, map key %s, chests %s (with map data %s), lairs %d, next price %s",
        tostring(RunPhase()),tostring(MapKey()),Num(C.total),Num(C.valid),lairs,
        Num(type(AZS_RUN)=="table" and AZS_RUN.chest or nil)))
    Add(string.format("Caches player position (%s): %s, %s; reason: %s",tostring(C.coordinateSource),Num(C.px,"%.4f"),Num(C.py,"%.4f"),tostring(C.reason or "drawing")))
    Add(string.format("Caches scale (yards per map unit): x %s, y %s, from %s pairs (%s)",
        Num(C.sx,"%.1f"),Num(C.sy,"%.1f"),Num(C.pairs),tostring(C.scaleSource or "none")))
    local diameter,inside,zoom=C.Diameter()
    Add(string.format("Caches minimap: zoom %s, diameter %s yards, %s, width %s, %s, cvars minimapZoom %s, minimapInsideZoom %s",
        Num(zoom),Num(diameter,"%.1f"),inside and "indoor" or "outdoor",Num(Minimap and Minimap:GetWidth(),"%.0f"),
        Square() and "square" or "round",tostring(GetCVar and GetCVar("minimapZoom")),tostring(GetCVar and GetCVar("minimapInsideZoom"))))
    local children=0
    if Minimap and Minimap.GetChildren then children=table.getn({Minimap:GetChildren()}) end
    Add(string.format("Caches facing: GetPlayerFacing %s, minimap arrow model %s (%d children), movement %s",
        Num(GETTERS.facing(),"%.3f"),Num(GETTERS.model(),"%.3f"),children,Num(moveHeading,"%.3f")))
    local facing,from=C.Facing()
    Add(string.format("Caches facing used: %s = %s (setting %s)",tostring(from),Num(facing,"%.3f"),tostring(K.DB().cachesSource or "auto")))
    if C.nearest then
        Add(string.format("Caches nearest: %.0f yards (east %.0f, north %.0f), %d symbols shown",
            C.nearest.dist,C.nearest.east,C.nearest.north,C.shown or 0))
    end
    Add("Caches "..K.navigation.SmoothText())
    Add(string.format("Caches settings: icons %s (size %d%%), edge arrow %s, screen arrow %s, message %s",
        tostring(C.IconsOn()),math.floor(C.IconScale()*100+0.5),tostring(C.EdgeOn()),tostring(C.ArrowOn()),tostring(C.MessageOn())))
    return lines
end
function K.CachesDebug() for _,line in ipairs(C.DebugLines()) do K.Say(line) end end
-- /kui caches icons, edge, arrow, msg, size <percent>, source <name>, debug
function K.CachesCommand(arg)
    arg=string.lower(arg or "")
    if arg=="debug" then K.CachesDebug(); return end
    local part=arg=="message" and "msg" or arg
    if FLAGS[part] then
        C.Set(part,not C.Get(part))
        K.Say(K.T(LABELS[part])..": "..(C.Get(part) and K.T("An") or K.T("Aus")))
        return
    end
    local _,_,percent=string.find(arg,"^size%s+(%d+)$")
    if percent then
        C.SetIconScale(tonumber(percent)/100)
        K.Say(K.T("Cache Symbolgröße")..": "..math.floor(C.IconScale()*100+0.5).."%")
        return
    end
    local _,_,value=string.find(arg,"^source%s+(%S+)$")
    if value=="auto" or GETTERS[value or ""] then
        K.DB().cachesSource=value
        K.Say("Caches facing source: "..value)
        return
    end
    K.Say(K.T("/kui caches icons, edge, arrow, msg, size 50-200, source auto, source facing, source model, source move, source north, debug"))
end

function C.Select(id)
    if not K.navigation.Active() or not K.Fresh(AZS_CHESTS_UPDATED) then return false end
    for _,v in ipairs(type(AZS_CHESTS)=="table" and AZS_CHESTS or {}) do
        if v.id==id then C.selectedId=id; C.Update(); return true end
    end
    return false
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then C.selectedId=nil; Reset() end
    if prefix=="AZSCHESTS" or prefix=="AZSLAIRS" then C.Update() end
end,"caches")
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.layout.Place("cachearrow") end end,"caches")
K.On("PLAYER_ENTERING_WORLD",function() inWorld=true end,"caches")
K.On("PLAYER_LEAVING_WORLD",function() C.selectedId=nil; inWorld=false; Clear("outside world") end,"caches")
K.On("PLAYER_LOGOUT",function() inWorld=false; Clear("logout") end,"caches")
K.Update("caches",C.Update)
function C.Stop() arrowModuleOn=false; Clear("disabled") end
