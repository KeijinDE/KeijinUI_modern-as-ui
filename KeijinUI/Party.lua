-- Co-op party window: up to four teammates (never the own hero) with class coloured name, health bar with percent
-- and status (offline, downed). Revive progress comes from AZS_GetRevive() (game with the co-op patch).
-- Teammates are read from the normal party units party1..party4. Whether co-op heroes appear there is not confirmed in
-- the game, so without party units the names and classes of AZS_GetPartyMeter() are listed instead (no health).
-- Older game versions without these functions leave the window hidden; nothing raises an error.
local K=KeijinUI
local P={}
K.party=P
local WIDTH,ROW,MAXMEMBERS=210,24,4
local TOP,BOTTOM,HINT=33,8,18
local panel=K.Panel("KeijinUIParty","Party",WIDTH,TOP+ROW+BOTTOM)
P.panel=panel
K.layout.Register("party",panel,"Partyfenster",function(f)
    -- Left of centre, clear of the statistics column (300 points at scale 0.9) at the left edge.
    f:ClearAllPoints(); f:SetPoint("LEFT",UIParent,"LEFT",332,0)
end,{hidden=true,inactive=function() return not K.ModuleOn("party") end})
local rows={}
-- Right click on a row with a real party unit opens the raid marker menu; rows from the party meter have no unit.
local function RowMouseUp()
    if arg1=="RightButton" and this.unit then K.marks.Open(this.unit,this) end
end
for i=1,MAXMEMBERS do
    local row=K.ListBarRow(panel,i,ROW-2)
    row.label:SetWidth(WIDTH-105)
    row:SetScript("OnMouseUp",RowMouseUp)
    row:Hide()
    rows[i]=row
end
local hint=K.Text(panel,"",10,"BOTTOMLEFT",13,9,WIDTH-26)
hint:SetTextColor(1,0.82,0.28); hint:Hide()

local function Revive()
    if type(AZS_GetRevive)~="function" then return nil end
    local ok,r=pcall(AZS_GetRevive)
    if not ok or type(r)~="table" then return nil end
    return r
end
local function Fraction(v) return K.Number(v) and math.min(1,v) or 0 end
local function Own(name) return name~=nil and name==UnitName("player") end
-- Once this client has exposed real party units, damage history is no longer a roster.
local rosterKnown=false
function P.Roster()
    if type(GetNumPartyMembers)~="function" then return nil,false end
    local count=GetNumPartyMembers()
    if not K.Number(count) then return nil,false end
    if count<=0 then return nil,rosterKnown end
    local names,n={},0
    local own=UnitName("player")
    if type(own)=="string" then names[own]=true end
    for i=1,MAXMEMBERS do
        local unit="party"..i
        if UnitExists(unit) then
            local name=UnitName(unit)
            if type(name)=="string" and name~="" then names[name]=true; n=n+1 end
        end
    end
    if n>0 then rosterKnown=true; return names,true end
    return nil,rosterKnown
end
local function NativeRevive(replace)
    -- Older clients silently ignore unknown HUD parts; don't save a fictitious state.
    if type(AZS_HUD_CVARS)~="table" or type(AZS_HUD_CVARS.revive)~="string" then return end
    K.Native("revive",replace)
end

