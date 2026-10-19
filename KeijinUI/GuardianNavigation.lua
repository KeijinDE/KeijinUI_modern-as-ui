-- Small arrows in existing guardian rows; directions lead to fixed lairs, never guessed moving creatures.
local K=KeijinUI
local N=K.navigation
local G={pins={}}
K.guardianNav=G
local selected,awaitLairs
local PATH="Interface\\AddOns\\KeijinUI\\media\\caches\\Arrow.tga"
local rows={}
function G.On() return K.ModuleOn("guardianNav") and K.DB().guardianGuide~=false end
function G.PinsOn() return K.ModuleOn("guardianNav") and K.DB().guardianPins~=false end
function G.Set(on) K.DB().guardianGuide=on and true or false; G.Update() end
function G.SetPins(on) K.DB().guardianPins=on and true or false; G.Update() end
-- A lair is "empty" both before its guardian first appears and after its death. Only a lair seen
-- asleep or awake in this run counts as defeated, so no skull shows during the first seconds.
local seenAlive,runStamp={},nil
local function Identity(lair) return tostring(lair.index)..":"..tostring(lair.id or 0) end
function G.List(includeEmpty)
    local out={}
    if not N.Active() or awaitLairs or type(AZS_LAIRS)~="table" or not K.Fresh(AZS_LAIRS_UPDATED) then return out end
    if runStamp~=AZS_ZONE_UPDATED then runStamp=AZS_ZONE_UPDATED; seenAlive={} end
    for i,lair in ipairs(AZS_LAIRS) do
        if type(lair)=="table" and (lair.state=="asleep" or lair.state=="awake") then seenAlive[lair.index or i]=true end
        if type(lair)=="table" and (lair.state=="asleep" or lair.state=="awake" or (includeEmpty and lair.state=="empty")) and N.Finite(lair.x) and N.Finite(lair.y) then
            local dist,east,north,source=N.Distance(lair)
            table.insert(out,{key=Identity(lair),lair=lair,index=i,defeated=lair.state=="empty" and seenAlive[lair.index or i]==true,dist=dist,east=east,north=north,source=source})
        end
    end
    return out
end
local function Nearest(list)
    local best
    for _,v in ipairs(list) do if not best or (v.dist and (not best.dist or v.dist<best.dist)) then best=v end end
    return best
end
function G.Select(index)
    for _,v in ipairs(G.List()) do
        if v.index==index or v.lair.index==index then selected=v.key; G.Update(); return true end
    end
    return false
end
function G.Cycle(step)
    local list=G.List(); local count=table.getn(list)
    if count==0 then return end
    local index=0
    for i,v in ipairs(list) do if v.key==selected then index=i; break end end
    index=math.mod(index-1+(step or 1),count)+1
    selected=list[index].key; G.Update()
end
function G.Nearest() selected=nil; G.Update() end
-- Each row gets its own direction. The overview keeps its size and status column.
function G.Decorate(row)
    rows[row]=true
    local destination
    if row:IsShown() and G.On() and row.lair then
        for _,v in ipairs(G.List()) do if v.lair==row.lair then destination=v; break end end
    end
    local visible=destination and destination.dist and destination.dist>.5
    if visible then
        if not row.direction then
            row.direction=row:CreateTexture(nil,"ARTWORK")
            row.direction:SetTexture(PATH); row.direction:SetWidth(14); row.direction:SetHeight(14)
        end
        local facing=N.Facing()
        row.directionStep=N.Arrow(row.direction,facing-math.atan2(-destination.east,destination.north))
        row.direction:SetVertexColor(1,.82,.28,1); row.direction:Show()
    elseif row.direction then row.direction:Hide(); row.directionStep=nil end
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT",row,"LEFT",0,0)
    row.name:SetWidth(visible and 133 or 150)
    if visible then
        local width=math.min(133,row.name:GetStringWidth())
        row.direction:ClearAllPoints(); row.direction:SetPoint("LEFT",row,"LEFT",width+3,0)
    end
