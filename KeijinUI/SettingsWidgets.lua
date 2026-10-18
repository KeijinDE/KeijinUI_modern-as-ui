-- Shared settings controls, built only from the client's 1.12 frame API.
local K=KeijinUI
local O={pages={},controls={},refreshers={},nav={},width=516}
K.settings=O
local GOLD={1,0.82,0.28}
local function Skin(f) K.Chamfer(f,4,{0.055,0.055,0.065,1},{0.67,0.57,0.36,1}) end
local panel=K.Panel("KeijinUIOptions","KeijinUI",760,570)
O.panel=panel
panel:SetFrameStrata("DIALOG"); panel:SetBackdropColor(0.045,0.045,0.05,1)
panel.strip:SetHeight(30)
panel.title:ClearAllPoints(); panel.title:SetPoint("TOP",panel,"TOP",0,-12)
panel.title:SetFont(K.font,14,"OUTLINE"); panel.title:SetWidth(680); panel.title:SetHeight(22); panel.title:SetJustifyH("CENTER")
K.Live(panel.title,function() return "KeijinUI · "..K.T("Einstellungen") end)
local function Rule(parent,x,y,width,height)
    local t=parent:CreateTexture(nil,"BORDER"); t:SetTexture(K.flat); t:SetVertexColor(.62,.53,.34,.45)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); t:SetWidth(width); t:SetHeight(height or 1); return t
end
Rule(panel,12,-43,736); Rule(panel,12,-512,736); Rule(panel,196,-44,1,468)
local saved=K.DB().options
if type(saved)=="table" and saved.point then panel:SetPoint(saved.point,UIParent,saved.relative,saved.x,saved.y)
else panel:SetPoint("CENTER",UIParent,"CENTER",0,0) end
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
function O.Fit()
    panel:SetScale(math.min(O.MenuScale(),math.max(.1,(UIParent:GetWidth()-24)/760),math.max(.1,(UIParent:GetHeight()-24)/570)))
end
function O.SetMenuScale(value) K.DB().optionsScale=value; O.Fit() end
O.Fit()
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
    page:Hide(); O.pages[key]=page; O.Wheel(page); return page
end
function O.Finish(page) page:SetHeight(math.max(376,-page.y+8)) end
function O.ShowPage(key)
    local page=O.pages[key] or O.pages.display
    O.CloseChoice()
    for _,p in pairs(O.pages) do p:Hide() end
    O.current=page; K.DB().optionsTab=page.key
    viewport:SetScrollChild(page); page:Show()
    title:SetText(K.T(page.caption)); subtitle:SetText(K.T(page.description))
    for navKey,b in pairs(O.nav) do
        local selected=navKey==page.parentKey
        b:SetBackdropColor(selected and .25 or .045,selected and .18 or .045,selected and .075 or .05,1)
        for _,t in ipairs(b.chamfer.rim) do if selected then t:Show() else t:Hide() end end
        b.text:SetTextColor(selected and 1 or .83,selected and .82 or .81,selected and .4 or .75)
    end
    O.Scroll(page.offset or 0); O.Refresh()
end
function O.Navigation(items)
    for i,v in ipairs(items) do
        local key=v[1]
        local b=O.Button(panel,v[2],12,-57-(i-1)*43,172,function() O.ShowPage(key) end)
        b:SetHeight(34); b.text:ClearAllPoints(); b.text:SetPoint("LEFT",b,"LEFT",14,0)
        b.text:SetFont(K.font,13,"OUTLINE"); O.nav[key]=b
    end
end
function O.Section(page,text)
    if page.y<0 then page.y=page.y-12 end
    local fs=K.LText(page,text,13,"TOPLEFT",0,page.y,516); fs:SetTextColor(unpack(GOLD)); fs:SetHeight(19)
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
        local option=O.Button(menu,item[2],4,-4-(i-1)*27,162,function() set(item[1]); O.CloseChoice(); O.Refresh() end)
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
-- A row that only matters while active() is true: dimmed and not clickable otherwise.
function O.Requires(row,active)
    O.Watch(function()
        local on=active() and true or false
        row:SetAlpha(on and 1 or .4); row:EnableMouse(on); row.locked=not on
        if row.button then row.button:EnableMouse(on) end
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
