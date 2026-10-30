local K=KeijinUI
local P=K.panelSizing
local function Inactive() return not K.basisHud.On() end
local stats=K.Panel("KeijinUIStatistics","Dieser Run",K.PANEL_WIDTH,185)
K.layout.Register("statistics",stats,"Runstatistiken",function(f) f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-36) end,{inactive=Inactive})
K.Shown(stats,false)
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
K.layout.Register("meter",meter,"Schadensanzeige",function(f) f:ClearAllPoints(); f:SetPoint("TOPRIGHT",stats,"BOTTOMRIGHT",0,-10) end,{inactive=Inactive})
K.Shown(meter,false)
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
local meterStart,offset,critOffset=0; P.offsets.crits=0,0,0
local MAX_ROWS=8
-- Height of the meter with data: as many rows as the screen allows, 3 to MAX_ROWS.
function K.MeterMaxHeight() return 56+math.max(3,math.min(MAX_ROWS,math.floor((K.UIHeight()-563)/22)))*22 end
local function AddSpellIcon(row,size)
    row.iconSize=size; row.labelWidth=row.label:GetWidth()
    row.icon=row.label:GetParent():CreateTexture(nil,"ARTWORK")
    K.SetW(row.icon,size); K.SetH(row.icon,size)
    row.icon:SetPoint("LEFT",row,"LEFT",5,0)
    row.icon:SetTexCoord(.08,.92,.08,.92); K.Shown(row.icon,false)
end
-- Party rows colour name and rim; every other view starts from the plain look again.
local function PlainRow(row)
    if row.kuiPlain then return end
    row.kuiPlain=true
    row.label:SetTextColor(0.94,0.91,0.82)
    if row.rim then for _,t in ipairs(row.rim) do t:SetVertexColor(0.62,0.57,0.43,0.95) end end
end
local function UpdateSpellIcon(row,name)
    PlainRow(row)
    local enabled=K.DB().meterIcons==true
    local inset=enabled and row.iconSize+3 or 0
    K.Anchor(row.label,"LEFT",row.label:GetParent(),"LEFT",5+inset,0)
    row.labelInset=inset
    K.SetW(row.label,row.labelWidth-inset)
    local texture=enabled and K.SpellIcon(name)
    if texture then row.icon:SetTexture(texture); K.Shown(row.icon,true) else K.Shown(row.icon,false) end
end
for i=1,MAX_ROWS do
    local row=K.ListBarRow(meter,i,20)
    -- Separate, bounded columns: ability | total damage | damage per second.
    -- Use the existing text layer so all three stay above the bar artwork.
    K.SetW(row.label,meter:GetWidth()-156)
    AddSpellIcon(row,16)
    row.value:ClearAllPoints(); row.value:SetPoint("RIGHT",row,"RIGHT",-73,0)
    K.SetW(row.value,53); K.SetH(row.value,16); row.value:SetJustifyH("RIGHT")
    row.dps=K.Text(row.value:GetParent(),"",10,"RIGHT",-6,0,62)
    row.dps:SetJustifyH("RIGHT"); row.dps:SetTextColor(0.84,0.82,0.75)
    meterRows[i]=row
