-- Assign addon actions through the same proven native binding APIs as autorun.
-- Bindings.xml supplies their bodies; no keyboard interception during play.
local K=KeijinUI
local A={}
K.shortcuts=A
A.actions={{"KEIJINUI_LAYOUT","Layout bearbeiten"},{"KEIJINUI_MARK1","Stern"},{"KEIJINUI_MARK2","Kreis"},{"KEIJINUI_MARK3","Diamant"},{"KEIJINUI_MARK4","Dreieck"},{"KEIJINUI_MARK5","Mond"},{"KEIJINUI_MARK6","Quadrat"},{"KEIJINUI_MARK7","Kreuz"},{"KEIJINUI_MARK8","Totenkopf"},{"KEIJINUI_MARK0","Entfernen"}}
local valid={}
for _,entry in ipairs(A.actions) do valid[entry[1]]=true end
function A.Available()
    return type(SetBinding)=="function" and type(GetBindingAction)=="function"
        and type(GetBindingKey)=="function" and type(SaveBindings)=="function"
        and type(GetCurrentBindingSet)=="function"
end
function A.On(action) return action=="KEIJINUI_LAYOUT" or K.ModuleOn("shortcuts") end
local function Saved()
    local db=K.DB()
    if type(db.shortcuts)~="table" then db.shortcuts={} end
    return db.shortcuts
end
function A.Label(action)
    if not A.Available() then return K.T("Nicht verfügbar") end
    local s=Saved()[action]
    if s and s.set==GetCurrentBindingSet() and GetBindingAction(s.key)==action then return s.key end
    return GetBindingKey(action) or K.T("Nicht belegt")
end
local function Release(action)
    local saved=Saved(); local s=saved[action]
    if s and s.set==GetCurrentBindingSet() and GetBindingAction(s.key)==action then
        if not SetBinding(s.key,s.previous) then return false end
    end
    saved[action]=nil; return true
end
local function Changed()
    SaveBindings(GetCurrentBindingSet())
    if A.onChange then A.onChange() end
end
function A.Assign(action,key,replace)
    if not A.On(action) then return false,"unavailable" end
    if not A.Available() then return false,"unavailable" end
    if not valid[action] or type(key)~="string" or key=="" then return false,"invalid" end
    local old=GetBindingAction(key)
    if old~="" and old~=action and not replace then return false,old end
    local current=Saved()[action]
    if current and current.key==key and current.set==GetCurrentBindingSet() and old==action then return true end
    if not SetBinding(key,action) then return false,"invalid" end
    if not Release(action) then
        SetBinding(key,old~="" and old or nil); return false,"invalid"
    end
    Saved()[action]={key=key,set=GetCurrentBindingSet(),previous=old~="" and old~=action and old or nil}
    if type(K.DB().shortcutsHeld)=="table" then K.DB().shortcutsHeld[action]=nil end
    Changed(); return true
end
function A.Clear(action)
    if type(K.DB().shortcutsHeld)=="table" then K.DB().shortcutsHeld[action]=nil end
    if A.Available() and valid[action] and Release(action) then Changed() end
end
local capture=CreateFrame("Frame","KeijinUIShortcutCapture",UIParent)
capture:SetAllPoints(UIParent); capture:SetFrameStrata("FULLSCREEN_DIALOG")
capture:EnableMouse(true); capture:EnableKeyboard(false); capture:EnableMouseWheel(true); capture:Hide()
local prompt=K.Panel("KeijinUIShortcutPrompt","KeijinUI",400,132)
prompt:SetParent(capture); prompt:SetFrameStrata("FULLSCREEN_DIALOG")
prompt:SetPoint("CENTER",capture,"CENTER",0,0); prompt:EnableMouse(false); prompt:Show()
local text=K.Text(prompt,"",11,"TOPLEFT",14,-38,372); text:SetHeight(74)
local pending,action
local function Finish() pending=nil; action=nil; capture:EnableKeyboard(false); capture:Hide() end
local function Input(key,mouse)
    if not capture:IsShown() or not action then return end
    if key=="ESCAPE" or (mouse and key=="LeftButton") then Finish(); return end
    local names={MiddleButton="BUTTON3",Button4="BUTTON4",Button5="BUTTON5"}
    if mouse then key=names[key] or key end
    if not key or key=="RightButton" or key=="UNKNOWN" or key=="SHIFT" or key=="CTRL" or key=="ALT" then return end
    if IsShiftKeyDown() then key="SHIFT-"..key end
    if IsControlKeyDown() then key="CTRL-"..key end
    if IsAltKeyDown() then key="ALT-"..key end
    local ok,reason=A.Assign(action,key,pending==key)
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
capture:SetScript("OnHide",function() pending=nil; action=nil; capture:EnableKeyboard(false) end)
function A.Capture(command)
    if K.layoutTap then K.layoutTap.Cancel() end
    if not A.On(command) then return end
    if not valid[command] then return end
    if not A.Available() then K.Say(K.T("Nicht verfügbar")); return end
    pending=nil; action=command
    prompt.title:SetText(getglobal("BINDING_NAME_"..command) or command)
    text:SetText(K.T("Taste oder Maustaste drücken, zum Beispiel Maustaste 5. Escape oder Linksklick bricht ab."))
    capture:Show(); capture:EnableKeyboard(true)
end
A.capture=capture

-- Layout is a core action and keeps its binding even with every module disabled.
function A.Refresh()
    if not K.ModuleOn("shortcuts") then capture:Hide() end
    if not A.Available() then return end
    local db=K.DB()
    if type(db.shortcutsHeld)~="table" then db.shortcutsHeld={} end
    for _,entry in ipairs(A.actions) do
        local command=entry[1]
        if command~="KEIJINUI_LAYOUT" then
            if K.ModuleOn("shortcuts") then
                local held=db.shortcutsHeld[command]
                if held and held.set==GetCurrentBindingSet() then
                    local current=GetBindingAction(held.key) or ""
                    if current==(held.previous or "") or current==command then
                        if A.Assign(command,held.key,true) then db.shortcutsHeld[command]=nil end
                    end
                end
            else
                local saved=Saved()[command]
                if saved and saved.set==GetCurrentBindingSet() then
                    local owned=GetBindingAction(saved.key)==command
                    if Release(command) and owned then db.shortcutsHeld[command]=saved; Changed() end
                end
            end
        end
    end
end
K.moduleRefresh.shortcuts=A.Refresh
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then A.Refresh() end end)
K.On("PLAYER_ENTERING_WORLD",A.Refresh)
