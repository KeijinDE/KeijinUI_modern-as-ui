-- Survivors proc resources, not a normal WoW casting-power bar.
-- Native active power is read directly. Never reconstruct points from combat events.
local K=KeijinUI
local R={}
K.resources=R
local PATH="Interface\\AddOns\\KeijinUI\\media\\resources\\"
local TYPES={
    ROGUE={key="seal_fate",power=3,label="Combopunkte",art="Point"},
    WARLOCK={key="soul_fire",power=0,label="Seelensplitter",art="Shard"},
    WARRIOR={key="bloodrage",power=1,label="Wut"}
}
local PHASES={playing=true,choosing=true,paused=true}
local frame=CreateFrame("Frame","KeijinUIResources",UIParent)
frame:SetWidth(146); frame:SetHeight(20); frame:SetFrameStrata("LOW"); frame:Hide()
frame:SetScale(K.CombatScale()); frame:EnableMouse(true)
R.frame=frame
local housing=CreateFrame("Frame",nil,frame)
housing:SetWidth(146); housing:SetHeight(16); housing:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-2)
K.Chamfer(housing,4,{0.07,0.07,0.085,0.96})
local icons={}
for i=1,5 do
    local icon=housing:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("CENTER",frame,"TOPLEFT",25+(i-1)*24,-10)
    icons[i]=icon
end
local rage=CreateFrame("StatusBar",nil,frame)
rage:SetPoint("TOPLEFT",frame,"TOPLEFT",7,-6); rage:SetWidth(132); rage:SetHeight(8)
rage:SetStatusBarTexture("Interface\\AddOns\\KeijinUI\\media\\FillWhite.tga")
rage:SetStatusBarColor(0.69,0.38,0.27); rage:SetMinMaxValues(0,100); rage:Hide()
local text=K.Text(rage,"",8,"CENTER",0,0)
local flash=housing:CreateTexture(nil,"OVERLAY")
flash:SetTexture(K.flat); flash:SetPoint("TOPLEFT",housing,"TOPLEFT",7,-1)
flash:SetPoint("TOPRIGHT",housing,"TOPRIGHT",-7,-1); flash:SetHeight(1); flash:SetVertexColor(0.88,0.82,0.67,1); flash:SetAlpha(0)
local inWorld=true
local glowUntil=0
local function Attached() return K.DB().resourceFree~=true end
local function Anchor(f)
    local player=K.units.player
    f:ClearAllPoints(); f:SetScale(player:GetScale())
    f:SetPoint("TOPLEFT",player,"BOTTOMLEFT",54,-4)
end
local function Detach()
    if not Attached() then return end
    local x,y=frame:GetLeft(),frame:GetTop()
    K.DB().resourceFree=true
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,y)
end
K.layout.Register("resources",frame,"Klassenressourcen",Anchor,
    {scale=K.CombatScale,hidden=true,follow=Attached,beforeMove=Detach})
local playerEntry=K.layout.entries.player
playerEntry.options.bottom=function()
    if Attached() and (frame:IsShown() or IsAltKeyDown() or K.layout.IsEditing()) then return 24 end
    return 0
end
local function Clear(reason)
    if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    frame:Hide(); R.kind=nil; R.value=nil; R.raw=nil; R.maximum=nil; R.reason=reason
    R.full=false; glowUntil=0; flash:SetAlpha(0)
    for _,icon in ipairs(icons) do icon:Hide() end
    rage:Hide(); text:SetText("")
end
local function Learned(key)
    if type(AZS_SPELLS)~="table" then return false end
    for _,spell in ipairs(AZS_SPELLS) do
        if type(spell)=="table" and spell.key==key and K.Number(spell.rank) and spell.rank>0 then return true end
    end
    return false
end
-- This mapping follows the reported Survivors mechanic: five absolute 20-unit steps.
-- Refuse ordinary mana pools / changed contracts rather than displaying fabricated points.
-- The packaged-game transitions still need runtime confirmation; /kui resources debug
-- reports exactly the native inputs without storing player data.
local function Read()
    if not inWorld then return nil,"outside world" end
    if K.DB().classResources==false then return nil,"disabled" end
    local phase=AZS_GetPhase and AZS_GetPhase() or (type(AZS_RUN)=="table" and AZS_RUN.ph)
    if not PHASES[phase] then return nil,"inactive phase" end
    if not UnitExists("player") or not UnitClass or not UnitMana or not UnitManaMax or not UnitPowerType then return nil,"native API unavailable" end
    local _,class=UnitClass("player")
    local kind=TYPES[class]
    if not kind then return nil,"class has no resource" end
    if not Learned(kind.key) then return nil,"ability not learned" end
    if UnitPowerType("player")~=kind.power then return nil,"power type mismatch" end
    local raw,max=UnitMana("player"),UnitManaMax("player")
    if not K.Number(raw) or not K.Number(max) or max<=0 or raw>max then return nil,"invalid native power" end
    if kind.art then
        if max~=100 then return nil,"point range not supported" end
        return kind,math.min(5,math.floor(raw/20)),raw,max
    end
    if max~=100 and max~=1000 then return nil,"rage range not supported" end
    return kind,math.min(100,raw/max*100),raw,max