end
meter:EnableMouseWheel(true)
meter:SetScript("OnMouseWheel",function() P.Scroll("meter",arg1) end)
local reset=CreateFrame("Button",nil,meter)
reset:SetWidth(44); reset:SetHeight(20); reset:SetPoint("TOPRIGHT",meter,"TOPRIGHT",-10,-6)
reset.text=K.LText(reset,"Reset",9,"CENTER",0,0)
-- Run/Boss/Healing share one meter. Automatic Boss is temporary; Run and Healing choices stay explicit.
local autoView,bossWasAlive,autoWasOn,awaitingBossRun
local tabRun=CreateFrame("Button","KeijinUIMeterTabRun",meter)
local tabBoss=CreateFrame("Button","KeijinUIMeterTabBoss",meter)
local tabHeal=CreateFrame("Button","KeijinUIMeterTabHeal",meter)
local tabParty=CreateFrame("Button","KeijinUIMeterTabParty",meter)
tabParty:SetWidth(38); tabParty:SetHeight(20); tabParty.text=K.LText(tabParty,"Party",9,"CENTER",0,0); K.Shown(tabParty,false)
for _,tab in ipairs({tabRun,tabBoss}) do tab:SetWidth(34); tab:SetHeight(20) end
tabRun.text=K.LText(tabRun,"Run",9,"CENTER",0,0)
tabBoss.text=K.LText(tabBoss,"Boss",9,"CENTER",0,0)
tabHeal:SetWidth(44); tabHeal:SetHeight(20); tabHeal.text=K.LText(tabHeal,"Heilung",9,"CENTER",0,0)
-- Party data of the co-op patch: AZS_GetPartyMeter() -> lines, total, rate (empty outside of a party, absent in older versions).
-- Returns the valid lines sorted by damage, or nil.
function K.PartyMeter()
    if type(AZS_GetPartyMeter)~="function" then return nil end
    local ok,lines,total,rate=pcall(AZS_GetPartyMeter)
    if not ok or type(lines)~="table" then return nil end
    local roster,known
    if K.party and K.party.Roster then roster,known=K.party.Roster() end
    if known and not roster then return nil end
    local sorted,sum,sumRate={},0,0
    local filtered=false
    for _,line in ipairs(lines) do
        if type(line)=="table" and type(line.name)=="string" and line.name~="" and K.Number(line.dmg) then
            if known and not roster[line.name] then filtered=true
            else table.insert(sorted,line); sum=sum+line.dmg; sumRate=sumRate+(K.Number(line.dps) and line.dps or 0) end
        end
    end
    if table.getn(sorted)==0 then return nil end
    table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
    return sorted,not filtered and K.Number(total) and total or sum,not filtered and K.Number(rate) and rate or sumRate
end
-- Class key of the game (paladin, ...) -> colour of KeijinUI; grey for unknown ones.
function K.PartyClassColor(class)
    local r,g,b=K.ClassColor(type(class)=="string" and string.upper(class) or nil)
    if r then return r,g,b end
    return 0.62,0.62,0.62
end
local partyReady=false   -- set by Update: the Party view exists only while the game reports party lines
function K.MeterView()
    if autoView then return autoView end
    local view=K.DB().meterView
    if view=="party" and partyReady then return "party" end
    return (view=="boss" or view=="healing") and view or "run"
end
local function PaintTabs()
    local view=K.MeterView()
    local function Paint(tab,on) if on then tab.text:SetTextColor(1,0.82,0.28) else tab.text:SetTextColor(0.62,0.6,0.54) end end
    Paint(tabRun,view=="run"); Paint(tabBoss,view=="boss"); Paint(tabHeal,view=="healing"); Paint(tabParty,view=="party")
end
function K.SetMeterView(view)
    if autoView and view==autoView then offset=0; P.offsets.meter=0; PaintTabs(); return end
    K.DB().meterView=(view=="boss" or view=="healing" or view=="party") and view or nil
    autoView=nil   -- Manual Run/Healing choices remain until the next fight.
    offset=0; P.offsets.meter=0; PaintTabs()
end
function K.SetMeterAuto(on) K.DB().meterAutoBoss=on and true or nil end
tabRun:SetScript("OnClick",function() K.SetMeterView("run") end)
tabBoss:SetScript("OnClick",function() K.SetMeterView("boss") end)
tabHeal:SetScript("OnClick",function() K.SetMeterView("healing") end)
tabParty:SetScript("OnClick",function() K.SetMeterView("party") end)
local headerMode="normal"
local function LayoutSummary()
    if headerMode=="off" then K.SetW(summary,meter:GetWidth()-160-(tabParty:IsShown() and 40 or 0))
    else K.SetW(summary,meter:GetWidth()-26) end
