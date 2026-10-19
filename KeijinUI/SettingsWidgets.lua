-- Shared settings controls, built only from the client's 1.12 frame API.
local K=KeijinUI
local O={pages={},controls={},refreshers={},nav={},navSections={},width=516}
K.settings=O
local GOLD={1,0.82,0.28}
local function Skin(f) K.Chamfer(f,4,{0.055,0.055,0.065,1},{0.67,0.57,0.36,1}) end
local panel=K.Panel("KeijinUIOptions","KeijinUI",760,570)
O.panel=panel
panel:SetFrameStrata("DIALOG"); panel:SetBackdropColor(0.045,0.045,0.05,1)
panel.strip:SetHeight(30)
panel.title:ClearAllPoints(); panel.title:SetPoint("TOP",panel,"TOP",0,-12)
panel.title:SetFont(K.font,14,"OUTLINE"); panel.title:SetWidth(680); panel.title:SetHeight(22); panel.title:SetJustifyH("CENTER")
K.Live(panel.title,function() return K.title.." · "..K.version.." · "..K.T("Einstellungen") end)
local function Rule(parent,x,y,width,height)
    local t=parent:CreateTexture(nil,"BORDER"); t:SetTexture(K.flat); t:SetVertexColor(.62,.53,.34,.45)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); t:SetWidth(width); t:SetHeight(height or 1); return t
end
Rule(panel,12,-43,736); Rule(panel,12,-512,736); Rule(panel,196,-44,1,468)
local saved=K.DB().options
if type(saved)=="table" and saved.point then panel:SetPoint(saved.point,UIParent,saved.relative,saved.x,saved.y)
else panel:SetPoint("CENTER",UIParent,"CENTER",0,0) end
-- The saved variables may not exist yet while this file loads: apply the position again after ADDON_LOADED.
K.On("ADDON_LOADED",function(_,name)
    if name~="KeijinUI" then return end
    local stored=K.DB().options
    if type(stored)=="table" and stored.point and not (type(saved)=="table" and saved.point) then
        panel:ClearAllPoints(); panel:SetPoint(stored.point,UIParent,stored.relative,stored.x,stored.y)
    end
    saved=stored
end)
panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
local shield=CreateFrame("Frame","KeijinUISettingsChoice",UIParent)
shield:SetAllPoints(UIParent); shield:SetFrameStrata("FULLSCREEN_DIALOG"); shield:EnableMouse(true); shield:Hide()
O.shield=shield
function O.CloseChoice() shield:Hide() end
shield:SetScript("OnMouseDown",O.CloseChoice)
panel:SetScript("OnDragStart",function() O.CloseChoice(); panel:StartMoving() end)
panel:SetScript("OnDragStop",function()
    panel:StopMovingOrSizing()
    local point,_,relative,x,y=panel:GetPoint()
    K.DB().options={point=point,relative=relative,x=x,y=y}
end)
function O.MenuScale()
    local value=K.DB().optionsScale
    return K.Number(value) and math.max(.7,math.min(1,value)) or .8
end
-- uiScale is the client's persisted setting for UIParent, not a multiplier on saved frame sizes.
function O.UIScaleSupported()
    local value=tonumber(GetCVar("uiScale"))
    return K.Number(value) and value>0 and true or false
end
function O.UIScale()
    local value=tonumber(GetCVar("uiScale"))
    return K.Number(value) and value>0 and math.max(.64,math.min(1.5,value)) or .9
end
local lastWidth,lastHeight,lastScale,lastUIValue
function O.Fit()
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    panel:SetScale(math.min(O.MenuScale(),math.max(.1,(w-24)/760),math.max(.1,(h-24)/570)))
    -- Retain a dragged menu's position where possible, keeping every control on screen.
    local ratio=panel:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local left,bottom=panel:GetLeft(),panel:GetBottom()
    if type(left)=="number" and type(bottom)=="number" then
        left,bottom=left*ratio,bottom*ratio
        local width,height=760*ratio,570*ratio
        local x=math.max(8,math.min(w-width-8,left))
        local y=math.max(8,math.min(h-height-8,bottom))
        if math.abs(x-left)>.1 or math.abs(y-bottom)>.1 then
            panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/ratio,(y+height)/ratio)
        end
    end
    lastWidth,lastHeight,lastScale,lastUIValue=w,h,UIParent:GetEffectiveScale(),GetCVar("uiScale")
