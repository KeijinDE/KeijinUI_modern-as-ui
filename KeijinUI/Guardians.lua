-- Guardian lairs below the boss schedule of the run overview: asleep, fighting (with health) or empty with
-- the time until the next guardian comes. Data: AZS_LAIRS (index, state, name, id, left, mx, my) and AZS_UNITS
-- for the health of a fighting guardian. The game sends a waiting lair about once a second; in between the
-- countdown runs on from AZS_LAIRS_UPDATED, at most two seconds, so a missing message never counts too far.
local K=KeijinUI
K.guardians={}
local G=K.guardians
local MAX=6
local rows={}
local head,count,line,viewport
local offset,visible,total,scrollRun=0,0,0,nil
function G.On() return K.ModuleOn("guardians") and K.DB().guardians~=false end
function G.Set(on) K.DB().guardians=on and true or false end
local function Left(lair)
    local left=lair.left
    if not K.Number(left) or left<=0 then return left end
    if K.Number(AZS_LAIRS_UPDATED) and GetTime then
        left=left-math.min(2,math.max(0,GetTime()-AZS_LAIRS_UPDATED))
    end
    return math.max(0,left)
end
-- Seconds since the last lair message; nil when the game never sent one.
local function Age()
    if not K.Number(AZS_LAIRS_UPDATED) or not GetTime then return nil end
    return math.max(0,GetTime()-AZS_LAIRS_UPDATED)
end
-- Respawn countdown text of a lair: empty unless it is held, "?" when the data is stale.
function G.Countdown(lair)
    if not lair or lair.state~="empty" then return "" end
    local left=Left(lair)
    if not K.Number(left) or (left>0 and Age() and Age()>5) then return "?" end
    return K.Clock(math.ceil(left))
end
-- The guardian unit of a held lair, by id, for its health. Units from the run before do not count.
local function Unit(lair)
    if type(AZS_UNITS)~="table" or not K.Fresh(AZS_UNITS_UPDATED) then return nil end
    if not K.Number(lair.id) or lair.id==0 then return nil end
    for _,u in ipairs(AZS_UNITS) do
        if u.kind=="guardian" and u.id==lair.id then return u end
    end
end
local function Health(u)
    if u and K.Number(u.hp) and K.Number(u.hpm) and u.hpm>0 then return u.hp/u.hpm end
end
-- Text and color of one lair.
function G.Status(lair)
    if lair.state=="awake" then
        local share=Health(Unit(lair))
        if share then return K.T("im Kampf").." "..string.format("%.0f%%",100*share),1,0.5,0.25 end
        return K.T("im Kampf"),1,0.5,0.25
    end
    if lair.state=="asleep" then return K.T("schläft"),0.48,0.7,0.43 end
    local left=Left(lair)
    -- A waiting lair is sent every second; without a message for five seconds the countdown is unknown.
    local age=Age()
    if K.Number(left) and left>0 and age and age>5 then return "?",0.6,0.6,0.62 end
    if K.Number(left) and left>0 then return K.T("zurück in %s",K.Clock(left)),1,0.75,0.4 end
    if left==0 then return K.T("fällig"),1,0.82,0.28 end
    return K.T("leer"),0.6,0.6,0.62
end
function G.Count()
    return G.On() and type(AZS_LAIRS)=="table" and K.Fresh(AZS_LAIRS_UPDATED) and math.min(MAX,table.getn(AZS_LAIRS)) or 0
end
function G.Scroll(delta)
    if K.layout.Active() then K.panelSizing.Scroll("tracker",delta); return end
    offset=math.max(0,math.min(math.max(0,total-visible),offset+(delta>0 and -1 or 1)))
    K.panelSizing.Refresh("tracker")
