-- Fixed-origin pointer tracking instead of StartSizing: panel heights are row based.
-- API evidence: FrameXML/FloatingChatFrame.lua:600,853; ChatFrame.xml:103-108.
local K=KeijinUI
local L,P=K.layout,K.panelSizing
local S={}
K.layoutSizing=S
local drag,pending,editor
local function Finite(n) return type(n)=="number" and n==n and math.abs(n)<1e15 end
local function Ratio(f)
    local a,b=f:GetEffectiveScale(),UIParent:GetEffectiveScale()
    if Finite(a) and Finite(b) and b>0 then return a/b end
    return 1
end
-- The client returns nil from GetLeft/GetBottom/GetRight/GetTop while a frame has no
-- resolved position (hidden, or right after SetPoint before the layout pass).
local function Rect(f)
    local l,b,r,t=f:GetLeft(),f:GetBottom(),f:GetRight(),f:GetTop()
    if not (Finite(l) and Finite(b) and Finite(r) and Finite(t)) then return end
    local q=Ratio(f)
    return l*q,b*q,r*q,t*q
end
-- The handle depends on this same anchor and may still hold last frame's geometry.
-- Only the window's resolved rectangle is authoritative.
local function FrameRect(e)
    return Rect(e.frame)
end
local function Bound(n,lo,hi) return math.max(lo,math.min(hi,n)) end
local function Copy(c) return {width=c.width,rows=c.rows,font=c.font} end
local function Number(s)
    local n=tonumber(s)
    if n and n==n and math.abs(n)<1e15 then return n end
end
local function Allowed(e)
    return e and e.handle:IsShown() and L.Active() and not (e.options.locked and e.options.locked())
end
local function RefreshSettings()
    if K.settings and K.settings.panel and K.settings.panel:IsShown() then K.settings.Refresh() end
end
local function Position(e,left,top)
    local f=e.frame; local q=Ratio(f)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/q,top/q)
end
-- Values shown to the user: the saved (P.Config) or effective setting, whole numbers within the
-- same limits P.Set enforces. Height is the rendered height; rows are the rows actually visible.
local function Visible(key)
    local c=P.Config(key); local counts=P.counts[key]
    return counts and counts[2] or c.rows or P.Maximum(key), counts and counts[1]
end
local function Values(key)
    local width,font=P.Values(key)
    local f=P.entries[key].frame
    local rows,total=Visible(key)
    return math.floor(width+.5),rows,math.floor(font+.5),math.floor((f:GetHeight() or 0)+.5),total
end
-- Only the moving edge snaps. Applying Layout.Snap would move the fixed edge.
function S.Snap(value,vertical,e)
    if K.DB().snap==false or IsShiftKeyDown() then return value end
    local size=vertical and K.UIHeight() or K.UIWidth()
    local cx,cy=UIParent:GetCenter()
    local middle=Number(vertical and cy or cx) or size/2
    local targets={0,size,middle}
    for _,other in pairs(L.entries) do
        if other~=e and other.frame:IsShown() then
            local l,b,r,t=Rect(other.frame)
            if l then table.insert(targets,vertical and b or l); table.insert(targets,vertical and t or r) end
        end
    end
    local best
    for _,target in ipairs(targets) do
        local delta=target-value
        if math.abs(delta)<=10 and (not best or math.abs(delta)<math.abs(best)) then best=delta end
    end
    if best then return value+best end
    local grid=middle+math.floor((value-middle)/32+.5)*32
    if math.abs(grid-value)<=10 then return grid end
    return value
end
local readout=CreateFrame("Frame","KeijinUILayoutSizeReadout",UIParent)
readout:SetFrameStrata("TOOLTIP"); readout:SetFrameLevel(230)
readout:SetWidth(300); readout:SetHeight(30); readout:EnableMouse(false)
K.Chamfer(readout,4,{.04,.06,.07,1},{.8,.66,.3,1})
readout.text=K.Text(readout,"",11,"CENTER",0,0); readout:Hide()
function S.AtMaximum(key,rows,total)
    return rows>=P.Maximum(key)
