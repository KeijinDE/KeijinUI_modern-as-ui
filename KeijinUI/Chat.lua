-- One chat window: the native ChatFrame1 (input, links, history stay native) sits inside a
-- KeijinUI panel that owns the position. The panel is registered with the layout, ChatFrame1 is
-- only anchored to it, so native re-anchoring (UIParent_ManageFramePositions, FCF_*) cannot move
-- the window for longer than one frame. No secure hook API is needed (not available in 1.12).
local K=KeijinUI
local PAD=7
local chat=ChatFrame1
if not chat then return end
local panel=K.Panel("KeijinUIChat","",chat:GetWidth()+2*PAD,chat:GetHeight()+2*PAD)
panel.strip:Hide(); panel.title:Hide()
K.chat={panel=panel}
K.layout.Register("chat",panel,"Chat",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",25,78) end)
-- What the native frame looked like before KeijinUI took it over (given back on logout).
local saved
local function Capture()
    if saved then return end
    local point,relative,relativePoint,x,y=chat:GetPoint()
    saved={parent=chat:GetParent() or UIParent,point=point or "BOTTOMLEFT",relative=relative or UIParent,
        relativePoint=relativePoint or "BOTTOMLEFT",x=x or 32,y=y or 85,
        strata=chat.GetFrameStrata and chat:GetFrameStrata() or "BACKGROUND"}
end
Capture()
-- Native parts replaced by the panel: tab, menu and scroll buttons, resize edges, background.
-- They are faded out and made click-through instead of hidden, because native code shows them again.
local hiddenNames={"ChatFrame1Tab","ChatFrameMenuButton","ChatFrame1UpButton","ChatFrame1DownButton",
    "ChatFrame1BottomButton","ChatFrame1ResizeTopLeft","ChatFrame1ResizeTopRight","ChatFrame1ResizeBottomLeft",
    "ChatFrame1ResizeBottomRight","ChatFrame1ResizeTop","ChatFrame1ResizeBottom","ChatFrame1ResizeLeft","ChatFrame1ResizeRight"}
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
bottom:SetWidth(18); bottom:SetHeight(18); bottom:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-4,4)
bottom:SetFrameLevel(panel:GetFrameLevel()+5)
K.Skin(bottom, 7); bottom.text=K.Text(bottom,"v",10,"CENTER",0,0)
bottom:SetScript("OnClick",function() chat:ScrollToBottom() end)
bottom:Hide()
panel:EnableMouse(true); panel:EnableMouseWheel(true)
panel:SetScript("OnMouseWheel",function()
    for _=1,3 do if arg1>0 then chat:ScrollUp() else chat:ScrollDown() end end
end)
local busy=false
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
    if busy then return end
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
    local width,height=chat:GetWidth(),chat:GetHeight()
    if K.Number(width) and K.Number(height) and width>0 and height>0 then
        if panel:GetWidth()~=width+2*PAD then panel:SetWidth(width+2*PAD) end
        if panel:GetHeight()~=height+2*PAD then panel:SetHeight(height+2*PAD) end
    end
    Style(true)
    StyleInput()
    -- The edit box is a separate UIParent frame under the chat: it follows the panel's scale.
    if ChatFrameEditBox and ChatFrameEditBox:GetScale()~=panel:GetScale() then ChatFrameEditBox:SetScale(panel:GetScale()) end
    if chat.AtBottom then
        if chat:AtBottom() then bottom:Hide() else bottom:Show() end
    end
    panel:Show()
    busy=false
end
K.chat.Enforce=Enforce
function K.chat.Release()
    if not saved then return end
    for _,part in ipairs(inputParts) do part[1]:SetAlpha(part[2]) end
    if ChatFrameEditBox and ChatFrameEditBox.chamfer then
        for _,part in ipairs(ChatFrameEditBox.chamfer.back) do part:Hide() end
        for _,part in ipairs(ChatFrameEditBox.chamfer.rim) do part:Hide() end
    end
    Style(false)
    chat:SetParent(saved.parent); chat:SetScale(1)
    chat:ClearAllPoints(); chat:SetPoint(saved.point,saved.relative,saved.relativePoint,saved.x,saved.y)
    if chat.SetFrameStrata then chat:SetFrameStrata(saved.strata) end
    if ChatFrameEditBox then ChatFrameEditBox:SetScale(1) end
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
    "FCF_DockUpdate","FCF_Set_SimpleChat","FCF_Set_NormalChat","FCF_ToggleLock","FCF_SetButtonSide","FCF_StopResize"}) do Wrap(name) end
-- Direct frame:SetPoint calls cannot be wrapped, so the anchor is also checked every frame.
local watcher=CreateFrame("Frame","KeijinUIChatWatch")
-- Cheap anchor check every frame; the full pass (styling, size, scroll button) on a 0.1 s tick.
local watched=0
watcher:SetScript("OnUpdate",function()
    if not saved then return end
    watched=watched+(tonumber(arg1) or 0)
    local point,relative,relativePoint,x,y=chat:GetPoint(1)
    if watched>=0.1 or chat:GetParent()~=panel or chat:GetNumPoints()~=1 or point~="TOPLEFT"
        or relative~=panel or relativePoint~="TOPLEFT" or x~=PAD or y~=-PAD then
        watched=0; Enforce()
    end
end)
K.On("PLAYER_ENTERING_WORLD",function() Capture(); Enforce(); K.layout.Place("chat") end)
K.On("PLAYER_LOGOUT",function() K.chat.Release() end)
Enforce()
