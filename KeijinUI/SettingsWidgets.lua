-- Shared settings controls, built only from the client's 1.12 frame API.
local K=KeijinUI
local O={pages={},controls={},refreshers={},nav={},navSections={},width=516,searchEntries={}}
K.settings=O
local GOLD={1,0.82,0.28}
local function Skin(f) K.Chamfer(f,4,{0.055,0.055,0.065,1},{0.67,0.57,0.36,1}) end
local panel=K.Panel("KeijinUIOptions","KeijinUI",760,570)
O.panel=panel
panel:SetFrameStrata("DIALOG"); panel:SetBackdropColor(0.045,0.045,0.05,1); panel.noOpacity=true
panel.strip:SetHeight(30)
panel.title:ClearAllPoints(); panel.title:SetPoint("TOP",panel,"TOP",0,-12)
K.SetFontSize(panel.title,14); panel.title:SetWidth(680); panel.title:SetHeight(22); panel.title:SetJustifyH("CENTER")
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
    local w,h=K.UIWidth(),K.UIHeight()
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
    if lastWidth~=K.UIWidth() or lastHeight~=K.UIHeight() or lastScale~=UIParent:GetEffectiveScale() or lastUIValue~=GetCVar("uiScale") then
        O.Fit(); O.Refresh()
    end
end)

table.insert(UISpecialFrames,"KeijinUIOptions"); table.insert(UISpecialFrames,"KeijinUISettingsChoice")
-- Modules switched off hide their rows and whole sections (O.Section(page,text,module)); the rows below move up.
-- The signature tells Refresh when a module was switched (also by /kui commands or the module page).
function O.ModuleSignature()
    local t={}
    for _,key in ipairs(K.modules and K.modules.order or {}) do table.insert(t,K.ModuleOn(key) and "1" or "0") end
    return table.concat(t)
end
function O.Refresh()
    if O.ModuleSignature()~=O.modulesSignature then O.ReflowAll() end
    for _,fn in ipairs(O.refreshers) do fn() end
    if O.navOrder then O.UpdateNavigation() end
end
function O.Watch(fn) table.insert(O.refreshers,fn); fn() end
-- Keep the original controls and their source-language labels available to the search.
function O.SearchEntry(frame,page,label,key)
    if not page.key or O.pages[page.key]~=page then return end
    local section=page.sections[table.getn(page.sections)]
    local entry={frame=frame,page=page,label=label,key=key,section=section and section.caption or "",sectionRef=section,help={}}
    frame.searchEntry=entry; page.searchLast=entry
    table.insert(O.searchEntries,entry)
end
function O.Button(parent,text,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent); b:SetWidth(width); b:SetHeight(28)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); Skin(b)
    b.text=K.LText(b,text,11,"CENTER",0,0)
    b:SetScript("OnClick",function() O.CloseChoice(); fn(); O.Refresh() end)
    b:SetScript("OnEnter",function() b:SetBackdropBorderColor(.94,.74,.37,1) end)
    b:SetScript("OnLeave",function() b:SetBackdropBorderColor(.67,.57,.36,1) end)
    O.SearchEntry(b,parent,text)
    if parent.items then O.Track(parent,b,x,y) end
    return b
end
O.Button(panel,"Schließen",644,-529,100,function() panel:Hide() end)
O.Button(panel,"Layout bearbeiten",16,-529,164,function() K.layout.Toggle(); panel:Hide() end)
-- Same plain x as the search field: no frame of its own, brighter on hover.
local close=CreateFrame("Button","KeijinUISettingsClose",panel)
close:SetWidth(16); close:SetHeight(16); close:SetPoint("CENTER",panel,"TOPLEFT",731,-20)
close.icon=close:CreateTexture(nil,"OVERLAY")
close.icon:SetTexture("Interface\\AddOns\\KeijinUI\\media\\guardians\\GuardianEmpty.tga")
close.icon:SetAllPoints(close); close.icon:SetVertexColor(.62,.59,.52,1)
close:SetScript("OnClick",function() panel:Hide() end)
close:SetScript("OnEnter",function() close.icon:SetVertexColor(1,.9,.6,1) end)
close:SetScript("OnLeave",function() close.icon:SetVertexColor(.62,.59,.52,1) end)
O.closeButton=close
local footer=K.LText(panel,"Änderungen werden sofort gespeichert.",10,"TOPLEFT",206,-538,424)
footer:SetTextColor(.66,.65,.60)
local title=K.Text(panel,"",20,"TOPLEFT",218,-59,516); title:SetTextColor(unpack(GOLD)); title:SetHeight(27)
local subtitle=K.Text(panel,"",10,"TOPLEFT",218,-91,516); subtitle:SetTextColor(.73,.72,.68); subtitle:SetHeight(20)
O.title,O.subtitle=title,subtitle
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
function O.Page(key,label,description,parent,module)
    local page=CreateFrame("Frame",nil,viewport)
    page:SetWidth(O.width); page:SetHeight(376); page:SetPoint("TOPLEFT",viewport,"TOPLEFT",0,0)
    page.key,page.caption,page.description,page.parentKey,page.y=key,label,description,parent or key,0
    page.module=module
    page.sections={}; page.items={}
    page:Hide(); O.pages[key]=page; O.Wheel(page); return page
