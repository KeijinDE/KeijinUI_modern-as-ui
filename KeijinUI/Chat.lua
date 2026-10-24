-- One chat window: the native ChatFrame1 (input, links, history stay native) sits inside a
-- KeijinUI panel that owns the position. The panel is registered with the layout, ChatFrame1 is
-- only anchored to it, so native re-anchoring (UIParent_ManageFramePositions, FCF_*) cannot move
-- the window for longer than one frame. No secure hook API is needed (not available in 1.12).
local K=KeijinUI
local PAD=7
local chat=ChatFrame1
if not chat then return end
local panel=K.Panel("KeijinUIChat","",K.PANEL_WIDTH,chat:GetHeight()+2*PAD)
panel.strip:Hide(); panel.title:Hide()
K.chat={panel=panel}
K.layout.Register("chat",panel,"Chat",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",25,78) end,
    {inactive=function() return chat.resizing end})
-- What the native frame looked like before KeijinUI took it over (given back on logout).
local saved
local function Capture()
    if saved then return end
    local point,relative,relativePoint,x,y=chat:GetPoint()
    saved={parent=chat:GetParent() or UIParent,point=point or "BOTTOMLEFT",relative=relative or UIParent,
        relativePoint=relativePoint or "BOTTOMLEFT",x=x or 32,y=y or 85,
        width=chat:GetWidth(),strata=chat.GetFrameStrata and chat:GetFrameStrata() or "BACKGROUND"}
end
Capture()
-- Native tab and resize edges keep their own scripts, fading and lock state.
-- Only the menu/scroll buttons and background are replaced by the panel.
-- They are faded out and made click-through instead of hidden, because native code shows them again.
local hiddenNames={"ChatFrameMenuButton","ChatFrame1UpButton","ChatFrame1DownButton","ChatFrame1BottomButton"}
local function Mute(part,hidden)
    if not part then return end
    if hidden then
        part:SetAlpha(0); if part.EnableMouse then part:EnableMouse(false) end
    else
        part:SetAlpha(1); if part.EnableMouse then part:EnableMouse(true) end
    end
end
local function Style(hidden)
    for _,name in ipairs(hiddenNames) do Mute(getglobal(name),hidden) end
    local background=getglobal("ChatFrame1Background")
    if background then background:SetAlpha(hidden and 0 or 1) end
end
-- Own "jump to newest" button: the native one is hidden with the others.
local bottom=CreateFrame("Button",nil,panel)
bottom:SetWidth(18); bottom:SetHeight(18); bottom:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-24,4)
bottom:SetFrameLevel(panel:GetFrameLevel()+5)
K.Skin(bottom, 7); bottom.text=K.Text(bottom,"v",10,"CENTER",0,0)
bottom:SetScript("OnClick",function() chat:ScrollToBottom() end)
bottom:Hide()
-- Small copy button in the top right corner: opens the copy window (the settings button stays as well).
local copy=CreateFrame("Button","KeijinUIChatCopyButton",panel)
copy:SetWidth(16); copy:SetHeight(16); copy:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-3,-3)
copy:SetFrameLevel(panel:GetFrameLevel()+5)
K.Skin(copy,5)
copy.back=copy:CreateTexture(nil,"OVERLAY"); copy.back:SetTexture(K.flat)
copy.back:SetWidth(6); copy.back:SetHeight(7); copy.back:SetPoint("TOPLEFT",copy,"TOPLEFT",3,-3)
copy.front=copy:CreateTexture(nil,"OVERLAY"); copy.front:SetTexture(K.flat)
copy.front:SetWidth(6); copy.front:SetHeight(7); copy.front:SetPoint("BOTTOMRIGHT",copy,"BOTTOMRIGHT",-3,3)
local function CopyColor(r,g,b) copy.back:SetVertexColor(r*.6,g*.6,b*.6,1); copy.front:SetVertexColor(r,g,b,1) end
CopyColor(.78,.69,.5)
copy:SetScript("OnClick",function() if K.chatCopy and K.chatCopy.Open then K.chatCopy.Open() end end)
copy:SetScript("OnEnter",function()
    CopyColor(1,.9,.6)
    GameTooltip:SetOwner(this,"ANCHOR_TOP"); GameTooltip:SetText(K.T("Chat kopieren"),1,.82,.28); GameTooltip:Show()
end)
copy:SetScript("OnLeave",function() CopyColor(.78,.69,.5); GameTooltip:Hide() end)
K.chat.copyButton=copy
panel:EnableMouse(true); panel:EnableMouseWheel(true)
panel:SetScript("OnMouseWheel",function()
    for _=1,3 do if arg1>0 then chat:ScrollUp() else chat:ScrollDown() end end
end)
local busy=false
local sizeLoaded=false
-- A visible grip uses the native resize lifecycle, including the chat lock.
-- Parent it to the chat: FCF_Resize/FCF_StopResize operate on this:GetParent().
local grip=CreateFrame("Button","KeijinUIChatResizeGrip",chat)
grip:SetWidth(18); grip:SetHeight(18)
grip:SetPoint("BOTTOMRIGHT",chat,"BOTTOMRIGHT",PAD-4,-PAD+4)
grip:SetFrameLevel(chat:GetFrameLevel()+5); grip:EnableMouse(true)
-- Two fine diagonal strokes sit inside the existing corner, without a second border.
local mark=grip:CreateTexture(nil,"OVERLAY")
mark:SetTexture("Interface\\AddOns\\KeijinUI\\media\\chamfer\\ChatResizeGrip.tga")
mark:SetWidth(12); mark:SetHeight(12); mark:SetPoint("BOTTOMRIGHT",grip,"BOTTOMRIGHT",-1,1)
local function GripColor(r,g,b)
    mark:SetVertexColor(r,g,b,1)
