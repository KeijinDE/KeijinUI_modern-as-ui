-- Small arrows in existing guardian rows; directions lead to fixed lairs, never guessed moving creatures.
local K=KeijinUI
local N=K.navigation
local G={pins={}}
K.guardianNav=G
local selected,awaitLairs
local inWorld=true
local PATH="Interface\\AddOns\\KeijinUI\\media\\caches\\Arrow.tga"
local rows={}
function G.On() return K.ModuleOn("guardianNav") and K.DB().guardianGuide~=false end
function G.PinsOn() return K.ModuleOn("guardianNav") and K.DB().guardianPins~=false end
function G.Set(on) K.DB().guardianGuide=on and true or false; G.Update() end
function G.SetPins(on) K.DB().guardianPins=on and true or false; G.Update() end
-- Game 0.102: AZS_SetHudShown("flag") hides the native minimap flag, AZS_GetFlaggedLair names its lair.
-- Older clients lack both (and AZS_HUD_CVARS.flag); there the native flag stays untouched.
function G.FlagSupported()
    return type(AZS_SetHudShown)=="function" and type(AZS_IsHudShown)=="function" and type(AZS_GetFlaggedLair)=="function"
        and type(AZS_HUD_CVARS)=="table" and AZS_HUD_CVARS.flag~=nil
end
-- Own the native flag while pins are enabled in the world, independently of lair data.
-- Keep its previous value, including false, and return it on shutdown or leaving the world.
local function NativeFlag(replaced)
    local db=K.DB()
    if replaced then
        if db.nativeFlagShown==nil then db.nativeFlagShown=AZS_IsHudShown("flag") and true or false end
        if AZS_IsHudShown("flag") then AZS_SetHudShown("flag",false) end
    elseif db.nativeFlagShown~=nil and G.FlagSupported() then
        AZS_SetHudShown("flag",db.nativeFlagShown); db.nativeFlagShown=nil
    end
end
-- Legacy clients cannot hide their native flags: only previously occupied, now empty lairs
-- receive a grey skull there. Clients with the flag API show all three states from the start.
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
local overlay,playerLayer
-- The ninth native minimap child is the facing model (also used by Caches.lua).
-- Raise that model, not the whole map, so the terrain cannot cover our pins.
local function PlayerAbovePins(on)
    local model
    if on and overlay and Minimap and Minimap.GetChildren then
        local children={Minimap:GetChildren()}
        local candidate=children[9]
        if candidate and candidate.GetObjectType and candidate.GetFacing then
            local kind=candidate:GetObjectType()
            if kind=="Model" or kind=="PlayerModel" then model=candidate end
        end
    end
    if playerLayer and playerLayer.frame~=model then
        playerLayer.frame:SetFrameLevel(playerLayer.level)
        if playerLayer.strata then playerLayer.frame:SetFrameStrata(playerLayer.strata) end
        playerLayer=nil
    end
    if not model then return end
    if not playerLayer then
        playerLayer={frame=model,level=model:GetFrameLevel(),strata=model.GetFrameStrata and model:GetFrameStrata()}
    end
    local strata=overlay.GetFrameStrata and overlay:GetFrameStrata()
    if strata then model:SetFrameStrata(strata) end
    model:SetFrameLevel(math.max(playerLayer.level,overlay:GetFrameLevel()+4))
end
local function Overlay()
    if not overlay then
        if not Minimap or not MinimapCluster then return end
        overlay=CreateFrame("Frame",nil,MinimapCluster); overlay:SetAllPoints(Minimap)
        overlay:SetFrameLevel(Minimap:GetFrameLevel()+4); overlay:EnableMouse(false)
    end
    return overlay