end
meter.headerExtra=function(mode)
    reset:ClearAllPoints(); reset:SetHeight(mode=="thin" and 14 or 20)
    tabRun:ClearAllPoints(); tabBoss:ClearAllPoints(); tabHeal:ClearAllPoints(); tabParty:ClearAllPoints()
    tabRun:SetHeight(mode=="thin" and 14 or 20); tabBoss:SetHeight(mode=="thin" and 14 or 20); tabHeal:SetHeight(mode=="thin" and 14 or 20)
    tabParty:SetHeight(mode=="thin" and 14 or 20); tabParty:SetWidth(38)
    tabRun:SetWidth(mode=="off" and 24 or 34); tabBoss:SetWidth(mode=="off" and 28 or 34); tabHeal:SetWidth(mode=="off" and 38 or 44)
    reset:SetWidth(mode=="off" and 28 or 44); K.SetFontSize(reset.text,mode=="off" and 8 or 9)
    K.SetFontSize(summary,mode=="off" and 9 or 10)
    if mode=="off" then
        -- No title strip: tabs and Reset share the bottom row with the summary.
        reset:SetPoint("BOTTOMRIGHT",meter,"BOTTOMRIGHT",-10,4)
        tabHeal:SetPoint("RIGHT",reset,"LEFT",-4,0)
        tabBoss:SetPoint("RIGHT",tabHeal,"LEFT",-2,0)
        tabRun:SetPoint("RIGHT",tabBoss,"LEFT",-2,0)
        tabParty:SetPoint("RIGHT",tabRun,"LEFT",-2,0)
    else
        if mode=="thin" then reset:SetPoint("RIGHT",meter.strip,"RIGHT",-3,0)
        else reset:SetPoint("TOPRIGHT",meter,"TOPRIGHT",-10,-6) end
        tabHeal:SetPoint("RIGHT",reset,"LEFT",-4,0)
        tabBoss:SetPoint("RIGHT",tabHeal,"LEFT",-2,0)
        tabRun:SetPoint("RIGHT",tabBoss,"LEFT",-2,0)
        tabParty:SetPoint("RIGHT",tabRun,"LEFT",-2,0)
    end
    headerMode=mode; LayoutSummary()
    PaintTabs()
end
local function Summary(full,total,rate)
    summary:SetText(K.headers.Mode(meter)=="off" and (K.Short(total).." · "..K.Short(rate).."/s") or full)
end
local function ResetMeter()
    K.liveDPS.Reset()
    baseline={}; meterStart=AZS_GetRunTime and AZS_GetRunTime() or 0; offset=0; P.offsets.meter=0
    local lines=AZS_GetMeter and AZS_GetMeter()
    for _,v in ipairs(lines or {}) do if K.Number(v.dmg) then baseline[v.name]=v.dmg end end
end
reset:SetScript("OnClick",ResetMeter)
local crit=K.Panel("KeijinUICrits","Größte kritische Treffer",K.PANEL_WIDTH,220)
K.layout.Register("crits",crit,"Kritische Treffer",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",meter,"BOTTOMLEFT",0,-10)
end,{inactive=Inactive})
K.Shown(crit,false)
crit:EnableMouseWheel(true)
crit:SetScript("OnMouseWheel",function() P.Scroll("crits",arg1) end)
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
    baseline={}; meterStart=0; offset=0; P.offsets.meter=0; critData={}; critOffset=0; P.offsets.crits=0
    if K.DB().meterAutoBoss==true and K.DB().meterView=="boss" then K.DB().meterView=nil end
    autoView=nil; bossWasAlive=nil; autoWasOn=nil; awaitingBossRun=waitForRun==true
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then ResetRun(true) elseif prefix=="AZSRUN" then awaitingBossRun=false end
end)
local combat=CreateFrame("Frame",nil,UIParent)
combat:SetScript("OnEvent",function()
    if Inactive() or not K.basisHud.ready then return end
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
        if autoView then offset=0; P.offsets.meter=0 end
        autoView=nil; return
    end
    if not alive then
        if autoView or (ended and K.MeterView()=="boss") then
            if K.DB().meterView=="boss" then K.DB().meterView=nil end
            autoView=nil; offset=0; P.offsets.meter=0
        end
    elseif began and K.MeterView()=="run" then autoView="boss"; offset=0; P.offsets.meter=0 end
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
        for _,row in ipairs(meterRows) do K.Shown(row,false) end
        -- Sized panels get their height from P.List below; writing the standard height first would flip it every update.
        if not P.Custom("meter") then K.SetH(meter,100) end; if P.Custom("meter") then P.List("meter",meterRows,0,8,22,math.max(54,46*P.Factor("meter"))) end; summary:SetText(K.T("Noch kein Bosskampf")); K.Shown(meter,true)
        return
    end
    table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
    if not K.Number(total) then total=sum end
    if not P.Custom("meter") then K.SetH(meter,K.MeterMaxHeight()) end
    local visible
    if P.Custom("meter") then visible,offset=P.List("meter",meterRows,table.getn(sorted),8,22,math.max(54,46*P.Factor("meter")))
    else visible=(meter.headerHeight-56)/22; offset=P.Range("meter",table.getn(sorted),visible) end
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
            K.Shown(row,true)
        else K.Shown(row,false) end
    end
    Summary(K.T(BossAlive() and "Bosskampf: %s gesamt   ·   %s / s   (läuft)" or "Bosskampf: %s gesamt   ·   %s / s",
        K.Short(total),K.Short(K.Number(dps) and dps or 0)),total,K.Number(dps) and dps or 0)
    K.Shown(meter,true)
end
-- Native effective healing by source. Reset and boss automation never replace a manual healing choice.
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then awaitingHealing=true elseif prefix=="AZSHEAL" then awaitingHealing=false end
end)
local function UpdateHealing(lines,total,hps,supported)
    local sorted=lines or {}; total=total or 0; hps=hps or 0
    if table.getn(sorted)==0 then
        for _,row in ipairs(meterRows) do K.Shown(row,false) end
        if not P.Custom("meter") then K.SetH(meter,100) end
        if P.Custom("meter") then P.List("meter",meterRows,0,8,22,math.max(54,46*P.Factor("meter"))) end
        summary:SetText(K.T(supported and "Noch keine Heilung" or "Heilungsdaten nicht verfügbar")); K.Shown(meter,true); return
    end
    if not P.Custom("meter") then K.SetH(meter,K.MeterMaxHeight()) end
    local visible
    if P.Custom("meter") then visible,offset=P.List("meter",meterRows,table.getn(sorted),8,22,math.max(54,46*P.Factor("meter")))
    else visible=(meter.headerHeight-56)/22; offset=P.Range("meter",table.getn(sorted),visible) end
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
            K.Shown(row,true)
        else K.Shown(row,false) end
    end
    Summary(K.T("Heilung: %s gesamt   ·   %s HPS",K.Short(total),K.Short(hps)),total,hps)
    K.Shown(meter,true)
