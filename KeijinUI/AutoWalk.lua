-- Uses the client's native action and binding persistence. No keyboard/mouse
-- interception during play and no binding changes while loading the addon.
-- Evidence: benilla-ui/script/keybind.rs, benilla-app/assets/ui/KeyBindingsPage.xml.
local K=KeijinUI
local A={}
K.autoWalk=A
function A.Available()
    return type(SetBinding)=="function" and type(GetBindingAction)=="function"
        and type(GetBindingKey)=="function" and type(SaveBindings)=="function"
        and type(GetCurrentBindingSet)=="function"
end
function A.Label()
    if not A.Available() then return K.T("Nicht verfügbar") end
    local key=K.DB().autoWalkKey
    if key and K.DB().autoWalkSet==GetCurrentBindingSet() and GetBindingAction(key)=="TOGGLEAUTORUN" then return key end
    return GetBindingKey("TOGGLEAUTORUN") or K.T("Nicht belegt")
end
local function Save() SaveBindings(GetCurrentBindingSet()) end
local function Release()
    local db=K.DB()
    if db.autoWalkSet==GetCurrentBindingSet() and db.autoWalkKey and GetBindingAction(db.autoWalkKey)=="TOGGLEAUTORUN" then
        if not SetBinding(db.autoWalkKey,db.autoWalkPrevious) then return false end
    end
    db.autoWalkKey=nil; db.autoWalkPrevious=nil; db.autoWalkSet=nil
    return true
end
function A.Assign(key,replace)
    if not A.Available() then return false,"unavailable" end
    if type(key)~="string" or key=="" then return false,"invalid" end
    local old=GetBindingAction(key)
    if old~="" and old~="TOGGLEAUTORUN" and not replace then return false,old end
    if key==K.DB().autoWalkKey and K.DB().autoWalkSet==GetCurrentBindingSet() and old=="TOGGLEAUTORUN" then return true end
    -- Bind first, so an invalid key never removes the existing assignment.
    if not SetBinding(key,"TOGGLEAUTORUN") then return false,"invalid" end
    if not Release() then
        SetBinding(key,old~="" and old or nil)
        return false,"invalid"
    end
    K.DB().autoWalkKey=key; K.DB().autoWalkSet=GetCurrentBindingSet()
    K.DB().autoWalkPrevious=old~="" and old or nil
    Save(); if A.onChange then A.onChange() end; return true
end
function A.Clear()
    if not A.Available() then return end
    if Release() then Save() end
end
-- Module "Eingabehilfen" off: give the key back to the game but remember it, so switching on restores the choice.
function A.Suspend()
    if not A.Available() then return end
    local db=K.DB()
    local key=db.autoWalkKey
    if not key then return end
    if db.autoWalkSet==GetCurrentBindingSet() and GetBindingAction(key)=="TOGGLEAUTORUN" then
        if not Release() then return end
        db.autoWalkHeld=key; Save()
    else db.autoWalkHeld=key; db.autoWalkKey=nil; db.autoWalkPrevious=nil; db.autoWalkSet=nil end
end
function A.Resume()
    local key=K.DB().autoWalkHeld
    if not key or not A.Available() then return end
    K.DB().autoWalkHeld=nil
    local ok,reason=A.Assign(key,true)
    if not ok then K.DB().autoWalkHeld=(reason=="unavailable") and key or nil end
end
-- The shield captures a mouse binding regardless of where the cursor is.
-- It exists only while assigning, so a side button cannot reach the world.
local capture=CreateFrame("Frame","KeijinUIAutoWalkCapture",UIParent)
capture:SetAllPoints(UIParent); capture:SetFrameStrata("FULLSCREEN_DIALOG")
capture:EnableMouse(true); capture:EnableKeyboard(false); capture:EnableMouseWheel(true); capture:Hide()
local prompt=K.Panel("KeijinUIAutoWalkPrompt","Automatisch laufen",400,132)
prompt:SetParent(capture); prompt:SetFrameStrata("FULLSCREEN_DIALOG")
prompt:SetPoint("CENTER",capture,"CENTER",0,0); prompt:EnableMouse(false); prompt:Show()
local text=K.Text(prompt,"",11,"TOPLEFT",14,-38,372); text:SetHeight(74)
local pending
local function Finish() pending=nil; capture:EnableKeyboard(false); capture:Hide() end
local function Input(key,mouse)
    if not capture:IsShown() then return end
    if key=="ESCAPE" or (mouse and key=="LeftButton") then Finish(); return end
    local names={MiddleButton="BUTTON3",Button4="BUTTON4",Button5="BUTTON5"}
    if mouse then key=names[key] or key end
    if not key or key=="RightButton" or key=="UNKNOWN" or key=="SHIFT" or key=="CTRL" or key=="ALT" then return end
    if IsShiftKeyDown() then key="SHIFT-"..key end
    if IsControlKeyDown() then key="CTRL-"..key end
    if IsAltKeyDown() then key="ALT-"..key end
    local ok,reason=A.Assign(key,pending==key)
    if ok then Finish()
    elseif reason=="invalid" or reason=="unavailable" then text:SetText(K.T("Diese Taste kann nicht zugewiesen werden."))
    else
        pending=key
        text:SetText(K.T("%s ist bereits mit %s belegt. Zum Ersetzen dieselbe Taste erneut drücken. Escape bricht ab.",key,getglobal("BINDING_NAME_"..reason) or reason))
    end
end
capture:SetScript("OnKeyDown",function() Input(arg1,false) end)
capture:SetScript("OnMouseUp",function() Input(arg1,true) end)
capture:SetScript("OnMouseWheel",function() Input(arg1>0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN",true) end)
capture:SetScript("OnHide",function() pending=nil; capture:EnableKeyboard(false) end)
function A.Capture()
    if not A.Available() then K.Say(K.T("Nicht verfügbar")); return end
    pending=nil
    text:SetText(K.T("Taste oder Maustaste drücken, zum Beispiel Maustaste 5. Escape oder Linksklick bricht ab."))
    capture:Show(); capture:EnableKeyboard(true)
end
A.capture=capture
