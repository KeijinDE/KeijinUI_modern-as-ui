local K = KeijinUI
local tracker=K.Panel("KeijinUITracker","Runübersicht",300,220)
-- Default: right below the minimap (its size follows the minimap style), else the old absolute place.
K.layout.Register("tracker",tracker,"Runübersicht",function(f)
    f:ClearAllPoints()
    if MinimapCluster then f:SetPoint("TOPRIGHT",MinimapCluster,"BOTTOMRIGHT",-12,-10)
    else f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-24,-220) end
end)
local zone=K.Text(tracker,"",12,"TOPLEFT",14,-35,270)
zone:SetTextColor(1,0.82,0.28)
local time=K.Text(tracker,"",22,"TOPLEFT",14,-55)
local progress=CreateFrame("StatusBar",nil,tracker)
progress:SetPoint("TOPLEFT",tracker,"TOPLEFT",14,-85); progress:SetWidth(272); progress:SetHeight(12)
progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); progress:SetStatusBarColor(0.24,0.56,0.83)
progress:SetMinMaxValues(0,1)
progress:SetBackdrop({bgFile=K.flat}); progress:SetBackdropColor(0.02,0.02,0.025,1)
K.MetalBar(progress,progress)
local schedules={}
K.LText(tracker,"Boss",9,"TOPLEFT",14,-105,130):SetTextColor(0.65,0.63,0.58)
K.LText(tracker,"Bosszeit",9,"TOPRIGHT",-84,-105):SetTextColor(0.65,0.63,0.58)
K.LText(tracker,"Runzeit",9,"TOPRIGHT",-14,-105):SetTextColor(0.65,0.63,0.58)
local bosses=K.Panel("KeijinUIBosses","Begegnungen",300,40)
bosses.title:Hide(); bosses.strip:Hide()
K.layout.Register("bosses",bosses,"Begegnungen",function(f) f:ClearAllPoints(); f:SetPoint("TOP",UIParent,"TOP",0,-14) end,{hidden=true})
local bossRows={}
local bossOffset=0
bosses:EnableMouseWheel(true)
bosses:SetScript("OnMouseWheel",function() bossOffset=math.max(0,bossOffset+(arg1>0 and -1 or 1)) end)
local tally=K.Panel("KeijinUITally","",400,34)
tally.title:Hide()
K.layout.Register("tally",tally,"Kills, Gold, Cache",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOM",KeijinBuildBarFrame or UIParent,KeijinBuildBarFrame and "TOP" or "BOTTOM",0,KeijinBuildBarFrame and 6 or 102) end)
local tallyValues={}
local tallyIcons={
    "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
    "Interface\\MoneyFrame\\UI-MoneyIcons",
    "Interface\\Icons\\INV_Box_01"
}
local tallyCells={}
-- Five cells in 388 pixels: three symbol cells, "geöffnet" and the wait time (wider, it shows "~12:34").
local tallyWidths={74,74,74,74,92}
local tallyLeft=6
for i,label in ipairs({"Kills","Gold","Cache","Geöffnet","Bezahlbar"}) do
    local cell=CreateFrame("Frame",nil,tally)
    cell:SetWidth(tallyWidths[i]); cell:SetHeight(32); cell:SetPoint("TOPLEFT",tally,"TOPLEFT",tallyLeft,-1)
    tallyLeft=tallyLeft+tallyWidths[i]
    if tallyIcons[i] then
        local icon=cell:CreateTexture(nil,"ARTWORK")
        icon:SetTexture(tallyIcons[i]); icon:SetWidth(20); icon:SetHeight(20)
        icon:SetPoint("LEFT",cell,"LEFT",5,0)
        if i==2 then icon:SetTexCoord(0,0.25,0,1) end
        tallyValues[i]=K.Text(cell,"?",11,"LEFT",31,0,tallyWidths[i]-35)
    else
        tallyValues[i]=K.Text(cell,"?",11,"CENTER",0,0,tallyWidths[i]-6)
        tallyValues[i]:SetJustifyH("CENTER")
    end
    cell:EnableMouse(true)
    cell:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_TOP"); GameTooltip:SetText(this.tip or K.T(label),1,0.82,0.28)
        if this.detail then GameTooltip:AddLine(this.detail,0.9,0.88,0.8,true) end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave",function() GameTooltip:Hide() end)
    tallyCells[i]=cell
end
local xp=CreateFrame("StatusBar","KeijinUIXP",UIParent)
xp:SetWidth(400); xp:SetHeight(9); xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xp:SetStatusBarColor(0.57,0.28,0.83); xp:SetMinMaxValues(0,1)
K.MetalBar(xp,xp)
xp:SetStatusBarColor(0.57,0.28,0.83)
K.layout.Register("xp",xp,"Erfahrung",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOM",UIParent,"BOTTOM",0,26) end)
xp:Hide()
local level=K.Text(tracker,"",10,"BOTTOMLEFT",14,9,272)
local function Active(phase) return phase=="ready" or phase=="playing" or phase=="paused" or phase=="choosing" end
local function ScheduleRow(i)
    if schedules[i] then return schedules[i] end
    local row=CreateFrame("Frame",nil,tracker)
    row:SetWidth(272); row:SetHeight(17); row:SetPoint("TOPLEFT",tracker,"TOPLEFT",14,-123-(i-1)*18)
    row.name=K.Text(row,"",10,"LEFT",0,0,130)
    row.boss=K.Text(row,"",10,"RIGHT",-70,0)
    row.boss:SetWidth(62); row.boss:SetHeight(15); row.boss:SetJustifyH("RIGHT")
    row.run=K.Text(row,"",10,"RIGHT",0,0)
    row.run:SetWidth(64); row.run:SetHeight(15); row.run:SetJustifyH("RIGHT")
    row:EnableMouse(true)
    row:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText(this.bossName or "?",1,0.82,0.28)
        if this.detail then GameTooltip:AddLine(this.detail,0.94,0.91,0.82,true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    schedules[i]=row
    return row
end
-- Encounter group: every living, active boss, elite or rare that is demonstrably in a fight.
-- Evidence (UnitAffectingCombat is deliberately not used: the former gate on it never opened in the
-- game, and the game does not document it for this mode): the unit is the current target, or its health is below maximum,
-- or the schedule marks its boss as "up". AZS_UNITS lists final/boss/guardian/elite only; a rare is
-- known solely through UnitClassification of the target. Elites and rares are not in AZS_SCHEDULE.
local engaged={}
local KIND_ORDER={final=1,boss=2,guardian=3,elite=4,rare=5}
local function Flag(v) return v and v~=0 end
local function TargetEntry()
    if type(UnitExists)~="function" or not UnitExists("target") then return nil,nil,"kein Ziel" end
    if UnitIsPlayer and Flag(UnitIsPlayer("target")) then return nil,nil,"Ziel ist Spieler" end
    if UnitCanAttack and not Flag(UnitCanAttack("player","target")) then return nil,nil,"Ziel nicht angreifbar" end
    local name=UnitName("target")
    local t=type(AZS_TARGET)=="table" and AZS_TARGET or {}
    local same=t.name==name
    local key=(same and K.Number(t.id)) and ("id"..t.id) or ("t:"..tostring(name))
    if UnitIsDead and Flag(UnitIsDead("target")) then return nil,nil,"Ziel tot",key end
    if same and t.kind=="dead" then return nil,nil,"Ziel tot",key end
    local kind=same and t.kind or nil
    local class=UnitClassification and UnitClassification("target")
    if kind~="final" and kind~="boss" and kind~="guardian" and kind~="elite" then
        if class=="rare" or class=="rareelite" then kind="rare"
        elseif class=="elite" then kind="elite"
        elseif class=="worldboss" then kind="boss"
        else return nil,nil,"normaler Gegner (Art "..tostring(kind)..", Klasse "..tostring(class)..")" end
    end
    local hp,hpm=UnitHealth("target"),UnitHealthMax("target")
    -- Other units report health as percent (maximum 100): prefer the exact values of AZS_TARGET.
    if (not K.Number(hpm) or hpm<=100) and same and K.Number(t.hp) and K.Number(t.hpm) and t.hpm>0 then hp,hpm=t.hp,t.hpm end
    return key,{name=name or "?",kind=kind,hp=hp,hpm=hpm,class=class},"Ziel"
end
-- diag (optional) collects one line per unit for /kui bosses debug.
local function EngagedList(diag)
    local now=GetTime()
    local up={}
    for _,s in ipairs(K.Schedule()) do if s.state=="up" and s.name then up[s.name]=true end end
    local listed={}
    for _,u in ipairs(AZS_UNITS or {}) do
        local kind=u.kind
        local active=kind=="final" or kind=="boss" or kind=="elite" or (kind=="guardian" and u.state==1)
        local numbers=K.Number(u.id) and K.Number(u.hp) and K.Number(u.hpm) and u.hpm>0
        local why
        if not active then why="nicht aktiv (Art "..tostring(kind)..", Status "..tostring(u.state)..")"
        elseif not numbers then why="keine gültigen Zahlen"
        elseif u.hp<=0 then why="tot"
        else
            local key="id"..u.id
            listed[key]=true
            local reason
            if u.hp<u.hpm then reason="Leben unter Maximum" elseif up[u.name] then reason="Boss laut Zeitplan up" end
            local e=engaged[key]
            if reason then
                if not e then e={}; engaged[key]=e end
                e.seen=now
            end
            if e then e.name,e.kind,e.hp,e.hpm,e.listed=u.name or "?",kind,u.hp,u.hpm,true end
            why=reason and ("ANZEIGE: "..reason) or (e and "Nachlauf" or "kein Kampfnachweis (volles Leben, nicht Ziel)")
        end
        if diag then
            table.insert(diag,string.format("%s [%s] id %s hp %s/%s Status %s: %s",tostring(u.name),tostring(kind),
                tostring(u.id),tostring(u.hp),tostring(u.hpm),tostring(u.state),why))
        end
    end
    local key,entry,tnote,deadKey=TargetEntry()
    -- AZS_TARGET may arrive after the target changed: the name key and the id key are one enemy.
    local tname=UnitExists and UnitExists("target") and UnitName("target")
    if tname then engaged["t:"..tostring(tname)]=nil end
    if deadKey then engaged[deadKey]=nil end
    if key then
        local e=engaged[key]
        if not e then e={}; engaged[key]=e end
        e.name,e.kind,e.seen=entry.name,entry.kind,now
        if K.Number(entry.hp) and K.Number(entry.hpm) and entry.hpm>0 then e.hp,e.hpm=entry.hp,entry.hpm end
        if listed[key] then e.listed=true end
    end
    if diag then
        table.insert(diag,"Ziel: "..tostring(UnitExists and UnitExists("target") and UnitName("target") or nil).." -> "
            ..(key and ("ANZEIGE als "..entry.kind.." (Klasse "..tostring(entry.class)..", hp "..tostring(entry.hp).."/"..tostring(entry.hpm)..")") or tostring(tnote)))
    end
    local list={}
    for k,e in pairs(engaged) do
        if (e.listed and not listed[k]) or (e.listed and now-e.seen>3) or (not e.listed and now-e.seen>5) then engaged[k]=nil
        elseif K.Number(e.hp) and K.Number(e.hpm) and e.hpm>0 then table.insert(list,{key=k,name=e.name,kind=e.kind,hp=e.hp,hpm=e.hpm}) end
    end
    table.sort(list,function(a,b)
        local ra,rb=KIND_ORDER[a.kind] or 9,KIND_ORDER[b.kind] or 9
        if ra~=rb then return ra<rb end
        if a.name~=b.name then return a.name<b.name end
        return a.key<b.key
    end)
    return list
end
-- /kui bosses debug: what the game hands out and why each unit is or is not shown.
function K.BossDebug()
    local diag={}
    local list=EngagedList(diag)
    local pc,tc
    if type(UnitAffectingCombat)=="function" then pc,tc=UnitAffectingCombat("player"),UnitExists and UnitExists("target") and UnitAffectingCombat("target") or nil
    else pc="fehlt" end
    local t=type(AZS_TARGET)=="table" and AZS_TARGET or {}
    K.Say(string.format("Begegnungen: AZS_UNITS %d, AZS_SCHEDULE %d, angezeigt %d, Phase %s, UnitAffectingCombat Spieler %s Ziel %s (nur Info)",
        table.getn(AZS_UNITS or {}),table.getn(K.Schedule()),table.getn(list),tostring(AZS_GetPhase and AZS_GetPhase()),tostring(pc),tostring(tc)))
    K.Say(string.format("AZS_TARGET: Art %s, Name %s, id %s, hp %s/%s, Status %s, Elite %s",tostring(t.kind),tostring(t.name),tostring(t.id),
        tostring(t.hp),tostring(t.hpm),tostring(t.state),tostring(t.elite)))
    for _,s in ipairs(K.Schedule()) do K.Say("Zeitplan: "..tostring(s.name).." "..tostring(s.state)) end
    for _,line in ipairs(diag) do K.Say(line) end
end
local function DrawBosses(phase)
    local replace=Active(phase) and not K.DB().hidden.bosses
    -- Our group replaces the native boss bars as long as it is switched on, data or not; it is merely empty outside fights.
    K.Native("bosses",not K.DB().hidden.bosses)
    local list=replace and EngagedList() or {}
    if table.getn(list)==0 then bosses:Hide(); return end
    -- Native banners sit at about 38% of the screen height from the top: stay above 30%.
    local ratio=bosses:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local available=(UIParent:GetHeight()*0.30-14)/ratio
    local visible=math.min(table.getn(list),12,math.max(1,math.floor((available-20)/14)))
    local height=math.min(25,math.max(12,math.floor((available-20)/visible)-2))
    bossOffset=math.min(bossOffset,math.max(0,table.getn(list)-visible))
    for i=1,visible do
        local v=list[i+bossOffset]
        if not bossRows[i] then bossRows[i]=K.Row(bosses,i,height) end
        local row=bossRows[i]
        row:SetHeight(height)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",bosses,"TOPLEFT",10,-10-(i-1)*(height+2))
        row.label:SetText(v.name); row.value:SetText(string.format("%.0f%%",100*v.hp/v.hpm))
        row.bar:SetValue(math.min(1,v.hp/v.hpm)); row.bar:SetStatusBarColor(0.62,0.08,0.08,0.85)
        row.tip=v.name; row.detail=K.Short(v.hp).." / "..K.Short(v.hpm)
        row:Show()
    end
    for i=visible+1,table.getn(bossRows) do bossRows[i]:Hide() end
    bosses:SetHeight(20+visible*(height+2)); bosses:Show()
end
local function Update()
    local r=AZS_RUN
    local phase=AZS_GetPhase and AZS_GetPhase()
    local seconds=AZS_GetRunTime and AZS_GetRunTime()
    local duration=AZS_GetRunLength and AZS_GetRunLength()
    if not K.Number(duration) or duration<=0 then duration=type(r)=="table" and r.fin end
    local good=type(r)=="table" and phase and K.Number(seconds) and K.Number(duration) and duration>0
    if good and not K.DB().hidden.tracker then
        zone:SetText((AZS_ZONE and AZS_ZONE.zname) or (GetRealZoneText and GetRealZoneText()) or "Azeroth Survivors")
        time:SetText(K.Clock(seconds).." / "..K.Clock(duration))
        progress:SetValue(math.min(1,seconds/duration))
        local schedule=K.Schedule()
        local count=math.min(8,table.getn(schedule))
        for i=1,count do
            local v=schedule[i]; local row=ScheduleRow(i)
            row.name:SetText(v.name or "?")
            row.bossName=v.name
            local timing=K.BossTimes.Get(v)
            if v.state=="dead" then
                row.boss:SetText(K.Clock(timing and timing.duration))
                row.run:SetText(K.Clock(timing and timing.killedAt))
                row.name:SetTextColor(0.48,0.7,0.43)
                row.boss:SetTextColor(0.48,0.7,0.43); row.run:SetTextColor(0.48,0.7,0.43)
                if timing and K.Number(timing.duration) then
                    row.detail=K.T("Runzeit beim Sieg: %s\nBosszeit: %s\nErschienen bei: %s\nAktive Runzeit ohne Pausen. Erfasst beim Zustandswechsel des Spiels.",K.Clock(timing.killedAt),K.Clock(timing.duration),K.Clock(v.at))
                else row.detail=K.T("Bereits besiegt. Der Todeszeitpunkt wurde nicht erfasst.\nDie Spielschnittstelle liefert keine vergangenen Todeszeitpunkte.") end
            elseif v.state=="up" then
                local elapsed=K.Number(v.at) and math.max(0,seconds-v.at) or nil
                row.boss:SetText(K.Clock(elapsed)); row.run:SetText(K.Clock(seconds)); row.name:SetTextColor(1,0.5,0.25)
                row.boss:SetTextColor(1,0.75,0.4); row.run:SetTextColor(1,0.75,0.4)
                row.detail=K.T("Seit Erscheinen: %s\nErschienen bei: %s\nPausen und Kartenwahl zählen nicht mit.",K.Clock(elapsed),K.Clock(v.at))
            else
                row.boss:SetText(K.Number(v.at) and (K.T("in").." "..K.Clock(math.max(0,v.at-seconds))) or "?")
                row.run:SetText(K.Clock(v.at))
                row.name:SetTextColor(0.85,0.82,0.75)
                row.boss:SetTextColor(0.85,0.82,0.75); row.run:SetTextColor(0.85,0.82,0.75)
                row.detail=K.T("Erscheint bei: %s Runzeit.",K.Clock(v.at))
            end
            row:Show()
        end
        for i=count+1,table.getn(schedules) do schedules[i]:Hide() end
        -- Level and experience live in the run statistics; the tracker keeps time, zone and bosses.
        tracker:SetHeight(136+count*18)
        level:SetText("")
        tracker:Show(); K.Native("clock",true)
    else
        K.Native("clock",not K.DB().hidden.tracker)
        if K.DB().hidden.tracker then tracker:Hide()
        else
            zone:SetText((GetRealZoneText and GetRealZoneText()) or "Azeroth Survivors")
            time:SetText(K.Clock(seconds).." / "..K.Clock(duration)); progress:SetValue(0)
            level:SetText(K.T("Warte auf Spieldaten")); tracker:SetHeight(154); tracker:Show()
            for _,row in ipairs(schedules) do row:Hide() end
        end
    end
    DrawBosses(phase)
    local tallyGood=Active(phase) and type(r)=="table" and K.Number(r.kills) and K.Number(r.gold) and K.Number(r.chest)
    if tallyGood and not K.DB().hidden.tally then
        tallyValues[1]:SetText(K.Short(r.kills)); tallyValues[2]:SetText(K.Short(r.gold)); tallyValues[3]:SetText(K.Short(r.chest))
        local wait="?"
        if r.gold>=r.chest then wait=K.T("Bereit")
        elseif K.Number(seconds) and seconds>0 and K.Number(r.ge) and r.ge>0 then wait="~"..K.Clock((r.chest-r.gold)/(r.ge/seconds)) end
        tallyValues[4]:SetText(K.Number(r.ck) and K.T("geöffnet %s",K.Short(r.ck)) or K.T("geöffnet ?"))
        tallyValues[5]:SetText(wait); tallyValues[5]:SetTextColor(r.gold>=r.chest and 0.45 or 1,0.82,0.28)
        for i,key in ipairs({"kills","gold","chest"}) do tallyCells[i].tip=string.format("%.0f",r[key]) end
        tallyCells[1].detail=K.T("Besiegte Gegner in diesem Run")
        tallyCells[2].detail=K.T("Aktueller Goldbestand")
        tallyCells[3].detail=K.T("Preis des nächsten Caches")
        tallyCells[4].tip=K.Number(r.ck) and string.format("%.0f",r.ck) or "?"
        tallyCells[4].detail=K.T("Geöffnete Caches in diesem Run")
        tallyCells[5].tip=wait
        tallyCells[5].detail=K.T("Geschätzte Zeit, bis der nächste Cache bezahlbar ist. Grundlage: Goldverdienst geteilt durch aktive Runzeit. Kein Timer für das Erscheinen einer Kiste.")
        tally:Show(); K.Native("tally",true)
    else
        K.Native("tally",not K.DB().hidden.tally)
        if K.DB().hidden.tally then tally:Hide() else for _,value in ipairs(tallyValues) do value:SetText("?") end; tally:Show() end
    end
    if Active(phase) and type(r)=="table" and K.Number(r.xp) and K.Number(r.xpn) and r.xpn>0 and not K.DB().hidden.xp then
        xp:SetValue(math.min(1,r.xp/r.xpn)); xp:Show()
    else xp:SetValue(0); if K.DB().hidden.xp then xp:Hide() else xp:Show() end end
end
table.insert(K.updates,Update)
local function MoveStock()
    -- The minimap (layout key "minimap") is registered in Minimap.lua.
    -- Automatic spells are represented by the single build bar. The chat window lives in Chat.lua.
    if MainMenuBar then MainMenuBar:SetAlpha(0); MainMenuBar:EnableMouse(false); MainMenuBar:Hide() end
    if MainMenuExpBar then MainMenuExpBar:Hide() end
    if KeijinBuildBarFrame then
        K.layout.Register("build",KeijinBuildBarFrame,"Zauber, Schmuck und Buildtipps",function(f)
            f:ClearAllPoints(); f:SetPoint("BOTTOM",UIParent,"BOTTOM",0,42)
        end)
    end
    if KeijinAchievementsFrame then
        K.layout.Register("achievements",KeijinAchievementsFrame,"Erfolgsmeldung",function(f)
            f:ClearAllPoints(); f:SetPoint("BOTTOM",UIParent,"BOTTOM",0,200)
        end,{hidden=true})
    end
end
K.On("PLAYER_ENTERING_WORLD",function()
    MoveStock()
    for key in pairs(K.layout.entries) do K.layout.Place(key) end
    Update()
end)
table.insert(K.updates,MoveStock)
MoveStock()
Update()