end
-- Co-op: damage of all heroes of the party (AZS_GetPartyMeter), class coloured, own hero framed in gold.
local function UpdateParty(sorted,total,rate)
    if not P.Custom("meter") then K.SetH(meter,K.MeterMaxHeight()) end
    local visible
    if P.Custom("meter") then visible,offset=P.List("meter",meterRows,table.getn(sorted),8,22,math.max(54,46*P.Factor("meter")))
    else visible=(meter.headerHeight-56)/22; offset=P.Range("meter",table.getn(sorted),visible) end
    local me=UnitName("player")
    for i,row in ipairs(meterRows) do
        local v=sorted[i+offset]
        if v and i<=visible then
            local dps=K.Number(v.dps) and v.dps or 0
            local own=me~=nil and v.name==me
            local red,green,blue=K.PartyClassColor(v.class)
            -- No spell icon in this view: the label returns to the left edge.
            K.Anchor(row.label,"LEFT",row.label:GetParent(),"LEFT",5,0)
            if row.icon then row.labelInset=0; K.SetW(row.label,row.labelWidth); K.Shown(row.icon,false) end
            row.kuiPlain=nil
            row.label:SetText(v.name); row.label:SetTextColor(red,green,blue)
            row.value:SetText(K.Short(v.dmg)); row.dps:SetText(K.Short(dps).." DPS")
            row.bar:SetValue(sorted[1].dmg>0 and v.dmg/sorted[1].dmg or 0)
            row.bar:SetStatusBarColor(red,green,blue,own and 0.95 or 0.65)
            for _,t in ipairs(row.rim) do if own then t:SetVertexColor(1,0.82,0.28,1) else t:SetVertexColor(0.62,0.57,0.43,0.95) end end
            row.tip=v.name
            row.detail=string.format(K.T("%.0f Schaden\n%s / Sekunde\n%.1f%% Anteil%s"),v.dmg,K.Short(dps),total>0 and v.dmg/total*100 or 0,"")
            if type(v.top)=="string" and v.top~="" then
                row.detail=row.detail.."\n"..K.T("Stärkster Zauber: %s (%s DPS)",K.DisplayName(v.top),K.Short(K.Number(v.topdps) and v.topdps or 0))
            end
            K.Shown(row,true)
        else K.Shown(row,false) end
    end
    Summary(K.T("Party: %s gesamt · %s DPS",K.Short(total),K.Short(rate)),total,rate)
    K.Shown(meter,true)
end
local previousReported
local sizedMeter
local function Release()
    K.Shown(stats,false); K.Shown(meter,false); K.Shown(crit,false)
    for _,key in ipairs({"statistics","meter","crits"}) do
        local e=K.layout.entries[key]
        if e and e.handle then e.handle:Hide() end
    end
    for ev in pairs(K.tools.CombatEvents) do combat:UnregisterEvent(ev) end
    K.basisHud.Native("meter",false)
