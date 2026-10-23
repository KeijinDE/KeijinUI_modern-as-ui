local K=KeijinUI
local stats=K.Panel("KeijinUIStatistics","Dieser Run",K.PANEL_WIDTH,185)
K.layout.Register("statistics",stats,"Runstatistiken",function(f) f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-36) end)
-- Level and experience of the current level only: the game hands out no run total of experience.
local definitions={
    {"lvl","Level"},{"xp","Erfahrung"},
    {"ek","Eliten besiegt"},{"gk","Wächter besiegt"},{"bk","Bosse besiegt"},
    {"taken","Schaden erlitten"},{"ge","Gold verdient"}
}
local function HealingSupported() return type(AZS_GetHealing)=="function" end
local rows={}
-- Closures get a body local: the game's Lua (0.101) loses for loop variables captured by closures.
for i,v in ipairs(definitions) do local text=v[2]; rows[i]=K.ValueRow(stats,i,19); K.Live(rows[i].label,function() return K.T(text) end) end
-- The panel border closes the list, so the last row needs no line of its own.
rows[table.getn(rows)].line:Hide()
local meter=K.Panel("KeijinUIDamage","Schaden",K.PANEL_WIDTH,235)
K.layout.Register("meter",meter,"Schadensanzeige",function(f) f:ClearAllPoints(); f:SetPoint("TOPRIGHT",stats,"BOTTOMRIGHT",0,-10) end)
local summary=K.Text(meter,"",10,"BOTTOMLEFT",13,10,K.PANEL_WIDTH-26)
local summaryHover=CreateFrame("Frame",nil,meter)
summaryHover:SetAllPoints(summary); summaryHover:EnableMouse(true)
summaryHover:SetScript("OnEnter",function()
    if K.MeterView()~="run" or not meter.runAverage then return end
    GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText(K.T("Schaden"),1,.82,.28)
    GameTooltip:AddLine(K.T("Durchschnitt seit Runbeginn oder Reset: %s DPS",K.Short(meter.runAverage)),.94,.91,.82,true)
    GameTooltip:AddLine(K.T("DPS: letzte 10 Spielsekunden, ohne Pausen."),.7,.7,.67,true); GameTooltip:Show()
end)
summaryHover:SetScript("OnLeave",function() GameTooltip:Hide() end)
local meterRows,baseline={},{}
local meterStart,offset,critOffset=0,0,0
local MAX_ROWS=8
-- Height of the meter with data: as many rows as the screen allows, 3 to MAX_ROWS.
function K.MeterMaxHeight() return 56+math.max(3,math.min(MAX_ROWS,math.floor((K.UIHeight()-563)/22)))*22 end
local function AddSpellIcon(row,size)
    row.iconSize=size; row.labelWidth=row.label:GetWidth()
    row.icon=row.label:GetParent():CreateTexture(nil,"ARTWORK")
    row.icon:SetWidth(size); row.icon:SetHeight(size)
    row.icon:SetPoint("LEFT",row,"LEFT",5,0)
    row.icon:SetTexCoord(.08,.92,.08,.92); row.icon:Hide()
end
local function UpdateSpellIcon(row,name)
    local enabled=K.DB().meterIcons==true
    local inset=enabled and row.iconSize+3 or 0
    row.label:ClearAllPoints(); row.label:SetPoint("LEFT",row.label:GetParent(),"LEFT",5+inset,0)
    row.label:SetWidth(row.labelWidth-inset)
    local texture=enabled and K.SpellIcon(name)
    if texture then row.icon:SetTexture(texture); row.icon:Show() else row.icon:Hide() end
end
for i=1,MAX_ROWS do
    local row=K.ListBarRow(meter,i,20)
    -- Separate, bounded columns: ability | total damage | damage per second.
    -- Use the existing text layer so all three stay above the bar artwork.
    row.label:SetWidth(meter:GetWidth()-156)
    AddSpellIcon(row,16)
    row.value:ClearAllPoints(); row.value:SetPoint("RIGHT",row,"RIGHT",-73,0)
    row.value:SetWidth(53); row.value:SetHeight(16); row.value:SetJustifyH("RIGHT")
    row.dps=K.Text(row.value:GetParent(),"",10,"RIGHT",-6,0,62)
    row.dps:SetJustifyH("RIGHT"); row.dps:SetTextColor(0.84,0.82,0.75)
    meterRows[i]=row