end
function S.Readout(e)
    local width,rows,_,height,total=Values(e.key)
    local text=((drag and drag.limit=="max.") or S.AtMaximum(e.key,rows,total)) and "Breite %d · Höhe %d (%d Zeilen, max.)" or "Breite %d · Höhe %d (%d Zeilen)"
    local label=string.format(K.T(text),width,height,rows)
    if rows<=1 or (drag and drag.limit=="min.") then label=string.gsub(label,"%)$",", min.)") end
    readout.text:SetText(label)
    local l,b,r,t=FrameRect(e)
    if not l then return end -- no Hide here: OnHide ends the drag
    local x=Bound(l,0,math.max(0,K.UIWidth()-300))
    local y=t+34
    if y>K.UIHeight() then y=math.max(30,b-4) end
    readout:ClearAllPoints(); readout:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,y); readout:Show()
end
function S.Finish()
    pending=nil
    if not drag then return end
    local e=drag.entry
    e.sizing=nil
    -- Nothing was applied (no valid step before release): leave saved values and dock alone.
    if drag.stepped then L.Save(e.key); L.SyncFollowers() end
    drag=nil; readout:Hide(); RefreshSettings()
end
local function Start(e,edge,x,y,l,b,r,t)
    S.Finish(); L.EndMove(e.key)
    if editor then editor:Hide() end
    local key=e.key
    local _,rows=Values(key)
    -- The drag measures against the rendered width, not the saved one (minimum width may apply).
    local width=math.floor((e.frame:GetWidth() or 0)+.5)
    local _,step=P.Metrics(key,key=="tracker" and 18 or 20)
    drag={entry=e,edge=edge,x=x,y=y,left=l,bottom=b,right=r,top=t,
        width=width,rows=rows,height=e.frame:GetHeight(),step=step,custom=P.Custom(key),scale=e.frame:GetEffectiveScale(),q=Ratio(e.frame),accepted=Copy(P.Config(key)),
        screenWidth=K.UIWidth(),screenHeight=K.UIHeight()}
    e.sizing=true
    S.Readout(e)
end
function S.Busy() return drag or pending or (editor and editor:IsShown() and editor.inputFocused) end
function S.Begin(key,edge)
    if K.layoutTap then K.layoutTap.Cancel() end
    local e=L.entries[key]
    if not Allowed(e) or not P.entries[key] or not P.On(key) then return end
    if edge~="LEFT" and edge~="RIGHT" and edge~="TOP" and edge~="BOTTOM" then return end
    local x,y=GetCursorPosition()
    local l,b,r,t=FrameRect(e)
    if not l then
        -- The client resolves a position often one frame after Show/SetPoint: wait for it
        -- while the button is held. Released unresolved, the drag ends without any change.
        S.Finish(); pending={entry=e,edge=edge,x=x,y=y}
        return
    end
    Start(e,edge,x,y,l,b,r,t)
