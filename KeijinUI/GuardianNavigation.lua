-- Small arrows in existing guardian rows; directions lead to fixed lairs, never guessed moving creatures.
local K=KeijinUI
local N=K.navigation
local G={pins={}}
K.guardianNav=G
local selected,awaitLairs -- selected: manual choice only (Select, Cycle, pin click); the automatic one is made per update
local autoKey -- key of the last automatic target, kept by the hysteresis against near ties
local inWorld=true
local PATH="Interface\\AddOns\\KeijinUI\\media\\caches\\Arrow.tga"
local rows={}
function G.On() return K.ModuleOn("guardians") and K.DB().guardianGuide~=false end
function G.PinsOn() return K.ModuleOn("guardians") and K.DB().guardianPins~=false end
function G.TimersOn() return G.PinsOn() and K.DB().guardianTimers~=false end
function G.SetTimers(on) K.DB().guardianTimers=on and true or false; G.Update() end
function G.Set(on) K.DB().guardianGuide=on and true or false; G.Update() end
function G.SetPins(on) K.DB().guardianPins=on and true or false; G.Update() end
function G.ArrowOn() return K.ModuleOn("guardians") and K.DB().guardianArrow==true end
function G.SetArrow(on) K.DB().guardianArrow=on and true or false; G.Update() end
-- Lair markers: one symbol per lair for the whole run, on the minimap and before the name in the overview.
local MEDIA="Interface\\AddOns\\KeijinUI\\media\\guardians\\"
local SKULL="Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local RAID="Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local STYLES={creatures=true,raid=true,skulls=true,seals=true,classic=true}
-- Cells of the three 128x64 atlases (left,right,top,bottom), lairs 1 to 6.
local CELLS={
    {0.015625,0.234375,0.03125,0.46875},{0.265625,0.484375,0.03125,0.46875},{0.515625,0.734375,0.03125,0.46875},
    {0.765625,0.984375,0.03125,0.46875},{0.015625,0.234375,0.53125,0.96875},{0.265625,0.484375,0.53125,0.96875},
}
local RAIDCELLS={
    {0,0.25,0,0.25},{0.25,0.5,0,0.25},{0.5,0.75,0,0.25},{0.75,1,0,0.25},{0,0.25,0.25,0.5},{0.25,0.5,0.25,0.5},
}
local SKULLTINT={
    {0.901961,0.729412,0.301961},{0.2,0.5,1},{0.8,0.474510,0.654902},
    {0.7,0.92,0.05},{0.835294,0.368627,0},{0.905882,0.913725,0.898039},
}
function G.MarkerStyle()
    local style=K.DB().guardianMarker
    if STYLES[style] then return style end
    return "skulls"
end
function G.SetMarker(style)
    K.DB().guardianMarker=STYLES[style] and style or "skulls"; G.Update()
end
-- Only minimap pins scale; the small symbols in guardian rows keep their text layout.
function G.IconScale()
    local value=tonumber(K.DB().guardianIconScale)
    if not N.Finite(value) then return 1 end
    return math.max(0.5,math.min(2,value))
end
function G.SetIconScale(value)
    value=tonumber(value)
    if not N.Finite(value) then return end
    K.DB().guardianIconScale=math.max(0.5,math.min(2,value)); G.Update()
end
-- The badge extends three points beyond the base frame. Include its diagonal reach on round maps.
local function PinInset() return math.ceil(16*G.IconScale()) end
-- The lair number is stable for the run (lair.index); only without it the list position counts.
function G.Slot(lair,position)
    local n=lair and lair.index
    if not K.Number(n) or n<1 then n=position end
    if not K.Number(n) or n<1 then n=1 end
    return math.mod(math.floor(n)-1,6)+1