end
meter:EnableMouseWheel(true)
meter:SetScript("OnMouseWheel",function() offset=math.max(0,offset+(arg1>0 and -1 or 1)) end)
local reset=CreateFrame("Button",nil,meter)
reset:SetWidth(44); reset:SetHeight(20); reset:SetPoint("TOPRIGHT",meter,"TOPRIGHT",-10,-6)
reset.text=K.LText(reset,"Reset",9,"CENTER",0,0)
-- Run/Boss/Healing share one meter. Automatic Boss is temporary; Run and Healing choices stay explicit.
local autoView,bossWasAlive,autoWasOn,awaitingBossRun
local tabRun=CreateFrame("Button","KeijinUIMeterTabRun",meter)
local tabBoss=CreateFrame("Button","KeijinUIMeterTabBoss",meter)
local tabHeal=CreateFrame("Button","KeijinUIMeterTabHeal",meter)
for _,tab in ipairs({tabRun,tabBoss}) do tab:SetWidth(34); tab:SetHeight(20) end
tabRun.text=K.LText(tabRun,"Run",9,"CENTER",0,0)
tabBoss.text=K.LText(tabBoss,"Boss",9,"CENTER",0,0)
tabHeal:SetWidth(44); tabHeal:SetHeight(20); tabHeal.text=K.LText(tabHeal,"Heilung",9,"CENTER",0,0)
function K.MeterView()
    if autoView then return autoView end
    local view=K.DB().meterView
    return (view=="boss" or view=="healing") and view or "run"
end
local function PaintTabs()
    local view=K.MeterView()
    local function Paint(tab,on) if on then tab.text:SetTextColor(1,0.82,0.28) else tab.text:SetTextColor(0.62,0.6,0.54) end end
    Paint(tabRun,view=="run"); Paint(tabBoss,view=="boss"); Paint(tabHeal,view=="healing")
end
function K.SetMeterView(view)
    if autoView and view==autoView then offset=0; PaintTabs(); return end
    K.DB().meterView=(view=="boss" or view=="healing") and view or nil
    autoView=nil   -- Manual Run/Healing choices remain until the next fight.
    offset=0; PaintTabs()
end
function K.SetMeterAuto(on) K.DB().meterAutoBoss=on and true or nil end
tabRun:SetScript("OnClick",function() K.SetMeterView("run") end)
tabBoss:SetScript("OnClick",function() K.SetMeterView("boss") end)
tabHeal:SetScript("OnClick",function() K.SetMeterView("healing") end)
meter.headerExtra=function(mode)
    reset:ClearAllPoints(); reset:SetHeight(mode=="thin" and 16 or 20)
    tabRun:ClearAllPoints(); tabBoss:ClearAllPoints(); tabHeal:ClearAllPoints()
    tabRun:SetHeight(mode=="thin" and 16 or 20); tabBoss:SetHeight(mode=="thin" and 16 or 20); tabHeal:SetHeight(mode=="thin" and 16 or 20)
    tabRun:SetWidth(mode=="off" and 24 or 34); tabBoss:SetWidth(mode=="off" and 28 or 34); tabHeal:SetWidth(mode=="off" and 38 or 44)
    reset:SetWidth(mode=="off" and 28 or 44); reset.text:SetFont(K.font,mode=="off" and 8 or 9,"OUTLINE")
    summary:SetFont(K.font,mode=="off" and 9 or 10,"OUTLINE")
    if mode=="off" then
        -- No title strip: tabs and Reset share the bottom row with the summary.
        reset:SetPoint("BOTTOMRIGHT",meter,"BOTTOMRIGHT",-10,4)
        tabHeal:SetPoint("RIGHT",reset,"LEFT",-4,0)
        tabBoss:SetPoint("RIGHT",tabHeal,"LEFT",-2,0)
        tabRun:SetPoint("RIGHT",tabBoss,"LEFT",-2,0)
        summary:SetWidth(meter:GetWidth()-160)
    else
        if mode=="thin" then reset:SetPoint("RIGHT",meter.strip,"RIGHT",-3,0)
        else reset:SetPoint("TOPRIGHT",meter,"TOPRIGHT",-10,-6) end
        tabHeal:SetPoint("RIGHT",reset,"LEFT",-4,0)
        tabBoss:SetPoint("RIGHT",tabHeal,"LEFT",-2,0)
        tabRun:SetPoint("RIGHT",tabBoss,"LEFT",-2,0)
        summary:SetWidth(meter:GetWidth()-26)
    end
    PaintTabs()