end
function S.Track()
    local p=pending
    if p then
        local e=p.entry
        if not Allowed(e) or not P.On(e.key) then pending=nil; return end
        local l,b,r,t=FrameRect(e)
        if not l then return end
        pending=nil; Start(e,p.edge,p.x,p.y,l,b,r,t)
    end
    local d=drag
    if not d then return end
    local e=d.entry; local f=e.frame
    if not Allowed(e) or not P.On(e.key) or f:GetEffectiveScale()~=d.scale
        or K.UIWidth()~=d.screenWidth or K.UIHeight()~=d.screenHeight then S.Finish(); return end
    local x,y=GetCursorPosition()
    if x==d.lastX and y==d.lastY and f:GetWidth()==d.lastWidth and f:GetHeight()==d.lastHeight then return end
    local dx,dy=(x-d.x)/UIParent:GetEffectiveScale(),(y-d.y)/UIParent:GetEffectiveScale()
    local horizontal=d.edge=="LEFT" or d.edge=="RIGHT"
    if math.abs(horizontal and dx or dy)<1 and not d.changed then return end
    -- Skip the whole step while the window or its dock target has no resolved rectangle:
    -- nothing (including e.dock) is touched and the step is retried on the next update.
    if not FrameRect(e) then return end
    local target=e.dock and L.entries[e.dock.target]
    local tl=target and Rect(target.frame)
    if target and not tl then return end
    local oldWidth,oldHeight=f:GetWidth(),f:GetHeight()
    d.limit=nil
    if horizontal then
        local edge=d.edge=="LEFT" and d.left+dx or d.right+dx
        edge=S.Snap(edge,false,e)
        local room=math.min(K.UIWidth()-16,d.edge=="LEFT" and d.right or K.UIWidth()-d.left)
        local width=(d.edge=="LEFT" and d.right-edge or edge-d.left)/d.q
        width=math.floor(Bound(width,180,math.min(1200,math.max(180,room/d.q)))+.5)
        if width~=d.width or d.changed then P.Set(e.key,"width",width,true) end
    else
        local edge=d.edge=="TOP" and d.top+dy or d.bottom+dy
        -- Vertical sizing snaps to whole rendered rows, not pixel targets.
        local height=(d.edge=="TOP" and edge-d.bottom or d.top-edge)/d.q
        local rows
        if not d.custom then
            -- Legacy row pitches differ. Resolve the custom fixed header first,
            -- then snap the requested physical height instead of adding legacy rows.
            P.Set(e.key,"rows",d.rows,true)
            rows=P.HeightRows(e.key,height)
        else rows=Bound(math.floor(d.rows+(height-d.height)/d.step+.5),1,P.Maximum(e.key)) end
        if rows~=d.rows or d.changed then P.Set(e.key,"rows",rows,true) end
        -- Use the rendered height, including tracker clock, pace and guardians.
        local room=math.min(K.UIHeight()-16,d.edge=="TOP" and K.UIHeight()-d.bottom or d.top)
        local wanted=rows
        while rows>1 and f:GetHeight()*d.q>room+.1 do rows=rows-1; P.Set(e.key,"rows",rows,true) end
        if rows<wanted then d.limit="max." end
        -- Some legacy empty frames are shorter than the new one-row minimum.
        -- Before the first accepted conversion, pulling inward must stop there.
        -- Once converted, reversal must reach the new one-row minimum.
        if not d.custom and not d.accepted.rows and height<d.height and f:GetHeight()>d.height then
            K.DB().panelSizing[e.key]=Copy(d.accepted); P.Refresh(e.key); d.limit="min."
        end
    end
    -- A new content minimum can be wider/taller than the free space at the fixed
    -- edge (especially the first change from legacy geometry). Reject that step
    -- instead of letting Clamp shrink the scale and feed font compensation back.
    local widthRoom=math.min(K.UIWidth()-16,d.edge=="LEFT" and d.right or K.UIWidth()-d.left)
    local keepBottom=d.edge=="TOP" or (horizontal and e.dock and e.dock.edge=="above")
    local heightRoom=math.min(K.UIHeight()-16,keepBottom and K.UIHeight()-d.bottom or d.top)
    if f:GetWidth()*d.q>widthRoom+.1 or f:GetHeight()*d.q>heightRoom+.1 then
        K.DB().panelSizing[e.key]=Copy(d.accepted); P.Refresh(e.key)
    else
        d.accepted=Copy(P.Config(e.key))
        -- Moving the contact edge releases that dock only after a real change.
        if (f:GetWidth()~=oldWidth or f:GetHeight()~=oldHeight) and e.dock
            and ((d.edge=="TOP" and e.dock.edge=="below") or (d.edge=="BOTTOM" and e.dock.edge=="above")) then e.dock=nil end
    end
    d.changed=d.changed or f:GetWidth()~=d.width or f:GetHeight()~=d.height
    local left=d.edge=="LEFT" and d.right-f:GetWidth()*d.q or d.left
    local top=d.edge=="TOP" and d.bottom+f:GetHeight()*d.q or d.top
    if horizontal and e.dock and e.dock.edge=="above" then top=d.bottom+f:GetHeight()*d.q end
    Position(e,left,top)
    if e.dock and tl then
        local ox=e.dock.ref=="bar" and e.options.edge and (e.options.edge()) or 0
        e.dock.x=left-tl+ox*d.q
    end
    d.stepped=true
    L.Save(e.key); L.SyncFollowers(); S.Readout(e)
    d.lastX,d.lastY,d.lastWidth,d.lastHeight=x,y,f:GetWidth(),f:GetHeight()
