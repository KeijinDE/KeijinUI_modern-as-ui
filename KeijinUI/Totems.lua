-- Totem groups are independent of AZS_PETS. Their first expiry uses the paused run clock.
local K=KeijinUI
local T={slots={}}
K.totems=T
local frame=CreateFrame("Frame","KeijinUITotems",UIParent)
T.frame=frame
frame:SetWidth(34); frame:SetHeight(47); frame:SetFrameStrata("LOW"); frame:SetClampedToScreen(true)
K.Skin(frame,4); frame:Hide()
function T.On() return K.ModuleOn("totems") end
local function Shaman() local _,class=UnitClass("player"); return class=="SHAMAN" end
local function Available()
    if Shaman() then return true end
    -- The raw current payload is sufficient here; both public getters allocate.
    return type(AZS_TOTEMS)=="table" and table.getn(AZS_TOTEMS)>0
end
-- Layout asks this on its idle path; never allocate a new API group table there.
function T.Available() return T.available end
K.layout.Register("totems",frame,"Totems",function(f)
    K.Anchor(f,"BOTTOMLEFT",K.units.player,"TOPLEFT",0,65)
end,{hidden=true,scaleGrips=true,inactive=function() return not T.On() or not T.Available() end})
local function Text(fs,value)
    if fs.totemText~=value then fs.totemText=value; fs:SetText(value) end
end
local function Seconds(value)
    value=math.ceil(math.max(0,value))
    if value>=60 then return string.format("%d:%02d",math.floor(value/60),math.mod(value,60)) end
    return string.format("%ds",value)
end
local function Tip(b)
    local g=b.group; if not g then return end
    GameTooltip:SetOwner(b,"ANCHOR_TOP"); GameTooltip:SetText(g.name or g.key or "?",1,.82,.28)
    GameTooltip:AddLine(tostring(g.count).." / "..tostring(g.cap),1,1,1)
    if K.Number(g.remaining) then GameTooltip:AddLine(K.T("Nächste läuft ab in %s",Seconds(g.remaining)),1,.82,.28) end
    GameTooltip:Show()
end
local function Slot(i)
    if T.slots[i] then return T.slots[i] end
    local b=CreateFrame("Button","KeijinUITotem"..i,frame)
    b:SetWidth(34); b:SetHeight(34); K.Anchor(b,"TOPLEFT",frame,"TOPLEFT",(i-1)*38,0)
    K.Skin(b,4); b.layoutKey="totems"; K.ApplyWindow(b)
    b.icon=b:CreateTexture(nil,"ARTWORK")
    b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
    b.icon:SetTexCoord(.07,.93,.07,.93)
    b.count=K.Text(b,"",10,"BOTTOMRIGHT",-2,3,30); b.count:SetJustifyH("RIGHT")
    b.left=K.Text(b,"",10,"TOP",0,-35,38); b.left:SetHeight(13); b.left:SetJustifyH("CENTER"); b.left:SetTextColor(1,.82,.28)
    b:SetScript("OnEnter",function() this.hover=true; Tip(this) end)
    b:SetScript("OnLeave",function() this.hover=nil; GameTooltip:Hide() end)
    b:SetScript("OnHide",function() if this.hover then this.hover=nil; GameTooltip:Hide() end end)
    T.slots[i]=b; return b
end
local elapsed=0
local driver=CreateFrame("Frame","KeijinUITotemsDriver",UIParent)
T.driver=driver
local function Tick()
    elapsed=elapsed+(tonumber(arg1) or 0)
    if elapsed<.2 then return end
    elapsed=0
    local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase()
    if phase=="paused" or phase=="choosing" then return end
    T.Refresh()
end
function T.Refresh()
    T.phase=type(AZS_GetPhase)=="function" and AZS_GetPhase()
    T.available=Available()
    local hasData=type(AZS_TOTEMS)=="table" and table.getn(AZS_TOTEMS)>0
    if not T.On() or not T.available or (not hasData and not K.layout.Active()) then
        for _,slot in ipairs(T.slots) do slot.group=nil; K.Shown(slot,false) end
        K.Shown(frame,false)
        if driver:GetScript("OnUpdate") then driver:SetScript("OnUpdate",nil) end
        return
    end
    local groups={}
    local phase=T.phase
    local run=phase=="playing" or phase=="paused" or phase=="choosing"
    if hasData and run and type(AZS_GetTotems)=="function" then
        local ok,result=pcall(AZS_GetTotems)
        if ok and type(result)=="table" then
            for _,g in ipairs(result) do if K.Number(g.count) and g.count>0 and (not K.Number(g.remaining) or g.remaining>0) then table.insert(groups,g) end end
        end
    end
    local preview=false
    if T.On() and K.layout.Active() and T.Available() and table.getn(groups)==0 then
        preview=true
        groups={{key="searing_totem",name=K.T("Totems"),icon="Interface\\Icons\\Spell_Fire_SearingTotem",count=2,cap=3,remaining=24}}
    end
    local n=table.getn(groups)
    local ticking=false
    for i=1,n do
        local g=groups[i]; local b=Slot(i); b.group=g
        local icon=g.icon
        if type(icon)~="string" or icon=="" then icon="Interface\\Icons\\INV_Misc_QuestionMark"
        elseif not string.find(icon,"\\",1,true) and not string.find(icon,"/",1,true) then icon="Interface\\Icons\\"..icon end
        if b.texture~=icon then b.texture=icon; b.icon:SetTexture(icon) end
        Text(b.count,tostring(g.count).."/"..tostring(g.cap or "?"))
        Text(b.left,K.Number(g.remaining) and Seconds(g.remaining) or "")
        K.Shown(b,true)
        if b.hover then Tip(b) end
        if run and not preview and K.Number(g.remaining) and g.remaining>0 then ticking=true end
    end
    for i=n+1,table.getn(T.slots) do T.slots[i].group=nil; K.Shown(T.slots[i],false) end
    K.SetW(frame,math.max(34,n*38-4)); K.Shown(frame,n>0)
    local update=ticking and Tick or nil
    if driver:GetScript("OnUpdate")~=update then driver:SetScript("OnUpdate",update); elapsed=0 end
end
function T.Stop() T.Refresh() end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSTOTEMS" or prefix=="AZSZONE" or prefix=="AZSEND" then T.Refresh()
    elseif prefix=="AZSRUN" then
        -- The countdown already has a 0.2 s driver. Ordinary run/stat packets
        -- must not allocate another group list; only a phase change needs it.
        local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase()
        if phase~=T.phase then T.Refresh() end
    end
end,"totems")
K.On("PLAYER_ENTERING_WORLD",T.Refresh,"totems")
K.On("PLAYER_LEAVING_WORLD",function() driver:SetScript("OnUpdate",nil); K.Shown(frame,false) end)
-- Register through the same public module definition shape as OptionalModules.
K.modules.definitions.totems={key="totems",label="Totems",text="Totems mit Anzahl, Obergrenze und Restzeit. Position und Größe im Layoutmodus ändern.",drivers={},stop=T.Stop,resume=T.Refresh}
table.insert(K.modules.order,"totems")
