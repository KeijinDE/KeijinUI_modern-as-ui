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
-- Minimap is north up. Return an inset position, clamping outside destinations to its edge.
function N.MinimapPoint(east,north,inset)
    local diameter=K.caches and K.caches.Diameter()
    if not Minimap or not diameter or diameter<=0 then return end
    local width,height=Minimap:GetWidth(),Minimap:GetHeight()
    local x,y=east*width/diameter,north*width/diameter
    local half,halfH=math.max(1,width/2-(inset or 9)),math.max(1,height/2-(inset or 9))
    local square=K.MinimapStyled and K.MinimapStyled()
    local factor
    if square then factor=math.max(math.abs(x)/half,math.abs(y)/halfH)
    else factor=math.sqrt((x/half)^2+(y/halfH)^2) end
    if factor>1 then return x/factor,y/factor,true end
    return x,y,false
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then needsRun=true
    elseif prefix=="AZSRUN" then needsRun=false end
end)
K.On("PLAYER_LEAVING_WORLD",function() inWorld=false; needsRun=true end)
K.On("PLAYER_ENTERING_WORLD",function() inWorld=true end)
K.On("PLAYER_LOGOUT",function() inWorld=false end)

function N.Debug()
    local x,y=N.WorldPosition(); local facing,source=N.Facing()
    K.Say("Navigation: active="..tostring(N.Active())..", world="..tostring(x)..","..tostring(y)..", facing="..tostring(facing).." ("..source..")")
    local guide=K.guardianNav
    if guide then
        local current=guide.current
        K.Say("Guardian guide: target="..tostring(current and current.key)..", distance="..tostring(current and current.dist)..", source="..tostring(current and current.source)..", pins="..tostring(guide.shownPins or 0))
    end
end