end
-- Smooth pointer tracking is independent of the shared 0.1 second data update.
-- Pending starts have no readout yet, so tracking must live on a visible driver.
local driver=CreateFrame("Frame","KeijinUILayoutSizingDriver",UIParent)
driver:SetScript("OnUpdate",function() S.Track(); S.EditorPosition() end)
readout:SetScript("OnHide",S.Finish)
local function GripHover()
    this.bar:SetVertexColor(1,.88,.45,1)
end
local function GripLeave()
    this.bar:SetVertexColor(.83,.64,.27,1)
end
local function AddGrip(e,edge)
    local grip=CreateFrame("Frame",nil,e.handle)
    grip.key=e.key; grip.edge=edge; grip:SetFrameLevel(190)
    grip:EnableMouse(true); grip:EnableMouseWheel(true)
    local vertical=edge=="LEFT" or edge=="RIGHT"
    grip:SetWidth(vertical and 9 or 64); grip:SetHeight(vertical and 64 or 9)
    -- Side grips sit below the label band, including on 28 px handles.
    grip:SetPoint(edge,e.handle,edge,0,vertical and -11 or 0)
    K.Chamfer(grip,3,{.035,.065,.075,.98},{.53,.42,.2,1})
    grip.bar=grip:CreateTexture(nil,"OVERLAY"); grip.bar:SetTexture(K.flat)
    grip.bar:SetWidth(vertical and 3 or 42); grip.bar:SetHeight(vertical and 42 or 3)
    grip.bar:SetPoint("CENTER",grip,"CENTER",0,0); grip.bar:SetVertexColor(.83,.64,.27,1)
    grip:SetScript("OnEnter",GripHover); grip:SetScript("OnLeave",GripLeave)
    grip:SetScript("OnMouseDown",function() if arg1=="LeftButton" then S.Begin(this.key,this.edge) end end)
    grip:SetScript("OnMouseUp",function() S.Track(); S.Finish() end)
    grip:SetScript("OnHide",function()
        local d=drag or pending
        if d and d.entry==e and d.edge==edge then S.Finish() end
    end)
    grip:SetScript("OnMouseWheel",function() L.entries[this.key].handle:GetScript("OnMouseWheel")() end)
    return grip
end
local function Button(parent,text,width,x,action)
    local b=CreateFrame("Button",nil,parent); b:SetWidth(width); b:SetHeight(28)
    b:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",x,12)
    K.Chamfer(b,4,{.12,.16,.18,1},{.67,.54,.27,1}); K.LText(b,text,11,"CENTER",0,0)
    b:SetScript("OnClick",action); return b
end
local function Field(parent,key,label,y,labelWidth)
    local text=K.LText(parent,label,11,"TOPLEFT",14,y-5,labelWidth or 166)
    if key=="alpha" then parent.alphaLabel=text
    elseif key=="scale" then parent.scaleLabel=text
    else parent.sizingLabels=parent.sizingLabels or {}; table.insert(parent.sizingLabels,text) end
    local box=CreateFrame("EditBox",nil,parent)
    box:SetWidth(82); box:SetHeight(26); box:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-14,y)
    K.Chamfer(box,3,{.025,.035,.04,1},{.4,.5,.54,1})
    K.SetFontSize(box,12); table.insert(K.fontStrings,{box,12})
    box:SetAutoFocus(false); box:SetTextInsets(8,6,0,0)
    box:SetScript("OnEditFocusGained",function() parent.inputFocused=true; if K.layoutTap then K.layoutTap.Cancel() end end)
    box:SetScript("OnEditFocusLost",function() parent.inputFocused=nil end)
    box:SetScript("OnEnterPressed",function() S.Apply() end)
    box:SetScript("OnEscapePressed",function() S.Close() end)
    parent.fields[key]=box
    if key=="height" then parent.rowsHint=K.Text(parent,"",9,"TOPLEFT",14,y-28); parent.rowsHint:SetTextColor(.7,.75,.78) end
