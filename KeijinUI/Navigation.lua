-- Shared navigation math. Positions are native yards, never inferred from run speed.
local K=KeijinUI
local N={}
K.navigation=N
local inWorld,needsRun=true,false
local PHASES={playing=true,choosing=true,paused=true}
function N.Finite(v) return type(v)=="number" and v==v and math.abs(v)<1e15 end
function N.Active()
    local phase=AZS_GetPhase and AZS_GetPhase() or (type(AZS_RUN)=="table" and AZS_RUN.ph)
    return inWorld and not needsRun and PHASES[phase] and true or false
end
function N.WorldPosition()
    local run=AZS_RUN
    if not N.Active() or type(run)~="table" or not N.Finite(run.px) or not N.Finite(run.py) then return end
    if not K.Number(AZS_RUN_UPDATED) or not K.Fresh(AZS_RUN_UPDATED) then return end
    return run.px,run.py
end
function N.WorldFacing()
    local x=N.WorldPosition()
    if x~=nil and N.Finite(AZS_RUN.pf) then return AZS_RUN.pf end
end
function N.Facing()
    local facing=N.WorldFacing()
    if facing~=nil then return facing,"world" end
    if type(GetPlayerFacing)=="function" then
        local value=GetPlayerFacing()
        if N.Finite(value) then return value,"facing" end
    end
    return 0,"north"
end
function N.Offset(point)
    if not N.Active() or type(point)~="table" then return end
    local x,y=N.WorldPosition()
    if x~=nil and N.Finite(point.x) and N.Finite(point.y) then
        return y-point.y,point.x-x,"world"
    end
    if N.mapOffset then return N.mapOffset(point) end
end
function N.Distance(point)
    local east,north,source=N.Offset(point)
    if east==nil then return end
    return math.sqrt(east*east+north*north),east,north,source
end
function N.Arrow(texture,clockwise)
    local step=math.mod(math.floor(clockwise/(2*math.pi)*32+0.5),32)
    if step<0 then step=step+32 end
    local column,row=math.mod(step,8),math.floor(step/8)
    texture:SetTexCoord(column/8,(column+1)/8,row/4,(row+1)/4)
    return step
end
-- Minimap is north up. Project an offset in yards to an inset position, clamping outside destinations to its edge.
-- The geometry is passed in so the per frame glide can read it once for all of its symbols.
function N.Project(east,north,inset,width,height,diameter,square)
    local x,y=east*width/diameter,north*width/diameter
    local half,halfH=math.max(1,width/2-(inset or 9)),math.max(1,height/2-(inset or 9))
    local factor
    if square then factor=math.max(math.abs(x)/half,math.abs(y)/halfH)
    else factor=math.sqrt((x/half)^2+(y/halfH)^2) end
    if factor>1 then return x/factor,y/factor,true end
    return x,y,false
end
-- The player arrow is drawn by the minimap itself, below every frame on it. A square symbol of half size `half`
-- (default 8) fades while it covers the centre and recovers over the arrow's own reach, CENTER_REACH points further.
local CENTER_REACH,CENTER_ALPHA=8,0.35
function N.CenterFade(x,y,half)
    half=half or 8
    local d=math.max(math.abs(x),math.abs(y))
    if d<=half then return CENTER_ALPHA end
    if d>=half+CENTER_REACH then return 1 end
    return CENTER_ALPHA+(1-CENTER_ALPHA)*(d-half)/CENTER_REACH
end
function N.MinimapPoint(east,north,inset)
    local diameter=K.caches and K.caches.Diameter()
    if not Minimap or not diameter or diameter<=0 then return end
    return N.Project(east,north,inset,Minimap:GetWidth(),Minimap:GetHeight(),diameter,K.MinimapStyled and K.MinimapStyled())
end

