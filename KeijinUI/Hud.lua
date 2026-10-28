local K = KeijinUI
local P=K.panelSizing
local H={ready=false,refresh={}}
K.basisHud=H
function H.On() return K.ModuleOn("basisHud") end
-- Native takeover starts only after saved variables arrive. Geometry may initialize earlier.
function H.Native(part,replace) if H.ready then K.Native(part,replace) end end
function H.NativeFollow(part,replace) if H.ready then K.NativeFollow(part,replace) end end
local function Inactive() return not H.On() end
local tracker=K.Panel("KeijinUITracker","Runübersicht",K.PANEL_WIDTH,220)
-- Default: right below the minimap (its size follows the minimap style), else the old absolute place.
K.layout.Register("tracker",tracker,"Runübersicht",function(f)
    f:ClearAllPoints()
    if MinimapCluster then f:SetPoint("TOPRIGHT",MinimapCluster,"BOTTOMRIGHT",-12,-10)
    else f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-24,-220) end
end,{inactive=Inactive})
tracker:Hide()
local zone=K.Text(tracker,"",12,"TOPLEFT",14,-35,270)
zone:SetTextColor(1,0.82,0.28)
local time=K.Text(tracker,"",22,"TOPLEFT",14,-55)
local progress=CreateFrame("StatusBar",nil,tracker)
progress:SetPoint("TOPLEFT",tracker,"TOPLEFT",14,-85); progress:SetWidth(272); progress:SetHeight(12)
progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); progress:SetStatusBarColor(0.24,0.56,0.83)
progress:SetMinMaxValues(0,1)
progress:SetBackdrop({bgFile=K.flat}); progress:SetBackdropColor(0.02,0.02,0.025,1)
local progressFace=K.PixelProgress(progress)
-- Checkpoints: one thin mark per scheduled boss at its spawn time (schedule "at" over run length),
-- colored like its row (due light, up orange, dead green). A layer above the bar keeps them visible.
-- Marks and their outlines use integer display pixels, with equal top/bottom gaps. A boss at the full run length
-- (the final boss) gets no mark: the end of the bar is its time, and a mark there covers the border.
local markLayer=CreateFrame("Frame",nil,progressFace)
markLayer:SetAllPoints(progressFace); markLayer:SetFrameLevel(progressFace:GetFrameLevel()+1)
local marks={}
local MARK_COLORS={dead={0.5,1,0.55},up={1,0.5,0.25}}
local function DrawMarks(schedule,count,duration)
    progressFace:Paint()
    local scale=progressFace.pixelsPerUnit or 1
    local width,height=progressFace:GetWidth(),progressFace:GetHeight()
    local markWidth=math.max(1,math.floor(3*scale+0.5))
    local pad=math.max(progressFace.stroke+2,math.floor(2*scale+0.5))
    local markHeight=math.max(1,height-2*pad)
    local margin=progressFace.cut+2
    local shown=0
    for i=1,count do
        local v=schedule[i]
        if K.Number(v.at) and v.at>0 and v.at<duration then
            shown=shown+1
            local mark=marks[shown]
            if not mark then
                mark=markLayer:CreateTexture(nil,"OVERLAY")
                mark:SetTexture(K.flat); mark:SetWidth(3); mark:SetHeight(8)
                mark.outline=markLayer:CreateTexture(nil,"ARTWORK")
                mark.outline:SetTexture(K.flat); mark.outline:SetVertexColor(0.01,0.01,0.015,1)
                mark.outline:SetWidth(5); mark.outline:SetHeight(10)
                marks[shown]=mark
            end
            local x=math.floor(math.min(width-margin-markWidth,math.max(margin,width*v.at/duration-markWidth/2))+0.5)
            mark:SetWidth(markWidth); mark:SetHeight(markHeight)
            mark:ClearAllPoints(); mark:SetPoint("TOPLEFT",progressFace,"TOPLEFT",x,-pad)
            local c=MARK_COLORS[v.state] or {0.85,0.82,0.75}
            mark.outline:ClearAllPoints(); mark.outline:SetPoint("TOPLEFT",mark,"TOPLEFT",-1,1)
            mark.outline:SetWidth(markWidth+2); mark.outline:SetHeight(markHeight+2); mark.outline:Show()
            mark:SetVertexColor(c[1],c[2],c[3],1)
            mark:Show()
        end
    end
    for i=shown+1,table.getn(marks) do marks[i]:Hide(); marks[i].outline:Hide() end
