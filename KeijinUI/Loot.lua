-- The native boss loot notice is drawn outside the Lua frame layout.
-- Replace it from the game's localized self-loot chat, retaining the chat itself.
local K=KeijinUI
local notice=K.Panel("KeijinUILoot","Beute",300,76)
K.layout.Register("loot",notice,"Beutemeldung",function(f)
    -- Anchored to the run overview below the minimap, independent of the encounter group at the top.
    local relative=KeijinUITracker
    f:ClearAllPoints()
    if relative then f:SetPoint("TOPRIGHT",relative,"BOTTOMRIGHT",0,-10)
    else f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-24,40) end
end,{hidden=true})
local icon=notice:CreateTexture(nil,"ARTWORK")
icon:SetWidth(32); icon:SetHeight(32); icon:SetPoint("TOPLEFT",notice,"TOPLEFT",12,-33)
local label=K.Text(notice,"",11,"TOPLEFT",52,-32,234)
label:SetHeight(18)
local detail=K.Text(notice,"",9,"TOPLEFT",52,-51,234)
detail:SetHeight(19); detail:SetTextColor(0.72,0.7,0.64)
-- Prefixes from the installed client's localization dictionaries.
local prefixes={"You receive loot:","Du erhältst Beute:","Otrzymujesz łup:",
    "Você recebe saque:","Recibes botín:","Vous recevez du butin :","Ganimet aldın:",
    "Вы получаете добычу:","你获得了战利品：","전리품을 받았습니다:"}
local current
local function Enabled()
    return AZS_SetHudShown and AZS_IsHudShown and GetItemInfo and AZS_GetPhase and AZS_GetPhase()
end
local function Plain(text)
    text=string.gsub(text,"|c%x%x%x%x%x%x%x%x","")
    return string.gsub(text,"|r","")
end
local function Trim(text) return string.gsub(text,"^%s*(.-)%s*$","%1") end
local function Icon()
    if not current then return end
    local texture
    if current.item then
        local name,link,quality,minLevel,itemType,subType,stack,equipLoc,itemTexture=GetItemInfo(current.item)
        texture=itemTexture
        current.cached=name and true or false
        local slot=equipLoc and getglobal(equipLoc)
        if slot then notice.title:SetText(K.T("Beute").." · "..slot) end
    end
    icon:SetTexture(texture or "Interface\\Icons\\INV_Box_01")
end
local function Receive(_,message)
    if not Enabled() or type(message)~="string" then return end
    local plain=Plain(message)
    local body
    for _,prefix in ipairs(prefixes) do
        if string.sub(plain,1,string.len(prefix))==prefix then
            body=Trim(string.sub(plain,string.len(prefix)+1)); break
        end
    end
    if not body or body=="" then return end
    notice.title:SetText(K.T("Beute"))
    local first,last,item,name=string.find(message,"|H(item:[^|]+)|h(.-)|h")
    local _,_,foundColor=string.find(message,"(|c%x%x%x%x%x%x%x%x)|Hitem:")
    local suffix
    if item then
        suffix=Trim(Plain(string.sub(message,last+1)))
        label:SetText((foundColor or "")..name..(foundColor and "|r" or ""))
    else
        label:SetText(body)
        suffix=""
    end
    if suffix=="" or suffix=="." then suffix=K.T("Beute erhalten") end
    detail:SetText(suffix)
    current={item=item,message=message,expires=GetTime()+8}
    Icon()
    if not K.DB().layout.loot then K.layout.Place("loot") end
    notice:Show(); K.Native("loot",true)
end
notice:EnableMouse(true)
notice:SetScript("OnEnter",function()
    if not current then return end
    GameTooltip:SetOwner(notice,"ANCHOR_LEFT")
    if current.item and current.cached then GameTooltip:SetHyperlink(current.item)
    else GameTooltip:SetText(current.message,0.94,0.91,0.82) end
    GameTooltip:Show()
end)
notice:SetScript("OnLeave",function() GameTooltip:Hide() end)
local function Update()
    K.Native("loot",Enabled() and true or false)
    if not Enabled() or not current or GetTime()>=current.expires then
        current=nil; notice:Hide(); return
    end
    Icon()
    if not K.DB().layout.loot then K.layout.Place("loot") end
end
K.On("CHAT_MSG_LOOT",Receive)
K.On("CHAT_MSG_SYSTEM",Receive)
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then current=nil; notice:Hide() end
end)
table.insert(K.updates,Update)
Update()
