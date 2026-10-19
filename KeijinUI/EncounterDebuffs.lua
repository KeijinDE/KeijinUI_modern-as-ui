-- Native boss/guardian effects, keyed only by spawn id. Target/nameplate UnitDebuff rows stay separate.
local K=KeijinUI
local D={height=24}
K.encounterDebuffs=D
local MAX,SIZE,STEP=8,22,25
local colors={Magic={0.25,0.55,1},Curse={0.65,0.3,0.9},Disease={0.7,0.5,0.2},Poison={0.25,0.75,0.25}}
local awaiting=false
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then awaiting=true elseif prefix=="AZSDEBUFFS" then awaiting=false end
end)
function D.Read(id,kind)
    if kind~="boss" and kind~="final" and kind~="guardian" then return {} end
    if not K.Number(id) or type(AZS_GetDebuffs)~="function" or awaiting or not K.Fresh(AZS_DEBUFFS_UPDATED) then return {} end
    local list=AZS_GetDebuffs(id)
    local out={}
    for _,v in ipairs(type(list)=="table" and list or {}) do
        if type(v)=="table" and type(v.icon)=="string" and v.icon~="" then table.insert(out,v) end
    end
    return out
end
local function Time(v)
    if v.permanent==true then return "" end
    if not K.Number(v.remaining) then return "?" end
    local seconds=math.ceil(v.remaining)
    return seconds>=60 and K.Clock(seconds) or tostring(seconds)
end
local function Detail(v)
    local text=v.name or "?"
    if K.Number(v.stacks) and v.stacks>1 then text=text.." · "..K.T("%s Stapel",v.stacks) end
    if v.permanent==true then text=text.." · "..K.T("Dauerhaft")
    elseif K.Number(v.remaining) then
        text=text.." · "..K.T("Restzeit: %s",K.Clock(v.remaining))
        if K.Number(v.duration) then text=text.." · "..K.T("Dauer: %s",K.Clock(v.duration)) end
    else text=text.." · "..K.T("Restzeit unbekannt") end
    if v.dispelType then text=text.." · "..K.T(v.dispelType) end
    return text
end
local function Tooltip(button)
    local strip=button.strip
    GameTooltip:SetOwner(button,"ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetText(strip.unitName or "?",1,0.82,0.28)
    if button.effect then GameTooltip:AddLine(Detail(button.effect),0.94,0.91,0.82,true)
    else
        for i=MAX+1,table.getn(strip.effects) do GameTooltip:AddLine(Detail(strip.effects[i]),0.94,0.91,0.82,true) end
    end
    GameTooltip:Show()
end
local function Hover(button,strip)
    button.strip=strip; button:EnableMouse(true); button:EnableMouseWheel(true)
    button:SetScript("OnEnter",function() strip.hovered=this; Tooltip(this) end)
    button:SetScript("OnLeave",function() strip.hovered=nil; GameTooltip:Hide() end)
    button:SetScript("OnMouseWheel",function()
        local handler=strip:GetParent():GetParent():GetScript("OnMouseWheel")
        if handler then handler() end
    end)
end
local function Create(parent)
    local strip=CreateFrame("Frame",nil,parent)
    strip:SetWidth(parent:GetWidth()); strip:SetHeight(SIZE)
    strip:SetPoint("TOPLEFT",parent,"BOTTOMLEFT",1,-2)
    strip:SetFrameLevel(parent:GetFrameLevel()+5)
    strip.icons={}; strip.effects={}; strip.visibleCount=0
    for i=1,MAX do
        local icon=CreateFrame("Frame",nil,strip)
        icon:SetWidth(SIZE); icon:SetHeight(SIZE); icon:SetPoint("LEFT",strip,"LEFT",(i-1)*STEP,0)
        K.Chamfer(icon,2,{0.02,0.02,0.025,0.95})
        icon.tex=icon:CreateTexture(nil,"ARTWORK"); icon.tex:SetPoint("TOPLEFT",icon,"TOPLEFT",2,-2)
        icon.tex:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",-2,2); icon.tex:SetTexCoord(0.08,0.92,0.08,0.92)
        -- Text above the texture, not on a lower parent layer.
        local overlay=CreateFrame("Frame",nil,icon); overlay:SetAllPoints(icon); overlay:SetFrameLevel(icon:GetFrameLevel()+1)
        icon.count=K.Text(overlay,"",9,"TOPRIGHT",0,0)
        icon.time=K.Text(overlay,"",9,"BOTTOM",0,0)
        Hover(icon,strip); icon:Hide(); strip.icons[i]=icon
    end
    strip.more=CreateFrame("Frame",nil,strip)
    strip.more:SetWidth(40); strip.more:SetHeight(SIZE); strip.more:SetPoint("LEFT",strip,"LEFT",MAX*STEP,0)
    strip.more.label=K.Text(strip.more,"",10,"LEFT",0,0)
    Hover(strip.more,strip); strip.more:Hide()
    return strip
end
function D.Clear(row)
    local strip=row.encounterDebuffs
    if not strip then return end
    if strip.hovered then GameTooltip:Hide(); strip.hovered=nil end
    for _,icon in ipairs(strip.icons) do icon.effect=nil; icon:Hide() end
    strip.effects={}; strip.spawnId=nil; strip.visibleCount=0; strip.unitName=nil
    strip.more:Hide(); strip:Hide()
end
function D.Draw(row,entry)
    local effects=entry.debuffs or {}
    if table.getn(effects)==0 then D.Clear(row); return end
    local strip=row.encounterDebuffs
    if not strip then strip=Create(row); row.encounterDebuffs=strip end
    if strip.spawnId~=entry.id then D.Clear(row) end
    strip.spawnId=entry.id; strip.unitName=entry.name; strip.effects=effects
    strip.visibleCount=math.min(MAX,table.getn(effects))
    for i,icon in ipairs(strip.icons) do
        local v=i<=MAX and effects[i]
        icon.effect=v
        if v then
            icon.tex:SetTexture(v.icon); icon.count:SetText(K.Number(v.stacks) and v.stacks>1 and tostring(v.stacks) or "")
            icon.time:SetText(Time(v))
            local c=colors[v.dispelType] or {0.6,0.55,0.45}
            icon:SetBackdropBorderColor(c[1],c[2],c[3],1); icon:Show()
        else icon:Hide() end
    end
    local extra=table.getn(effects)-MAX
    if extra>0 then strip.more.label:SetText("+"..extra); strip.more:Show() else strip.more:Hide() end
    strip:Show()
    if strip.hovered then
        if strip.hovered:IsShown() then Tooltip(strip.hovered) else GameTooltip:Hide(); strip.hovered=nil end
    end
end