end
GripColor(.62,.57,.43)
grip:SetScript("OnEnter",function() GripColor(1,.9,.6) end)
grip:SetScript("OnLeave",function() GripColor(.62,.57,.43) end)
grip:SetScript("OnMouseDown",function()
    if saved and arg1=="LeftButton" and FCF_Resize then FCF_Resize("BOTTOMRIGHT") end
end)
grip:SetScript("OnMouseUp",function()
    if saved and arg1=="LeftButton" and chat.resizing and FCF_StopResize then FCF_StopResize() end
end)
grip:RegisterForDrag("LeftButton")
grip:SetScript("OnDragStart",function()
    if saved and not chat.resizing and FCF_Resize then FCF_Resize("BOTTOMRIGHT") end
end)
grip:SetScript("OnDragStop",function()
    if saved and chat.resizing and FCF_StopResize then FCF_StopResize() end
end)
K.chat.resizeGrip=grip
local tabScale=ChatFrame1Tab and ChatFrame1Tab:GetScale() or 1
local function LoadSize()
    local size=K.DB().chatSize
    local width,height=K.PANEL_WIDTH-2*PAD,chat:GetHeight()
    if type(size)=="table" then
        if K.Number(size.width) and size.width>=200 and size.width<=608 then width=size.width end
        if K.Number(size.height) and size.height>=75 and size.height<=400 then height=size.height end
    end
    chat:SetWidth(width); chat:SetHeight(height)
    sizeLoaded=true