end
-- Paints the symbol of one lair into icon (and digit, only used by the skull style) for its state.
-- Badges for "!" and "x" belong to the minimap pin and are set there.
function G.ApplyMarker(icon,digit,slot,state)
    local style=G.MarkerStyle()
    local empty=state=="empty"
    if not CELLS[slot] then slot=1 end
    if digit then digit:Hide() end
    if style=="classic" then
        icon:SetTexture(SKULL); icon:SetTexCoord(0,1,0,1)
        if empty then icon:SetVertexColor(.55,.55,.55,.75)
        elseif state=="awake" then icon:SetVertexColor(1,.45,.16,1)
        else icon:SetVertexColor(1,.82,.28,1) end
        return style
    end
    local cell=CELLS[slot]
    if style=="raid" then
        cell=RAIDCELLS[slot]; icon:SetTexture(RAID)
        if empty then icon:SetVertexColor(.65,.65,.65,.9) else icon:SetVertexColor(1,1,1,1) end
    elseif style=="skulls" then
        local tint=SKULLTINT[slot]
        icon:SetTexture(SKULL)
        if empty then icon:SetVertexColor(tint[1]*.65,tint[2]*.65,tint[3]*.65,.9) else icon:SetVertexColor(tint[1],tint[2],tint[3],1) end
    elseif style=="seals" then
        icon:SetTexture(MEDIA.."GuardianSeals.tga")
        if empty then icon:SetVertexColor(.75,.75,.75,1) else icon:SetVertexColor(1,1,1,1) end
    else
        icon:SetTexture(MEDIA.."GuardianCreatures.tga")
        if empty then icon:SetVertexColor(.65,.65,.65,.9) else icon:SetVertexColor(1,1,1,1) end
    end
    if style=="skulls" then
        icon:SetTexCoord(0,1,0,1)
        if digit then
            digit:SetTexture(MEDIA.."GuardianDigits.tga"); digit:SetTexCoord(CELLS[slot][1],CELLS[slot][2],CELLS[slot][3],CELLS[slot][4])
            if empty then digit:SetVertexColor(.65,.65,.65,.9) else digit:SetVertexColor(1,1,1,1) end
            digit:Show()
        end
    else icon:SetTexCoord(cell[1],cell[2],cell[3],cell[4]) end
    return style
end
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
    if runStamp~=AZS_ZONE_UPDATED then runStamp=AZS_ZONE_UPDATED; seenAlive={}; selected=nil; autoKey=nil end
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
-- Health share of a fighting guardian, same lookup as Unit/Health in Guardians.lua (not exported there):
-- unit of AZS_UNITS by lair id, units from the run before do not count. nil without a value.
local function Share(lair)
    if type(AZS_UNITS)~="table" or not K.Fresh(AZS_UNITS_UPDATED) then return nil end
    if not K.Number(lair.id) or lair.id==0 then return nil end
    for _,u in ipairs(AZS_UNITS) do
        if u.kind=="guardian" and u.id==lair.id then
            if K.Number(u.hp) and K.Number(u.hpm) and u.hpm>0 then return u.hp/u.hpm end
            return nil
        end
    end
end
local function Closer(a,b)
    return a.dist and (not b.dist or a.dist<b.dist)
end
-- Automatic target: the fighting guardian with the least health (without a value after those with one,
-- ties by distance); nobody fighting means the nearest lair. Without a fight the previous automatic target
-- stays until another one is at least 10 yards or 10 percent (the larger) nearer, so equal distances do not flip it.
local function Pick(list)
    local best,bestShare
    for _,v in ipairs(list) do
        if v.lair.state=="awake" then
            local share=Share(v.lair)
            local better=not best
            if best and share and (not bestShare or share<bestShare) then better=true
            elseif best and share==bestShare and Closer(v,best) then better=true end
            if better then best,bestShare=v,share end
        end
    end
    if best then return best,true end
    return Nearest(list),false
end
local function Automatic(list)
    local best,fighting=Pick(list)
    if best and not fighting and autoKey and best.key~=autoKey then
        for _,v in ipairs(list) do
            if v.key==autoKey and v.dist and best.dist and v.dist-best.dist<math.max(10,v.dist*.1) then best=v; break end
        end
    end
    autoKey=best and best.key
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
    local shown=G.current and G.current.key
    for i,v in ipairs(list) do if v.key==shown then index=i; break end end
    index=math.mod(index-1+(step or 1)+count,count)+1
    selected=list[index].key; G.Update()
end
-- A click on the guardian already chosen by hand gives the choice back to the automatic target.
function G.Click(index)
    local current=G.current
    if selected and current and current.key==selected and (current.index==index or current.lair.index==index) then
        selected=nil; autoKey=nil; G.Update(); return true
    end
    return G.Select(index)