end
function G.AddTooltip(lair)
    if not lair then return end
    for _,v in ipairs(G.List(true)) do
        if v.lair==lair then
            GameTooltip:AddLine(v.dist and K.T("Entfernung: %d Yards",math.floor(v.dist+.5)) or K.T("Position unbekannt"),.9,.88,.8)
            GameTooltip:AddLine(K.T("Richtung und Entfernung zeigen zum Hort, nicht zum bewegten Wächter."),.7,.7,.7,true)
            local _,from=N.Facing()
            if lair.state~="empty" and G.On() and v.dist and v.dist>.5 and from=="north" then GameTooltip:AddLine(K.T("Keine Blickrichtung verfügbar: Pfeil ist nordorientiert."),1,.82,.28,true) end
            return
        end
    end
end
local function Tip(v,owner)
    if not v then return end
    GameTooltip:SetOwner(owner,"ANCHOR_LEFT"); GameTooltip:SetText(v.lair.name or K.T("Hort"),1,.82,.28)
    local text,r,g,b=K.guardians.Status(v.lair)
    GameTooltip:AddLine(text,r,g,b)
    G.AddTooltip(v.lair)
    GameTooltip:Show()
end
local overlay
local function Pin(i)
    if not overlay then
        if not Minimap or not MinimapCluster then return end
        overlay=CreateFrame("Frame",nil,MinimapCluster); overlay:SetAllPoints(Minimap)
        overlay:SetFrameLevel(Minimap:GetFrameLevel()+4); overlay:EnableMouse(false)
    end
    local pin=G.pins[i]
    if not pin then
        pin=CreateFrame("Button",nil,overlay); pin:SetWidth(18); pin:SetHeight(18)
        pin.icon=pin:CreateTexture(nil,"ARTWORK"); pin.icon:SetWidth(14); pin.icon:SetHeight(14)
        pin.icon:SetPoint("CENTER",pin,"CENTER",0,0)
        pin.icon:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
        pin.icon:SetVertexColor(.55,.55,.55,.75)
        pin:SetScript("OnEnter",function() Tip(this.destination,this) end)
        pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
        pin:SetScript("OnHide",function() if GameTooltip.GetOwner and GameTooltip:GetOwner()==this then GameTooltip:Hide() end end)
        pin:EnableMouseWheel(true)
        pin:SetScript("OnMouseWheel",function() local f=Minimap:GetScript("OnMouseWheel"); if f then f() end end)
        G.pins[i]=pin
    end
    return pin
end
function G.Update()
    for row in pairs(rows) do G.Decorate(row) end
    if not G.On() and not G.PinsOn() then
        G.current=nil; G.shownPins=0
        for _,pin in ipairs(G.pins) do pin.destination=nil; pin:Hide() end
        return
    end
    local list=G.List(); local chosen
    for _,v in ipairs(list) do if selected==v.key then chosen=v; break end end
    chosen=chosen or Nearest(list); selected=chosen and chosen.key or nil; G.current=chosen
    local count=0
    if G.PinsOn() then
        for _,v in ipairs(G.List(true)) do
            -- Native flags cover living guardians until a targeted flag API exists.
            -- Only a lair seen alive earlier in this run and now empty gets our skull; respawn removes it.
            if v.defeated and v.dist then
                local x,y,edge=N.MinimapPoint(v.east,v.north,11)
                if x then
                    local pin=Pin(count+1)
                    if pin then
                        count=count+1; pin.destination=v; pin.atEdge=edge
                        pin:ClearAllPoints(); pin:SetPoint("CENTER",Minimap,"CENTER",x,y)
                        pin.state=v.lair.state
                        pin:SetAlpha(edge and .8 or 1); pin:Show()
                    end
                end
            end
        end
    end
    for i=count+1,table.getn(G.pins) do G.pins[i].destination=nil; G.pins[i]:Hide() end
    G.shownPins=count
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then selected=nil; awaitLairs=true
    elseif prefix=="AZSLAIRS" then awaitLairs=false end
end)
K.On("PLAYER_LEAVING_WORLD",function() selected=nil; awaitLairs=true; G.Update() end)
K.On("PLAYER_LOGOUT",function() selected=nil; G.Update() end)
K.Update("guardianNav",G.Update)