end
function O.SetMenuScale(value)
    if not K.Number(value) or value<=0 then return end
    K.DB().optionsScale=math.max(.7,math.min(1,value)); O.Fit()
end
function O.SetUIScale(value)
    if not O.UIScaleSupported() or not K.Number(value) or value<=0 then return end
    value=math.max(.64,math.min(1.5,value))
    local reference=K.DB().layoutScaleReference
    if not K.Number(reference) or reference<=0 then K.DB().layoutScaleReference=UIParent:GetEffectiveScale() end
    SetCVar("uiScale",string.format("%.2f",value)); O.Fit()
end
O.Fit()
table.insert(K.updates,function()
    if lastWidth~=UIParent:GetWidth() or lastHeight~=UIParent:GetHeight() or lastScale~=UIParent:GetEffectiveScale() or lastUIValue~=GetCVar("uiScale") then
        O.Fit(); O.Refresh()
    end
end)

table.insert(UISpecialFrames,"KeijinUIOptions"); table.insert(UISpecialFrames,"KeijinUISettingsChoice")
function O.Refresh()
    for _,fn in ipairs(O.refreshers) do fn() end
end
function O.Watch(fn) table.insert(O.refreshers,fn); fn() end
function O.Button(parent,text,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent); b:SetWidth(width); b:SetHeight(28)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); Skin(b)
    b.text=K.LText(b,text,11,"CENTER",0,0)
    b:SetScript("OnClick",function() O.CloseChoice(); fn(); O.Refresh() end)
    b:SetScript("OnEnter",function() b:SetBackdropBorderColor(.94,.74,.37,1) end)
    b:SetScript("OnLeave",function() b:SetBackdropBorderColor(.67,.57,.36,1) end)
    return b
end
O.Button(panel,"Schließen",644,-529,100,function() panel:Hide() end)
O.Button(panel,"Layout bearbeiten",16,-529,164,function() K.layout.Toggle(); panel:Hide() end)
O.Button(panel,"×",718,-8,26,function() panel:Hide() end)
local footer=K.LText(panel,"Änderungen werden sofort gespeichert.",10,"TOPLEFT",206,-538,424)
footer:SetTextColor(.66,.65,.60)
local title=K.Text(panel,"",20,"TOPLEFT",218,-59,516); title:SetTextColor(unpack(GOLD)); title:SetHeight(27)
local subtitle=K.Text(panel,"",10,"TOPLEFT",218,-91,516); subtitle:SetTextColor(.73,.72,.68); subtitle:SetHeight(20)
local viewport=CreateFrame("ScrollFrame","KeijinUISettingsScroll",panel)
viewport:SetPoint("TOPLEFT",panel,"TOPLEFT",218,-121); viewport:SetWidth(516); viewport:SetHeight(376)
O.viewport=viewport
local slider=CreateFrame("Slider","KeijinUISettingsScrollbar",panel)
slider:SetPoint("TOPLEFT",panel,"TOPLEFT",741,-121); slider:SetWidth(8); slider:SetHeight(376)
slider:SetOrientation("VERTICAL"); slider:SetMinMaxValues(0,0); slider:SetValueStep(24)
slider:SetBackdrop({bgFile=K.flat}); slider:SetBackdropColor(.12,.11,.09,.9)
slider:SetThumbTexture(K.flat)
local thumb=slider:GetThumbTexture()
if thumb then thumb:SetWidth(8); thumb:SetHeight(34); thumb:SetVertexColor(.65,.52,.28,1) end
slider:Hide(); O.scrollbar=slider
function O.Scroll(value)
    O.CloseChoice()
    local page=O.current
    if not page then return end
    local max=math.max(0,page:GetHeight()-viewport:GetHeight())
    value=math.max(0,math.min(max,tonumber(value) or 0))
    page.offset=value; viewport:SetVerticalScroll(value)
    O.scrolling=true; slider:SetMinMaxValues(0,max); slider:SetValue(value); O.scrolling=false
    if max>0 then slider:Show() else slider:Hide() end
    if O.UpdateSection then O.UpdateSection() end
end
slider:SetScript("OnValueChanged",function() if not O.scrolling then O.Scroll(slider:GetValue()) end end)
function O.Wheel(frame)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel",function() O.Scroll((O.current and O.current.offset or 0)+(arg1>0 and -48 or 48)) end)
end
O.Wheel(viewport)
function O.Page(key,label,description,parent)
    local page=CreateFrame("Frame",nil,viewport)
    page:SetWidth(O.width); page:SetHeight(376); page:SetPoint("TOPLEFT",viewport,"TOPLEFT",0,0)
    page.key,page.caption,page.description,page.parentKey,page.y=key,label,description,parent or key,0
    page.sections={}
    page:Hide(); O.pages[key]=page; O.Wheel(page); return page