end
function G.Nearest() selected=nil; autoKey=nil; G.Update() end
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
    -- The lair symbol (14 px plus 3 px gap) pushes name and arrow right; the status column stays where it is.
    local marked=row:IsShown() and row.lair and G.PinsOn()
    local offset=marked and 17 or 0
    if marked then
        if not row.marker then
            row.marker=row:CreateTexture(nil,"ARTWORK"); row.marker:SetWidth(14); row.marker:SetHeight(14)
            row.marker:SetPoint("LEFT",row,"LEFT",0,0)
            row.markerDigit=row:CreateTexture(nil,"ARTWORK"); row.markerDigit:SetWidth(14); row.markerDigit:SetHeight(14)
            row.markerDigit:SetPoint("LEFT",row,"LEFT",0,0)
        end
        G.ApplyMarker(row.marker,row.markerDigit,G.Slot(row.lair,row.position),row.lair.state)
        row.marker:Show()
    elseif row.marker then row.marker:Hide(); row.markerDigit:Hide() end
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT",row,"LEFT",offset,0)
    row.name:SetWidth((visible and 133 or 150)-offset)
    if visible then
        local width=math.min(133-offset,row.name:GetStringWidth())
        row.direction:ClearAllPoints(); row.direction:SetPoint("LEFT",row,"LEFT",offset+width+3,0)
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
            if G.current and G.current.key==v.key and selected==v.key then GameTooltip:AddLine(K.T("Erneut klicken: automatisch"),.7,.7,.7,true) end
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
-- Dimmer at the minimap border, faded under the player arrow in the centre (N.CenterFade).
local function Fade(pin,x,y,edge)
    local alpha=(edge and .8 or 1)*N.CenterFade(x,y,pin:GetWidth()/2)
    if alpha~=pin.fade then pin.fade=alpha; pin:SetAlpha(alpha) end
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
        pin.icon:SetTexture(SKULL)
        -- Number plate of the skull style: same place as the symbol, above it, below the badge frame.
        pin.digit=pin:CreateTexture(nil,"ARTWORK"); pin.digit:SetWidth(14); pin.digit:SetHeight(14)
        pin.digit:SetPoint("CENTER",pin,"CENTER",0,0); pin.digit:Hide()
        pin.timer=K.Text(pin,"",10,"TOP",0,-18,48)
        pin.timer:ClearAllPoints(); pin.timer:SetPoint("TOP",pin,"BOTTOM",0,1)
        pin.timer:SetJustifyH("CENTER"); pin.timer:SetHeight(14)
        pin.badge=CreateFrame("Frame",nil,pin); pin.badge:SetAllPoints(pin); pin.badge:SetFrameLevel(pin:GetFrameLevel()+1)
        -- Tiny FontStrings are clipped/wrapped by this client. Draw one complete transparent
        -- symbol instead, straddling the lower-right corner rather than floating beside it.
        pin.badge.mark=pin.badge:CreateTexture(nil,"OVERLAY")
        pin.badge.mark:SetWidth(8); pin.badge.mark:SetHeight(8)
        pin.badge.mark:SetPoint("CENTER",pin,"BOTTOMRIGHT",-1,1)
        pin:SetScript("OnClick",function() if this.destination and this.destination.lair.state~="empty" then G.Click(this.destination.lair.index or this.destination.index) end end)
        pin:SetScript("OnEnter",function() Tip(this.destination,this) end)
        pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
        pin:SetScript("OnHide",function() if GameTooltip.GetOwner and GameTooltip:GetOwner()==this then GameTooltip:Hide() end end)
        pin:EnableMouseWheel(true)
        pin:SetScript("OnMouseWheel",function() local f=Minimap:GetScript("OnMouseWheel"); if f then f() end end)
        G.pins[i]=pin
    end
    local scale=G.IconScale()
    if pin.iconScale~=scale then
        pin.iconScale=scale
        pin:SetWidth(16*scale); pin:SetHeight(16*scale)
        K.Chamfer(pin,3*scale,{.035,.035,.045,1},{.62,.57,.43,1})
        pin.icon:SetWidth(14*scale); pin.icon:SetHeight(14*scale)
        pin.digit:SetWidth(14*scale); pin.digit:SetHeight(14*scale)
        pin.badge.mark:SetWidth(8*scale); pin.badge.mark:SetHeight(8*scale)
        pin.badge.mark:ClearAllPoints()
        pin.badge.mark:SetPoint("CENTER",pin,"BOTTOMRIGHT",-scale,scale)
        pin.glideX=nil; pin.boxed=nil
    end
    return pin
