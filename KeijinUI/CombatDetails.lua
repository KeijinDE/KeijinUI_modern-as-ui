-- Observed hit counts are never reconstructed from native aggregate damage.
local K=KeijinUI
local C={sources={}}
K.combatDetails=C
local lastRunStart
function C.Reset() C.sources={} end
function C.Observe(hit)
    if not hit or hit.kind~="damage" or not K.Number(hit.amount) then return end
    if lastRunStart~=K.runStart then C.Reset(); lastRunStart=K.runStart end
    local name=K.SourceKey(hit.spell or hit.sourceName or K.T("Nahkampf"))
    local s=C.sources[name] or {hits=0,crits=0,normal=0,sum=0}
    s.hits=s.hits+1
    if hit.critical then s.crits=s.crits+1
    else
        s.normal=s.normal+1; s.sum=s.sum+hit.amount
        s.min=s.min and math.min(s.min,hit.amount) or hit.amount
        s.max=s.max and math.max(s.max,hit.amount) or hit.amount
    end
    C.sources[name]=s
end
function C.Detail(name)
    local s=C.sources[K.SourceKey(name)]
    if not s then return K.T("\nKeine beobachteten Treffer seit Laden der UI.") end
    local text=K.T("\nBeobachtet seit Laden der UI: %s Treffer · %.1f%% Krit",s.hits,s.hits>0 and s.crits/s.hits*100 or 0)
    if s.normal>0 then text=text..K.T("\nNormale Treffer: %s · Ø %s · Min %s · Max %s",s.normal,K.Short(s.sum/s.normal),K.Short(s.min),K.Short(s.max)) end
    return text
end
local takenNames={['boss melee']="Boss Nahkampf",['boss spell']="Boss Zauber",elite="Elite",['mob melee']="Gegner Nahkampf",['mob spell']="Gegner Zauber",area="Fläche"}
local awaiting=false
function C.Taken()
    if awaiting or not K.Fresh(AZS_TAKEN_UPDATED) or type(AZS_TAKEN)~="table" then return K.T("Noch keine Schadensquellen") end
    local lines,total={},0
    for _,v in ipairs(AZS_TAKEN) do if K.Number(v.dmg) then total=total+v.dmg end end
    for _,v in ipairs(AZS_TAKEN) do
        if K.Number(v.dmg) then table.insert(lines,K.T("%s: %s (%.1f%%)",K.T(takenNames[v.source] or v.source or "?"),K.Short(v.dmg),total>0 and v.dmg/total*100 or 0)) end
    end
    return table.getn(lines)>0 and table.concat(lines,"\n") or K.T("Noch keine Schadensquellen")
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then C.Reset(); awaiting=true elseif prefix=="AZSTAKEN" then awaiting=false end
end)
local observer=CreateFrame("Frame")
for ev in pairs(K.tools.CombatEvents) do observer:RegisterEvent(ev) end
observer:SetScript("OnEvent",function()
    if AZS_GetPhase and AZS_GetPhase()=="playing" then C.Observe(K.tools.ParseCombatLine(event,arg1)) end
end)
-- A line and an indicator leave the frame's class and classification colours intact.
function C.Execute(parent,bar,share,mirrored)
    local enabled=K.DB().executeMarker==true
    if not enabled or not K.Number(share) then if parent.execute then parent.execute:Hide() end; return end
    local marker=parent.execute
    if not marker then
        marker=CreateFrame("Frame",nil,parent); marker:SetAllPoints(bar); marker:SetFrameLevel(bar:GetFrameLevel()+8)
        marker.line=marker:CreateTexture(nil,"OVERLAY"); marker.line:SetTexture(K.flat); marker.line:SetWidth(1)
        parent.execute=marker
    end
    local x=bar:GetWidth()*(mirrored and .70 or .30)
    marker.line:ClearAllPoints(); marker.line:SetPoint("TOPLEFT",bar,"TOPLEFT",x,0); marker.line:SetHeight(bar:GetHeight())
    marker.line:SetVertexColor(1,share<=.30 and .25 or .72,.12,.9)
    marker:Show()
end
