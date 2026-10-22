-- Active summons of the player (Spiel 0.110, all classes): one symbol per creature kind from AZS_GetSummonGroups().
-- Count bottom right (only from 2), seconds left of the first one to go below the symbol (none for permanent ones).
-- The bar shows during a run (playing, choosing, paused); the tables keep old values outside of a run.
-- An older client without AZS_GetSummonGroups leaves the module idle without errors.
local K=KeijinUI
local S={}
K.summons=S
local SIZE,GAP,TIMEH,MAXSLOTS=34,4,13,16
local SHOWN={playing=true,choosing=true,paused=true}
local frame=CreateFrame("Frame","KeijinUISummons",UIParent)
S.frame=frame
frame:SetWidth(SIZE); frame:SetHeight(SIZE+TIMEH); frame:SetFrameStrata("LOW"); frame:SetClampedToScreen(true)
frame:Hide()
K.layout.Register("summons",frame,"Beschwörungen",function(f)
    f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",K.units.player,"TOPLEFT",0,8)
end,{hidden=true,inactive=function() return not K.ModuleOn("summons") end})
local slots={}
local function Seconds(s)
    s=math.ceil(s)
    if s>=60 then return string.format("%d:%02d",math.floor(s/60),math.mod(s,60)) end
    return string.format("%ds",s)
end
local function Tip(b)
    local g=b.group
    if not g then return end
    b.hover=true
    GameTooltip:SetOwner(b,"ANCHOR_TOP")
    GameTooltip:SetText(g.name or "?",1,0.82,0.28)
    GameTooltip:AddLine(K.T("Anzahl: %d",g.count),1,1,1)
    if g.permanent>0 then GameTooltip:AddLine(K.T("Dauerhaft: %d",g.permanent),0.94,0.91,0.82) end
    if g.temporary>0 then GameTooltip:AddLine(K.T("Zeitlich: %d",g.temporary),0.94,0.91,0.82) end
    if g.remaining then GameTooltip:AddLine(K.T("Nächste läuft ab in %s",Seconds(g.remaining)),1,0.82,0.28) end
    GameTooltip:Show()
end
local function Slot(i)
    if slots[i] then return slots[i] end
    local b=CreateFrame("Button","KeijinUISummon"..i,frame)
    b:SetWidth(SIZE); b:SetHeight(SIZE)
    b:SetPoint("TOPLEFT",frame,"TOPLEFT",(i-1)*(SIZE+GAP),0)
    K.Skin(b,4)
    b.icon=b:CreateTexture(nil,"ARTWORK")
    b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
    b.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    b.count=K.Text(b,"",12,"BOTTOMRIGHT",-3,3)
    b.left=K.Text(b,"",10,"TOP",0,-(SIZE+1))
    b.left:SetTextColor(1,0.82,0.28)
    b:SetScript("OnEnter",function() Tip(this) end)
    b:SetScript("OnLeave",function() this.hover=nil; GameTooltip:Hide() end)
    b:SetScript("OnHide",function() if this.hover then this.hover=nil; GameTooltip:Hide() end end)
    slots[i]=b
    return b
end
-- Groups to show, or nil without summons, outside of a run and without the API.
local function Groups()
    if type(AZS_GetSummonGroups)~="function" or type(AZS_GetPhase)~="function" then return nil end
    local okPhase,phase=pcall(AZS_GetPhase)
    if not okPhase or not SHOWN[phase] then return nil end
    local ok,groups=pcall(AZS_GetSummonGroups)
    if not ok or type(groups)~="table" then return nil end
    return groups
end
function S.Refresh()
    local groups=K.ModuleOn("summons") and Groups()
    local n=groups and math.min(table.getn(groups),MAXSLOTS) or 0
    for i=1,table.getn(slots) do
        if i>n then
            if slots[i].hover then slots[i].hover=nil; GameTooltip:Hide() end
            slots[i].group=nil; slots[i]:Hide()
        end
    end
    if n==0 then frame:Hide(); frame:SetWidth(SIZE); return end
    for i=1,n do
        local g=groups[i]
        local b=Slot(i)
        local count=K.Number(g.count) and g.count or 1
        local row={name=g.name,count=count,remaining=K.Number(g.remaining) and g.remaining or nil,
            permanent=K.Number(g.permanent) and g.permanent or 0,temporary=K.Number(g.temporary) and g.temporary or 0}
        b.group=row
        b.icon:SetTexture(g.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        b.count:SetText(count>=2 and tostring(count) or "")
        b.left:SetText(row.remaining and Seconds(row.remaining) or "")
        b:Show()
        if b.hover then Tip(b) end
    end
    frame:SetWidth(n*SIZE+(n-1)*GAP)
    frame:Show()
end
function S.Stop()
    for _,b in ipairs(slots) do
        if b.hover then b.hover=nil; GameTooltip:Hide() end
    end
    frame:Hide()
end
-- Driver frame: events rebuild the bar, the time left follows throttled.
local driver=CreateFrame("Frame","KeijinUISummonsDriver",UIParent)
S.driver=driver
driver:RegisterEvent("CHAT_MSG_ADDON"); driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:SetScript("OnEvent",function()
    if event=="CHAT_MSG_ADDON" and arg1~="AZSPETS" then return end
    S.Refresh()
end)
local elapsed=0
driver:SetScript("OnUpdate",function()
    elapsed=elapsed+(tonumber(arg1) or 0)
    if elapsed<0.2 then return end
    elapsed=0
    S.Refresh()
end)