end
function O.Finish(page) page.endY=page.y; page:SetHeight(math.max(viewport:GetHeight(),-page.y+8)) end
function O.ShowPage(key)
    key=(O.pageAliases and O.pageAliases[key]) or key
    local page=O.pages[key] or O.pages.display
    -- A page whose module is off has nothing to show: the module page takes over.
    if not O.PageVisible(page) and O.pages.modules then page=O.pages.modules end
    O.CloseChoice()
    for _,p in pairs(O.pages) do p:Hide() end
    O.current=page; K.DB().optionsTab=page.key
    if O.categoryPage and page.key~="search" then O.categoryPage[page.parentKey]=page.key end
    viewport:SetScrollChild(page); page:Show()
    title:SetText(K.T(page.caption)); subtitle:SetText(K.T(page.description))
    O.UpdateNavigation()
    O.Scroll(page.offset or 0); O.Refresh()

end
-- The sidebar expands page links, never sections of one long document.
local function GroupVisible(item)
    for _,key in ipairs(item[3]) do
        if O.pages[key] and O.PageVisible(O.pages[key]) then return true end
    end
    return false
end
function O.MarkSections()
    for _,buttons in pairs(O.navSections) do
        for _,b in ipairs(buttons) do
            local selected=O.current and O.current.key==b.pageKey
            b.selected=selected and true or false
            b:SetBackdropColor(.25,.19,.08,selected and .4 or 0)
            b.text:SetTextColor(selected and 1 or .76,selected and .82 or .73,selected and .4 or .67)
            if selected then b.marker:Show() else b.marker:Hide() end
        end
    end
end
function O.UpdateSection() O.MarkSections() end
function O.JumpSection(key,index)
    local page=O.pages[key]; local section=page and page.sections[index]
    if not section or not O.SectionVisible(section) then return end
    if O.current~=page then O.ShowPage(key) end
    O.Scroll(section.offset); page.sectionIndex=index; O.MarkSections()
end
local function FitLabel(button,size,width)
    K.SetFontSize(button.text,size)
    local measured=button.text:GetStringWidth()
    if measured>width then
        local path,points,flags=button.text:GetFont()
        button.text:SetFont(path,math.max(8,points*width/measured),flags)
    end
end
function O.UpdateNavigation()
    local y=-57
    local current=O.current and O.current.parentKey
    for _,item in ipairs(O.navOrder or {}) do
        local key=item[1]; local b=O.nav[key]
        local visible=GroupVisible(item)
        if not visible then
            b:Hide(); for _,sub in ipairs(O.navSections[key]) do sub:Hide() end
        else
            b:Show(); FitLabel(b,12,136)
            local selected=current==key
            b:ClearAllPoints(); b:SetPoint("TOPLEFT",panel,"TOPLEFT",12,y)
            b:SetBackdropColor(selected and .25 or .045,selected and .18 or .045,selected and .075 or .05,1)
            b.selected=selected and true or false
            b:SetBackdropBorderColor(selected and .9 or .48,selected and .71 or .40,selected and .34 or .24,1)
            b.disclosure:SetText(selected and "v" or ">")
            y=y-34
            local count=0
            for _,sub in ipairs(O.navSections[key]) do
                FitLabel(sub,11,140)
                if selected and table.getn(item[3])>1 and O.PageVisible(O.pages[sub.pageKey]) then
                    sub:ClearAllPoints(); sub:SetPoint("TOPLEFT",panel,"TOPLEFT",24,y); sub:Show(); y=y-22; count=count+1
                else sub:Hide() end
            end
            if count>0 then y=y-5 end
        end
    end
    O.MarkSections()