end
function O.Finish(page) page:SetHeight(math.max(376,-page.y+8)) end
function O.ShowPage(key)
    -- Preserve callers using the former categories; there is only one shared UI page.
    local alias=key=="layout" or key=="units"
    local page=O.pages[alias and "display" or key] or O.pages.display
    O.CloseChoice()
    for _,p in pairs(O.pages) do p:Hide() end
    O.current=page; K.DB().optionsTab=page.key
    viewport:SetScrollChild(page); page:Show()
    title:SetText(K.T(page.caption)); subtitle:SetText(K.T(page.description))
    O.UpdateNavigation()
    O.Scroll(page.offset or 0); O.Refresh()
    if alias then
        local caption=key=="layout" and "Größe & Position" or "Einheitenrahmen"
        for i,section in ipairs(page.sections) do if section.caption==caption then O.JumpSection("display",i); break end end
    end
end
-- Only the current category expands. Section buttons share the headings' live translations.
function O.MarkSections()
    for key,buttons in pairs(O.navSections) do
        for i,b in ipairs(buttons) do
            local selected=O.current==O.pages[key] and O.current.sectionIndex==i
            b.selected=selected
            b:SetBackdropColor(.25,.19,.08,selected and .4 or 0)
            b.text:SetTextColor(selected and 1 or .72,selected and .82 or .70,selected and .4 or .64)
            if selected then b.marker:Show() else b.marker:Hide() end
        end
    end
end
function O.UpdateSection()
    local page=O.current
    if not page then return end
    local index=1
    for i,section in ipairs(page.sections) do if section.offset<=(page.offset or 0)+1 then index=i end end
    local max=math.max(0,page:GetHeight()-viewport:GetHeight())
    if max>0 and (page.offset or 0)>=max-1 then index=table.getn(page.sections) end
    page.sectionIndex=index; O.MarkSections()
end
function O.JumpSection(key,index)
    local page=O.pages[key]; local section=page and page.sections[index]
    if not section then return end
    if O.current~=page then O.ShowPage(key) end
    O.Scroll(section.offset)
    -- Short final sections cannot reach the viewport top; keep the clicked destination marked.
    page.sectionIndex=index; O.MarkSections()
end
function O.UpdateNavigation()
    local y=-57
    local currentKey=O.current and O.current.parentKey
    local count=table.getn(O.navSections[currentKey] or {})
    local categories=table.getn(O.navOrder or {})
    local step=count>0 and math.min(22,math.floor((455-categories*40-8-math.max(0,categories-1)*3)/count)) or 22
    for _,item in ipairs(O.navOrder or {}) do
        local key=item[1]; local b=O.nav[key]
        local selected=O.current and key==O.current.parentKey
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",panel,"TOPLEFT",12,y)
        b:SetBackdropColor(selected and .25 or .045,selected and .18 or .045,selected and .075 or .05,1)
        b.selected=selected and true or false
        b:SetBackdropBorderColor(selected and .9 or .48,selected and .71 or .40,selected and .34 or .24,1)
        b.text:SetTextColor(selected and 1 or .94,selected and .82 or .79,selected and .4 or .47)
        b.disclosure:SetText(selected and "v" or ">")
        y=y-40
        for _,sub in ipairs(O.navSections[key]) do
            if selected then
                sub:SetHeight(step-2); sub:ClearAllPoints(); sub:SetPoint("TOPLEFT",panel,"TOPLEFT",28,y); sub:Show(); y=y-step
            else sub:Hide() end
        end
        y=y+(selected and -8 or -3)
    end
    O.MarkSections()