end
local function Summary(full,total,rate)
    summary:SetText(K.headers.Mode()=="off" and (K.Short(total).." · "..K.Short(rate).."/s") or full)
end
local function ResetMeter()
    K.liveDPS.Reset()
    baseline={}; meterStart=AZS_GetRunTime and AZS_GetRunTime() or 0; offset=0
    local lines=AZS_GetMeter and AZS_GetMeter()
    for _,v in ipairs(lines or {}) do if K.Number(v.dmg) then baseline[v.name]=v.dmg end end
end
reset:SetScript("OnClick",ResetMeter)
local crit=K.Panel("KeijinUICrits","Größte kritische Treffer",K.PANEL_WIDTH,220)
K.layout.Register("crits",crit,"Kritische Treffer",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",meter,"BOTTOMLEFT",0,-10)
end)
crit:EnableMouseWheel(true)
crit:SetScript("OnMouseWheel",function() critOffset=math.max(0,critOffset+(arg1>0 and -1 or 1)) end)
local critRows,critData={},{}
for i=1,8 do
    local row=K.ListBarRow(crit,i,19); AddSpellIcon(row,15); critRows[i]=row
end
-- Validated native sources for the Healing meter and diagnostic command.
local awaitingHealing=false
local function ReadHealing(valid)
    local supported=HealingSupported()
    if not supported then return nil,nil,nil,false end
    if not valid or awaitingHealing or not K.Number(AZS_HEALING_UPDATED) or not K.Fresh(AZS_HEALING_UPDATED) then return nil,nil,nil,true end
    local ok,lines,total,hps=pcall(AZS_GetHealing)
    if not ok or type(lines)~="table" then return nil,nil,nil,true end
    local sorted,sum,rate={},0,0
    for _,line in ipairs(lines) do
        if type(line)~="table" or type(line.name)~="string" or line.name=="" or not K.Number(line.dmg) or not K.Number(line.dps) then return nil,nil,nil,true end
        table.insert(sorted,line); sum=sum+line.dmg; rate=rate+line.dps
    end
    if not K.Number(sum) or not K.Number(rate) then return nil,nil,nil,true end
    if not K.Number(total) then total=sum end
    if not K.Number(hps) then hps=rate end
    table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
    return sorted,total,hps,true
end
local function ResetRun(waitForRun)
    K.liveDPS.Reset()
    baseline={}; meterStart=0; offset=0; critData={}; critOffset=0
    if K.DB().meterAutoBoss==true and K.DB().meterView=="boss" then K.DB().meterView=nil end
    autoView=nil; bossWasAlive=nil; autoWasOn=nil; awaitingBossRun=waitForRun==true
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then ResetRun(true) elseif prefix=="AZSRUN" then awaitingBossRun=false end
end)
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
-- Boss view: lines, total and dps of the last boss fight as the game reports them (empty before the first one).
local function BossAlive()
    local phase=AZS_GetPhase and AZS_GetPhase()
    if awaitingBossRun or (phase~="playing" and phase~="paused" and phase~="choosing") or not K.Fresh(AZS_RUN_UPDATED) then return false end
    return type(AZS_RUN)=="table" and K.Number(AZS_RUN.bu) and AZS_RUN.bu>0