end
K.HeaderPoint(zone,tracker,"TOPLEFT",14,-35)
K.HeaderPoint(time,tracker,"TOPLEFT",14,-55)
K.HeaderPoint(progress,tracker,"TOPLEFT",14,-85)
local schedules={}
local scheduleRun
local scheduleScroll=CreateFrame("Frame",nil,tracker)
scheduleScroll:EnableMouse(true); scheduleScroll:EnableMouseWheel(true)
scheduleScroll:SetScript("OnMouseWheel",function() P.Scroll("tracker",arg1) end)
scheduleScroll:Hide()
local paceRow=CreateFrame("Frame",nil,tracker)
paceRow:SetWidth(272); paceRow:SetHeight(16); paceRow:EnableMouse(true)
paceRow.text=K.Text(paceRow,"",11,"LEFT",0,0,272)
paceRow:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText(K.T("Pace-Indikator"),1,.82,.28)
    if not this.account then GameTooltip:AddLine(K.T("Vergleicht dieselbe Klasse, Zone, Schwierigkeit und Modifikatoren zur gleichen Spielzeit. Grün ab 90%, Gelb ab 70%, sonst Rot."),.94,.91,.82,true) end
    local d=K.pace.Details(this.account)
    if this.account then GameTooltip:AddLine(K.T("Alle lokal gespeicherten Klassen, gleiche Zone, Schwierigkeit und Modifikatoren."),.94,.91,.82,true) end
    if d.ratio then
        GameTooltip:AddLine(K.T("Gegner: %s / %s · %s%%",K.Short(d.kills),K.Short(d.refKills),math.floor(d.killRatio*100+.5)),.94,.91,.82)
        if d.dpsRatio then
            GameTooltip:AddLine(K.T("DPS (30 s): %s / %s · %s%%",K.Short(d.dps),K.Short(d.refDps),math.floor(d.dpsRatio*100+.5)),.94,.91,.82)
            GameTooltip:AddLine(K.T("70%% Gegnerfortschritt + 30%% DPS. DPS Beitrag bei 150%% begrenzt. Vergleich: Median aus %s Runden.",d.refs),.7,.7,.67,true)
        else
            GameTooltip:AddLine(K.T("Nur Gegnerdaten: Für den DPS Vergleich fehlen passende 30 Sekunden Schadensverlauf."),.7,.7,.67,true)
        end
    else GameTooltip:AddLine(K.T(d.status),.7,.7,.67) end
    GameTooltip:Show()
end)
paceRow:SetScript("OnLeave",function() GameTooltip:Hide() end)
local accountRow=CreateFrame("Frame",nil,tracker)
accountRow:SetWidth(272); accountRow:SetHeight(16); accountRow:EnableMouse(true); accountRow.account=true
accountRow.text=K.Text(accountRow,"",11,"LEFT",0,0,272)
accountRow:SetScript("OnEnter",paceRow:GetScript("OnEnter"))
accountRow:SetScript("OnLeave",paceRow:GetScript("OnLeave"))
local paceExtra=0
local function TrackerPoint(child,point,x,y)
    if tracker.headerPoints[child] then tracker.headerPoints[child][3]=y end
    K.HeaderPoint(child,tracker,point,x,y)
end
local headBoss=K.LText(tracker,"Boss",9,"TOPLEFT",14,-105,130); headBoss:SetTextColor(0.65,0.63,0.58)
K.HeaderPoint(headBoss,tracker,"TOPLEFT",14,-105)
local head84=K.LText(tracker,"Bosszeit",9,"TOPRIGHT",-84,-105); head84:SetTextColor(0.65,0.63,0.58)
K.HeaderPoint(head84,tracker,"TOPRIGHT",-84,-105)
local head14=K.LText(tracker,"Runzeit",9,"TOPRIGHT",-14,-105); head14:SetTextColor(0.65,0.63,0.58)
K.HeaderPoint(head14,tracker,"TOPRIGHT",-14,-105)
local bosses=K.Panel("KeijinUIBosses","Begegnungen",K.PANEL_WIDTH,40)
bosses.title:Hide(); bosses.strip:Hide()
K.layout.Register("bosses",bosses,"Begegnungen",function(f) f:ClearAllPoints(); f:SetPoint("TOP",UIParent,"TOP",0,-14) end,{hidden=true,inactive=Inactive})
bosses:Hide()
local bossRows={}
local bossOffset=0
bosses:EnableMouseWheel(true)
bosses:SetScript("OnMouseWheel",function() bossOffset=math.max(0,bossOffset+(arg1>0 and -1 or 1)) end)
local tally=K.Panel("KeijinUITally","",400,34)
tally:Hide()
tally.title:Hide()
local T={frame=tally}
K.tally=T
-- Bottom anchors let the optional second row grow away from the build bar.
-- Convert the previous 34-point panel's top coordinates once.
local function MigrateTally()
    local db=K.DB()
    if db.tallyBottomAnchor then return end
    local function Convert(layout)
        local p=type(layout)=="table" and layout.tally
        if type(p)=="table" and K.Number(p.y) and K.Number(p.scale) and p.scale>0 then
            p.y=p.y-34*math.max(.5,math.min(1.8,p.scale))/K.UIHeight()
        end
    end
    Convert(db.layout)
    db.tallyBottomAnchor=true
end
MigrateTally()
K.layout.Register("tally",tally,"Kills, Gold, Cache",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOM",KeijinBuildBarFrame or UIParent,KeijinBuildBarFrame and "TOP" or "BOTTOM",0,KeijinBuildBarFrame and 6 or 102) end,{inactive=Inactive,grow=function() return true end})
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then MigrateTally(); K.layout.Place("tally") end end)
local tallyValues={}
local tallyIcons={
    "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
    "Interface\\MoneyFrame\\UI-MoneyIcons",
    "Interface\\Icons\\INV_Box_01"
}
local tallyCells={}
-- Five cells in 388 pixels: three symbol cells, "geöffnet" and the wait time (wider, it shows "~12:34").
local tallyWidths={74,74,74,74,92}
local CACHE_NEAR=0.25 -- share of the cache price below which missing gold counts as "little"
local tallyLeft=6
for i,label in ipairs({"Kills","Gold","Cache","Geöffnet","Bezahlbar"}) do
    local name=label   -- body local for the tooltip closure (see Statistics.lua)
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
        GameTooltip:SetOwner(this,"ANCHOR_TOP"); GameTooltip:SetText(this.tip or K.T(name),1,0.82,0.28)
        if this.detail then GameTooltip:AddLine(this.detail,0.9,0.88,0.8,true) end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave",function() GameTooltip:Hide() end)
    tallyCells[i]=cell