end
local function Row(parent,i)
    if rows[i] then return rows[i] end
    local row=CreateFrame("Frame",nil,parent)
    row:SetWidth(272); row:SetHeight(17); row.position=i
    row.name=K.Text(row,"",10,"LEFT",0,0,150)
    row.state=K.Text(row,"",10,"RIGHT",0,0)
    row.state:SetWidth(120); row.state:SetHeight(15); row.state:SetJustifyH("RIGHT")
    row:EnableMouse(true)
    row:SetScript("OnEnter",function()
        local lair=this.lair
        if not lair then return end
        GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText(lair.name or "?",1,0.82,0.28)
        local text=G.Status(lair)
        GameTooltip:AddLine(text,0.94,0.91,0.82)
        if K.guardianNav then K.guardianNav.AddTooltip(lair) end
        if K.Number(lair.mx) and lair.mx>=0 and K.Number(lair.my) and lair.my>=0 then
            GameTooltip:AddLine(K.T("Hort auf der Karte bei %s, %s",string.format("%.0f",lair.mx*100),string.format("%.0f",lair.my*100)),0.7,0.7,0.7)
        end
        GameTooltip:AddLine(K.T("Ein Wächter kämpft dort, wo er geweckt wurde, und kehrt zurück, wenn er zu weit gelockt wird."),0.7,0.7,0.7,true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    row:SetScript("OnMouseUp",function()
        if this.lair and K.guardianNav then K.guardianNav.Click(this.lair.index or i) end
    end)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel",function()
        if this.panelSizingGeometry then G.Scroll(arg1) end
    end)
    rows[i]=row
    return row
end
function G.Hide()
    if head then head:Hide(); count:Hide(); line:Hide(); viewport:Hide() end
    offset=0; total=0; visible=0
    for _,row in ipairs(rows) do row.lair=nil; row:Hide() end
end
-- Draws the lairs into parent from top (negative y) downward and returns the height used, 0 when nothing is shown.
-- Navigation decorates these rows again on its own update. Keep its icons and
-- direction intact, then restore the tracker columns only for our sized rows.
local function Reflow(row)
    local g=row.panelSizingGeometry
    if not g or not row:IsShown() then return end
    local mark=row.marker and row.marker:IsShown() and 17 or 0
    local arrow=row.direction and row.direction:IsShown() and 17 or 0
    local width=math.max(30,g.width-g.state-8-mark-arrow)
    row.name:SetWidth(width)
    if arrow>0 then
        row.direction:ClearAllPoints()
        row.direction:SetPoint("LEFT",row,"LEFT",mark+math.min(width,row.name:GetStringWidth())+3,0)
    end
end
function G.Draw(parent,top,sizing)
    if K.guardianNav and not G.decorator then
        local decorate=K.guardianNav.Decorate
        G.decorator=decorate
        K.guardianNav.Decorate=function(row) decorate(row); Reflow(row) end
    end
    local list=type(AZS_LAIRS)=="table" and K.Fresh(AZS_LAIRS_UPDATED) and AZS_LAIRS or {}
    local n=G.Count()
    if scrollRun~=K.runStart then offset=0; scrollRun=K.runStart end
    total=n; visible=sizing and math.min(n,sizing.visible or n) or n
    offset=sizing and math.max(0,math.min(offset,n-visible)) or 0
    if n==0 then G.Hide(); return 0 end
    if not head then
        viewport=CreateFrame("Frame",nil,parent)
        viewport:EnableMouse(true); viewport:EnableMouseWheel(true)
        viewport:SetScript("OnMouseWheel",function() G.Scroll(arg1) end)
        head=K.LText(parent,"Wächter",9,"TOPLEFT",14,0,130); head:SetTextColor(0.65,0.63,0.58)
        count=K.Text(parent,"",9,"TOPRIGHT",-14,0); count:SetTextColor(0.65,0.63,0.58)
        -- Faint line between the last boss and the guardians, the same as between the run statistics rows.
        line=parent:CreateTexture(nil,"ARTWORK")
        line:SetTexture(K.flat); line:SetVertexColor(0.62,0.57,0.43,0.22); line:SetHeight(1)
    end
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT",parent,"TOPLEFT",14,top+1); line:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-14,top+1)
    top=top-5
    head:ClearAllPoints(); head:SetPoint("TOPLEFT",parent,"TOPLEFT",14,top)
    count:ClearAllPoints(); count:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-14,top)
    local step=sizing and sizing.step or 18
    local q=sizing and sizing.q or 1
    local width=sizing and sizing.width-28 or 272
    local heading=math.max(16,16*q)
    head:SetWidth(width*.46); head:SetHeight(heading)
    count:SetWidth(width*.5); count:SetHeight(heading); count:SetJustifyH("RIGHT")
    viewport:SetParent(parent); viewport:ClearAllPoints()
    viewport:SetPoint("TOPLEFT",parent,"TOPLEFT",14,top)
    viewport:SetWidth(width); viewport:SetHeight(heading+visible*step)
    if sizing then viewport:Show() else viewport:Hide() end
    local up=0
    for i=1,n do
        if list[i].state=="asleep" or list[i].state=="awake" then up=up+1 end
    end
    for i=1,visible do
        local lair=list[i+offset]
        local row=Row(parent,i)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",parent,"TOPLEFT",14,top-heading-(i-1)*step)
        row:SetWidth(width); row:SetHeight(step-1)
        local stateWidth=sizing and math.max(width*.46,KeijinUI.panelSizing.Measure(row.state,K.T("zurück in %s","99:59"))) or 120
        row.name:SetWidth(math.max(30,width-stateWidth-8)); row.name:SetHeight(step-2)
        row.state:SetWidth(stateWidth); row.state:SetHeight(step-2)
        row.panelSizingGeometry=sizing and {width=width,state=stateWidth} or nil
        row.lair=lair; row.position=i+offset
        row.name:SetText(lair.name or (K.T("Hort").." "..(i+offset)))
        row.name:SetTextColor(0.85,0.82,0.75)
        local text,r,g,b=G.Status(lair)
        row.state:SetText(text); row.state:SetTextColor(r,g,b)
        row:Show()
        if K.guardianNav then K.guardianNav.Decorate(row) end
    end
    for i=visible+1,table.getn(rows) do rows[i].lair=nil; rows[i]:Hide() end
    count:SetText(K.T("%d von %d da",up,table.getn(list)))
    head:Show(); count:Show(); line:Show()
    return 9+heading+visible*step