-- Teammates as {name,class,hp,max,dead,offline,health=true|false}. Party units first, otherwise the party meter.
local function Members(revive)
    local list={}
    local roster,known=P.Roster()
    if known and not roster then return list,"units" end
    local reviving=revive and type(revive.reviving)=="string" and revive.reviving~="" and revive.reviving or nil
    if type(GetNumPartyMembers)=="function" and GetNumPartyMembers()>0 then
        for i=1,MAXMEMBERS do
            local unit="party"..i
            if UnitExists(unit) then
                local name=UnitName(unit) or "?"
                local _,token=UnitClass(unit)
                local hp,max=UnitHealth(unit),UnitHealthMax(unit)
                local offline=type(UnitIsConnected)=="function" and not UnitIsConnected(unit)
                local dead=type(UnitIsDeadOrGhost)=="function" and UnitIsDeadOrGhost(unit) and true or false
                if K.Number(max) and max>0 and K.Number(hp) and hp<=0 then dead=true end
                if reviving and name==reviving then dead=true end
                table.insert(list,{unit=unit,name=name,class=token,hp=hp,max=max,dead=dead,offline=offline and true or false,health=true})
            end
        end
    end
    if table.getn(list)>0 then return list,"units" end
    local lines=type(K.PartyMeter)=="function" and K.PartyMeter() or nil
    for _,line in ipairs(lines or {}) do
        if not Own(line.name) and table.getn(list)<MAXMEMBERS then
            table.insert(list,{name=line.name,class=type(line.class)=="string" and string.upper(line.class) or nil,
                dead=reviving~=nil and line.name==reviving,offline=false,health=false})
        end
    end
    return list,"meter"
end

-- The game's party frames stay untouched unless they would show next to this window: then they are hidden
-- while the window is up and shown again afterwards (only frames that exist and were shown).
local hiddenStock={}
local function StockFrames(hide)
    for i=1,MAXMEMBERS do
        local f=getglobal("PartyMemberFrame"..i)
        if f then
            if hide then
                if f:IsShown() then hiddenStock[i]=true; f:Hide() end
            elseif hiddenStock[i] then
                hiddenStock[i]=nil
                if UnitExists("party"..i) then f:Show() end
            end
        end
    end
end

function P.Refresh()
    local revive=Revive()
    local members,mode
    if K.ModuleOn("party") then members,mode=Members(revive) else members={} end
    local n=table.getn(members)
    local own=K.ModuleOn("party") and revive and (revive.down==1 or revive.down==true)
    if n==0 and not own then
        for _,row in ipairs(rows) do row.unit=nil; row:Hide() end
        hint:Hide(); panel:Hide(); StockFrames(false); NativeRevive(false)
        return
    end
    local covered=own and K.Number(revive.share) and true or false
    for i,row in ipairs(rows) do
        local m=members[i]
        row.unit=m and m.unit or nil
        if not m then row:Hide()
        else
            local red,green,blue=K.PartyClassColor(m.class)
            local reviveShare=revive and revive.reviving==m.name and Fraction(revive.rshare) or nil
            row.label:SetText(m.name)
            row.value:SetTextColor(0.94,0.91,0.82)
            if m.offline then
                row.label:SetTextColor(0.5,0.5,0.5); row.value:SetText(K.T("Offline")); row.value:SetTextColor(0.5,0.5,0.5)
                row.bar:SetValue(0)
            elseif m.dead or reviveShare then
                row.label:SetTextColor(red,green,blue)
                if reviveShare then
                    -- The gold bar says "being revived"; the number alone fits beside long names in every language.
                    row.value:SetText(string.format("%d%%",math.floor(reviveShare*100+0.5))); row.value:SetTextColor(1,0.82,0.28)
                    row.bar:SetStatusBarColor(1,0.82,0.28,0.85); row.bar:SetValue(reviveShare)
                    if not own and K.Number(revive.rshare) then covered=true end
                else
                    row.value:SetText(K.T("Am Boden")); row.value:SetTextColor(1,0.25,0.2)
                    row.bar:SetValue(0)
                end
            else
                row.label:SetTextColor(red,green,blue)
                if m.health and K.Number(m.hp) and K.Number(m.max) and m.max>0 then
                    local share=math.min(1,m.hp/m.max)
                    row.value:SetText(string.format("%d%%",math.floor(share*100+0.5)))
                    if K.DB().classHealth~=false then row.bar:SetStatusBarColor(red,green,blue,0.85)
                    else row.bar:SetStatusBarColor(share>0.35 and 0.12 or 0.85,share>0.35 and 0.88 or 0.08,share>0.35 and 0.08 or 0.08,0.85) end
                    row.bar:SetValue(share)
                else
                    row.value:SetText(""); row.bar:SetValue(0)
                end
            end
            row:Show()
        end
    end
    -- Own hero downed: who revives and how far (shown at the bottom of the window).
    if own then
        local percent=math.floor(Fraction(revive.share)*100+0.5)
        -- Without the reviver's name: a long hero name would cut the line off in some languages.
        hint:SetText(K.T("Du wirst belebt: %d%%",percent))
        hint:Show()
    else hint:Hide() end
    panel:SetHeight(TOP+n*(ROW+0)+BOTTOM+(own and HINT or 0))
    panel:Show()
    if mode=="units" then StockFrames(true) else StockFrames(false) end
    NativeRevive(covered)