end
local extras=CreateFrame("Frame","KeijinUITallyExtras",tally)
extras:SetWidth(388); extras:SetHeight(24); extras:SetPoint("TOPLEFT",tally,"TOPLEFT",6,-33); extras:Hide()
T.extras=extras; T.cells={}
local divider=extras:CreateTexture(nil,"BACKGROUND")
divider:SetTexture(K.flat); divider:SetVertexColor(.62,.57,.43,.28)
divider:SetPoint("TOPLEFT",extras,"TOPLEFT",3,0); divider:SetPoint("TOPRIGHT",extras,"TOPRIGHT",-3,0); divider:SetHeight(1)
for i,def in ipairs({
    {key="lives",label="Zusatzleben",icon="Interface\\Icons\\Spell_Holy_Resurrection"},
    {key="rr",label="Rerolls",icon="Interface\\Buttons\\UI-RotationRight-Button-Up"}
}) do
    local cell=CreateFrame("Frame",nil,extras)
    cell:SetWidth(194); cell:SetHeight(24); cell:SetPoint("TOPLEFT",extras,"TOPLEFT",(i-1)*194,0)
    cell.key=def.key
    local title=def.label   -- body local for the tooltip closure
    cell.icon=cell:CreateTexture(nil,"ARTWORK"); cell.icon:SetTexture(def.icon)
    cell.icon:SetWidth(16); cell.icon:SetHeight(16); cell.icon:SetPoint("LEFT",cell,"LEFT",5,0)
    cell.label=K.LText(cell,def.label,10,"LEFT",29,0,110)
    cell.value=K.Text(cell,"",11,"RIGHT",-8,0,def.key=="rr" and 80 or 40); cell.value:SetJustifyH("RIGHT")
    if def.key=="rr" then cell.label:SetWidth(70) end
    cell:EnableMouse(true)
    cell:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_TOP"); GameTooltip:SetText(K.T(title),1,.82,.28)
        if this.detail then GameTooltip:AddLine(this.detail,.9,.88,.8,true) end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave",function() GameTooltip:Hide() end)
    T.cells[i]=cell
end
function T.UpdateExtras()
    local phase=AZS_GetPhase and AZS_GetPhase()
    local active=phase=="playing" or phase=="paused" or phase=="choosing"
    local enabled=K.DB().runResources==true and K.ModuleOn("analysis") and not K.DB().hidden.tally
        and active and K.Fresh(AZS_RUN_UPDATED) and type(AZS_RUN)=="table"
    local count=0
    for _,cell in ipairs(T.cells) do
        local value=enabled and AZS_RUN[cell.key]
        if K.Number(value) then
            cell.value:SetText(string.format("%.0f",value))
            cell.detail=K.T(cell.key=="lives" and "Verbleibende Zusatzleben in diesem Run." or "Verbleibende freie Rerolls in diesem Run.")
            if cell.key=="rr" then
                local price=AZS_RUN.rrc
                if value==0 then
                    cell.value:SetText(K.Number(price) and (K.Short(price).." G") or "?")
                    cell.detail=K.T("Keine freien Rerolls mehr.")
                end
                if K.Number(price) then
                    cell.detail=cell.detail.."\n"..K.T("Preis eines weiteren Rerolls: %s Gold",string.format("%.0f",price))
                elseif value==0 then cell.detail=cell.detail.."\n"..K.T("Preis des nächsten Rerolls noch unbekannt.") end
            end
            cell:ClearAllPoints(); cell:SetPoint("TOPLEFT",extras,"TOPLEFT",count*194,0)
            cell:Show(); count=count+1
        else
            if GameTooltip.GetOwner and GameTooltip:GetOwner()==cell then GameTooltip:Hide() end
            cell.value:SetText(""); cell.detail=nil; cell:Hide()
        end
    end
    local height=count>0 and 58 or 34
    if tally:GetHeight()~=height then tally:SetHeight(height) end
    if count>0 then extras:Show() else extras:Hide() end