end
local inputParts={}
local function StyleInput()
    if not ChatFrameEditBox then return end
    if not ChatFrameEditBox.chamfer then
        for _,region in ipairs({ChatFrameEditBox:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType()=="Texture" then
                local path=region:GetTexture()
                if type(path)=="string" and string.find(string.lower(path),"ui%-chatinputborder") then
                    table.insert(inputParts,{region,region:GetAlpha() or 1}); region:SetAlpha(0)
                end
            end
        end
        K.Skin(ChatFrameEditBox,7)
    end
end
local function Enforce()
    -- StartSizing controls both dimensions and anchors until FCF_StopResize.
    if busy or chat.resizing then return end
    busy=true
    if chat:GetParent()~=panel then chat:SetParent(panel); chat:SetScale(1) end
    local point,relative,relativePoint,x,y=chat:GetPoint(1)
    if chat:GetNumPoints()~=1 or point~="TOPLEFT" or relative~=panel or relativePoint~="TOPLEFT" or x~=PAD or y~=-PAD then
        chat:ClearAllPoints(); chat:SetPoint("TOPLEFT",panel,"TOPLEFT",PAD,-PAD)
    end
    -- The native frame is BACKGROUND strata, which would put it below the panel's own backdrop.
    if chat.GetFrameStrata and chat:GetFrameStrata()~="LOW" then chat:SetFrameStrata("LOW") end
    if chat.SetFrameLevel and chat.GetFrameLevel and chat:GetFrameLevel()<=panel:GetFrameLevel() then
        chat:SetFrameLevel(panel:GetFrameLevel()+2)
    end
    if not sizeLoaded then chat:SetWidth(K.PANEL_WIDTH-2*PAD) end
    local width=chat:GetWidth()
    local height=chat:GetHeight()
    if K.Number(height) and height>0 then
        if K.Number(width) and width>0 and panel:GetWidth()~=width+2*PAD then panel:SetWidth(width+2*PAD) end
        if panel:GetHeight()~=height+2*PAD then panel:SetHeight(height+2*PAD) end
    end
    Style(true)
    StyleInput()
    -- The edit box is a separate UIParent frame under the chat: it follows the panel's scale.
    if ChatFrameEditBox and ChatFrameEditBox:GetScale()~=panel:GetScale() then ChatFrameEditBox:SetScale(panel:GetScale()) end
    -- The native tab is also a UIParent child; match the chat's effective scale.
    if ChatFrame1Tab then ChatFrame1Tab:SetScale(panel:GetEffectiveScale()/UIParent:GetEffectiveScale()) end
    if chat.AtBottom then
        if chat:AtBottom() then bottom:Hide() else bottom:Show() end
    end
    panel:Show()
    busy=false
end
K.chat.Enforce=Enforce
function K.chat.Release()
    if not saved then return end
    if chat.resizing then chat:StopMovingOrSizing(); chat.resizing=nil end
    grip:Hide()
    for _,part in ipairs(inputParts) do part[1]:SetAlpha(part[2]) end
    if ChatFrameEditBox and ChatFrameEditBox.chamfer then
        for _,part in ipairs(ChatFrameEditBox.chamfer.back) do part:Hide() end
        for _,part in ipairs(ChatFrameEditBox.chamfer.rim) do part:Hide() end
    end
    Style(false)
    chat:SetParent(saved.parent); chat:SetScale(1); chat:SetWidth(saved.width)
    chat:ClearAllPoints(); chat:SetPoint(saved.point,saved.relative,saved.relativePoint,saved.x,saved.y)
    if chat.SetFrameStrata then chat:SetFrameStrata(saved.strata) end
    if ChatFrameEditBox then ChatFrameEditBox:SetScale(1) end
    if ChatFrame1Tab then ChatFrame1Tab:SetScale(tabScale) end
    saved=nil
end
-- Native code that re-anchors the chat: run the original, then put the chat back at once.
local wrapped={}
local function Wrap(name)
    if wrapped[name] then return end
    local original=getglobal(name)
    if type(original)~="function" then return end
    wrapped[name]=true
    setglobal(name,function(a,b,c,d) original(a,b,c,d); if saved then Enforce() end end)
end
for _,name in ipairs({"UIParent_ManageFramePositions","FCF_UpdateDockPosition","FCF_ValidateChatFramePosition",
    "FCF_DockUpdate","FCF_Set_SimpleChat","FCF_Set_NormalChat","FCF_ToggleLock","FCF_SetButtonSide"}) do Wrap(name) end
-- Anchor independently of the housing before the single native StartSizing call.
-- Reparenting/restarting an active resize can lose the mouse-release capture.
local resize=FCF_Resize
if type(resize)=="function" then
    FCF_Resize=function(anchor)
        local own=saved and this and this:GetParent()==chat
        if own then
            local left,top=chat:GetLeft(),chat:GetTop()
            chat:ClearAllPoints(); chat:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top)
        end
        resize(anchor)
        if own then
            if chat.resizing then K.layout.entries.chat.dock=nil else Enforce() end
        end
    end
end
local function FollowResize()
    local ratio=chat:GetEffectiveScale()/panel:GetEffectiveScale()
    local left,top=chat:GetLeft()*ratio,chat:GetTop()*ratio
    panel:SetWidth(chat:GetWidth()*ratio+2*PAD); panel:SetHeight(chat:GetHeight()*ratio+2*PAD)
    panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left-PAD,top+PAD)
    K.layout.SyncFollowers()
end
-- Keep the rectangle produced by any native resize edge, including top/left edges.
-- Native StopResize calls DockUpdate while resizing is still set; Enforce waits for it.
local stopResize=FCF_StopResize
if type(stopResize)=="function" then
    FCF_StopResize=function()
        local own=saved and this and this:GetParent()==chat and chat.resizing
        stopResize()
        if not own then return end
        local left,top=chat:GetLeft(),chat:GetTop()
        local width,height=chat:GetWidth(),chat:GetHeight()
        if not K.Number(width) or not K.Number(height) or width<=0 or height<=0 then return end
        K.DB().chatSize={width=width,height=height}
        -- Native resizing can move the opposite corner. Transfer that position to the panel.
        local entry=K.layout.entries.chat
        entry.dock=nil
        panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left-PAD,top+PAD)
        Enforce(); K.layout.Save("chat"); K.layout.SyncFollowers()
    end
end
-- Direct frame:SetPoint calls cannot be wrapped, so the anchor is also checked every frame.
local watcher=CreateFrame("Frame","KeijinUIChatWatch")
-- Cheap anchor check every frame; the full pass (styling, size, scroll button) on a 0.1 s tick.
local watched=0
watcher:SetScript("OnUpdate",function()
    if not saved then return end
    if chat.resizing then FollowResize(); return end
    watched=watched+(tonumber(arg1) or 0)
    local point,relative,relativePoint,x,y=chat:GetPoint(1)
    if watched>=0.1 or chat:GetParent()~=panel or chat:GetNumPoints()~=1 or point~="TOPLEFT"
        or relative~=panel or relativePoint~="TOPLEFT" or x~=PAD or y~=-PAD then
        watched=0; Enforce()
    end
end)
K.On("PLAYER_ENTERING_WORLD",function() Capture(); LoadSize(); Enforce(); grip:Show(); K.layout.Place("chat") end)
K.On("PLAYER_LOGOUT",function() K.chat.Release() end)
Enforce()