end
-- The symbol of the lair (see G.ApplyMarker), "!" in combat, darker with "x" once empty.
local function Paint(pin,state,slot)
    pin.state=state
    -- Raid markers stand on their own; every other style keeps its dark plate with rim.
    local boxed=G.ApplyMarker(pin.icon,pin.digit,slot,state)~="raid"
    if pin.boxed~=boxed then
        pin.boxed=boxed
        for _,t in ipairs(pin.chamfer.back) do if boxed then t:Show() else t:Hide() end end
        for _,t in ipairs(pin.chamfer.rim) do if boxed then t:Show() else t:Hide() end end
    end
    if state=="empty" then
        pin.badge.mark:SetTexture(MEDIA.."GuardianEmpty.tga")
        pin.badge.mark:SetVertexColor(.85,.85,.85,1); pin.badge:Show()
    elseif state=="awake" then
        pin.badge.mark:SetTexture(MEDIA.."GuardianCombat.tga")
        pin.badge.mark:SetVertexColor(1,.7,.3,1); pin.badge:Show()
    else pin.badge:Hide() end
end
-- Every frame: the shown pins follow the smooth player position (sx, sy). Each pin keeps the offset the tick gave
-- it relative to the raw position of that tick; the clamp at the border is the same as in the tick.
function G.Glide(sx,sy)
    local count,px,py=G.shownPins,G.glideX,G.glideY
    if not count or count<1 or not px or not inWorld or not Minimap or not K.ModuleOn("guardians") or not G.PinsOn() then return end
    local diameter=K.caches and K.caches.Diameter()
    if not diameter or diameter<=0 then return end
    local width,height=Minimap:GetWidth(),Minimap:GetHeight()
    local square=K.MinimapStyled and K.MinimapStyled()
    local dx,dy=sx-px,sy-py
    for i=1,count do
        local pin=G.pins[i]
        local v=pin and pin.destination
        if v and v.source=="world" and pin:IsShown() then
            local x,y,edge=N.Project(v.east+dy,v.north-dx,PinInset(),width,height,diameter,square)
            if not pin.glideX or math.abs(pin.glideX-x)>=0.01 or math.abs(pin.glideY-y)>=0.01 then
                pin.glideX,pin.glideY=x,y
                pin:ClearAllPoints(); pin:SetPoint("CENTER",Minimap,"CENTER",x,y)
            end
            pin.atEdge=edge; Fade(pin,x,y,edge)
        end
    end
