local K=KeijinUI
local C={lines={}}
K.chatCopy=C
-- The game client may offer no message history (GetMessageInfo is not part of the 1.12 API), so the last 300
-- lines are kept in a ring buffer: one slot write per line, nothing is shifted or removed.
local LIMIT,head,count=300,0,0
function C.Capture(text)
    if not K.ModuleOn("chat") or type(text)~="string" then return end
    head=head+1; if head>LIMIT then head=1 end
    C.lines[head]=text
    if count<LIMIT then count=count+1 end
end
-- Observe the native window's actual messages without filtering or replacing them.
local original,wrapper
function C.Refresh()
    if not ChatFrame1 then return end
    if K.ModuleOn("chat") then
        if wrapper and ChatFrame1.AddMessage==wrapper then return end
        original=ChatFrame1.AddMessage
        if type(original)~="function" then return end
        local previous=original
        wrapper=function(self,text,r,g,b,id,hold)
            C.Capture(text); return previous(self,text,r,g,b,id,hold)
        end
        ChatFrame1.AddMessage=wrapper
    else
        if wrapper and ChatFrame1.AddMessage==wrapper then ChatFrame1.AddMessage=original end
        if C.panel then C.panel:Hide() end
    end
end
function C.Text()
    local lines={}
    if ChatFrame1 and ChatFrame1.GetNumMessages and ChatFrame1.GetMessageInfo then
        local n=ChatFrame1:GetNumMessages()
        for i=math.max(1,n-299),n do
            local text=ChatFrame1:GetMessageInfo(i)
            if type(text)=="string" then table.insert(lines,text) end
        end
    else
        local first=head-count
        for i=1,count do
            local slot=first+i; if slot<1 then slot=slot+LIMIT end
            table.insert(lines,C.lines[slot])
        end
    end
    local text=table.concat(lines,"\n")
    text=string.gsub(text,"|c%x%x%x%x%x%x%x%x",""); text=string.gsub(text,"|r","")
    text=string.gsub(text,"|H.-|h(.-)|h","%1")
    return text
end
local panel=K.Panel("KeijinUIChatCopy","Chat kopieren",640,440); C.panel=panel
panel:SetPoint("CENTER",UIParent,"CENTER",0,0); panel:SetFrameStrata("DIALOG"); panel:Hide()
table.insert(UISpecialFrames,"KeijinUIChatCopy")
-- Named: the template's OnLoad builds its child names from GetName().
local scroll=CreateFrame("ScrollFrame","KeijinUIChatCopyScroll",panel,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",panel,"TOPLEFT",14,-38); scroll:SetWidth(585); scroll:SetHeight(350)
local edit=CreateFrame("EditBox",nil,scroll); edit:SetWidth(580); edit:SetHeight(350)
K.SetFontSize(edit,11); edit:SetAutoFocus(false); K.fontStrings=K.fontStrings or {}; table.insert(K.fontStrings,{edit,11})
if edit.SetMultiLine then edit:SetMultiLine(true) end
if edit.SetMaxLetters then edit:SetMaxLetters(200000) end
scroll:SetScrollChild(edit); C.edit=edit
edit:SetScript("OnEscapePressed",function() panel:Hide() end)
K.LText(panel,"Strg+A, Strg+C zum Kopieren. Originalmeldungen bleiben im Chat.",10,"BOTTOMLEFT",14,15,590)
local close=CreateFrame("Button",nil,panel); close:SetWidth(28); close:SetHeight(24); close:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-10,-6)
K.Text(close,"×",13,"CENTER",0,0); close:SetScript("OnClick",function() panel:Hide() end)
function C.Open()
    if not K.ModuleOn("chat") then panel:Hide(); return end
    local text=C.Text(); local _,newlines=string.gsub(text,"\n","\n")
    edit:SetText(text); edit:SetHeight(math.max(350,(newlines+2)*15)); panel:Show()
    if edit.HighlightText then edit:HighlightText() end
    if edit.SetFocus then edit:SetFocus() end
end

C.Refresh()