end
local xp=K.Panel("KeijinUIXP","",400,28)
xp.title:Hide(); xp.strip:Hide()
local xpBar=CreateFrame("StatusBar",nil,xp)
xpBar:SetWidth(386); xpBar:SetHeight(16); xpBar:SetPoint("CENTER",xp,"CENTER",0,0)
xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar:SetStatusBarColor(.48,.30,.66); xpBar:SetMinMaxValues(0,1)
K.MetalBar(xpBar,xpBar)
local rateHost=CreateFrame("Frame",nil,xpBar)
rateHost:SetAllPoints(xpBar)
local xpRate=K.Text(rateHost,"",10,"CENTER",0,0,378)
xpRate:SetHeight(14); xpRate:SetJustifyH("CENTER"); xpRate:SetJustifyV("MIDDLE"); xpRate:Hide()
K.xpDisplay={frame=xp,bar=xpBar,rateLabel=xpRate}
-- Keep the panel below the default build bar; saved custom positions retain their top anchor.
K.layout.Register("xp",xp,"Erfahrung",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOM",UIParent,"BOTTOM",0,8) end,{inactive=Inactive})
xp:Hide()
local guardianContent=CreateFrame("Frame",nil,tracker)
guardianContent:SetAllPoints(tracker)
local level=K.Text(tracker,"",10,"BOTTOMLEFT",14,9,272)
local function Active(phase) return phase=="ready" or phase=="playing" or phase=="paused" or phase=="choosing" end
local function ScheduleRow(i)
    if schedules[i] then return schedules[i] end
    local row=CreateFrame("Frame",nil,tracker)
    row:SetWidth(272); row:SetHeight(17); K.HeaderPoint(row,tracker,"TOPLEFT",14,-123-(i-1)*18-paceExtra)
    row.tint=row:CreateTexture(nil,"BACKGROUND"); row.tint:SetTexture(K.flat)
    row.tint:SetAllPoints(row); row.tint:Hide()
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
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel",function() P.Scroll("tracker",arg1) end)
    schedules[i]=row
    return row
end
-- Encounter group: every living, active boss, elite or rare that is demonstrably in a fight.
-- Evidence (UnitAffectingCombat is deliberately not used: the former gate on it never opened in the
-- game, and the game does not document it for this mode): the unit is the current target, or its health is below maximum,
-- or the schedule marks its boss as "up". AZS_UNITS lists final/boss/guardian/elite only; a rare is
-- known solely through UnitClassification of the target. Elites and rares are not in AZS_SCHEDULE.
local engaged={}
local engagedRunStart
local KIND_ORDER={final=1,boss=2,guardian=3,elite=4,rare=5}
local function Flag(v) return v and v~=0 end
local function TargetEntry()
    if type(UnitExists)~="function" or not UnitExists("target") then return nil,nil,"kein Ziel" end
    if UnitIsPlayer and Flag(UnitIsPlayer("target")) then return nil,nil,"Ziel ist Spieler" end
    if UnitCanAttack and not Flag(UnitCanAttack("player","target")) then return nil,nil,"Ziel nicht angreifbar" end
    local name=UnitName("target")
    local t=type(AZS_TARGET)=="table" and AZS_TARGET or {}
    local same=t.name==name and K.Fresh(AZS_TARGET_UPDATED)
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
    local id=same and K.Number(t.id) and t.id or nil
    return key,{id=id,name=name or "?",kind=kind,hp=hp,hpm=hpm,class=class},"Ziel"
end
-- diag (optional) collects one line per unit for /kui bosses debug.
local function EngagedList(diag)
    if engagedRunStart~=K.runStart then engaged={}; bossOffset=0; engagedRunStart=K.runStart end
    local now=GetTime()
    local up={}
    for _,s in ipairs(K.Schedule()) do if s.state=="up" and s.name then up[s.name]=true end end
    local listed={}
    for _,u in ipairs(K.Fresh(AZS_UNITS_UPDATED) and AZS_UNITS or {}) do
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
            if e then e.id,e.name,e.kind,e.hp,e.hpm,e.listed=u.id,u.name or "?",kind,u.hp,u.hpm,true end
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
        e.id,e.name,e.kind,e.seen=entry.id,entry.name,entry.kind,now
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
        elseif K.Number(e.hp) and K.Number(e.hpm) and e.hpm>0 then table.insert(list,{id=e.id,key=k,name=e.name,kind=e.kind,hp=e.hp,hpm=e.hpm}) end
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
    H.NativeFollow("bosses",not K.DB().hidden.bosses)
    local list=replace and EngagedList() or {}
    if table.getn(list)==0 then
        for _,row in ipairs(bossRows) do K.encounterDebuffs.Clear(row); row:Hide() end
        bosses:Hide(); return
    end
    -- Native banners sit at about 38% of the screen height from the top: stay above 30%.
    local ratio=bosses:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local available=(K.UIHeight()*0.30-14)/ratio
    local limit=math.min(table.getn(list),12,math.max(1,math.floor((available-20)/14)))
    for _,v in ipairs(list) do
        v.debuffs=K.encounterDebuffs.Read(v.id,v.kind)
        v.extra=table.getn(v.debuffs)>0 and K.encounterDebuffs.height or 0
    end
    -- Work out the last full page as well, so scrolling can reach every enemy with effects.
    local lastCount,lastExtra=0,0
    for i=table.getn(list),math.max(1,table.getn(list)-limit+1),-1 do
        local addition=list[i].extra
        if lastCount>0 and 20+(lastCount+1)*14+lastExtra+addition>available then break end
        lastCount=lastCount+1; lastExtra=lastExtra+addition
    end
    bossOffset=math.min(bossOffset,math.max(0,table.getn(list)-lastCount))
    local visible,extra=0,0
    for i=1,math.min(limit,table.getn(list)-bossOffset) do
        local v=list[i+bossOffset]
        if visible>0 and 20+(visible+1)*14+extra+v.extra>available then break end
        visible=visible+1; extra=extra+v.extra
    end
    -- Fewer visible rows, rather than effects extending into the native banner area.
    local height=math.min(25,math.max(12,math.floor((available-20-extra)/visible)-2))
    local top=10
    for i=1,visible do
        local v=list[i+bossOffset]
        if not bossRows[i] then bossRows[i]=K.Row(bosses,i,height) end
        local row=bossRows[i]
        row:SetHeight(height)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",bosses,"TOPLEFT",10,-top)
        row.spawnId=v.id
        row.label:SetText(v.name); row.value:SetText(string.format("%.0f%%",100*v.hp/v.hpm))
        row.bar:SetValue(math.min(1,v.hp/v.hpm)); row.bar:SetStatusBarColor(0.62,0.08,0.08,0.85)
        row.tip=v.name; row.detail=K.Short(v.hp).." / "..K.Short(v.hpm)
        K.encounterDebuffs.Draw(row,v)
        row:Show(); top=top+height+2+v.extra
    end
    for i=visible+1,table.getn(bossRows) do K.encounterDebuffs.Clear(bossRows[i]); bossRows[i]:Hide() end
    bosses:SetHeight(top+10); bosses:Show()
end
local guardianPanel=K.Panel("KeijinUIGuardianOverview","Wächter",K.PANEL_WIDTH,60)
guardianPanel:Hide()
local analysisPanel=K.Panel("KeijinUIAnalysisOverview","Run-Analyse",400,88)
analysisPanel:Hide()
local function GuardianInactive() return not H.ready or H.On() or not K.guardians.On() end
local function AnalysisInactive() return not H.ready or H.On() or not K.ModuleOn("analysis") end
K.layout.Register("guardianOverview",guardianPanel,"Wächter",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-24,-220)
end,{inactive=GuardianInactive,hidden=true})
K.layout.Register("analysisOverview",analysisPanel,"Run-Analyse",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-36)
end,{inactive=AnalysisInactive,hidden=true})
local function Support()
    local on=H.On()
    if on and not H.supportDetached then return end
    H.supportDetached=not on
    if not on and GuardianInactive() and AnalysisInactive() then
        if not H.supportStopped then
            guardianPanel:Hide(); analysisPanel:Hide()
            for _,key in ipairs({"guardianOverview","analysisOverview"}) do
                local e=K.layout.entries[key]
                if e.handle then e.handle:Hide() end
            end
        end
        H.supportStopped=true
        return
    end
    H.supportStopped=false
    guardianContent:SetParent(on and tracker or guardianPanel)
    guardianContent:ClearAllPoints(); guardianContent:SetAllPoints(on and tracker or guardianPanel)
    if not GuardianInactive() then
        local height=K.guardians.Draw(guardianContent,-30)
        if height>0 then guardianPanel:SetHeight(40+height); guardianPanel:Show() else guardianPanel:Hide() end
    else guardianPanel:Hide() end
    -- The rate label remains the same object used by RunInsights.lua.
    -- Its frame host can move without changing the FontString API.
    rateHost:SetParent(on and xpBar or analysisPanel)
    rateHost:ClearAllPoints()
    if on then
        rateHost:SetAllPoints(xpBar)
        paceRow:SetParent(tracker); accountRow:SetParent(tracker)
        extras:SetParent(tally); extras:ClearAllPoints(); extras:SetPoint("TOPLEFT",tally,"TOPLEFT",6,-33)
    elseif not AnalysisInactive() then
        local height=30
        paceRow:SetParent(analysisPanel); accountRow:SetParent(analysisPanel)
        paceRow:ClearAllPoints(); paceRow:SetPoint("TOPLEFT",analysisPanel,"TOPLEFT",14,-height)
        if K.pace.On() then
            local d=K.pace.Details()
            paceRow.text:SetText(K.T("Pace: %s",K.T(d.status))..(d.ratio and (" · "..math.floor(d.ratio*100+.5).."%") or ""))
            paceRow.text:SetTextColor(K.pace.Color(d.status)); paceRow:Show(); height=height+18
        else paceRow:Hide() end
        accountRow:ClearAllPoints(); accountRow:SetPoint("TOPLEFT",analysisPanel,"TOPLEFT",14,-height)
        if K.pace.AccountOn() then
            local d=K.pace.Details(true)
            accountRow.text:SetText(K.T("Account Pace: %s",K.T(d.status))..(d.ratio and (" · "..math.floor(d.ratio*100+.5).."%") or ""))
            accountRow.text:SetTextColor(K.pace.Color(d.status)); accountRow:Show(); height=height+18
        else accountRow:Hide() end
        rateHost:SetWidth(272); rateHost:SetHeight(18); rateHost:SetPoint("TOPLEFT",analysisPanel,"TOPLEFT",14,-height)
        if K.DB().xpRate==true and not K.DB().hidden.xp then height=height+18 end
        extras:SetParent(analysisPanel); extras:ClearAllPoints(); extras:SetPoint("TOPLEFT",analysisPanel,"TOPLEFT",6,-height)
        T.UpdateExtras()
        if extras:IsShown() then height=height+24 end
        analysisPanel:SetHeight(height+10)
        if height>30 then analysisPanel:Show() else analysisPanel:Hide() end
    else analysisPanel:Hide() end
    if on then analysisPanel:Hide() end
    for _,key in ipairs({"guardianOverview","analysisOverview"}) do
        local e=K.layout.entries[key]
        if e.options.inactive() and e.handle then e.handle:Hide() end
    end
