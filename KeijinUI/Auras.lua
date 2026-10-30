-- Move the native aura buttons as a group, retaining their updates and interactions.
local K=KeijinUI
local ready=false
local function Inactive() return not ready or not K.ModuleOn("units") end
local size,gap,rowHeight,columns=30,5,46,8
local container=CreateFrame("Frame","KeijinUIBuffs",UIParent)
-- Same base width as the 7 slot action bar (16+6*42+38) and the same scale rule, so both can be stacked flush.
container:SetWidth(306); container:SetHeight(rowHeight)
container:SetFrameStrata("LOW")
K.layout.Register("buffs",container,"Buffs",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12-K.PANEL_WIDTH-12,-13)   -- left of the 300 point minimap
end,{hidden=true,scale=K.CombatScale,inactive=Inactive})
container:Hide()
local entries,known,hooks={},{},{}
local busy=false
local Layout
local snapshots,skins={},{}
local function Remember(f)
    if not f or snapshots[f] then return end
    local s={parent=f:GetParent(),points=K.windowTools.Points(f),width=f:GetWidth(),height=f:GetHeight(),
        scale=f.GetScale and f:GetScale(),shown=f:IsShown()}
    snapshots[f]=s
end
local function Skin(entry)
    local button=entry.button
    if not entry.nativeSkin then
        entry.nativeSkin={backdrop=button.GetBackdrop and button:GetBackdrop(),
            color=button.GetBackdropColor and {button:GetBackdropColor()},
            border=button.GetBackdropBorderColor and {button:GetBackdropBorderColor()},
            setColor=button.SetBackdropColor,setBorder=button.SetBackdropBorderColor,chamfer=button.chamfer}
    end
    local cached=skins[button]
    if cached then
        button.chamfer=cached.shape
        button.SetBackdropColor=cached.setColor; button.SetBackdropBorderColor=cached.setBorder
        for _,t in ipairs(cached.shape.rim) do t:Show() end
    end
    local shape=K.Chamfer(button,2,{0.02,0.02,0.025,0.95})
    skins[button]={shape=shape,setColor=button.SetBackdropColor,setBorder=button.SetBackdropBorderColor}
end
local function Release()
    if busy then return end
    busy=true
    for _,entry in ipairs(entries) do
        local button=entry.button
        for script,saved in pairs(entry.scripts) do
            saved.active=false
            if button:GetScript(script)==saved.wrapper then button:SetScript(script,saved.original) end
        end
        local saved=entry.nativeSkin
        if saved then
            local skin=skins[button]
            if skin then
                for _,t in ipairs(skin.shape.back) do t:Hide() end
                for _,t in ipairs(skin.shape.rim) do t:Hide() end
            end
            button.chamfer=saved.chamfer
            button.SetBackdropColor=saved.setColor; button.SetBackdropBorderColor=saved.setBorder
            button:SetBackdrop(saved.backdrop)
            if saved.color then button:SetBackdropColor(unpack(saved.color)) end
            if saved.border then button:SetBackdropBorderColor(unpack(saved.border)) end
        end
    end
    for name,hook in pairs(hooks) do
        hook.active=false
        if getglobal(name)==hook.wrapper then setglobal(name,hook.original) end
    end
    -- Restore parents before geometry so no released button remains under our hidden container.
    for f,saved in pairs(snapshots) do
        if f:GetParent()~=saved.parent then f:SetParent(saved.parent) end
        if saved.scale then f:SetScale(saved.scale) end
        f:SetWidth(saved.width); f:SetHeight(saved.height)
        K.windowTools.Place(f,saved.points)
    end
    -- Only the border was hidden by us. Native aura visibility belongs to the game's updates.
    for _,entry in ipairs(entries) do
        local border=getglobal(entry.name.."Border")
        local saved=border and snapshots[border]
        if saved then if saved.shown then border:Show() else border:Hide() end end
    end
    entries={}; known={}; hooks={}; snapshots={}
    container:Hide()
    local e=K.layout.entries.buffs
    if e and e.handle then e.handle:Hide() end
    busy=false
end
local function NativeAnchor(frame)
    if not frame then return end
    Remember(frame)
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
    if icon then icon:ClearAllPoints(); icon:SetPoint("TOPLEFT",button,"TOPLEFT",2,-2); icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-2,2) end
    Skin(entry)
    local border=getglobal(name.."Border")
    if border then
        if border.GetVertexColor then button:SetBackdropBorderColor(border:GetVertexColor()) end
        border:Hide()
    end
    local duration=getglobal(name.."Duration")
    if duration then
        duration:ClearAllPoints(); duration:SetPoint("TOP",button,"BOTTOM",0,-1)
        duration:SetWidth(size); duration:SetHeight(12)
    end
end
local function Add(name)
    local button=getglobal(name)
    if not button or known[button] then return end
    Remember(button)
    Remember(getglobal(name.."Icon")); Remember(getglobal(name.."Duration")); Remember(getglobal(name.."Border"))
    local entry={button=button,name=name,scripts={}}; known[button]=entry; table.insert(entries,entry)
    for _,script in ipairs({"OnShow","OnHide"}) do
        local original=button:GetScript(script)
        local saved={original=original,active=true}
        saved.wrapper=function() if original then original() end; if saved.active and not Inactive() then Layout(false) end end
        entry.scripts[script]=saved
        button:SetScript(script,saved.wrapper)
    end
end
local function Hook(name,force)
    if hooks[name] then return end
    local original=getglobal(name)
    if type(original)~="function" then return end
    local hook={original=original,active=true}
    -- These stock Lua callbacks have no return values. No secure hook API is needed.
    hook.wrapper=function(a,b,c) original(a,b,c); if hook.active and not Inactive() then Layout(force) end end
    hooks[name]=hook
    setglobal(name,hook.wrapper)
end
Layout=function(force)
    if Inactive() then Release(); return end
    if busy then return end
    busy=true
    K.Shown(container,true)
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
    K.SetH(container,math.max(1,math.ceil(slot/columns))*rowHeight)
    Hook("BuffFrame_Enchant_OnUpdate",false)
    Hook("BuffButtons_UpdatePositions",true)
    Hook("UIParent_ManageFramePositions",true)
    busy=false
end
function K.SetBuffsLeft(left) K.DB().buffsLeft=left and true or nil; Layout(true) end
K.On("PLAYER_AURAS_CHANGED",function() Layout(true) end,"units")
function K.RefreshAuras() ready=true; Layout(true) end
K.On("PLAYER_ENTERING_WORLD",K.RefreshAuras)
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.RefreshAuras() end end)
K.Update("units",function() Layout(false) end)
Layout(true)
