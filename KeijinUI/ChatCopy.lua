local K=KeijinUI
local C={lines={}}
K.chatCopy=C
function C.Capture(text)
    if type(text)~="string" then return end
    table.insert(C.lines,text)
    while table.getn(C.lines)>300 do table.remove(C.lines,1) end
end
-- Observe the native window's actual messages without filtering or replacing them.
if ChatFrame1 and type(ChatFrame1.AddMessage)=="function" then
    local original=ChatFrame1.AddMessage
    ChatFrame1.AddMessage=function(self,text,r,g,b,id,hold)
        C.Capture(text); return original(self,text,r,g,b,id,hold)
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
    else for _,v in ipairs(C.lines) do table.insert(lines,v) end end
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
    local text=C.Text(); local _,newlines=string.gsub(text,"\n","\n")
    edit:SetText(text); edit:SetHeight(math.max(350,(newlines+2)*15)); panel:Show()
    if edit.HighlightText then edit:HighlightText() end
    if edit.SetFocus then edit:SetFocus() end
end