end
function O.Navigation(items)
    O.navOrder=items
    for _,v in ipairs(items) do
        local key=v[1]
        local b=O.Button(panel,v[2],12,-57,172,function() O.ShowPage(key) end)
        b:SetHeight(34); b.text:ClearAllPoints(); b.text:SetPoint("LEFT",b,"LEFT",14,0)
        b.text:SetWidth(136); b.text:SetHeight(22); b.text:SetJustifyH("LEFT"); b.text:SetJustifyV("MIDDLE")
        b.text:SetFont(K.font,14,"OUTLINE"); O.nav[key]=b
        b:SetScript("OnEnter",function() b:SetBackdropBorderColor(.94,.74,.37,1) end)
        b:SetScript("OnLeave",O.UpdateNavigation)
        b.disclosure=K.Text(b,">",10,"RIGHT",-10,0,10)
        b.disclosure:SetTextColor(.74,.65,.46)
        local buttons={}; O.navSections[key]=buttons
        for i,section in ipairs(O.pages[key].sections) do
            local index=i
            local sub=CreateFrame("Button",nil,panel); sub:SetWidth(156); sub:SetHeight(20)
            sub:SetBackdrop({bgFile=K.flat}); sub:SetBackdropColor(0,0,0,0)
            sub.text=K.LText(sub,section.caption,10,"LEFT",8,0,148)
            sub.text:SetHeight(14); sub.text:SetJustifyH("LEFT"); sub.text:SetJustifyV("MIDDLE")
            sub.marker=sub:CreateTexture(nil,"ARTWORK"); sub.marker:SetTexture(K.flat)
            sub.marker:SetWidth(2); sub.marker:SetHeight(12); sub.marker:SetPoint("LEFT",sub,"LEFT",0,0)
            sub.marker:SetVertexColor(1,.82,.28,1); sub.marker:Hide()
            sub:SetScript("OnClick",function() O.JumpSection(key,index) end)
            sub:SetScript("OnEnter",function() sub.text:SetTextColor(1,.87,.5) end)
            sub:SetScript("OnLeave",O.MarkSections)
            O.Wheel(sub); sub:Hide(); table.insert(buttons,sub)
        end
    end
end
function O.Section(page,text)
    if page.y<0 then page.y=page.y-12 end
    local fs=K.LText(page,text,13,"TOPLEFT",0,page.y,516); fs:SetTextColor(unpack(GOLD)); fs:SetHeight(19)
    table.insert(page.sections,{caption=text,offset=-page.y,heading=fs})
    Rule(page,0,page.y-22,516); page.y=page.y-36
end
function O.Help(page,text)
    local fs=K.LText(page,text,10,"TOPLEFT",0,page.y,512); fs:SetTextColor(.68,.67,.62); fs:SetHeight(32)
    page.y=page.y-36; return fs
end
function O.Row(page,key,label,height)
    local row=CreateFrame("Button",nil,page); row:SetPoint("TOPLEFT",page,"TOPLEFT",0,page.y)
    row:SetWidth(O.width); row:SetHeight(height or 31)
    row.name=K.LText(row,label,11,"LEFT",0,0,300)
    row:SetBackdrop({bgFile=K.flat}); row:SetBackdropColor(0,0,0,0)
    row:SetScript("OnEnter",function() row:SetBackdropColor(.25,.2,.1,.2) end)
    row:SetScript("OnLeave",function() row:SetBackdropColor(0,0,0,0) end)
    O.Wheel(row); O.controls[key]=row; page.y=page.y-(height or 31); return row
end
function O.Toggle(page,key,label,get,set)
    local row=O.Row(page,key,label)
    local box=CreateFrame("Frame",nil,row); box:SetWidth(20); box:SetHeight(20); box:SetPoint("RIGHT",row,"RIGHT",-54,0); Skin(box)
    local mark=box:CreateTexture(nil,"ARTWORK"); mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); mark:SetAllPoints(box); mark:SetVertexColor(.7,1,.4,1)
    row.box,row.mark=box,mark
    row.value=K.Text(row,"",10,"RIGHT",-4,0,42); row.value:SetJustifyH("RIGHT")
    O.Watch(function()
        local on=get() and true or false
        if on then mark:Show() else mark:Hide() end
        row.value:SetText(K.T(on and "An" or "Aus")); row.value:SetTextColor(on and .65 or .6,on and .92 or .6,on and .45 or .6)
    end)
    row:SetScript("OnClick",function() O.CloseChoice(); set(not get()); O.Refresh() end)
    return row