end
function P.Stop()
    for _,row in ipairs(rows) do row.unit=nil; row:Hide() end
    hint:Hide(); panel:Hide(); StockFrames(false)
    NativeRevive(false)
end

-- /kui party debug: what the game hands out for the party, in chat.
function P.Debug()
    local count=type(GetNumPartyMembers)=="function" and GetNumPartyMembers() or "n/a"
    K.Say("Party debug: GetNumPartyMembers="..tostring(count)..", module "..(K.ModuleOn("party") and "on" or "off")
        ..", window "..(panel:IsShown() and "shown" or "hidden"))
    for i=1,MAXMEMBERS do
        local unit="party"..i
        local exists=UnitExists(unit)
        if exists then
            local _,token=UnitClass(unit)
            K.Say(unit..": exists=1 name="..tostring(UnitName(unit)).." class="..tostring(token)
                .." hp="..tostring(UnitHealth(unit)).."/"..tostring(UnitHealthMax(unit))
                .." dead="..tostring(type(UnitIsDeadOrGhost)=="function" and UnitIsDeadOrGhost(unit) or nil)
                .." connected="..tostring(type(UnitIsConnected)=="function" and UnitIsConnected(unit) or nil))
        else K.Say(unit..": exists=nil") end
    end
    if type(AZS_GetPartyMeter)~="function" then K.Say("AZS_GetPartyMeter: missing (older game version)")
    else
        local lines=K.PartyMeter()
        K.Say("AZS_GetPartyMeter: "..(lines and table.getn(lines) or 0).." lines")
        for _,line in ipairs(lines or {}) do
            K.Say("  "..line.name.." class="..tostring(line.class).." dmg="..tostring(line.dmg).." dps="..tostring(line.dps)
                .." top="..tostring(line.top).." topdps="..tostring(line.topdps))
        end
    end
    if type(AZS_GetRevive)~="function" then K.Say("AZS_GetRevive: missing (older game version)")
    else
        local r=Revive() or {}
        K.Say("AZS_GetRevive: down="..tostring(r.down).." share="..tostring(r.share).." by="..tostring(r.by)
            .." reviving="..tostring(r.reviving).." rshare="..tostring(r.rshare))
    end
end

-- Driver frame: events rebuild the window at once, everything else follows throttled.
local driver=CreateFrame("Frame","KeijinUIPartyDriver",UIParent)
P.driver=driver
for _,ev in ipairs({"PARTY_MEMBERS_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","CHAT_MSG_ADDON","PLAYER_ENTERING_WORLD"}) do driver:RegisterEvent(ev) end
driver:SetScript("OnEvent",function()
    if event=="CHAT_MSG_ADDON" and arg1~="AZSPARTY" then return end
    if (event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH") and not string.find(arg1 or "","^party") then return end
    P.Refresh()
end)
K.On("PLAYER_LOGOUT",function() NativeRevive(false) end)
local elapsed=0
driver:SetScript("OnUpdate",function()
    elapsed=elapsed+(tonumber(arg1) or 0)
    if elapsed<0.2 then return end
    elapsed=0
    P.Refresh()
end)