end
local function AppearanceClick()
    if not editor or not L.Active() or not L.CanEdit(editor.key) then S.Close(); return end
    local field=this.option
    if field=="headers" then
        local current=K.WindowConfig(editor.key).headers
        local nextMode={normal="thin",thin="off",off="default"}
        local value=current and nextMode[current] or "normal"
        K.SetWindowOption(editor.key,field,value~="default" and value or nil)
    else K.SetWindowOption(editor.key,field,not K.WindowShown(editor.key,field)) end
    -- Keep all draft numbers untouched while immediately committing a switch.
    S.AppearanceValues(); S.EditorPosition(); RefreshSettings()
end
local function AppearanceRow(field,label)
    local row=CreateFrame("Button",nil,editor)
    row.option=field; row:SetWidth(264); row:SetHeight(28)
    K.Chamfer(row,3,{.07,.09,.10,1},{.3,.34,.35,1})
    row.label=K.LText(row,label,10,"LEFT",6,0,190)
    row.value=K.Text(row,"",10,"RIGHT",-6,0,60); row.value:SetJustifyH("RIGHT")
    row:SetScript("OnClick",AppearanceClick)
    editor.appearance[field]=row
end
function S.AppearanceValues()
    local key=editor.key; local cap=K.WindowCapabilities(key)
    local sized=P.entries[key] and P.On(key)
    local y=sized and -224 or -120
    editor.appearanceTitle:ClearAllPoints(); editor.appearanceTitle:SetPoint("TOPLEFT",editor,"TOPLEFT",14,y)
    local any=cap.rim or cap.back or cap.strip or cap.alpha or cap.headers
    if any then editor.appearanceTitle:Show() else editor.appearanceTitle:Hide() end
    y=y-24
    for _,field in ipairs({"rim","back","strip","headers"}) do
        local row=editor.appearance[field]
        if cap[field] then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT",editor,"TOPLEFT",14,y); row:Show()
            local value
            if field=="headers" then
                local modes={normal="Normal",thin="Schmal",off="Aus"}
                local mode=K.WindowConfig(key).headers
                value=mode and modes[mode] or "Vorgabe"
            else value=K.WindowShown(key,field) and "An" or "Aus" end
            row.value:SetText(K.T(value)); y=y-32
        else row:Hide() end
    end
    if cap.alpha then
        local box=editor.fields.alpha
        box:ClearAllPoints(); box:SetPoint("TOPRIGHT",editor,"TOPRIGHT",-14,y)
        editor.alphaLabel:ClearAllPoints(); editor.alphaLabel:SetPoint("TOPLEFT",editor,"TOPLEFT",14,y-5)
        box:Show(); editor.alphaLabel:Show(); y=y-34
        editor.appearanceReset:ClearAllPoints(); editor.appearanceReset:SetPoint("TOPLEFT",editor,"TOPLEFT",14,y)
        editor.appearanceReset:Show(); y=y-34
    else editor.fields.alpha:Hide(); editor.alphaLabel:Hide(); editor.appearanceReset:Hide() end
    editor:SetHeight(-y+102)
end
function S.ApplyAlpha()
    if not editor or editor.settingValues or not editor:IsShown() then return end
    if not L.Active() or not L.CanEdit(editor.key) then S.Close(); return end
    if not K.WindowCapabilities(editor.key).alpha then return end
    local value=Number(editor.fields.alpha:GetText())
    if not value or value<0 or value>100 then editor.error:Show(); return end
    editor.error:Hide()
    if value==editor.original.alpha then return end
    K.SetWindowOption(editor.key,"alpha",value/100)
    editor.original.alpha=value
    RefreshSettings()
