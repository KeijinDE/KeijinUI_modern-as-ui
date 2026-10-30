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
function K.chat.On() return K.ModuleOn("chat") end
panel:Hide()
K.layout.Register("chat",panel,"Chat",function(f) f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",25,78) end,
    {inactive=function() return not K.chat.On() or chat.resizing end})
-- What the native frame looked like before KeijinUI took it over (given back on logout).
local saved,watcher
local inputParts={}
local inputStyle,inputSkins=nil,{}
local wrapped={}
local function NativeHooks(enabled)
    for name,hook in pairs(wrapped) do
        local current=getglobal(name)
        if enabled and current==hook.original then setglobal(name,hook.wrapper)
        elseif not enabled and current==hook.wrapper then setglobal(name,hook.original) end
    end
end
local function Capture()
    if saved then return end
    for _,part in ipairs(inputParts) do part[2]=part[1]:GetAlpha() end
    saved={parent=chat:GetParent() or UIParent,parts={},level=chat.GetFrameLevel and chat:GetFrameLevel(),
        strata=chat.GetFrameStrata and chat:GetFrameStrata() or "BACKGROUND"}
    for _,name in ipairs({"ChatFrame1","ChatFrame1Tab","ChatFrameEditBox"}) do K.windowTools.Remember(saved.parts,getglobal(name)) end
    for _,name in ipairs({"ChatFrameMenuButton","ChatFrame1UpButton","ChatFrame1DownButton","ChatFrame1BottomButton","ChatFrame1Background"}) do
        local part=getglobal(name)
        K.windowTools.Remember(saved.parts,part)
        if part then saved.parts[part].restoreShown=part:IsShown() and true or false end
    end
end
-- Native tab and resize edges keep their own scripts, fading and lock state.
-- Only the menu/scroll buttons and background are replaced by the panel.
-- Native code may show these again; enforce visibility without changing native mouse state.
local hiddenNames={"ChatFrameMenuButton","ChatFrame1UpButton","ChatFrame1DownButton","ChatFrame1BottomButton"}
local function Mute(part,hidden)
    if not part then return end
    if hidden then
        part:SetAlpha(0); part:Hide()
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
local chatWidth,chatHeight
local personalSize=false
-- Keep the existing saved-size range, including legacy widths below the native XML
-- minimum (296). Native FloatingChatFrame.xml allows 296..608 by 75..400.
local function ValidWidth(width) return K.Number(width) and width>=200 and width<=608 end
local function ValidHeight(height) return K.Number(height) and height>=75 and height<=400 end
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
local function LoadSize()
    local size=K.DB().chatSize
    local width,height=K.PANEL_WIDTH-2*PAD,chat:GetHeight()
    personalSize=false
    if type(size)=="table" then
        if ValidWidth(size.width) then width=size.width; personalSize=true end
        if ValidHeight(size.height) then height=size.height; personalSize=true end
    end
    chatWidth,chatHeight=width,height
    chat:SetWidth(width); chat:SetHeight(height)
    sizeLoaded=true
