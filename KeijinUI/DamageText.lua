-- Floating damage numbers in the Survivor UI style: normal hits very small and white, only
-- critical hits large and yellow. The native floating text (cvar CombatDamage) cannot do this:
-- one colour per source, no size for crits (benilla combat_text/mod.rs), so Core.lua keeps it off
-- and this module draws from the same native combat messages the parser reads (CombatParser.lua).
-- Position: above the visible nameplate of the hit enemy (Nameplates.lua, K.PlateAnchor). Without
-- a plate (nameplates off, plate not on screen) the numbers rise over the screen centre, the
-- player's usual place. There is no world position in the addon API.
local K=KeijinUI
local NORMAL={size=10,r=1,g=1,b=1,life=0.8,rise=26}
local CRIT={size=26,r=1,g=0.82,b=0.1,life=1.3,rise=44}
local MAX=60
local host=CreateFrame("Frame","KeijinUIDamageText",UIParent)
host:SetFrameStrata("HIGH"); host:SetWidth(1); host:SetHeight(1)
host:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0); host:EnableMouse(false)
local active,pool={}, {}
K.damageText={active=active}
local function Take()
    local fs=table.remove(pool)
    if not fs then fs=host:CreateFontString(nil,"OVERLAY") end
    return fs
end
local function Give(item)
    item.fs:Hide(); table.insert(pool,item.fs)
end
local function Start()
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    return (w or 1024)/2+math.random(-50,50),(h or 768)/2+40+math.random(0,20)
end
-- Numbers never cover the unit frames, the skill bar or the counter row: a start point inside such
-- a frame (an enemy standing behind it) is moved up to just above its top edge, the numbers only rise.
local function KeepClear(x,y)
    local names={"KeijinUISkills","KeijinUITally"}
    local frames={K.units and K.units.player,K.units and K.units.target,getglobal(names[1]),getglobal(names[2])}
    local ui=UIParent:GetEffectiveScale()
    for _=1,3 do
        local moved
        for _,f in pairs(frames) do
            if f.IsShown and f:IsShown() and f.GetLeft and f:GetAlpha()>0 then
                local l,b,r,t=f:GetLeft(),f:GetBottom(),f:GetRight(),f:GetTop()
                local ratio=(f:GetEffectiveScale() or 1)/(ui or 1)
                if K.Number(l) and K.Number(b) and K.Number(r) and K.Number(t) then
                    l,b,r,t=l*ratio,b*ratio,r*ratio,t*ratio
                    if x>=l-12 and x<=r+12 and y>=b-14 and y<=t then y=t+6; moved=true end
                end
            end
        end
        if not moved then break end
    end
    return x,y
end
K.damageText.KeepClear=KeepClear
function K.damageText.Spawn(amount,crit,targetName)
    if K.DB().hideCombatText or not K.Number(amount) or amount<=0 then return end
    local style=crit and CRIT or NORMAL
    local x,y
    if K.PlateAnchor and targetName then x,y=K.PlateAnchor(targetName) end
    if x then x=x+math.random(-14,14) else x,y=Start() end
    x,y=KeepClear(x,y)
    if table.getn(active)>=MAX then Give(table.remove(active,1)) end
    local fs=Take()
    fs:SetFont(K.font,style.size,"OUTLINE")
    fs:SetTextColor(style.r,style.g,style.b)
    fs:SetText(string.format("%.0f",amount))
    fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",x,y)
    fs:SetAlpha(1); fs:Show()
    table.insert(active,{fs=fs,x=x,y=y,age=0,style=style,crit=crit and true or false,amount=amount})
end
local combat=CreateFrame("Frame",nil,UIParent)
for ev in pairs(K.tools.CombatEvents) do combat:RegisterEvent(ev) end
combat:SetScript("OnEvent",function()
    local hit=K.tools.ParseCombatLine(event,arg1)
    if hit and hit.kind=="damage" then K.damageText.Spawn(hit.amount,hit.critical,hit.targetName) end
end)
host:SetScript("OnUpdate",function()
    local dt=tonumber(arg1) or 0
    local i=1
    while i<=table.getn(active) do
        local item=active[i]
        item.age=item.age+dt
        local s=item.style
        if item.age>=s.life then Give(table.remove(active,i))
        else
            local t=item.age/s.life
            item.fs:ClearAllPoints()
            item.fs:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",item.x,item.y+s.rise*t)
            item.fs:SetAlpha(t<0.6 and 1 or (1-t)/0.4)
            i=i+1
        end
    end
end)
K.On("PLAYER_LEAVING_WORLD",function() while table.getn(active)>0 do Give(table.remove(active)) end end)
