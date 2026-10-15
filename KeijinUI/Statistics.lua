local K=KeijinUI
local stats=K.Panel("KeijinUIStatistics","Dieser Run",260,166)
K.layout.Register("statistics",stats,"Runstatistiken",function(f) f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-36) end)
local definitions={
    {"ek","Eliten besiegt"},{"gk","Wächter besiegt"},{"bk","Bosse besiegt"},
    {"taken","Schaden erlitten"},{"heal","Heilung (effektiv)"},{"ge","Gold verdient"}
}
local rows={}
for i,v in ipairs(definitions) do rows[i]=K.Row(stats,i,19); K.Live(rows[i].label,function() return K.T(v[2]) end) end
local meter=K.Panel("KeijinUIDamage","Schaden",260,235)
K.layout.Register("meter",meter,"Schadensanzeige",function(f) f:ClearAllPoints(); f:SetPoint("TOPRIGHT",stats,"BOTTOMRIGHT",0,-10) end)
local summary=K.Text(meter,"",10,"BOTTOMLEFT",13,10,236)
local meterRows,baseline={},{}
local meterStart,offset,critOffset=0,0,0
local MAX_ROWS=8
for i=1,MAX_ROWS do meterRows[i]=K.Row(meter,i,20) end
meter:EnableMouseWheel(true)
meter:SetScript("OnMouseWheel",function() offset=math.max(0,offset+(arg1>0 and -1 or 1)) end)
local reset=CreateFrame("Button",nil,meter)
reset:SetWidth(44); reset:SetHeight(20); reset:SetPoint("TOPRIGHT",meter,"TOPRIGHT",-10,-6)
reset.text=K.Text(reset,"Reset",9,"CENTER",0,0)
local function ResetMeter()
    baseline={}; meterStart=AZS_GetRunTime and AZS_GetRunTime() or 0; offset=0
    local lines=AZS_GetMeter and AZS_GetMeter()
    for _,v in ipairs(lines or {}) do if K.Number(v.dmg) then baseline[v.name]=v.dmg end end
end
reset:SetScript("OnClick",ResetMeter)
local crit=K.Panel("KeijinUICrits","Größte kritische Treffer",300,220)
K.layout.Register("crits",crit,"Kritische Treffer",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",meter,"BOTTOMLEFT",0,-10)
end)
crit:SetWidth(260)
crit:EnableMouseWheel(true)
crit:SetScript("OnMouseWheel",function() critOffset=math.max(0,critOffset+(arg1>0 and -1 or 1)) end)
local critRows,critData={},{}
local critNote=K.LText(crit,"Seit Laden der Oberfläche",9,"BOTTOMLEFT",13,9,270)
for i=1,8 do critRows[i]=K.Row(crit,i,19) end
-- Effective healing: sum of positive health gains of the player between two samples.
local healed,lastHp,lastMax=0,nil,nil
-- Estimated gross healing by source, integrated at every sample with the value valid at that moment:
-- leech (lch, a fraction) times own damage dealt, kill heal (heal) times kills, regeneration (reg,
-- health per second) times run seconds. "last" holds what was already credited; a component whose
-- stat is missing is not advanced, so it is credited later with the first value that arrives.
-- Loaded in the middle of a run, the first sample credits everything since run start with the
-- current values (the best available estimate).
local estimate,credited={leech=0,kill=0,regen=0},nil
local function ResetRun()
    baseline={}; meterStart=0; offset=0; critData={}; critOffset=0
    healed=0; lastHp=nil; lastMax=nil
    estimate={leech=0,kill=0,regen=0}; credited=nil
end
local function Integrate(seconds,r,lines)
    local stats=AZS_STATS
    if type(stats)~="table" or not K.Number(seconds) then return end
    local last=credited or {time=0,dmg=0,kills=0}; credited=last
    if K.Number(stats.reg) then
        if seconds>last.time then estimate.regen=estimate.regen+stats.reg*(seconds-last.time) end
        last.time=seconds
    end
    if type(lines)=="table" and K.Number(stats.lch) then
        local dmg=0
        for _,v in ipairs(lines) do if K.Number(v.dmg) then dmg=dmg+v.dmg end end
        if dmg>last.dmg then estimate.leech=estimate.leech+stats.lch*(dmg-last.dmg) end
        last.dmg=dmg
    end
    if type(r)=="table" and K.Number(r.kills) and K.Number(stats.heal) then
        if r.kills>last.kills then estimate.kill=estimate.kill+stats.heal*(r.kills-last.kills) end
        last.kills=r.kills
    end