end
-- Party tab, tab painting and the sized meter layout; split out of Update (Lua 5.0 allows 32 upvalues per function).
local function UpdateTabs(party)
    if (party~=nil)~=partyReady then
        partyReady=party~=nil
        if partyReady then K.Shown(tabParty,true) else K.Shown(tabParty,false) end
        LayoutSummary()
    end
    AutoSwitch(); PaintTabs()
    if not P.Custom("meter") and sizedMeter then
        P.Restore("meter"); meter.sizingMinimum=nil
        summary:ClearAllPoints(); summary:SetPoint("BOTTOMLEFT",meter,"BOTTOMLEFT",13,10)
        summary:SetHeight(15); meter.headerExtra(K.headers.Mode(meter)); sizedMeter=nil
    end
    if P.Custom("meter") then
        sizedMeter=true
        P.Fonts("meter")
        local q,step,pad=P.Metrics("meter",22)
        local tabs={tabRun,tabBoss,tabHeal,tabParty,reset}
        local x=13
        for _,tab in ipairs(tabs) do
            K.SetW(tab,math.max(30,P.Measure(tab.text,tab.text:GetText() or "")+12))
            K.SetH(tab,math.max(20,16*q))
            K.Anchor(tab,"BOTTOMLEFT",meter,"BOTTOMLEFT",x,8+math.max(30,26*q))
            if tab:IsShown() then x=x+tab:GetWidth()+3 end
        end
        meter.sizingMinimum=x+13
        P.Width("meter",x+13)
        K.Anchor(summary,"BOTTOMLEFT",meter,"BOTTOMLEFT",13,7)
        K.SetW(summary,meter:GetWidth()-26); K.SetH(summary,math.max(30,26*q))
        K.SetH(meter.title,K.HeaderTitleHeight(meter,q)); K.SetH(meter.strip,K.HeaderStripHeight(meter,q))
    end
end
-- Critical hit list; split out of Update for the same reason.
local function UpdateCrits(valid)
    local crits={}
    for _,v in pairs(critData) do table.insert(crits,v) end
    table.sort(crits,function(a,b) if a.best==b.best then return a.name<b.name end return a.best>b.best end)
    if valid and not K.DB().hidden.crits and table.getn(crits)>0 then
        local available=(meter:GetBottom() or 220)-190
        local visible=math.max(1,math.min(8,math.floor((available-42)/21)))
        if P.Custom("crits") then visible,critOffset=P.List("crits",critRows,table.getn(crits),8,21)
        else P.Restore("crits"); critOffset=P.Range("crits",table.getn(crits),visible) end
        for i,row in ipairs(critRows) do
            local v=crits[i+critOffset]
            if v and i<=visible then
                UpdateSpellIcon(row,v.name)
                row.label:SetText(v.name); row.value:SetText(K.Short(v.best))
                row.bar:SetValue(v.best/crits[1].best)
                local red,green,blue=K.SourceColor(v.name); row.bar:SetStatusBarColor(red,green,blue,0.85)
                row.tip=v.name
                row.detail=string.format(K.T("Größter: %.0f\nLetzter: %.0f\nDurchschnitt: %.0f\nKleinster: %.0f\nKritische Treffer: %d"),v.best,v.last,v.sum/v.count,v.min,v.count)
                K.Shown(row,true)
            else K.Shown(row,false) end
        end
        if not P.Custom("crits") then K.SetH(crit,42+math.min(visible,table.getn(crits))*21) end; K.Shown(crit,true)
    else
        for _,row in ipairs(critRows) do K.Shown(row,false) end
        if not P.Custom("crits") then P.Restore("crits") end
        if K.DB().hidden.crits then K.Shown(crit,false) else
            if not P.Custom("crits") then K.SetH(crit,63) end
            if P.Custom("crits") then P.List("crits",critRows,0,8,21) end
            K.Shown(crit,true)
        end
    end