end
function O.ShowCategory(key)
    local remembered=O.categoryPage and O.categoryPage[key]
    if remembered and O.pages[remembered] and O.PageVisible(O.pages[remembered]) then O.ShowPage(remembered); return end
    for _,item in ipairs(O.navOrder) do
        if item[1]==key then
            for _,pageKey in ipairs(item[3]) do
                if O.PageVisible(O.pages[pageKey]) then O.ShowPage(pageKey); return end
            end
        end
    end
end
function O.Navigation(items)
    O.navOrder=items; O.categoryPage={}
    for _,v in ipairs(items) do
        local key=v[1]
        local b=O.Button(panel,v[2],12,-57,172,function() O.ShowCategory(key) end)
        b:SetHeight(30); b.text:ClearAllPoints(); b.text:SetPoint("LEFT",b,"LEFT",12,0)
        b.text:SetWidth(136); b.text:SetHeight(22); b.text:SetJustifyH("LEFT"); b.text:SetJustifyV("MIDDLE")
        O.nav[key]=b
        b:SetScript("OnEnter",function() b:SetBackdropBorderColor(.94,.74,.37,1) end)
        b:SetScript("OnLeave",O.UpdateNavigation)
        b.disclosure=K.Text(b,">",10,"RIGHT",-9,0,10)
        local buttons={}; O.navSections[key]=buttons
        for _,pageKey in ipairs(v[3]) do
            local destination=pageKey
            local sub=CreateFrame("Button",nil,panel); sub:SetWidth(160); sub:SetHeight(20)
            sub.pageKey=destination
            sub:SetBackdrop({bgFile=K.flat}); sub:SetBackdropColor(0,0,0,0)
            sub.text=K.LText(sub,O.pages[destination].caption,11,"LEFT",8,0,140)
            sub.text:SetHeight(16); sub.text:SetJustifyH("LEFT"); sub.text:SetJustifyV("MIDDLE")
            sub.marker=sub:CreateTexture(nil,"ARTWORK"); sub.marker:SetTexture(K.flat)
            sub.marker:SetWidth(2); sub.marker:SetHeight(12); sub.marker:SetPoint("LEFT",sub,"LEFT",0,0)
            sub.marker:SetVertexColor(1,.82,.28,1); sub.marker:Hide()
            sub:SetScript("OnClick",function() O.ShowPage(destination) end)
            sub:SetScript("OnEnter",function() sub.text:SetTextColor(1,.87,.5) end)
            sub:SetScript("OnLeave",O.MarkSections)
            O.Wheel(sub); sub:Hide(); table.insert(buttons,sub)
        end
    end
end
-- Everything a page builds is tracked with its anchor and section, so a module switch can hide a section and move
-- the following rows up (O.Reflow). Items before the first section are never hidden.
function O.Track(page,obj,x,y,point,relative)
    if page.items then
        table.insert(page.items,{obj=obj,x=x,y=y,point=point or "TOPLEFT",relative=relative or point or "TOPLEFT",section=table.getn(page.sections)})
    end
    return obj
end
function O.SectionVisible(section)
    return not section.module or K.ModuleOn(section.module)
end
function O.PageVisible(page)
    if page.module and not K.ModuleOn(page.module) then return false end
    if table.getn(page.sections)==0 then return true end
    for _,section in ipairs(page.sections) do if O.SectionVisible(section) then return true end end
    return false
end
function O.EntryVisible(entry)
    local section=entry.sectionRef
    if entry.page.module and not K.ModuleOn(entry.page.module) then return false end
    return not section or not section.module or K.ModuleOn(section.module)
end
function O.Reflow(page)
    if not page.items then return end
    local shifts,total={},0
    for i,section in ipairs(page.sections) do
        shifts[i]=total
        section.offset=section.baseOffset-total
        if not O.SectionVisible(section) then
            local following=page.sections[i+1]
            total=total+(section.top-(following and following.top or page.endY or section.top))
        end
    end
    for _,item in ipairs(page.items) do
        local section=page.sections[item.section]
        if section and not O.SectionVisible(section) then
            item.obj:Hide(); item.hidden=true
        else
            if item.hidden then item.obj:Show(); item.hidden=nil end
            -- A control that the search shows temporarily lives on the result page; leave its anchor alone.
            if item.obj:GetParent()==page then
                item.obj:ClearAllPoints()
                item.obj:SetPoint(item.point,page,item.relative,item.x,item.y+(shifts[item.section] or 0))
            end
        end
    end
    if page.endY then page:SetHeight(math.max(viewport:GetHeight(),-(page.endY+total)+8)) end