end
-- Tooltip text of the healing row: effective total first, then the gross estimate by source.
local function HealDetail(value)
    local text=K.Number(value) and string.format("%.0f",value) or K.T("Noch keine Spieldaten")
    local stats=AZS_STATS
    if type(stats)~="table" or not credited then return text end
    local total=estimate.leech+estimate.kill+estimate.regen
    text=text..K.T("\n\nGeschätzt, brutto inkl. Überheilung (nicht die effektive Heilung):")
    text=text..K.T("\nLebensraub: %s (%.1f%% des Schadens)",K.Short(estimate.leech),(K.Number(stats.lch) and stats.lch or 0)*100)
    text=text..K.T("\nKill-Heilung: %s (%s pro Kill)",K.Short(estimate.kill),K.Short(K.Number(stats.heal) and stats.heal or 0))
    text=text..K.T("\nRegeneration: %s (%.1f pro Sekunde)",K.Short(estimate.regen),K.Number(stats.reg) and stats.reg or 0)
    return text..K.T("\nSumme: %s",K.Short(total))
end
local function SampleHealth()
    local hp,max=UnitHealth("player"),UnitHealthMax("player")
    local r=AZS_RUN
    if (not K.Number(hp) or not K.Number(max) or max<=0)
        and type(r)=="table" and K.Number(r.hp) and K.Number(r.hpm) and r.hpm>0 then hp,max=r.hp,r.hpm end
    if not K.Number(hp) or not K.Number(max) or max<=0 then lastHp=nil; lastMax=nil; return end
    -- Counting only while the run is official "playing": pause, card choice and no run just follow the value.
    if AZS_GetPhase and AZS_GetPhase()=="playing" and lastHp and lastHp>0 and lastMax==max and hp>lastHp then
        healed=healed+(hp-lastHp)
    end
    lastHp,lastMax=hp,max
end
K.On("UNIT_HEALTH",function(_,unit) if unit=="player" then SampleHealth() end end)
K.On("CHAT_MSG_ADDON",function(_,prefix) if prefix=="AZSZONE" then ResetRun() end end)
local combat=CreateFrame("Frame",nil,UIParent)
for ev in pairs(K.tools.CombatEvents) do combat:RegisterEvent(ev) end
combat:SetScript("OnEvent",function()
    local phase=AZS_GetPhase and AZS_GetPhase()
    if phase~="playing" then return end
    local hit=K.tools.ParseCombatLine(event,arg1)
    if not hit or hit.kind~="damage" or not hit.critical then return end
    local name=hit.spell or hit.sourceName or K.T("Nahkampf")
    if name=="" then name=K.T("Unbekannt") end
    name=K.DisplayName(name)
    local v=critData[name] or {name=name,best=0,sum=0,count=0,min=hit.amount}
    v.best=math.max(v.best,hit.amount); v.min=math.min(v.min,hit.amount)
    v.last=hit.amount; v.sum=v.sum+hit.amount; v.count=v.count+1; critData[name]=v
end)
local previousTime
local function Update()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local r=AZS_RUN
    local seconds=AZS_GetRunTime and AZS_GetRunTime()
    local valid=type(r)=="table" and phase and K.Number(seconds)
    if valid and previousTime and seconds<previousTime-1 then ResetRun() end
    if K.Number(seconds) then previousTime=seconds end
    SampleHealth()
    if valid then Integrate(seconds,r,AZS_GetMeter and AZS_GetMeter()) end
    if not K.DB().hidden.statistics then
        r=valid and r or {}
        for i,def in ipairs(definitions) do
            local key=def[1]; local value=r[key]
            if key=="heal" then value=valid and healed or nil end
            rows[i].value:SetText(K.Short(value))
            rows[i].tip=K.T(def[2]); rows[i].detail=key=="heal" and HealDetail(value) or (K.Number(value) and string.format("%.0f",value) or K.T("Noch keine Spieldaten"))
            rows[i].bar:SetValue(1); rows[i].bar:SetStatusBarColor(0.19,0.17,0.11,0.45)
        end
        stats:Show()
    else stats:Hide() end
    local lines=AZS_GetMeter and AZS_GetMeter()
    local meterValid=valid and type(lines)=="table" and not K.DB().hidden.meter
    local sorted,total={},0
    if meterValid then
        for _,v in ipairs(lines) do
            if type(v.name)~="string" or not K.Number(v.dmg) then meterValid=false; break end
            local value=math.max(0,v.dmg-(baseline[v.name] or 0))
            table.insert(sorted,{name=v.name,dmg=value,proc=v.proc}); total=total+value
        end
    end
    if meterValid then
        table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
        local visible=math.max(3,math.min(MAX_ROWS,math.floor((UIParent:GetHeight()-563)/22)))
        meter:SetHeight(56+visible*22)
        offset=math.min(offset,math.max(0,table.getn(sorted)-visible))
        local duration=seconds-meterStart
        for i,row in ipairs(meterRows) do
            local v=sorted[i+offset]
            if v and i<=visible then
                row.label:SetText(K.DisplayName(v.name)); row.value:SetText(K.Short(v.dmg))
                row.bar:SetValue(sorted[1].dmg>0 and v.dmg/sorted[1].dmg or 0)
                local red,green,blue=K.SourceColor(v.name)
                row.bar:SetStatusBarColor(red,green,blue,0.85)
                row.tip=K.DisplayName(v.name)
                row.detail=string.format(K.T("%.0f Schaden\n%s / Sekunde\n%.1f%% Anteil%s"),v.dmg,
                    K.Short(duration>0 and v.dmg/duration or 0),total>0 and v.dmg/total*100 or 0,v.proc==1 and K.T("\nZusätzlicher Effekt") or "")
                row:Show()
            else row:Hide() end
        end
        summary:SetText(K.T("%s gesamt   ·   %s / s",K.Short(total),K.Short(duration>0 and total/duration or 0)))
        meter:Show(); K.Native("meter",true)
    else
        K.Native("meter",not K.DB().hidden.meter)
        if K.DB().hidden.meter then meter:Hide()
        else
            for _,row in ipairs(meterRows) do row:Hide() end
            meter:SetHeight(100); summary:SetText(K.T("Noch kein Schaden")); meter:Show()
        end
    end
    local crits={}
    for _,v in pairs(critData) do table.insert(crits,v) end
    table.sort(crits,function(a,b) if a.best==b.best then return a.name<b.name end return a.best>b.best end)
    if valid and not K.DB().hidden.crits and table.getn(crits)>0 then
        local available=(meter:GetBottom() or 220)-190
        local visible=math.max(1,math.min(8,math.floor((available-56)/21)))
        critOffset=math.min(critOffset,math.max(0,table.getn(crits)-visible))
        for i,row in ipairs(critRows) do
            local v=crits[i+critOffset]
            if v and i<=visible then
                row.label:SetText(v.name); row.value:SetText(K.Short(v.best))
                row.bar:SetValue(v.best/crits[1].best)
                local red,green,blue=K.SourceColor(v.name); row.bar:SetStatusBarColor(red,green,blue,0.85)
                row.tip=v.name
                row.detail=string.format(K.T("Größter: %.0f\nLetzter: %.0f\nDurchschnitt: %.0f\nKleinster: %.0f\nKritische Treffer: %d"),v.best,v.last,v.sum/v.count,v.min,v.count)
                row:Show()
            else row:Hide() end
        end
        crit:SetHeight(56+math.min(visible,table.getn(crits))*21); crit:Show()
    else
        for _,row in ipairs(critRows) do row:Hide() end
        if K.DB().hidden.crits then crit:Hide() else crit:SetHeight(77); crit:Show() end
    end