end
-- Independent layout entry. The inactive predicate gives this entry to the guardians module
-- without adding another module or changing Layout.lua's frozen owner list.
local arrow=CreateFrame("Frame","KeijinUIGuardianArrow",UIParent)
N.Hex(arrow,"Guardian")
arrow.digit=arrow:CreateTexture(nil,"OVERLAY"); arrow.digit:SetWidth(22); arrow.digit:SetHeight(22)
arrow.digit:SetPoint("TOP",arrow,"TOP",0,-19)
local arrowOptions={hidden=false,inactive=function() return not K.ModuleOn("guardians") end}
K.layout.Register("guardianarrow",arrow,"Hort Pfeil",function(f)
    -- New defaults follow the existing cache position, including its personal scale.
    -- Never save this initial placement or overwrite either saved layout entry.
    local cache=K.caches.arrow
    local ratio=cache:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local left,top=cache:GetLeft(),cache:GetTop()
    left=N.Finite(left) and left*ratio or (K.UIWidth()-96)/2
    top=N.Finite(top) and top*ratio or K.UIHeight()-170
    local x=left+cache:GetWidth()*ratio+20
    if x+96>K.UIWidth() then x=left-116 end
    if x<0 then
        x=math.max(0,math.min(K.UIWidth()-96,left))
        local below=top-cache:GetHeight()*ratio-20
        if below>=92 then top=below else top=math.min(K.UIHeight(),top+112) end
    end
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,top)
end,arrowOptions)
G.arrow=arrow
local arrowModuleOn
local function ScreenArrow(chosen)
    arrowOptions.hidden=G.ArrowOn()
    if not G.ArrowOn() or not inWorld or not N.ScreenFresh() or not chosen or not chosen.dist then
        arrow.destination=nil; K.Shown(arrow,false); return
    end
    local slot=G.Slot(chosen.lair,chosen.index)
    local tint=SKULLTINT[slot]
    arrow.icon:SetVertexColor(tint[1],tint[2],tint[3],1)
    arrow.digit:SetTexture(MEDIA.."GuardianDigits.tga")
    local cell=CELLS[slot]; arrow.digit:SetTexCoord(cell[1],cell[2],cell[3],cell[4])
    local facing,source=N.Facing()
    arrow.step=N.HexDirection(arrow,chosen.east,chosen.north,facing,source)
    arrow.distance:SetText(K.T("%d Yards",math.floor(chosen.dist+.5)))
    local text,r,g,b=K.guardians.Status(chosen.lair)
    arrow.price:SetText(text); arrow.price:SetTextColor(r,g,b)
    arrow.destination=chosen; arrow:Show()
end
function G.Update()
    local moduleOn=K.ModuleOn("guardians")
    if moduleOn and not arrowModuleOn then K.layout.Place("guardianarrow") end
    arrowModuleOn=moduleOn
    G.glideX,G.glideY=nil,nil
    for row in pairs(rows) do G.Decorate(row) end
    if not inWorld or (not G.On() and not G.PinsOn() and not G.ArrowOn()) then
        G.current=nil; G.shownPins=0
        for _,pin in ipairs(G.pins) do pin.destination=nil; pin:Hide() end
        NativeFlag(false)
        ScreenArrow(nil)
        return
    end
    -- Even with no lair snapshot yet the native flag is ours to suppress. After leaving
    -- the world the early return above prevents later ticks from taking it over again.
    local replace=G.PinsOn() and G.FlagSupported()
    NativeFlag(replace)
    local tickX,tickY=N.WorldPosition()
    local list=G.List(); local chosen
    for _,v in ipairs(list) do if selected==v.key then chosen=v; break end end
    if not chosen then selected=nil; chosen=Automatic(list) end
    G.current=chosen
    ScreenArrow(chosen)
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
                local x,y,edge=N.MinimapPoint(v.east,v.north,PinInset())
                if x then
                    local pin=Pin(count+1)
                    if pin then
                        count=count+1; pin.destination=v; pin.atEdge=edge
                        pin:ClearAllPoints(); pin:SetPoint("CENTER",Minimap,"CENTER",x,y)
                        pin.glideX=nil
                        Paint(pin,v.lair.state,G.Slot(v.lair,v.index))
                        pin.timer:SetText(G.TimersOn() and K.guardians.Countdown(v.lair) or "")
                        Fade(pin,x,y,edge); pin:Show()
                    end
                end
            end
        end
    end
    for i=count+1,table.getn(G.pins) do G.pins[i].destination=nil; G.pins[i]:Hide() end
    G.shownPins=count
    -- The offsets of the pins are relative to the raw position of this tick; the glide shifts them every frame.
    if count>0 and tickX~=nil then
        G.glideX,G.glideY=tickX,tickY
        local sx,sy=N.SmoothPosition()
        if sx then G.Glide(sx,sy) end
    end
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then selected=nil; autoKey=nil; awaitLairs=true; G.Update()
    elseif prefix=="AZSLAIRS" then awaitLairs=false end
end)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.layout.Place("guardianarrow") end end)
K.On("PLAYER_ENTERING_WORLD",function() inWorld=true; G.Update() end)
K.On("PLAYER_LEAVING_WORLD",function() inWorld=false; selected=nil; autoKey=nil; awaitLairs=true; G.Update() end)
K.On("PLAYER_LOGOUT",function() inWorld=false; selected=nil; awaitLairs=true; G.Update() end)
K.Update("guardians",G.Update)
