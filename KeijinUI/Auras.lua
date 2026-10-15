-- Move the native aura buttons as a group, retaining their updates and interactions.
local K=KeijinUI
local size,gap,rowHeight,columns=30,5,46,8
local container=CreateFrame("Frame","KeijinUIBuffs",UIParent)
container:SetWidth(columns*size+(columns-1)*gap); container:SetHeight(rowHeight)
container:SetFrameStrata("LOW")
K.layout.Register("buffs",container,"Buffs",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-220,-13)
end,{hidden=true})
local entries,known,hooks={},{},{}
local busy=false
local Layout
local function NativeAnchor(frame)
    if not frame then return end
    if frame:GetParent()~=container then frame:SetParent(container); frame:SetScale(1) end
    local point,relative,other,x,y=frame:GetPoint(1)
    if frame:GetNumPoints()~=1 or point~="TOPLEFT" or relative~=container or other~="TOPLEFT" or x~=0 or y~=0 then
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",container,"TOPLEFT",0,0)
    end
end
local function Size(entry)
    local button,name=entry.button,entry.name
    button:SetScale(1); button:SetWidth(size); button:SetHeight(size)
    local icon=getglobal(name.."Icon")
    if icon then icon:ClearAllPoints(); icon:SetAllPoints(button) end
    local border=getglobal(name.."Border")
    if border then border:ClearAllPoints(); border:SetAllPoints(button) end
    local duration=getglobal(name.."Duration")
    if duration then
        duration:ClearAllPoints(); duration:SetPoint("TOP",button,"BOTTOM",0,-1)
        duration:SetWidth(size); duration:SetHeight(12)
    end
end
local function Add(name)
    local button=getglobal(name)
    if not button or known[button] then return end
    local entry={button=button,name=name}; known[button]=entry; table.insert(entries,entry)
    for _,script in ipairs({"OnShow","OnHide"}) do
        local original=button:GetScript(script)
        button:SetScript(script,function() if original then original() end; Layout(false) end)
    end
end
local function Hook(name,force)
    if hooks[name] then return end
    local original=getglobal(name)
    if type(original)~="function" then return end
    hooks[name]=true
    -- These stock Lua callbacks have no return values. No secure hook API is needed.
    setglobal(name,function(a,b,c) original(a,b,c); Layout(force) end)
end
Layout=function(force)
    if busy then return end
    busy=true
    NativeAnchor(BuffFrame); NativeAnchor(TemporaryEnchantFrame)
    for i=0,23 do Add("BuffButton"..i) end
    Add("TempEnchant1"); Add("TempEnchant2")
    -- Growth direction: right aligned (native) or left aligned, e.g. above the player frame.
    local left=K.DB().buffsLeft and true or false
    local corner=left and "TOPLEFT" or "TOPRIGHT"
    local direction=left and 1 or -1
    if container.left~=left then container.left=left; force=true end
    local slot=0
    for _,entry in ipairs(entries) do
        if entry.button:IsShown() then
            if force or entry.slot~=slot then
                Size(entry); entry.button:ClearAllPoints()
                entry.button:SetPoint(corner,container,corner,direction*math.mod(slot,columns)*(size+gap),-math.floor(slot/columns)*rowHeight)
                entry.slot=slot
            end
            slot=slot+1
        else entry.slot=nil end
    end
    container:SetHeight(math.max(1,math.ceil(slot/columns))*rowHeight)
    Hook("BuffFrame_Enchant_OnUpdate",false)
    Hook("BuffButtons_UpdatePositions",true)
    Hook("UIParent_ManageFramePositions",true)
    busy=false
end
function K.SetBuffsLeft(left) K.DB().buffsLeft=left and true or nil; Layout(true) end
K.On("PLAYER_AURAS_CHANGED",function() Layout(true) end)
K.On("PLAYER_ENTERING_WORLD",function() Layout(true) end)
table.insert(K.updates,function() Layout(false) end)
Layout(true)
