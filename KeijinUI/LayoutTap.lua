-- Best-effort modifier tap, Alt by default. Never captures keyboard or changes bindings.
local K=KeijinUI
local T={}
K.layoutTap=T
local candidate,started,blocked,last
local frame
function T.Get()
    local db=K.DB()
    local key=db.layoutTap
    -- Persist the result once, including explicit off. Legacy values are then inert.
    if key==nil then
        local old=db.layoutModifier
        if old=="ctrl" then key="CTRL"
        elseif old=="shift" then key="SHIFT"
        elseif old=="none" then key="off"
        else key="ALT" end
        db.layoutTap=key
    end
    if key=="ALT" or key=="CTRL" or key=="SHIFT" then return key end
    if key=="off" then return "off" end
    db.layoutTap="ALT"
    return "ALT"
end
function T.Set(key)
    K.DB().layoutTap=(key=="ALT" or key=="CTRL" or key=="SHIFT") and key or "off"
    candidate=nil; blocked=true; last=nil
    if frame then if T.Get()=="off" then frame:Hide() else frame:Show() end end
    if T.Get()~="off" and not T.watching then T.Watch(UIParent); T.watching=true end
end
local function Modifiers()
    local alt,ctrl,shift=IsAltKeyDown(),IsControlKeyDown(),IsShiftKeyDown()
    return alt,ctrl,shift,(alt and 1 or 0)+(ctrl and 1 or 0)+(shift and 1 or 0)
end
function T.Cancel()
    if T.Get()=="off" then return end
    local _,_,_,count=Modifiers()
    if candidate or count>0 then blocked=true end
end
-- Chain focus handlers: profile export still selects its code on focus.
function T.WatchEditFocus(edit,dialog)
    if edit.keijinTapFocusWatched then return end
    edit.keijinTapFocusWatched=true
    dialog=dialog or edit
    local hidden=dialog:GetScript("OnHide")
    dialog:SetScript("OnHide",function()
        edit.keijinTapFocused=nil
        if hidden then hidden() end
    end)
    local gained,lost=edit:GetScript("OnEditFocusGained"),edit:GetScript("OnEditFocusLost")
    edit:SetScript("OnEditFocusGained",function()
        edit.keijinTapFocused=true; T.Cancel()
        if gained then gained() end
    end)
    edit:SetScript("OnEditFocusLost",function()
        edit.keijinTapFocused=nil
        if lost then lost() end
    end)
end
if K.chatCopy and K.chatCopy.edit then T.WatchEditFocus(K.chatCopy.edit,K.chatCopy.panel) end
if K.collection and K.collection.search then T.WatchEditFocus(K.collection.search,K.collection.panel) end
local function Observe(frame,eventName)
    local original=frame:GetScript(eventName)
    frame.keijinTapScripts=frame.keijinTapScripts or {}
    if not original or frame.keijinTapScripts[eventName]==original then return end
    local callback=function() T.Cancel(); original() end
    frame.keijinTapScripts[eventName]=callback
    frame:SetScript(eventName,callback)
end
function T.Watch(frame,owned)
    local name=frame:GetName()
    -- A native frame can be reparented into our housing (notably ChatFrame1).
    -- Leave its scripts intact; Busy() already rejects mouse focus over it.
    if type(name)=="string" and name~="" then owned=string.sub(name,1,8)=="KeijinUI" end
    if owned then
        for _,eventName in ipairs({"OnMouseDown","OnMouseUp","OnClick","OnDragStart"}) do Observe(frame,eventName) end
    end
    for _,child in ipairs({frame:GetChildren()}) do T.Watch(child,owned) end
end
K.On("PLAYER_ENTERING_WORLD",function()
    if T.Get()=="off" then frame:Hide(); return end
    T.Cancel(); frame:Show(); T.Watch(UIParent); T.watching=true
end)
local function Busy()
    -- No reliable general combat state is exposed by this client.
    local chat=getglobal("ChatFrameEditBox") or getglobal("ChatFrame1EditBox")
    if chat and chat:IsShown() then return true end
    if K.layout.AnyMoving() or (K.layoutSizing and K.layoutSizing.Busy()) then return true end
    if K.settings and K.settings.searchFocused then return true end
    if K.settings and (K.settings.resizing or K.settings.moving) then return true end
    if K.profiles and K.profiles.dialog:IsShown() and K.profiles.edit.keijinTapFocused then return true end
    if K.chatCopy and K.chatCopy.panel:IsShown() and K.chatCopy.edit.keijinTapFocused then return true end
    if K.collection and K.collection.panel:IsShown() and K.collection.search.keijinTapFocused then return true end
    if K.shortcuts.capture:IsShown() or K.autoWalk.capture:IsShown() then return true end
    -- Hovering settings is not text input. Its click handlers still cancel chords.
    -- GetMouseFocus is not a mouse-button observer; very fast world chords can escape.
    local focus=GetMouseFocus and GetMouseFocus()
    local parent=focus
    while parent do
        if K.settings and parent==K.settings.panel then return false end
        parent=parent.GetParent and parent:GetParent()
    end
    return focus and focus~=UIParent and focus~=getglobal("WorldFrame")
end
function T.Update()
    local key=T.Get()
    if key=="off" then candidate=nil; blocked=nil; last=key; return end
    local alt,ctrl,shift,count=Modifiers()
    if last~=key then candidate=nil; blocked=count>0; last=key end
    -- Idle frame (no modifier held, no pending tap): nothing can be cancelled or fired, so Busy() is not asked.
    if count==0 and not candidate then blocked=nil; return end
    local down=(key=="ALT" and alt) or (key=="CTRL" and ctrl) or (key=="SHIFT" and shift)
    if count>1 or Busy() then T.Cancel() end
    if down and not candidate and not blocked then candidate=key; started=GetTime() end
    if candidate and not down then
        local fire=not blocked and count==0 and GetTime()-started<.4 and not Busy()
        candidate=nil
        if fire then
            K.layout.Toggle()
        end
    end
    if count==0 then blocked=nil end
end
frame=CreateFrame("Frame",nil,UIParent)
frame:SetScript("OnUpdate",T.Update)
if T.Get()=="off" then frame:Hide() end
-- Proven client events, not a complete observer of arbitrary keys or world clicks.
for _,eventName in ipairs({"ACTIONBAR_UPDATE_STATE","ACTIONBAR_UPDATE_COOLDOWN","CURRENT_SPELL_CAST_CHANGED","SPELLCAST_START","SPELLCAST_STOP","PLAYER_TARGET_CHANGED","CURSOR_UPDATE","RAID_TARGET_UPDATE"}) do
    K.On(eventName,T.Cancel)
end