end
local function MakeEditor()
    editor=K.Panel("KeijinUILayoutSizing","Größe & Position",292,220)
    editor.minBackgroundAlpha=.8
    K.ApplyBackground()
    S.editor=editor; editor.fields={}; editor:SetFrameStrata("TOOLTIP"); editor:SetFrameLevel(240)
    editor.windowName=K.Text(editor,"",10,"TOPLEFT",14,-34,264)
    editor.sizeTitle=K.LText(editor,"Größe",11,"TOPLEFT",14,-54,264)
    Field(editor,"width","Fensterbreite",-76)
    Field(editor,"height","Höhe",-110,54)
    Field(editor,"font","Schriftgröße",-162)
    Field(editor,"scale","Skalierung (%)",-76)
    Field(editor,"alpha","Hintergrund (%)",-300)
    editor.fields.alpha:SetScript("OnTextChanged",function() S.ApplyAlpha() end)
    editor.appearance={}
    editor.appearanceTitle=K.LText(editor,"Darstellung",11,"TOPLEFT",14,-224,264)
    AppearanceRow("rim","Rahmen anzeigen")
    AppearanceRow("back","Hintergrund anzeigen")
    AppearanceRow("strip","Headergrafik anzeigen")
    AppearanceRow("headers","Abschnittstitel")
    editor.appearanceReset=Button(editor,"Darstellung zurücksetzen",264,14,function()
        if not L.Active() or not L.CanEdit(editor.key) then S.Close(); return end
        K.ResetWindowOptions(editor.key)
        editor.settingValues=true
        editor.fields.alpha:SetText(tostring(math.floor(K.WindowAlpha(editor.key)*100+.5)))
        editor.original.alpha=Number(editor.fields.alpha:GetText())
        editor.settingValues=nil
        local fields=P.entries[editor.key] and P.On(editor.key) and {"width","height","font"} or {"scale"}
        local valid=true
        for _,field in ipairs(fields) do if not Number(editor.fields[field]:GetText()) then valid=false end end
        if valid then editor.error:Hide() end
        S.AppearanceValues(); S.EditorPosition(); RefreshSettings()
    end)
    editor.saveHint=K.LText(editor,"Darstellung sofort. Größe mit Übernehmen.",10,"BOTTOMLEFT",14,66,264)
    editor.saveHint:SetHeight(28); editor.saveHint:SetJustifyV("TOP")
    editor.error=K.LText(editor,"Bitte gültige Zahlen eingeben.",10,"BOTTOMLEFT",14,48,264)
    editor.error:SetTextColor(1,.48,.35); editor.error:Hide()
    editor.apply=Button(editor,"Übernehmen",118,14,function() if S.Apply() then S.Close() end end)
    editor.reset=Button(editor,"Zurücksetzen",134,144,function() S.Reset() end)
    local close=CreateFrame("Button",nil,editor); close:SetWidth(28); close:SetHeight(28)
    close:SetPoint("TOPRIGHT",editor,"TOPRIGHT",-2,-2); K.Text(close,"X",12,"CENTER",0,0)
    close:SetScript("OnClick",function() S.Close() end); editor.close=close
    editor:SetScript("OnHide",function() editor.inputFocused=nil; L.EditorEscape(false) end)
    editor:Hide()
    if K.layoutTap then K.layoutTap.Watch(editor,true) end