end
function O.ReflowPages() for _,page in pairs(O.pages) do O.Reflow(page) end end
function O.ReflowAll()
    O.modulesSignature=O.ModuleSignature()
    O.ReflowPages()
    if O.current and O.current.items and not O.PageVisible(O.current) and O.pages.modules then O.ShowPage("modules")
    else
        if O.current then O.Scroll(O.current.offset or 0) end
        O.UpdateNavigation()
    end
    if O.afterReflow then O.afterReflow() end
end
function O.Section(page,text,module)
    module=module or page.module
    page.searchLast=nil
    local top=page.y
    if page.y<0 then page.y=page.y-12 end
    local fs=K.LText(page,text,13,"TOPLEFT",0,page.y,516); fs:SetTextColor(unpack(GOLD)); fs:SetHeight(19)
    table.insert(page.sections,{caption=text,offset=-page.y,baseOffset=-page.y,top=top,module=module,heading=fs})
    O.Track(page,fs,0,page.y)
    O.Track(page,Rule(page,0,page.y-22,516),0,page.y-22); page.y=page.y-36
end
function O.Help(page,text)
    local fs=K.LText(page,text,10,"TOPLEFT",0,page.y,512); fs:SetTextColor(.68,.67,.62); fs:SetHeight(32)
    if page.searchLast then table.insert(page.searchLast.help,text) end
    O.Track(page,fs,0,page.y)
    page.y=page.y-36; return fs
end
function O.Row(page,key,label,height)
    local row=CreateFrame("Button",nil,page); row:SetPoint("TOPLEFT",page,"TOPLEFT",0,page.y)
    row:SetWidth(O.width); row:SetHeight(height or 31)
    row.name=K.LText(row,label,11,"LEFT",0,0,300)
    row:SetBackdrop({bgFile=K.flat}); row:SetBackdropColor(0,0,0,0)
    row:SetScript("OnEnter",function() row:SetBackdropColor(.25,.2,.1,.2) end)
    row:SetScript("OnLeave",function() row:SetBackdropColor(0,0,0,0) end)
    O.Wheel(row); O.controls[key]=row; O.Track(page,row,0,page.y); page.y=page.y-(height or 31)
    O.SearchEntry(row,page,label,key)
    return row
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
-- Opens below the button; flips above it when the bottom edge would be crossed, otherwise slides to stay fully on screen.
-- The menu stays anchored to the button, only the offsets change.
function O.PlaceMenu(menu,button)
    menu:ClearAllPoints(); menu:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-3)
    local bb,bt,br=button:GetBottom(),button:GetTop(),button:GetRight()
    if type(bb)~="number" or type(bt)~="number" or type(br)~="number" then return end
    local ratio=button:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local s=menu:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local w,h=K.UIWidth(),K.UIHeight()
    local mh,mw=menu:GetHeight()*s,menu:GetWidth()*s
    local bottom,top,right=bb*ratio,bt*ratio,br*ratio
    local y,x=bottom-3*s,right   -- top and right edge of the menu in UIParent units
    local flipped,dx,dy=false,0,-3
    if y-mh<8 then
        if top+3*s+mh<=h-8 then flipped=true; dy=3
        else dy=-3+(math.max(mh+8,math.min(h-8,y))-y)/s end
    end
    dx=(math.max(mw+8,math.min(w-8,x))-x)/s
    menu:ClearAllPoints()
    if flipped then menu:SetPoint("BOTTOMRIGHT",button,"TOPRIGHT",dx,dy)
    else menu:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",dx,dy) end