-- Smooth player position. The native position arrives as addon messages at an unknown rate, the minimap scrolls
-- every frame. The last reports are buffered and drawn a little late: the position at (now - delay) is interpolated
-- between the two reports around that moment, so it never leaves the path that was really reported and never
-- runs ahead of the newest report. The delay is 1.2 times the median spacing of the reports, so a single early or
-- late report does not move it, and it follows its target slowly so the drawing time never runs backwards.
-- A report that arrives within half a median spacing of the newest one, before that one was drawn, replaces it
-- instead of being added, so a squeezed pair does not turn into a short burst of speed. A report is replaced only
-- once: after a rise of the report rate every other report is kept, and the median finds the new rate.
-- Only the drawing uses this, all logic keeps the raw position.
local SLOTS=32             -- reports kept, enough to hold the delay after the rate went up
local MIN_REPORTS=3        -- fewer reports and the raw position is shown
local DELAY_FACTOR=1.2     -- delay per median spacing
local MIN_DELAY,MAX_DELAY=0.05,0.5   -- seconds
local RAMP=0.1             -- seconds the delay may change per second
local SQUEEZE=0.05          -- seconds; a report this close to the newest is squeezed while there is no median yet
local STALE=1              -- seconds without a report until the buffer is dropped
local JUMP=40              -- yards; a larger step between two reports is a teleport
local RATE_SAMPLES=20
local bx,by,bt,gaps={},{},{},{}
for i=1,SLOTS do bx[i]=0; by[i]=0; bt[i]=0; gaps[i]=0 end
local S={n=0,head=0,delay=0,clock=0,squeezed=false}
local stamps,stampCount,stampHead={},0,0
-- Slot of the i-th oldest report.
local function Slot(i) return math.mod(S.head-S.n+i+SLOTS-1,SLOTS)+1 end
local function DropSmoothing()
    S.n,S.head,S.delay,S.target,S.median,S.when,S.squeezed=0,0,0,nil,nil,nil,false
end
local function Retarget(now)
    if S.n<MIN_REPORTS then S.target,S.median,S.when=nil,nil,nil; S.delay=0; return end
    local count=S.n-1
    for i=1,count do
        local gap=bt[Slot(i+1)]-bt[Slot(i)]
        local j=i-1
        while j>=1 and gaps[j]>gap do gaps[j+1]=gaps[j]; j=j-1 end
        gaps[j+1]=gap
    end
    local median
    if math.mod(count,2)==1 then median=gaps[(count+1)/2] else median=(gaps[count/2]+gaps[count/2+1])/2 end
    S.median=median
    local delay=median*DELAY_FACTOR
    if delay<MIN_DELAY then delay=MIN_DELAY elseif delay>MAX_DELAY then delay=MAX_DELAY end
    if not S.target then S.delay=0; S.clock=now end
    S.target=delay
end
local function Stamp(t)
    stampHead=math.mod(stampHead,RATE_SAMPLES)+1
    stamps[stampHead]=t
    if stampCount<RATE_SAMPLES then stampCount=stampCount+1 end
end
-- Takes in a report. A report from the same instant replaces the newest one, and so does a squeezed one.
local function Take(x,y,stamp,now)
    local t=now
    if K.Number(stamp) and stamp<now and stamp~=S.stamp then t=stamp end
    S.stamp,S.rawX,S.rawY=stamp,x,y
    if S.n>0 then
        local last=S.head
        local dx,dy=x-bx[last],y-by[last]
        if t<bt[last] then t=bt[last] end
        if dx*dx+dy*dy>JUMP*JUMP or t-bt[last]>STALE then DropSmoothing()
        elseif t==bt[last] then bx[last],by[last]=x,y; Retarget(now); return
        elseif not S.squeezed and t-bt[last]<(S.median and S.median/2 or SQUEEZE) and now-S.delay<bt[last] then
            Stamp(t); bx[last],by[last],bt[last]=x,y,t; S.squeezed=true; Retarget(now); return
        end
    end
    Stamp(t)
    S.squeezed=false
    S.head=math.mod(S.head,SLOTS)+1
    bx[S.head],by[S.head],bt[S.head]=x,y,t
    if S.n<SLOTS then S.n=S.n+1 end
    Retarget(now)
end
-- Takes in a new report if there is one; returns the raw position.
local function Track(now)
    local x,y=N.WorldPosition()
    if x==nil then
        if S.n>0 then DropSmoothing() end
        return
    end
    local stamp=AZS_RUN_UPDATED
    if stamp~=S.stamp or x~=S.rawX or y~=S.rawY then Take(x,y,stamp,now)
    elseif S.n>0 and now-bt[S.head]>STALE then DropSmoothing() end
    return x,y