end
function S.EditorValues()
    editor.settingValues=true
    local e=L.entries[editor.key]; local sized=P.entries[editor.key] and P.On(editor.key) and true or false
    editor.windowName:SetText(K.T(e.name))
    for key,box in pairs(editor.fields) do
        if (key=="scale")~=sized then box:Show() else box:Hide() end
    end
    -- Labels are separate font strings and follow the same visibility as their box.
    for _,label in ipairs(editor.sizingLabels or {}) do if sized then label:Show() else label:Hide() end end
    if editor.rowsHint then if sized then editor.rowsHint:Show() else editor.rowsHint:Hide() end end
    if editor.scaleLabel then if sized then editor.scaleLabel:Hide() else editor.scaleLabel:Show() end end
    if sized then
        local w,r,f,h,total=Values(editor.key)
        editor.fields.width:SetText(tostring(w)); editor.fields.height:SetText(tostring(h))
        editor.fields.font:SetText(tostring(f))
        local hint=string.format(K.T(S.AtMaximum(editor.key,r,total) and "= %d Zeilen (max.)" or "= %d Zeilen"),r)
        if r<=1 then hint=hint.." (min.)" end
        editor.rowsHint:SetText(hint)
    else editor.fields.scale:SetText(tostring(math.floor(e.frame:GetScale()/e.baseScale*100+.5))) end
    S.AppearanceValues()
    editor.fields.alpha:SetText(tostring(math.floor(K.WindowAlpha(editor.key)*100+.5)))
    editor.original={}
    for key,box in pairs(editor.fields) do editor.original[key]=Number(box:GetText()) end
    editor.error:Hide(); editor.settingValues=nil
end
-- Fit in a free strip next to the window. At tight resolutions shrink the editor,
-- never cover its target. Both frame coordinates and strip sizes use UIParent units.
function S.EditorPosition()
    if not editor or not editor:IsShown() then return end
    local e=L.entries[editor.key]
    if not L.Active() or not L.CanEdit(editor.key) then S.Close(); return end
    local w,h=K.UIWidth(),K.UIHeight()
    local l,b,r,t=FrameRect(e)
    -- Layout.Update reanchors handles/docks before this shared update. Retry on
    -- the independent OnUpdate after the client has resolved the anchor chain.
    -- Alpha keeps the driver/editor updating without showing a guessed position.
    if not l then editor:SetAlpha(0); editor:EnableMouse(false); return end
    editor:SetAlpha(1); editor:EnableMouse(true)
    local height=editor:GetHeight()
    local q=math.min(1,w/292,h/height)
    local candidates={{w-r-8,h,r+8,h},{l-8,h,0,h},{w,h-t-8,0,h},{w,b-8,0,b-8}}
    local best,score,room,side
    for i,c in ipairs(candidates) do
        local fit=math.min(q,c[1]/292,c[2]/height)
        local horizontal=i<=2
        local space=horizontal and c[1] or c[2]
        if fit>0 and (not score or fit>score or (fit==score and
            ((horizontal and not side) or (horizontal==side and space>room)))) then
            best=c; score=fit; room=space; side=horizontal
        end
    end
    if not best then editor:Hide(); return end
    editor:SetScale(score)
    -- Sit directly against the window on the side with room: right strip at r+8, left strip
    -- ending at l-8, above or below with the window's left edge.
    local x=best[3]
    if best==candidates[2] then x=l-8-292*score elseif best==candidates[3] or best==candidates[4] then x=l end
    x=Bound(x,0,math.max(0,w-292*score))
    local y=Bound(math.min(t,best[4]),height*score,h)
    if best==candidates[3] then y=Bound(t+8+height*score,height*score,h) end
    editor:ClearAllPoints(); editor:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/score,y/score)
end
function S.Open(key)
    local e=L.entries[key]; if not Allowed(e) then return end
    S.Finish()
    if not editor then MakeEditor() end
    editor.key=key; editor:Show(); L.EditorEscape(true); S.EditorValues(); S.EditorPosition()
end
function S.Close()
    S.Finish(); if editor then editor:Hide() end
end
function S.Changed(key)
    if editor and editor:IsShown() and editor.key==key then S.EditorValues(); S.EditorPosition() end