end
function G.Debug()
    local age=Age()
    K.Say("guardians debug: AZS_LAIRS "..(type(AZS_LAIRS)=="table" and table.getn(AZS_LAIRS) or "nil")
        .." age "..(age and string.format("%.1f",age) or "nil").." AZS_GetLairs "..tostring(AZS_GetLairs~=nil)
        .." run gu/ga/lairs "..(type(AZS_RUN)=="table" and (tostring(AZS_RUN.gu).."/"..tostring(AZS_RUN.ga).."/"..tostring(AZS_RUN.lairs)) or "nil"))
    if K.navigation and K.navigation.SmoothText then K.Say("guardians debug: "..K.navigation.SmoothText()) end
    for _,l in ipairs(type(AZS_LAIRS)=="table" and AZS_LAIRS or {}) do
        K.Say(string.format("lair %s %s %s id=%s left=%s",tostring(l.index),tostring(l.name),tostring(l.state),tostring(l.id),tostring(l.left)))
    end
    for _,u in ipairs(type(AZS_UNITS)=="table" and AZS_UNITS or {}) do
        if u.kind=="guardian" then K.Say(string.format("unit %s %s hp=%s/%s state=%s",tostring(u.id),tostring(u.name),tostring(u.hp),tostring(u.hpm),tostring(u.state))) end
    end
end
function G.Command(rest)
    if rest=="debug" then G.Debug(); return end
    if rest=="on" then G.Set(true) elseif rest=="off" then G.Set(false) else G.Set(not G.On()) end
    K.Say(K.T("Wächter in der Runübersicht")..": "..(G.On() and K.T("An") or K.T("Aus")))
end