end
local function Pin(i)
    if not Overlay() then return end
    local pin=G.pins[i]
    if not pin then
        pin=CreateFrame("Button",nil,overlay); pin:SetWidth(16); pin:SetHeight(16)
        K.Chamfer(pin,3,{.035,.035,.045,1},{.62,.57,.43,1})
        pin.icon=pin:CreateTexture(nil,"ARTWORK"); pin.icon:SetWidth(14); pin.icon:SetHeight(14)
        pin.icon:SetPoint("CENTER",pin,"CENTER",0,0)
        pin.icon:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
        pin.badge=CreateFrame("Frame",nil,pin); pin.badge:SetAllPoints(pin); pin.badge:SetFrameLevel(pin:GetFrameLevel()+1)
        -- Tiny FontStrings are clipped/wrapped by this client. Draw one complete transparent
        -- symbol instead, straddling the lower-right corner rather than floating beside it.
        pin.badge.mark=pin.badge:CreateTexture(nil,"OVERLAY")
        pin.badge.mark:SetWidth(8); pin.badge.mark:SetHeight(8)
        pin.badge.mark:SetPoint("CENTER",pin,"BOTTOMRIGHT",-1,1)
        pin:SetScript("OnClick",function() if this.destination and this.destination.lair.state~="empty" then G.Select(this.destination.lair.index or this.destination.index) end end)
        pin:SetScript("OnEnter",function() Tip(this.destination,this) end)
        pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
        pin:SetScript("OnHide",function() if GameTooltip.GetOwner and GameTooltip:GetOwner()==this then GameTooltip:Hide() end end)
        pin:EnableMouseWheel(true)
        pin:SetScript("OnMouseWheel",function() local f=Minimap:GetScript("OnMouseWheel"); if f then f() end end)
        G.pins[i]=pin
    end
    return pin
end
-- Gold skull while held, orange with "!" in combat, grey with "x" once empty.
local function Paint(pin,state)
    pin.state=state
    if state=="empty" then
        pin.icon:SetVertexColor(.55,.55,.55,.75)
        pin.badge.mark:SetTexture("Interface\\AddOns\\KeijinUI\\media\\guardians\\GuardianEmpty.tga")
        pin.badge.mark:SetVertexColor(.85,.85,.85,1); pin.badge:Show()
    elseif state=="awake" then
        pin.icon:SetVertexColor(1,.45,.16,1)
        pin.badge.mark:SetTexture("Interface\\AddOns\\KeijinUI\\media\\guardians\\GuardianCombat.tga")
        pin.badge.mark:SetVertexColor(1,.7,.3,1); pin.badge:Show()
    else pin.icon:SetVertexColor(1,.82,.28,1); pin.badge:Hide() end
end
function G.Update()
    for row in pairs(rows) do G.Decorate(row) end
    if not inWorld or (not G.On() and not G.PinsOn()) then
        G.current=nil; G.shownPins=0
        for _,pin in ipairs(G.pins) do pin.destination=nil; pin:Hide() end
        PlayerAbovePins(false)
        NativeFlag(false)
        return
    end
    -- Even with no lair snapshot yet the native flag is ours to suppress. After leaving
    -- the world the early return above prevents later ticks from taking it over again.
    local replace=G.PinsOn() and G.FlagSupported()
    NativeFlag(replace)
    local list=G.List(); local chosen
    for _,v in ipairs(list) do if selected==v.key then chosen=v; break end end
    chosen=chosen or Nearest(list); selected=chosen and chosen.key or nil; G.current=chosen
    local count=0
    -- With the 0.102 flag switch our skulls stand for every lair and replace the native flag.
    -- Older clients keep their native flag, so only defeated lairs get a skull there.
    if G.PinsOn() then
        for _,v in ipairs(G.List(true)) do
            -- Replacing the native flag: every lair gets a skull, empty ones grey with x from the run start.
            -- Older clients keep their flag, so there only lairs defeated in this run get one.
            local wanted=v.defeated or replace
            if wanted and v.dist then
                -- Include the small status overhang at the lower-right corner.
                local x,y,edge=N.MinimapPoint(v.east,v.north,14)
                if x then
                    local pin=Pin(count+1)
                    if pin then
                        count=count+1; pin.destination=v; pin.atEdge=edge
                        pin:ClearAllPoints(); pin:SetPoint("CENTER",Minimap,"CENTER",x,y)
                        Paint(pin,v.lair.state)
                        pin:SetAlpha(edge and .8 or 1); pin:Show()
                    end
                end
            end
        end
    end
    for i=count+1,table.getn(G.pins) do G.pins[i].destination=nil; G.pins[i]:Hide() end
    G.shownPins=count
    PlayerAbovePins(count>0)
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then selected=nil; awaitLairs=true
    elseif prefix=="AZSLAIRS" then awaitLairs=false end
end)
K.On("PLAYER_ENTERING_WORLD",function() inWorld=true; G.Update() end)
K.On("PLAYER_LEAVING_WORLD",function() inWorld=false; selected=nil; awaitLairs=true; G.Update() end)
K.On("PLAYER_LOGOUT",function() inWorld=false; selected=nil; awaitLairs=true; G.Update() end)
K.Update("guardianNav",G.Update)