end
-- Returns the position to draw, and whether it is smoothed. Nothing without a native position.
function N.SmoothPosition()
    local now=GetTime()
    local rawX,rawY=Track(now)
    if rawX==nil then return end
    if S.n<MIN_REPORTS or not S.target then return rawX,rawY,false end
    local dt=now-S.clock
    S.clock=now
    if dt>0 then
        local step,diff=RAMP*dt,S.target-S.delay
        if diff>step then diff=step elseif diff<-step then diff=-step end
        S.delay=S.delay+diff
    end
    local when=now-S.delay
    local oldest=Slot(1)
    -- Never before the oldest buffered report and never before the last drawn time: shorten the delay instead.
    local floor=bt[oldest]
    if S.when and S.when>floor then floor=S.when end
    if when<floor then
        when=floor
        S.delay=now-when
        if S.delay<0 then S.delay=0; when=now end
    end
    S.when=when
    local newest=S.head
    if when>=bt[newest] then return bx[newest],by[newest],true end
    if when<=bt[oldest] then return bx[oldest],by[oldest],true end
    for i=S.n-1,1,-1 do
        local a=Slot(i)
        if when>=bt[a] then
            local b=Slot(i+1)
            local span=bt[b]-bt[a]
            if span<=0 then return bx[b],by[b],true end
            local f=(when-bt[a])/span
            return bx[a]+(bx[b]-bx[a])*f,by[a]+(by[b]-by[a])*f,true
        end
    end
    return bx[oldest],by[oldest],true
end
-- Mean spacing of the last reports as a rate in Hz, and how many reports it rests on.
function N.ReportRate()
    if stampCount<2 then return nil,stampCount end
    local newest,oldest=stamps[stampHead]
    if stampCount<RATE_SAMPLES then oldest=stamps[1] else oldest=stamps[math.mod(stampHead,RATE_SAMPLES)+1] end
    local span=newest-oldest
    if span<=0 then return nil,stampCount end
    return (stampCount-1)/span,stampCount
end
function N.ResetSmoothing()
    DropSmoothing(); S.stamp,S.rawX,S.rawY=nil,nil,nil
    stampCount,stampHead=0,0
end
function N.SmoothText()
    N.SmoothPosition()
    local rate,count=N.ReportRate()
    local active=S.n>=MIN_REPORTS and S.target~=nil
    return "Position reports: "..(rate and string.format("%.1f Hz",rate) or "n/a").." (last "..count.."), delay "
        ..string.format("%d ms",math.floor(S.delay*1000+0.5))..", smoothing "..(active and "active" or "off")
end
-- Own light frame: moves the visible lair pins and cache symbols every frame, the 0.1 s tick only decides.
local glide=CreateFrame("Frame","KeijinUIMinimapGlide")
glide:SetScript("OnUpdate",function()
    local x,y=N.SmoothPosition()
    if x==nil then return end
    local lairs,caches=K.guardianNav,K.caches
    if lairs and lairs.Glide then lairs.Glide(x,y) end
    if caches and caches.Glide then caches.Glide(x,y) end
end)
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then needsRun=true; N.ResetSmoothing()
    elseif prefix=="AZSRUN" then needsRun=false end
end)
K.On("PLAYER_LEAVING_WORLD",function() inWorld=false; needsRun=true; N.ResetSmoothing() end)
K.On("PLAYER_ENTERING_WORLD",function() inWorld=true end)
K.On("PLAYER_LOGOUT",function() inWorld=false end)

function N.Debug()
    local x,y=N.WorldPosition(); local facing,source=N.Facing()
    K.Say("Navigation: active="..tostring(N.Active())..", world="..tostring(x)..","..tostring(y)..", facing="..tostring(facing).." ("..source..")")
    local guide=K.guardianNav
    if guide then
        local current=guide.current
        K.Say("Guardian guide: target="..tostring(current and current.key)..", distance="..tostring(current and current.dist)..", source="..tostring(current and current.source)..", pins="..tostring(guide.shownPins or 0))
        local cvars=type(AZS_HUD_CVARS)=="table" and AZS_HUD_CVARS or nil
        local flagged=type(AZS_GetFlaggedLair)=="function" and AZS_GetFlaggedLair() or nil
        K.Say("Guardian flag: supported="..tostring(guide.FlagSupported and guide.FlagSupported())..", skulls="..tostring(guide.PinsOn and guide.PinsOn())
            ..", cvar="..tostring(cvars and cvars.flag)..", nativeShown="..tostring(type(AZS_IsHudShown)=="function" and AZS_IsHudShown("flag"))
            ..", flagged="..tostring(flagged and flagged.state)..", saved="..tostring(K.DB().nativeFlagShown)
            ..", lairs="..tostring(type(AZS_LAIRS)=="table" and table.getn(AZS_LAIRS) or "nil")
            ..", age="..tostring(K.Number(AZS_LAIRS_UPDATED) and math.floor(GetTime()-AZS_LAIRS_UPDATED) or "nil"))
    end
end