end
local function AutoSwitch()
    local alive=BossAlive() and true or false
    local enabled=K.DB().meterAutoBoss==true
    local ended=bossWasAlive==true and not alive
    local began=alive~=bossWasAlive or not autoWasOn
    bossWasAlive=alive; autoWasOn=enabled
    -- Process setting changes even when the boss count has not changed.
    if not enabled then
        if autoView then offset=0 end
        autoView=nil; return
    end
    if not alive then
        if autoView or (ended and K.MeterView()=="boss") then
            if K.DB().meterView=="boss" then K.DB().meterView=nil end
            autoView=nil; offset=0
        end
    elseif began and K.MeterView()=="run" then autoView="boss"; offset=0 end
end
local function UpdateBoss()
    local lines,total,dps
    if AZS_GetBossMeter then lines,total,dps=AZS_GetBossMeter() end
    local sorted,sum={},0
    if type(lines)=="table" then
        for _,v in ipairs(lines) do
            if type(v.name)=="string" and K.Number(v.dmg) then table.insert(sorted,v); sum=sum+v.dmg end
        end
    end
    if table.getn(sorted)==0 then
        for _,row in ipairs(meterRows) do row:Hide() end
        meter:SetHeight(100); summary:SetText(K.T("Noch kein Bosskampf")); meter:Show()
        return
    end
    table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
    if not K.Number(total) then total=sum end
    meter:SetHeight(K.MeterMaxHeight())
    local visible=(meter.headerHeight-56)/22
    offset=math.min(offset,math.max(0,table.getn(sorted)-visible))
    for i,row in ipairs(meterRows) do
        local v=sorted[i+offset]
        if v and i<=visible then
            local rate=K.Number(v.dps) and v.dps or 0
            UpdateSpellIcon(row,v.name)
            row.label:SetText(K.DisplayName(v.name)); row.value:SetText(K.Short(v.dmg))
            row.dps:SetText(K.Short(rate).." DPS")
            row.bar:SetValue(sorted[1].dmg>0 and v.dmg/sorted[1].dmg or 0)
            local red,green,blue=K.SourceColor(v.name)
            row.bar:SetStatusBarColor(red,green,blue,0.85)
            row.tip=K.DisplayName(v.name)
            row.detail=string.format(K.T("%.0f Schaden\n%s / Sekunde\n%.1f%% Anteil%s"),v.dmg,
                K.Short(rate),total>0 and v.dmg/total*100 or 0,v.proc==1 and K.T("\nZusätzlicher Effekt") or "")
            row:Show()
        else row:Hide() end
    end
    Summary(K.T(BossAlive() and "Bosskampf: %s gesamt   ·   %s / s   (läuft)" or "Bosskampf: %s gesamt   ·   %s / s",
        K.Short(total),K.Short(K.Number(dps) and dps or 0)),total,K.Number(dps) and dps or 0)
    meter:Show()
end
-- Native effective healing by source. Reset and boss automation never replace a manual healing choice.
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then awaitingHealing=true elseif prefix=="AZSHEAL" then awaitingHealing=false end
end)
local function UpdateHealing(lines,total,hps,supported)
    local sorted=lines or {}; total=total or 0; hps=hps or 0
    if table.getn(sorted)==0 then
        for _,row in ipairs(meterRows) do row:Hide() end
        meter:SetHeight(100)
        summary:SetText(K.T(supported and "Noch keine Heilung" or "Heilungsdaten nicht verfügbar")); meter:Show(); return
    end
    meter:SetHeight(K.MeterMaxHeight())
    local visible=(meter.headerHeight-56)/22
    offset=math.min(offset,math.max(0,table.getn(sorted)-visible))
    for i,row in ipairs(meterRows) do
        local value=sorted[i+offset]
        if value and i<=visible then
            UpdateSpellIcon(row,value.name)
            row.label:SetText(K.DisplayName(value.name)); row.value:SetText(K.Short(value.dmg))
            row.dps:SetText(K.Short(K.Number(value.dps) and value.dps or 0).." HPS")
            row.bar:SetValue(sorted[1].dmg>0 and value.dmg/sorted[1].dmg or 0)
            local red,green,blue=K.SourceColor(value.name); row.bar:SetStatusBarColor(red,green,blue,.85)
            row.tip=K.DisplayName(value.name)
            row.detail=K.T("%.0f Heilung\n%s HPS\n%.1f%% Anteil\nNative Heilungsdaten, ohne Überheilung.",value.dmg,
                K.Short(K.Number(value.dps) and value.dps or 0),total>0 and value.dmg/total*100 or 0)
            row:Show()
        else row:Hide() end
    end
    Summary(K.T("Heilung: %s gesamt   ·   %s HPS",K.Short(total),K.Short(hps)),total,hps)
    meter:Show()