end
function S.Apply()
    if not editor or not editor:IsShown() then return false end
    local key=editor.key; local e=L.entries[key]
    if not L.Active() or not L.CanEdit(key) then S.Close(); return false end
    local alpha=Number(editor.fields.alpha:GetText())
    local hasAlpha=K.WindowCapabilities(key).alpha
    if hasAlpha and (not alpha or alpha<0 or alpha>100) then editor.error:Show(); return false end
    if P.entries[key] and P.On(key) then
        local w,h,f=Number(editor.fields.width:GetText()),Number(editor.fields.height:GetText()),Number(editor.fields.font:GetText())
        if not w or not h or not f then editor.error:Show(); return false end
        -- Validate every field before changing any saved value.
        f=math.floor(f+.5)
        local widthChanged,heightChanged,fontChanged=w~=editor.original.width,h~=editor.original.height,f~=editor.original.font
        if e.options.beforeMove then e.options.beforeMove() end
        if fontChanged then P.Set(key,"font",f) end
        if heightChanged then
            -- First sizing switches legacy panels to PanelSizing geometry. Resolve
            -- its real header and row pitch before converting the requested height.
            if not P.Custom(key) then P.Set(key,"rows",Visible(key),true) end
            P.Set(key,"rows",P.HeightRows(key,h))
        end
        if widthChanged then P.Set(key,"width",w) end
    else
        local value=Number(editor.fields.scale:GetText())
        if not value then editor.error:Show(); return false end
        if e.options.beforeMove then e.options.beforeMove() end
        local maximum=e.options.maxScale and e.options.maxScale() or 1.8
        e.frame:SetScale(e.baseScale*Bound(value/100,.5,math.min(1.8,maximum)))
    end
    S.ApplyAlpha()
    L.Save(key); L.SyncFollowers(); S.EditorValues(); S.EditorPosition(); RefreshSettings(); return true
end
function S.Reset()
    if not editor then return end
    local key=editor.key
    if not L.Active() or not L.CanEdit(key) then S.Close(); return end
    local e=L.entries[key]
    if e.options.beforeMove then e.options.beforeMove() end
    if P.entries[key] and P.On(key) then P.Reset(key); L.Place(key)
    else
        local e=L.entries[key]; local default=L.defaults[key]
        e.frame:SetScale(e.baseScale*(default and default.scale or 1)); L.Save(key)
    end
    L.SyncFollowers(); S.EditorValues(); S.EditorPosition(); RefreshSettings()
end
local gripsHidden
function S.Update()
    S.Track()
    if not L.Active() then
        -- Grips only exist in layout mode: hide them once, then the tick has nothing to do.
        if not gripsHidden then
            gripsHidden=true
            for _,e in pairs(L.entries) do
                for _,grip in ipairs(e.sizeGrips or {}) do K.Shown(grip,false) end
            end
        end
        S.EditorPosition()
        return
    end
    gripsHidden=false
    for key,e in pairs(L.entries) do
        if P.entries[key] and not e.sizeGrips then
            e.sizeGrips={AddGrip(e,"LEFT"),AddGrip(e,"RIGHT"),AddGrip(e,"TOP"),AddGrip(e,"BOTTOM")}
        end
        if e.sizeGrips then
            local handle=e.handle
            local hw,hh=handle:GetWidth(),handle:GetHeight()
            -- Label band and grip sizes only depend on the handle size: write them when it changes.
            if e.gripWidth~=hw or e.gripHeight~=hh then
                e.gripWidth,e.gripHeight=hw,hh
                -- Reserve a 12 px label band, including 11 px fonts and tiny panels.
                K.Anchor(handle.label,"TOP",handle,"TOP",0,-math.min(10,math.floor((hh-14)/2)+1))
                K.SetH(handle.label,12)
                for _,grip in ipairs(e.sizeGrips) do
                    local vertical=grip.edge=="LEFT" or grip.edge=="RIGHT"
                    local length=math.max(6,math.min(64,(vertical and hh-24 or hw-22)))
                    local thickness=vertical and 9 or math.max(6,math.min(9,math.floor((hh-14)/2)))
                    K.SetW(grip,vertical and thickness or length); K.SetH(grip,vertical and length or thickness)
                    K.SetW(grip.bar,vertical and 3 or math.max(2,length-22))
                    K.SetH(grip.bar,vertical and math.max(2,length-22) or 3)
                end
            end
            local show=Allowed(e) and P.On(key) and true or false
            for _,grip in ipairs(e.sizeGrips) do K.Shown(grip,show) end
        end
    end
    S.EditorPosition()
end
table.insert(K.updates,S.Update)
K.On("PLAYER_LEAVING_WORLD",S.Close)