end
function O.Choice(page,key,label,get,set,items,style)
    local row=O.Row(page,key,label,34)
    local button=O.Button(row,"",342,-2,170,function() end)
    O.Wheel(button)
    local text=button.text; text:SetWidth(146); text:SetJustifyH("LEFT"); text:ClearAllPoints(); text:SetPoint("LEFT",button,"LEFT",9,0)
    local arrow=K.Text(button,"v",9,"RIGHT",-8,0); arrow:SetTextColor(unpack(GOLD))
    row.value=text; row.items=items; row.button=button
    row.searchEntry.items=items
    local menuWidth,pitch=style and style.width or 170,style and style.pitch or 27
    local menu=CreateFrame("Frame",nil,shield); menu:SetWidth(menuWidth); menu:SetHeight(8+table.getn(items)*pitch); Skin(menu)
    row.menu=menu; row.options={}
    menu:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-3)
    for i,item in ipairs(items) do
        local value=item[1]   -- body local for the closure (see Statistics.lua)
        local option=O.Button(menu,item[2],4,-4-(i-1)*pitch,menuWidth-8,function() set(value); O.CloseChoice(); O.Refresh() end)
        option:SetHeight(pitch-2); option.value=value; table.insert(row.options,option)
        if style and style.decorate then style.decorate(option,value) end
    end
    local function Open()
        local was=O.openMenu==menu and shield:IsShown()
        O.CloseChoice()
        if was then return end
        for _,m in ipairs(O.menus or {}) do m:Hide() end
        O.openMenu=menu; O.Fit(); shield:SetScale(1); menu:SetScale(panel:GetEffectiveScale()/UIParent:GetEffectiveScale()); shield:Show(); menu:Show()
        O.PlaceMenu(menu,button)
        if style and style.refresh then style.refresh(row) end
    end
    O.menus=O.menus or {}; table.insert(O.menus,menu); menu:Hide()
    button:SetScript("OnClick",Open); row:SetScript("OnClick",Open)
    O.Watch(function() for _,v in ipairs(items) do if v[1]==get() then text:SetText(K.T(v[2])); return end end; text:SetText("?") end)
    return row
end
-- Font names stay readable in the interface font; the second line shows the
-- actual candidate for this language, including its fallback where needed.
function O.FontChoice(page)
    local function Sample(option,key)
        local path,factor,substituted=K.ResolveFont(K.lang,key)
        option.sample:SetFont(path,math.floor(12*factor+.5),"")
        option.sample:SetText(K.T("Abenteuer 123 · Schaden 456"))
        option.text:SetText(K.FontName(key)..(substituted and " *" or ""))
        option.selected:SetAlpha(K.FontChoice()==key and 1 or 0)
    end
    local row=O.Choice(page,"font","Schrift",K.FontChoice,K.SetFontChoice,K.fontChoices,{
        width=286,pitch=48,
        decorate=function(option,key)
            option.text:ClearAllPoints(); option.text:SetPoint("TOPLEFT",option,"TOPLEFT",10,-5)
            option.text:SetWidth(250); option.text:SetHeight(15); option.text:SetJustifyH("LEFT")
            option.sample=option:CreateFontString(nil,"OVERLAY")
            option.sample:SetPoint("TOPLEFT",option,"TOPLEFT",10,-25)
            option.sample:SetWidth(250); option.sample:SetHeight(18); option.sample:SetJustifyH("LEFT")
            option.sample:SetTextColor(.85,.84,.79)
            option.selected=option:CreateTexture(nil,"ARTWORK"); option.selected:SetTexture(K.flat)
            option.selected:SetPoint("TOPLEFT",option,"TOPLEFT",1,-2); option.selected:SetWidth(2); option.selected:SetHeight(42)
            option.selected:SetVertexColor(1,.82,.28,1)
            Sample(option,key)
        end,
        refresh=function(control) for _,option in ipairs(control.options) do Sample(option,option.value) end end
    })
    local preview=CreateFrame("Frame",nil,page); preview:SetWidth(516); preview:SetHeight(65)
    preview:SetPoint("TOPLEFT",page,"TOPLEFT",0,page.y); Skin(preview)
    preview.text=K.Text(preview,"",16,"TOPLEFT",12,-8,490); preview.text:SetHeight(23)
    preview.detail=K.Text(preview,"",10,"TOPLEFT",12,-39,490); preview.detail:SetHeight(18)
    preview.detail:SetTextColor(.75,.73,.68)
    O.Track(page,preview,0,page.y); page.y=page.y-73; row.preview=preview
    O.Watch(function()
        preview.text:SetText(K.T("Abenteuer 123 · Schaden 456"))
        local path,factor,substituted=K.ResolveFont(K.lang)
        preview.text:SetFont(path,math.floor(16*factor+.5),"")
        local actual=substituted and K.FontName("droid") or K.FontName(K.FontChoice())
        preview.detail:SetText(K.T("Vorschau")..": "..actual)
        for _,option in ipairs(row.options) do Sample(option,option.value) end
    end)
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