end
function O.Choice(page,key,label,get,set,items)
    local row=O.Row(page,key,label,34)
    local button=O.Button(row,"",342,-2,170,function() end)
    O.Wheel(button)
    local text=button.text; text:SetWidth(146); text:SetJustifyH("LEFT"); text:ClearAllPoints(); text:SetPoint("LEFT",button,"LEFT",9,0)
    local arrow=K.Text(button,"v",9,"RIGHT",-8,0); arrow:SetTextColor(unpack(GOLD))
    row.value=text; row.items=items; row.button=button
    local menu=CreateFrame("Frame",nil,shield); menu:SetWidth(170); menu:SetHeight(8+table.getn(items)*27); Skin(menu)
    menu:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-3)
    for i,item in ipairs(items) do
        local value=item[1]   -- body local for the closure (see Statistics.lua)
        local option=O.Button(menu,item[2],4,-4-(i-1)*27,162,function() set(value); O.CloseChoice(); O.Refresh() end)
        option:SetHeight(25)
    end
    local function Open()
        local was=O.openMenu==menu and shield:IsShown()
        O.CloseChoice()
        if was then return end
        for _,m in ipairs(O.menus or {}) do m:Hide() end
        O.openMenu=menu; O.Fit(); shield:SetScale(1); menu:SetScale(panel:GetEffectiveScale()/UIParent:GetEffectiveScale()); shield:Show(); menu:Show()
    end
    O.menus=O.menus or {}; table.insert(O.menus,menu); menu:Hide()
    button:SetScript("OnClick",Open); row:SetScript("OnClick",Open)
    O.Watch(function() for _,v in ipairs(items) do if v[1]==get() then text:SetText(K.T(v[2])); return end end; text:SetText("?") end)
    return row
end
-- Preview the percentage during a drag; commit on release so the control does not move under the cursor.
function O.Slider(page,key,label,get,set,minimum,maximum)
    local row=O.Row(page,key,label,48); row.name:SetWidth(240)
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT",row,"LEFT",0,3)
    local control=CreateFrame("Slider",nil,row); row.slider=control
    control:SetWidth(190); control:SetHeight(18); control:SetPoint("RIGHT",row,"RIGHT",-64,3)
    control:SetOrientation("HORIZONTAL"); control:SetMinMaxValues(minimum,maximum); control:SetValueStep(1)
    Skin(control); control:SetThumbTexture(K.flat)
    local thumb=control:GetThumbTexture()
    if thumb then thumb:SetWidth(10); thumb:SetHeight(20); thumb:SetVertexColor(.8,.66,.38,1) end
    row.value=K.Text(row,"",11,"RIGHT",-4,3,52); row.value:SetJustifyH("RIGHT")
    local low=K.Text(control,minimum.."%",9,"TOPLEFT",0,-21,45)
    local high=K.Text(control,maximum.."%",9,"TOPRIGHT",0,-21,45); high:SetJustifyH("RIGHT")
    low:SetTextColor(.65,.63,.57); high:SetTextColor(.65,.63,.57)
    local function Percent(value) return math.max(minimum,math.min(maximum,math.floor(value+.5))) end
    O.Watch(function()
        if row.pending then return end
        row.refreshing=true; control:SetValue(Percent(get()*100)); row.refreshing=nil
        row.value:SetText(Percent(get()*100).."%")
    end)
    control:SetScript("OnValueChanged",function()
        if row.refreshing or row.locked then return end
        row.pending=Percent(control:GetValue()); row.value:SetText(row.pending.."%")
    end)
    control:SetScript("OnMouseUp",function()
        if arg1~="LeftButton" or not row.pending or row.locked then return end
        local value=row.pending/100; row.pending=nil; O.CloseChoice(); set(value); O.Refresh()
    end)
    control:SetScript("OnHide",function() row.pending=nil end)
    O.Wheel(control)
    return row
end
-- A row that only matters while active() is true: dimmed and not clickable otherwise.
function O.Requires(row,active)
    O.Watch(function()
        local on=active() and true or false
        row:SetAlpha(on and 1 or .4); row:EnableMouse(on); row.locked=not on
        if row.button then row.button:EnableMouse(on) end
        if row.slider then row.slider:EnableMouse(on) end
    end)
    return row
end
function O.Pair(page,left,fn,right,other)
    local a=O.Button(page,left,0,page.y,248,fn)
    local b=right and O.Button(page,right,264,page.y,248,other)
    O.Wheel(a); if b then O.Wheel(b) end; page.y=page.y-36; return a,b
end
panel:SetScript("OnShow",function() O.Fit(); O.ShowPage("display"); O.Scroll(0) end)
panel:SetScript("OnHide",O.CloseChoice)
K.OnLang(function() if O.current then title:SetText(K.T(O.current.caption)); subtitle:SetText(K.T(O.current.description)) end; O.Refresh() end)