end
-- /kui heal debug: 60 seconds of buff chat events (all names are in the 1.12 event catalog).
local HEAL_EVENTS={"CHAT_MSG_SPELL_SELF_BUFF","CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS","CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
    "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS","CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF","CHAT_MSG_SPELL_PARTY_BUFF"}
local debugFrame=CreateFrame("Frame",nil,UIParent)
local debugUntil,debugLines,debugCounts
local function DebugStop()
    if not debugUntil then return end
    debugUntil=nil
    for _,ev in ipairs(HEAL_EVENTS) do debugFrame:UnregisterEvent(ev) end
    local parts={}
    for _,ev in ipairs(HEAL_EVENTS) do table.insert(parts,ev.." "..(debugCounts[ev] or 0)) end
    K.Say("Heilmitschnitt beendet: "..table.concat(parts,", "))
end
debugFrame:SetScript("OnEvent",function()
    if not debugUntil then return end
    debugCounts[event]=(debugCounts[event] or 0)+1
    if debugLines<20 then
        debugLines=debugLines+1
        local text=tostring(arg1)
        if string.len(text)>120 then text=string.sub(text,1,120) end
        K.Say(event..": "..text)
    end
end)
function K.HealDebug()
    if debugUntil then K.Say("Heilmitschnitt läuft bereits."); return end
    debugUntil=GetTime()+60; debugLines=0; debugCounts={}
    for _,ev in ipairs(HEAL_EVENTS) do debugFrame:RegisterEvent(ev) end
    K.Say("Heilmitschnitt läuft 60 Sekunden (höchstens 20 Zeilen).")
end
table.insert(K.updates,function() if debugUntil and GetTime()>=debugUntil then DebugStop() end end)
K.ResetMeter=ResetMeter
K.ResetCrits=function() critData={} end
table.insert(K.updates,Update)
Update()