end
local function Update()
    if Inactive() then Release(); return end
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
        local visible,statOffset=P.List("statistics",rows,7,7,21)
        if not P.Custom("statistics") then K.SetH(stats,185) end
        for i,row in ipairs(rows) do
            local def=definitions[i+statOffset]
            if def and i<=visible then
                K.Shown(row,true)
                local key=def[1]; local value=r[key]
                row.tip=K.T(def[2]); row.label:SetText(K.T(def[2]))
                if key=="xp" then
                    local need=r.xpn
                    if K.Number(value) and K.Number(need) and need>0 then
                        row.value:SetText(K.Short(value).." / "..K.Short(need))
                        row.detail=K.T("%.0f / %.0f, %.0f %% bis zum nächsten Level",value,need,math.min(100,value/need*100))
                    else
                        row.value:SetText(K.Short(nil)); row.detail=K.T("Noch keine Spieldaten")
                    end
                else
                    row.value:SetText(K.Short(value))
                    if key=="taken" then row.detail=K.combatDetails.Taken()
                    else row.detail=K.Number(value) and string.format("%.0f",value) or K.T("Noch keine Spieldaten") end
                end
            K.Shown(row.line,i~=visible)
            else K.Shown(row,false) end
        end
        K.Shown(stats,true)
    else K.Shown(stats,false) end
    local party,partyTotal,partyRate=K.PartyMeter()
    UpdateTabs(party)
    local lines=AZS_GetMeter and AZS_GetMeter()
    local meterValid=valid and type(lines)=="table" and not K.DB().hidden.meter
    local bossView=K.MeterView()=="boss"
    local healingView=K.MeterView()=="healing"
    local partyView=K.MeterView()=="party"
    if bossView or healingView or partyView then K.Shown(reset,false) else K.Shown(reset,true) end
    local sorted,total={},0
    if meterValid and not bossView and not healingView and not partyView then
        for _,v in ipairs(lines) do
            if type(v.name)~="string" or not K.Number(v.dmg) then meterValid=false; break end
            local value=math.max(0,v.dmg-(baseline[v.name] or 0))
            table.insert(sorted,{name=v.name,dmg=value,proc=v.proc}); total=total+value
        end
    end
    if healingView and not K.DB().hidden.meter then
        UpdateHealing(healing,healTotal,healRate,healSupported); K.basisHud.Native("meter",true)
    elseif bossView and not K.DB().hidden.meter then
        UpdateBoss(); K.basisHud.Native("meter",true)
    elseif partyView and not K.DB().hidden.meter then
        UpdateParty(party,partyTotal,partyRate); K.basisHud.Native("meter",true)
    elseif meterValid then
        table.sort(sorted,function(a,b) if a.dmg==b.dmg then return a.name<b.name end return a.dmg>b.dmg end)
        if not P.Custom("meter") then K.SetH(meter,K.MeterMaxHeight()) end
        local visible
        if P.Custom("meter") then visible,offset=P.List("meter",meterRows,table.getn(sorted),8,22,math.max(54,46*P.Factor("meter")))
        else visible=(meter.headerHeight-56)/22; offset=P.Range("meter",table.getn(sorted),visible) end
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
                K.Shown(row,true)
            else K.Shown(row,false) end
        end
        meter.runAverage=duration>0 and total/duration or 0
        local ready=sorted[1] and K.liveDPS.Rate(sorted[1].name)~=nil
        Summary(K.T("%s gesamt · %s DPS",K.Short(total),ready and K.Short(liveTotal) or "?"),total,ready and liveTotal or nil)
        K.Shown(meter,true); K.basisHud.Native("meter",true)
    else
        K.basisHud.NativeFollow("meter",not K.DB().hidden.meter)
        if K.DB().hidden.meter then K.Shown(meter,false)
        else
            for _,row in ipairs(meterRows) do K.Shown(row,false) end
            if not P.Custom("meter") then K.SetH(meter,100) end; summary:SetText(K.T("Noch kein Schaden")); K.Shown(meter,true)
        end
    end
    if P.Custom("meter") and not meterValid and not bossView and not healingView and not partyView then P.List("meter",meterRows,0,8,22,math.max(54,46*P.Factor("meter"))) end
    if P.Custom("meter") then K.SetW(summary,meter:GetWidth()-26) end
    UpdateCrits(valid)
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
    if Inactive() then return end
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
P.Register("statistics",stats,"Runstatistiken",Update)
P.Register("meter",meter,"Schadensanzeige",Update)
P.Register("crits",crit,"Kritische Treffer",Update)
K.ResetMeter=ResetMeter
K.ResetCrits=function() critData={} end
local function Refresh()
    if Inactive() then Release(); DebugStop()
    else
        if K.basisHud.ready then
            for ev in pairs(K.tools.CombatEvents) do combat:RegisterEvent(ev) end
        end
        Update()
    end
end
table.insert(K.basisHud.refresh,Refresh)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then Refresh() end end)
K.On("PLAYER_ENTERING_WORLD",Refresh)
K.Update("basisHud",Update)
Refresh()