end
H.Support=Support
local function Release()
    tracker:Hide(); bosses:Hide(); tally:Hide(); xp:Hide()
    for _,key in ipairs({"tracker","bosses","tally","xp"}) do
        local e=K.layout.entries[key]
        if e and e.handle then e.handle:Hide() end
    end
    for _,row in ipairs(bossRows) do K.encounterDebuffs.Clear(row); row:Hide() end
    K.guardians.Hide()
    for _,part in ipairs({"clock","bosses","tally"}) do K.Native(part,false) end
end
local function Update()
    if Inactive() then Release(); return end
    local custom=P.Custom("tracker")
    if custom then P.Fonts("tracker") end
    local q,step,pad=1,18,0
    if custom then q,step,pad=P.Metrics("tracker",18) end
    -- At very small physical viewports use one-line list cells, retaining the
    -- selected font size and the existing full-name tooltips instead of shrinking
    -- forever. This leaves room for one boss and one independently paged lair.
    local compact=false
    if custom then
        local n=K.guardians.Count()
        local fixed=136+math.max(0,math.ceil(math.max(17,26*q)+math.max(27,25*q)-44))+pad
            +math.max(0,12*q-14)+(K.pace.On() and (K.pace.AccountOn() and 36 or 18)*math.max(1,q) or 0)
        local minimum=fixed+step+(n>0 and 9+math.max(16,16*q)+step or 0)-K.HeaderOffset(tracker)
        compact=minimum>P.AvailableHeight("tracker")
        if compact then
            local font=P.Config("tracker").font
            if font then
                -- Compact minimum: at most 136*q + 64 logical units, including
                -- rounding and one row per list. Solve once instead of converging
                -- through repeated Layout.Clamp / font compensation updates.
                local budget=(K.UIHeight()-16)*UIParent:GetEffectiveScale()
                local ceiling=(budget-136*font/11*(K.fontFactor or 1))/64
                local effective=tracker:GetEffectiveScale()
                if ceiling>0 and effective>ceiling then
                    tracker:SetScale(tracker:GetScale()*ceiling/effective)
                    P.Fonts("tracker")
                    q,step,pad=P.Metrics("tracker",18)
                end
            end
            step=math.max(18,math.ceil(18*q)); pad=math.max(0,math.ceil(18*q-18))
        end
    end
    local column=custom and math.max(64,68*q,P.Measure(head14,head14:GetText())+8,P.Measure(head84,head84:GetText())+8) or 64
    local width=custom and P.Width("tracker",math.max(220,250*q,2*column+28+80*q)) or K.PANEL_WIDTH
    tracker:SetWidth(width); tracker.title:SetWidth(width-26)
    local headExtra=custom and math.max(0,12*q-14) or 0
    headBoss:SetWidth(custom and width-40-2*column or 130); headBoss:SetHeight(math.max(14,12*q))
    if custom then
        head84:SetWidth(column); head14:SetWidth(column); tracker.sizingHeaders=true
    elseif tracker.sizingHeaders then
        head84:SetWidth(math.max(64,P.Measure(head84,head84:GetText())+16))
        head14:SetWidth(math.max(64,P.Measure(head14,head14:GetText())+16))
    end
    head84:SetHeight(math.max(14,12*q)); head84:SetJustifyH("RIGHT")
    head14:SetHeight(math.max(14,12*q)); head14:SetJustifyH("RIGHT")
    local zoneHeight=custom and math.max(17,26*q) or 17
    local timeHeight=math.max(27,25*q)
    local extra=custom and math.max(0,math.ceil(zoneHeight+timeHeight-44))+pad or 0
    tracker.title:SetHeight(math.max(17,15*q)); tracker.strip:SetHeight(math.max(23,18*q))
    zone:SetWidth(width-28); zone:SetHeight(zoneHeight)
    time:SetWidth(width-28); time:SetHeight(timeHeight)
    progress:SetWidth(width-28)
    TrackerPoint(zone,"TOPLEFT",14,-35-pad)
    TrackerPoint(time,"TOPLEFT",14,-38-pad-zoneHeight)
    paceRow:SetWidth(width-28); accountRow:SetWidth(width-28)
    paceRow:SetHeight(math.max(16,15*q)); accountRow:SetHeight(math.max(16,15*q))
    paceRow.text:SetWidth(width-28); accountRow.text:SetWidth(width-28)
    paceRow.text:SetHeight(math.max(16,15*q)); accountRow.text:SetHeight(math.max(16,15*q))
    paceExtra=K.pace.On() and (K.pace.AccountOn() and 36 or 18) or 0
    if custom then paceExtra=paceExtra*math.max(1,q) end
    TrackerPoint(progress,"TOPLEFT",14,-85-paceExtra-extra)
    TrackerPoint(headBoss,"TOPLEFT",14,-105-paceExtra-extra)
    TrackerPoint(head84,"TOPRIGHT",custom and -20-column or -84,-105-paceExtra-extra)
    TrackerPoint(head14,"TOPRIGHT",-14,-105-paceExtra-extra)
    TrackerPoint(paceRow,"TOPLEFT",14,-83-extra)
    TrackerPoint(accountRow,"TOPLEFT",14,-83-extra-math.max(18,18*q))
    local scheduleTop=123+paceExtra+extra+headExtra
    local trackerFixed=136+paceExtra+extra+headExtra
    if compact then
        -- Two columns retain the full clock and both pace tooltips. This removes
        -- vertical duplication without reducing the configured font size.
        local clockWidth=P.Measure(time,"99:59 / 99:59")+8
        width=P.Width("tracker",math.max(width,clockWidth+80*q+28))
        tracker:SetWidth(width); tracker.title:SetWidth(width-26)
        zone:SetWidth(math.max(30,width-36-clockWidth)); time:SetWidth(clockWidth)
        TrackerPoint(time,"TOPRIGHT",-14,-35-pad)
        local paceTop=35+pad+math.max(zoneHeight,timeHeight)+4
        local half=(width-36)/2
        paceRow:SetWidth(half); accountRow:SetWidth(half)
        paceRow.text:SetWidth(half); accountRow.text:SetWidth(half)
        TrackerPoint(paceRow,"TOPLEFT",14,-paceTop)
        TrackerPoint(accountRow,"TOPRIGHT",-14,-paceTop)
        local barTop=paceTop+(K.pace.On() and math.max(18,18*q) or 0)+4
        progress:SetWidth(width-28); TrackerPoint(progress,"TOPLEFT",14,-barTop)
        local headingTop=barTop+math.max(10,10*q)
        TrackerPoint(headBoss,"TOPLEFT",14,-headingTop)
        TrackerPoint(head84,"TOPRIGHT",-20-column,-headingTop)
        TrackerPoint(head14,"TOPRIGHT",-14,-headingTop)
        scheduleTop=headingTop+math.max(14,12*q)+4
        trackerFixed=scheduleTop+9
    end
    accountRow:Hide()
    local r=AZS_RUN
    local phase=AZS_GetPhase and AZS_GetPhase()
    local seconds=AZS_GetRunTime and AZS_GetRunTime()
    local duration=AZS_GetRunLength and AZS_GetRunLength()
    if not K.Number(duration) or duration<=0 then duration=type(r)=="table" and r.fin end
    local good=type(r)=="table" and phase and K.Number(seconds) and K.Number(duration) and duration>0
    if good and not K.DB().hidden.tracker then
        if K.pace.On() then
            local d=K.pace.Details()
            paceRow.text:SetText(K.T("Pace: %s",K.T(d.status))..(d.ratio and (" · "..math.floor(d.ratio*100+.5).."%"..(d.mode=="kills" and (" · "..K.T("nur Gegner")) or "")) or ""))
            paceRow.text:SetTextColor(K.pace.Color(d.status)); paceRow:Show()
        else paceRow:Hide() end
        if K.pace.AccountOn() then
            local d=K.pace.Details(true)
            accountRow.text:SetText(K.T("Account Pace: %s",K.T(d.status))..(d.ratio and (" · "..math.floor(d.ratio*100+.5).."%") or ""))
            accountRow.text:SetTextColor(K.pace.Color(d.status)); accountRow:Show()
        end
        zone:SetText((AZS_ZONE and AZS_ZONE.zname) or (GetRealZoneText and GetRealZoneText()) or "Azeroth Survivors")
        time:SetText(K.Clock(seconds).." / "..K.Clock(duration))
        if r.endl==1 then time:SetText(K.Clock(seconds).." · "..K.T("Endlos")) end
        progress:SetValue(math.min(1,seconds/duration))
        if scheduleRun~=K.runStart then P.offsets.tracker=0; scheduleRun=K.runStart end
        local schedule=K.Schedule()
        local endless=r.endl==1
        local total=endless and 1 or table.getn(schedule)
        local count=custom and P.Config("tracker").rows or math.min(total,8)
        local guardianSizing=custom and {width=width,q=q,step=step} or nil
        -- Bound both lists before Layout.Clamp can shrink the compensated font again.
        -- Guardians keep their own wheel area; the clock and pace never scroll.
        if custom then
            local available=P.AvailableHeight("tracker")
            local fixed=trackerFixed-K.HeaderOffset(tracker)
            local n=K.guardians.Count()
            local heading=n>0 and (9+math.max(16,16*q)) or 0
            local slots=math.max(0,math.floor((available-fixed-heading)/step))
            local guardianRows=n>0 and math.max(1,math.min(n,slots-(total>0 and 1 or 0))) or 0
            guardianSizing.visible=guardianRows
            count=math.min(count,math.max(1,slots-guardianRows))
        end
        local scheduleOffset=P.Range("tracker",total,math.max(1,count))
        if not custom then scheduleOffset=0 end
        scheduleScroll:ClearAllPoints(); scheduleScroll:SetPoint("TOPLEFT",tracker,"TOPLEFT",14,-scheduleTop+K.HeaderOffset(tracker))
        scheduleScroll:SetWidth(width-28); scheduleScroll:SetHeight(math.max(1,count*step)); scheduleScroll:Show()
        for i=1,math.min(count,total) do
            local v=schedule[i+scheduleOffset]; local row=ScheduleRow(i)
            if endless then
                local left=K.Number(r.nb) and r.nb>=0 and r.nb or nil
                if left and K.Number(r.t) then left=math.max(0,left-math.max(0,seconds-r.t)) end
                v={name=K.T("Nächster Endlosboss"),at=left and seconds+left}
            end
            TrackerPoint(row,"TOPLEFT",14,-scheduleTop-(i-1)*step)
            row:SetWidth(width-28); row:SetHeight(step-1)
            local timeWidth=column
            row.name:SetWidth(custom and width-28-2*timeWidth-10 or 130); row.name:SetHeight(custom and step-2 or 15)
            row.boss:SetWidth(custom and timeWidth-4 or 62); row.boss:SetHeight(custom and step-2 or 15)
            row.run:SetWidth(timeWidth); row.run:SetHeight(custom and step-2 or 15)
            row.boss:ClearAllPoints(); row.boss:SetPoint("RIGHT",row,"RIGHT",-timeWidth-6,0)
            row.tint:Hide()
            row.name:SetText(v.name or "?")
            row.bossName=v.name
            local timing=K.BossTimes.Get(v)
            if v.state=="dead" then
                row.boss:SetText(K.Clock(timing and timing.duration))
                row.run:SetText(K.Clock(timing and timing.killedAt))
                row.name:SetTextColor(0.5,1,0.55)
                local grade=K.pace.BossGrade(timing and timing.duration,v.final==1)
                local cr,cg,cb=K.pace.Color(grade)
                row.boss:SetTextColor(cr,cg,cb); row.run:SetTextColor(cr,cg,cb)
                if grade then row.tint:SetVertexColor(cr,cg,cb,.16); row.tint:Show() end
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
        for i=math.min(count,total)+1,table.getn(schedules) do schedules[i]:Hide() end
        DrawMarks(schedule,endless and 0 or total,duration)
        -- Level and experience live in the run statistics; the tracker keeps time, zone and bosses.
        local guardians=K.guardians.Draw(guardianContent,-scheduleTop-4-count*step+K.HeaderOffset(tracker),guardianSizing)
        tracker:SetHeight(trackerFixed+count*step+guardians)
        level:SetText("")
        tracker:Show(); H.Native("clock",true)
    else
        paceRow:Hide()
        H.NativeFollow("clock",not K.DB().hidden.tracker)
        if K.DB().hidden.tracker then tracker:Hide()
        else
            zone:SetText((GetRealZoneText and GetRealZoneText()) or "Azeroth Survivors")
            time:SetText(K.Clock(seconds).." / "..K.Clock(duration)); progress:SetValue(0)
            level:SetWidth(width-28); level:SetHeight(math.max(16,14*q))
            level:SetText(K.T("Warte auf Spieldaten"))
            if custom then
                local count=math.max(1,math.min(P.Rows("tracker",1),math.floor((P.AvailableHeight("tracker")-154-extra)/step)))
                P.Range("tracker",0,count); tracker:SetHeight(154+extra+count*step)
            else tracker:SetHeight(154+extra) end
            tracker:Show()
            scheduleScroll:Hide()
            for _,row in ipairs(schedules) do row:Hide() end
            DrawMarks({},0,0)
            K.guardians.Hide()
        end
    end
    DrawBosses(phase)
    T.UpdateExtras()
    local tallyGood=Active(phase) and type(r)=="table" and K.Number(r.kills) and K.Number(r.gold) and K.Number(r.chest)
    if tallyGood and not K.DB().hidden.tally then
        tallyValues[1]:SetText(K.Short(r.kills)); tallyValues[2]:SetText(K.Short(r.gold)); tallyValues[3]:SetText(K.Short(r.chest))
        -- Missing gold for the next cache: green when affordable, yellow when at most a quarter of the price is
        -- missing, red above.
        local missing=math.max(0,r.chest-r.gold)
        local wait=missing<=0 and K.T("Bereit") or K.T("fehlt %s",K.Short(missing))
        tallyValues[4]:SetText(K.Number(r.ck) and K.T("geöffnet %s",K.Short(r.ck)) or K.T("geöffnet ?"))
        tallyValues[5]:SetText(wait)
        if missing<=0 then tallyValues[5]:SetTextColor(0.3,0.9,0.3)
        elseif missing<=r.chest*CACHE_NEAR then tallyValues[5]:SetTextColor(1,0.85,0.2)
        else tallyValues[5]:SetTextColor(1,0.3,0.25) end
        for i,key in ipairs({"kills","gold","chest"}) do tallyCells[i].tip=string.format("%.0f",r[key]) end
        tallyCells[1].detail=K.T("Besiegte Gegner in diesem Run")
        tallyCells[2].detail=K.T("Aktueller Goldbestand")
        tallyCells[3].detail=K.T("Preis des nächsten Caches")
        tallyCells[4].tip=K.Number(r.ck) and string.format("%.0f",r.ck) or "?"
        tallyCells[4].detail=K.T("Geöffnete Caches in diesem Run")
        tallyCells[5].tip=string.format("%.0f",missing)
        tallyCells[5].detail=K.T("Fehlendes Gold bis zum nächsten Cache. Grün: bezahlbar, Gelb: höchstens ein Viertel des Preises fehlt, Rot: mehr.")
        tally:Show(); H.Native("tally",true)
    else
        H.NativeFollow("tally",not K.DB().hidden.tally)
        if K.DB().hidden.tally then tally:Hide() else for _,value in ipairs(tallyValues) do value:SetText("?") end; tally:Show() end
    end
    if Active(phase) and type(r)=="table" and K.Number(r.xp) and K.Number(r.xpn) and r.xpn>0 and not K.DB().hidden.xp then
        xpBar:SetValue(math.min(1,r.xp/r.xpn)); xp:Show()
    else xpBar:SetValue(0); if K.DB().hidden.xp then xp:Hide() else xp:Show() end end
