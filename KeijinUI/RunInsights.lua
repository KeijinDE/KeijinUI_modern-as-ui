-- Samples only received run packets. Native run time excludes pauses/card choices.
local K=KeijinUI
local X={segments={}}
K.xpRate=X
local previous,lastRunStart
function X.Reset() X.segments={}; previous=nil end
function X.Observe(r)
    if type(r)~="table" or not K.Number(r.t) or not K.Number(r.lvl) or not K.Number(r.xp)
        or not K.Number(r.xpn) or r.xpn<=0 or r.xp>r.xpn then X.Reset(); return end
    if lastRunStart~=K.runStart then X.Reset(); lastRunStart=K.runStart end
    local p=previous
    previous={t=r.t,lvl=r.lvl,xp=r.xp,xpn=r.xpn}
    if not p then return end
    local dt=r.t-p.t
    if dt<0 or r.lvl<p.lvl then X.Reset(); previous={t=r.t,lvl=r.lvl,xp=r.xp,xpn=r.xpn}; return end
    local gain
    if r.lvl==p.lvl and r.xpn==p.xpn then gain=r.xp-p.xp
    elseif r.lvl==p.lvl+1 then gain=p.xpn-p.xp+r.xp end
    -- Multiple unseen level requirements cannot be reconstructed from the final packet.
    if not gain or gain<0 or dt>10 then X.Reset(); previous={t=r.t,lvl=r.lvl,xp=r.xp,xpn=r.xpn}; return end
    if dt==0 then
        if gain>0 then X.Reset(); previous={t=r.t,lvl=r.lvl,xp=r.xp,xpn=r.xpn} end
        return
    end
    table.insert(X.segments,{start=p.t,stop=r.t,gain=gain})
    while table.getn(X.segments)>0 and X.segments[1].stop<=r.t-60 do table.remove(X.segments,1) end
end
function X.Read()
    local total,elapsed,events=0,0,0
    local last=previous and previous.t
    if not last then return end
    for _,s in ipairs(X.segments) do
        local dt=s.stop-math.max(s.start,last-60)
        if dt>0 then
            total=total+s.gain*dt/(s.stop-s.start); elapsed=elapsed+dt
            if s.gain>0 then events=events+1 end
        end
    end
    if elapsed<10 or events<3 or total<=0 then return end
    local rate=total/elapsed
    return rate,math.max(0,previous.xpn-previous.xp)/rate
end
local function XPText()
    local rate,left=X.Read()
    if not rate then return K.T("XP/min: ? · nächstes Level: ?") end
    return K.T("%s XP/min · nächstes Level ~%s",K.Short(rate*60),K.Clock(left))
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then X.Reset()
    elseif prefix=="AZSRUN" then X.Observe(AZS_RUN) end
end,"analysis")
local label=K.xpDisplay.rateLabel; X.label=label
K.Update("analysis",function()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local active=phase=="playing" or phase=="paused" or phase=="choosing"
    if K.DB().xpRate==true and active and not K.DB().hidden.xp then label:SetText(XPText()); label:Show() else label:Hide() end
end)