end
local function StyleInput()
    local box=ChatFrameEditBox
    if not box then return end
    if not inputStyle then
        if saved then K.windowTools.Remember(saved.parts,box) end
        inputStyle={frame=box,backdrop=box.GetBackdrop and box:GetBackdrop(),
            color=box.GetBackdropColor and {box:GetBackdropColor()},
            border=box.GetBackdropBorderColor and {box:GetBackdropBorderColor()}}
        for _,region in ipairs({box:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType()=="Texture" then
                local path=region:GetTexture()
                if type(path)=="string" and string.find(string.lower(path),"ui%-chatinputborder") then
                    local found=false
                    for _,part in ipairs(inputParts) do if part[1]==region then found=true end end
                    if not found then table.insert(inputParts,{region,region:GetAlpha() or 1}) end
                end
            end
        end
    end
    local skin=inputSkins[box]
    if not skin then
        skin=CreateFrame("Frame",nil,box); skin:SetAllPoints(box); skin:EnableMouse(false)
        skin:SetFrameLevel(box:GetFrameLevel()); K.Skin(skin,7); inputSkins[box]=skin
    end
    -- Skin only our child: native backdrop colour methods remain untouched.
    box:SetBackdrop({}); skin:Show()
    for _,part in ipairs(inputParts) do part[1]:SetAlpha(0) end
end

local function Enforce()
    -- StartSizing controls both dimensions and anchors until FCF_StopResize.
    if not K.chat.On() or not saved or busy or chat.resizing then return end
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
    -- Native restore can set dimensions after ADDON_LOADED or ENTERING_WORLD.
    -- A saved personal size changes only on completed player resize. Without one,
    -- keep following native geometry; StartSizing always owns its live rectangle.
    if sizeLoaded and personalSize then
        if chat:GetWidth()~=chatWidth then chat:SetWidth(chatWidth) end
        if chat:GetHeight()~=chatHeight then chat:SetHeight(chatHeight) end
    elseif not sizeLoaded then chat:SetWidth(K.PANEL_WIDTH-2*PAD) end
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
        if chat:AtBottom() then K.Shown(bottom,false) else K.Shown(bottom,true) end
    end
    K.Shown(panel,true)
    busy=false
end
K.chat.Enforce=Enforce
function K.chat.Release()
    if watcher then watcher:SetScript("OnUpdate",nil) end
    NativeHooks(false)
    if not saved then panel:Hide(); grip:Hide(); return end
    K.layout.EndMove("chat")
    if chat.resizing then chat:StopMovingOrSizing(); chat.resizing=nil end
    grip:Hide()
    for _,part in ipairs(inputParts) do part[1]:SetAlpha(part[2]) end
    if inputStyle then
        local box=inputStyle.frame
        if inputSkins[box] then inputSkins[box]:Hide() end
        box:SetBackdrop(inputStyle.backdrop)
        if inputStyle.color then box:SetBackdropColor(unpack(inputStyle.color)) end
        if inputStyle.border then box:SetBackdropBorderColor(unpack(inputStyle.border)) end
        inputStyle=nil
    end
    chat:SetParent(saved.parent)
    -- The player can change chat font size while the housing is active.
    for part,state in pairs(saved.parts) do
        if state.font and part.GetFont then
            local _,size,flags=part:GetFont()
            state.font[2]=size or state.font[2]; state.font[3]=flags or state.font[3]
        end
    end
    K.windowTools.Restore(saved.parts)
    if chat.SetFrameStrata then chat:SetFrameStrata(saved.strata) end
    if saved.level then chat:SetFrameLevel(saved.level) end
    panel:Hide(); bottom:Hide(); copy:Hide()
    if K.chatCopy then K.chatCopy.panel:Hide() end
    saved=nil; sizeLoaded=false; busy=false

end
-- Native code that re-anchors the chat: run the original, then put the chat back at once.
local function Wrap(name)
    if wrapped[name] then return end
    local original=getglobal(name)
    if type(original)~="function" then return end
    local wrapper=function(a,b,c,d) original(a,b,c,d); if saved then Enforce() end end
    wrapped[name]={original=original,wrapper=wrapper}
    setglobal(name,wrapper)
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
    wrapped.FCF_Resize={original=resize,wrapper=FCF_Resize}
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
        if not ValidWidth(width) or not ValidHeight(height) then Enforce(); return end
        K.DB().chatSize={width=width,height=height}
        chatWidth,chatHeight=width,height
        personalSize=true
        -- Native resizing can move the opposite corner. Transfer that position to the panel.
        local entry=K.layout.entries.chat
        entry.dock=nil
        panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left-PAD,top+PAD)
        Enforce(); K.layout.Save("chat"); K.layout.SyncFollowers()
    end
    wrapped.FCF_StopResize={original=stopResize,wrapper=FCF_StopResize}
end
-- Direct frame:SetPoint calls cannot be wrapped, so the anchor is also checked every frame.
watcher=CreateFrame("Frame","KeijinUIChatWatch")
-- Cheap anchor check every frame; the full pass (styling, size, scroll button) on a 0.1 s tick.
local watched=0
local function Watch()
    if not saved then return end
    if chat.resizing then FollowResize(); return end
    watched=watched+(tonumber(arg1) or 0)
    local point,relative,relativePoint,x,y=chat:GetPoint(1)
    if watched>=0.1 or chat:GetParent()~=panel or chat:GetNumPoints()~=1 or point~="TOPLEFT"
        or relative~=panel or relativePoint~="TOPLEFT" or x~=PAD or y~=-PAD then
        watched=0; Enforce()
    end
end
function K.chat.Refresh()
    if K.chat.On() then
        NativeHooks(true)
        watcher:SetScript("OnUpdate",Watch)
        Capture()
        if not sizeLoaded then LoadSize() end
        copy:Show(); grip:Show(); Enforce(); K.layout.Place("chat")
    else K.chat.Release() end
    if K.ApplyFont then K.ApplyFont() end
    if K.chatCopy then K.chatCopy.Refresh() end
end
K.moduleRefresh.chat=K.chat.Refresh
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then sizeLoaded=false; K.chat.Refresh() end end)
K.On("PLAYER_ENTERING_WORLD",K.chat.Refresh)
K.On("PLAYER_LOGOUT",function() K.chat.Release() end)
K.chat.Refresh()