end
P.Register("tracker",tracker,"Runübersicht",Update)
K.Update("basisHud",Update)
table.insert(K.updates,Support)
local function MoveStock()
    -- The minimap (layout key "minimap") is registered in Minimap.lua.
    -- Automatic spells are represented by the single build bar. The chat window lives in Chat.lua.
    -- The game's action bar is only hidden while our action bar is on (KeijinBuildBar keeps it in step).
    -- The action bar belongs to build, never to this module.
    if H.ready and H.On() and MainMenuExpBar then
        if not H.xpOriginal then
            local f=MainMenuExpBar
            local saved={shown=f:IsShown(),show=f:GetScript("OnShow"),active=true}
            H.xpOriginal=saved
            saved.hook=function()
                if saved.show then saved.show() end
                if saved.active and H.On() then saved.shown=true; f:Hide() end
            end
            f:SetScript("OnShow",saved.hook)
        end
        MainMenuExpBar:Hide()
    elseif H.xpOriginal and MainMenuExpBar then
        local f,saved=MainMenuExpBar,H.xpOriginal
        saved.active=false
        if f:GetScript("OnShow")==saved.hook then f:SetScript("OnShow",saved.show) end
        H.xpOriginal=nil
        if saved.shown then f:Show() else f:Hide() end
    end
    if KeijinBuildBarFrame then
        K.layout.Register("build",KeijinBuildBarFrame,"Zauber, Schmuck und Buildtipps",function(f)
            f:ClearAllPoints(); f:SetPoint("BOTTOM",UIParent,"BOTTOM",0,42)
        end,{keepBottom=true,legacyHeight=82})
    end
    if KeijinAchievementsFrame then
        K.layout.Register("achievements",KeijinAchievementsFrame,"Erfolgsmeldung",function(f)
            f:ClearAllPoints(); f:SetPoint("BOTTOM",UIParent,"BOTTOM",0,200)
        end,{hidden=true})
    end
end
K.On("PLAYER_ENTERING_WORLD",function()
    H.ready=true
    MoveStock()
    for key in pairs(K.layout.entries) do K.layout.Place(key) end
    Update()
end)
table.insert(K.updates,MoveStock)
K.moduleRefresh=K.moduleRefresh or {}
K.moduleRefresh.basisHud=function()
    H.ready=true
    MoveStock(); Update(); Support()
    for _,refresh in ipairs(H.refresh) do refresh() end
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.moduleRefresh.basisHud() end end)
MoveStock()
Update()