end
function R.Update()
    local kind,value,raw,max=Read()
    if not kind then Clear(value); return end
    local changed=R.kind~=kind or R.value~=value
    local full=value>=(kind.art and 5 or 100)
    -- Only flash an observed transition, never merely a full value during initialization.
    if R.kind==kind and not R.full and full then glowUntil=GetTime()+0.15 end
    if R.kind~=kind or (R.value and value<R.value) then glowUntil=0 end
    R.kind,R.value,R.raw,R.maximum,R.reason,R.full=kind,value,raw,max,nil,full
    if Attached() then Anchor(frame) end
    if kind.art then
        rage:Hide()
        if changed then
            for i,icon in ipairs(icons) do
                icon:SetTexture(PATH..kind.art..(i<=value and "Full.tga" or "Empty.tga"))
                icon:SetWidth(kind.art=="Point" and 13.4 or 9.2)
                icon:SetHeight(kind.art=="Point" and 13.4 or 11)
                icon:Show()
            end
        end
    else
        for _,icon in ipairs(icons) do icon:Hide() end
        rage:SetValue(value); rage:Show()
        if frame:GetEffectiveScale()/UIParent:GetEffectiveScale()>=0.8 then
            text:SetText(string.format("%.0f / 100",math.floor(value))); text:Show()
        else text:Hide() end
    end
    flash:SetAlpha(GetTime()<glowUntil and 0.8 or 0)
    frame:Show()
end
function K.SetClassResources(on) K.DB().classResources=on and true or false; R.Update() end
function K.SetResourceFree(free)
    if free then Detach(); K.layout.Save("resources")
    else K.DB().resourceFree=nil; K.DB().layout.resources=nil; K.layout.Place("resources") end
    R.Update()
end
function K.ResourceDebug()
    local _,class=UnitClass("player")
    local phase=AZS_GetPhase and AZS_GetPhase() or "?"
    R.Update()
    K.Say(string.format("Resources: class %s, phase %s, type %s, native %s / %s, shown %s, reason %s",
        tostring(class),tostring(phase),tostring(UnitPowerType and UnitPowerType("player")),
        tostring(UnitMana and UnitMana("player")),tostring(UnitManaMax and UnitManaMax("player")),
        tostring(R.value),tostring(R.reason or "valid")))
end
frame:SetScript("OnEnter",function()
    if not R.kind then return end
    GameTooltip:SetOwner(this,"ANCHOR_TOP")
    GameTooltip:SetText(K.T(R.kind.label),1,0.82,0.28)
    GameTooltip:AddLine(string.format("%.0f / %d",R.value,R.kind.art and 5 or 100),0.94,0.91,0.82)
    GameTooltip:AddLine(K.T(R.kind.key=="seal_fate" and "Bei fünf Punkten wird automatisch Ausweiden ausgelöst." or
        (R.kind.key=="soul_fire" and "Bei fünf Splittern wird automatisch Seelenfeuer ausgelöst." or "Volle Wut löst automatisch Flächenschaden aus.")),0.94,0.91,0.82,true)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
for _,ev in ipairs({"UNIT_MANA","UNIT_ENERGY","UNIT_RAGE","UNIT_MAXMANA","UNIT_MAXENERGY","UNIT_MAXRAGE","UNIT_DISPLAYPOWER","PLAYER_TARGET_CHANGED"}) do
    K.On(ev,function(_,unit) if not unit or unit=="player" then R.Update() end end)
end
K.On("CHAT_MSG_ADDON",function(_,prefix) if prefix=="AZSRUN" or prefix=="AZSSPELLS" or prefix=="AZSZONE" then R.Update() end end)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.layout.Place("resources"); R.Update() end end)
K.On("PLAYER_ENTERING_WORLD",function() inWorld=true; R.Update() end)
K.On("PLAYER_LEAVING_WORLD",function() inWorld=false; Clear("outside world") end)
K.On("PLAYER_LOGOUT",function() inWorld=false; Clear("logout") end)
table.insert(K.updates,R.Update)
R.Update()