end
local previousReported
local function Update()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local r=AZS_RUN
    local seconds=AZS_GetRunTime and AZS_GetRunTime()
    local valid=type(r)=="table" and phase and K.Number(seconds)
    local reported=K.ReportedRunTime()
    if valid and reported and previousReported and reported<previousReported-K.RUN_BACK then ResetRun() end
    if reported then previousReported=reported end
    local healing,healTotal,healRate,healSupported=ReadHealing(valid)
    if not K.DB().hidden.statistics then
        r=valid and r or {}
        for i,def in ipairs(definitions) do
            local key=def[1]; local value=r[key]
            rows[i].tip=K.T(def[2]); rows[i].label:SetText(K.T(def[2]))
            if key=="xp" then
                local need=r.xpn
                if K.Number(value) and K.Number(need) and need>0 then
                    rows[i].value:SetText(K.Short(value).." / "..K.Short(need))
                    rows[i].detail=K.T("%.0f / %.0f, %.0f %% bis zum nächsten Level",value,need,math.min(100,value/need*100))
                else
                    rows[i].value:SetText(K.Short(nil)); rows[i].detail=K.T("Noch keine Spieldaten")
                end
            else
                rows[i].value:SetText(K.Short(value))
                if key=="taken" then rows[i].detail=K.combatDetails.Taken()
                else rows[i].detail=K.Number(value) and string.format("%.0f",value) or K.T("Noch keine Spieldaten") end
            end
        end
        stats:Show()
    else stats:Hide() end
    AutoSwitch(); PaintTabs()
    local lines=AZS_GetMeter and AZS_GetMeter()
    if phase=="playing" and K.Number(AZS_RUN_UPDATED) and GetTime()-AZS_RUN_UPDATED>5 then
        K.liveDPS.Reset()
    elseif valid and not awaitingBossRun then K.liveDPS.Observe(reported or seconds,lines) end
    local meterValid=valid and type(lines)=="table" and not K.DB().hidden.meter
    local bossView=K.MeterView()=="boss"
    local healingView=K.MeterView()=="healing"
    if bossView or healingView then reset:Hide() else reset:Show() end
    local sorted,total={},0
    if meterValid and not bossView and not healingView then
        for _,v in ipairs(lines) do
            if type(v.name)~="string" or not K.Number(v.dmg) then meterValid=false; break end
            local value=math.max(0,v.dmg-(baseline[v.name] or 0))
            table.insert(sorted,{name=v.name,dmg=value,proc=v.proc}); total=total+value
        end
    end
    if healingView and not K.DB().hidden.meter then
        UpdateHealing(healing,healTotal,healRate,healSupported); K.Native("meter",true)
    elseif bossView and not K.DB().hidden.meter then
        UpdateBoss(); K.Native("meter",true)
    elseif meterValid then
        table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
        meter:SetHeight(K.MeterMaxHeight())
        local visible=(meter.headerHeight-56)/22
        offset=math.min(offset,math.max(0,table.getn(sorted)-visible))
        local duration=seconds-meterStart
        local liveTotal=0
        for _,v in ipairs(sorted) do liveTotal=liveTotal+(K.liveDPS.Rate(v.name) or 0) end
        for i,row in ipairs(meterRows) do
            local v=sorted[i+offset]
            if v and i<=visible then
                -- Same run clock and reset baseline as the summary and tooltip;
                -- do not mix native run DPS with damage measured since Reset.
                local average=duration>0 and v.dmg/duration or 0
                local dps=K.liveDPS.Rate(v.name)
                UpdateSpellIcon(row,v.name)
                row.label:SetText(K.DisplayName(v.name)); row.value:SetText(K.Short(v.dmg))
                row.dps:SetText(dps and (K.Short(dps).." DPS") or "?")
                row.bar:SetValue(sorted[1].dmg>0 and v.dmg/sorted[1].dmg or 0)
                local red,green,blue=K.SourceColor(v.name)
                row.bar:SetStatusBarColor(red,green,blue,0.85)
                row.tip=K.DisplayName(v.name)
                row.detail=string.format(K.T("%.0f Schaden\n%s / Sekunde\n%.1f%% Anteil%s"),v.dmg,
                    K.Short(average),total>0 and v.dmg/total*100 or 0,v.proc==1 and K.T("\nZusätzlicher Effekt") or "")
                row.detail=row.detail.."\n"..K.T("DPS (10 s): %s\nDPS oben: letzte 10 Spielsekunden. Durchschnitt: seit Runbeginn oder Reset.",K.Short(dps))
                row.detail=row.detail..K.combatDetails.Detail(v.name)
                row:Show()
            else row:Hide() end
        end
        meter.runAverage=duration>0 and total/duration or 0
        local ready=sorted[1] and K.liveDPS.Rate(sorted[1].name)~=nil
        summary:SetText(K.T("%s gesamt · %s DPS",K.Short(total),ready and K.Short(liveTotal) or "?"))
        meter:Show(); K.Native("meter",true)
    else
        K.NativeFollow("meter",not K.DB().hidden.meter)
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
        local visible=math.max(1,math.min(8,math.floor((available-42)/21)))
        critOffset=math.min(critOffset,math.max(0,table.getn(crits)-visible))
        for i,row in ipairs(critRows) do
            local v=crits[i+critOffset]
            if v and i<=visible then
                UpdateSpellIcon(row,v.name)
                row.label:SetText(v.name); row.value:SetText(K.Short(v.best))
                row.bar:SetValue(v.best/crits[1].best)
                local red,green,blue=K.SourceColor(v.name); row.bar:SetStatusBarColor(red,green,blue,0.85)
                row.tip=v.name
                row.detail=string.format(K.T("Größter: %.0f\nLetzter: %.0f\nDurchschnitt: %.0f\nKleinster: %.0f\nKritische Treffer: %d"),v.best,v.last,v.sum/v.count,v.min,v.count)
                row:Show()
            else row:Hide() end
        end
        crit:SetHeight(42+math.min(visible,table.getn(crits))*21); crit:Show()
    else
        for _,row in ipairs(critRows) do row:Hide() end
        if K.DB().hidden.crits then crit:Hide() else crit:SetHeight(63); crit:Show() end
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
    if HealingSupported() then
        local lines,total,hps=ReadHealing(AZS_GetPhase and AZS_GetPhase() and K.Number(AZS_GetRunTime and AZS_GetRunTime()))
        if not lines then K.Say(K.T("Noch keine aktuellen Heilungsdaten")); return end
        local shock=false
        for _,line in ipairs(lines) do
            K.Say(K.T("Heilquelle: %s [%s] · %s Heilung · %s HPS",K.DisplayName(line.name),line.name,tostring(line.dmg),tostring(line.dps)))
            if K.SourceKey(line.name)=="holy_shock" then shock=true end
        end
        K.Say(K.T(shock and "Holy Shock: als eigene Heilquelle vom Spiel gemeldet." or "Holy Shock: keine eigene Heilquelle vom Spiel gemeldet. Ursache noch offen."))
        K.Say(K.T("Heilung nativ: %s · %s HPS · Quellen: %d",K.Short(total),K.Short(hps),lines and table.getn(lines) or 0))
        return
    end
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
