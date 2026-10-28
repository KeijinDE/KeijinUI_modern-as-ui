-- Personal dimensions are separate from layout positions and survive moving/docking.
-- Missing fields deliberately keep the pre-sizing appearance, without a migration.
local K=KeijinUI
local P={entries={},frames={},offsets={},counts={}}
K.panelSizing=P
P.order={{"tracker","Runübersicht",8},{"statistics","Runstatistiken",7},{"meter","Schadensanzeige",8},{"crits","Kritische Treffer",8},{"attributes","Charakterwerte",29}}
local function Finite(v) return type(v)=="number" and v==v and math.abs(v)<1e15 end
local function Bound(v,low,high,fallback)
    if not Finite(v) then return fallback end
    return math.max(low,math.min(high,v))
end
function P.Config(key)
    local all=K.DB().panelSizing
    local c=type(all)=="table" and all[key]
    if type(c)~="table" then return {} end
    return {width=Bound(c.width,180,1200,nil),rows=Bound(c.rows,1,P.Maximum(key),nil),font=Bound(c.font,8,20,nil)}
end
function P.Maximum(key)
    for _,v in ipairs(P.order) do if v[1]==key then return v[3] end end
    return 1
end
-- Numeric editor uses the same setting units and limits for every UI scale.
-- Defaults are settings, never measurements of the rendered frame.
function P.Values(key)
    local c=P.Config(key)
    return math.floor((c.width or K.PANEL_WIDTH)+.5),math.floor((c.font or 11)+.5)
end
function P.HeightRows(key,height)
    local f=P.entries[key].frame
    local count=P.counts[key]
    local rows=count and count[2] or P.Rows(key,P.Maximum(key))
    local _,step=P.Metrics(key,key=="tracker" and 18 or 20)
    -- Subtract the real header/footer (clock, pace and guardians for tracker).
    local fixed=f:GetHeight()-rows*step
    return math.max(1,math.min(P.Maximum(key),math.floor((height-fixed)/step+.5)))
end
function P.On(key)
    if not P.entries[key] then return false end
    if key=="attributes" then return K.ModuleOn("attributes") end
    return K.ModuleOn("basisHud")
end
function P.Custom(key)
    local c=P.Config(key)
    return c.width or c.rows or c.font
end
function K.PanelFontSize(fs,size)
    local parent=fs
    while parent do
        local key=P.frames[parent]
        if key then
            if not P.On(key) then return size end
            local font=P.Config(key).font
            if font then return size*font/11/math.max(.01,parent:GetEffectiveScale()) end
            return size
        end
        parent=parent.GetParent and parent:GetParent() or nil
    end
    return size
end
function P.Fonts(key)
    if not P.On(key) then return end
    for _,v in ipairs(K.fontStrings or {}) do
        local fs=v[1]; local parent=fs
        while parent and parent~=P.entries[key].frame do parent=parent.GetParent and parent:GetParent() or nil end
        if parent then K.SetFontSize(fs,K.fontBase[fs] or v[2]) end
    end
end
function P.Factor(key)
    local c=P.Config(key)
    return (c.font and c.font/11/math.max(.01,P.entries[key].frame:GetEffectiveScale()) or 1)*(K.fontFactor or 1)
end
function P.Metrics(key,baseStep)
    local f=P.entries[key].frame
    local q=P.Factor(key)
    local step=math.max(baseStep,math.ceil(26*q))
    local pad=math.max(0,math.ceil(18*q-18))
    return q,step,pad
end
-- Measure actual glyphs in the selected font. A label keeps room for at least
-- eight glyphs and two lines; numeric columns never borrow the label's space.
local measure=UIParent:CreateFontString(nil,"OVERLAY")
measure:Hide()
function P.Measure(fs,text)
    local path,size,flags=fs:GetFont()
    measure:SetFont(path or K.font,size or 11,flags or "OUTLINE")
    measure:SetText(text or "")
    return measure:GetStringWidth()
end
function P.Width(key,minimum)
    local f=P.entries[key].frame
    local c=P.Config(key)
    if not P.Custom(key) then return f:GetWidth() end
    local title=P.Measure(f.title,K.T(P.entries[key].name))
    minimum=math.max(minimum or 180,f.sizingMinimum or 0,math.min(title,420*P.Factor(key))+26)
    local width=math.max(minimum,c.width or K.PANEL_WIDTH)
    f:SetWidth(width); f.title:SetWidth(width-26)
    return width
end
function P.AvailableHeight(key)
    local f=P.entries[key].frame
    return (K.UIHeight()-16)*UIParent:GetEffectiveScale()/math.max(.01,f:GetEffectiveScale())
end
function P.Rows(key,fallback)
    local c=P.Config(key)
    return math.floor(c.rows or fallback)
end
function P.Range(key,total,visible)
    total=math.max(0,total); visible=math.max(1,visible)
    P.counts[key]={total,visible}
    local offset=Bound(P.offsets[key],0,math.max(0,total-visible),0)
    offset=math.floor(offset); P.offsets[key]=offset
    return offset
end
function P.Scroll(key,delta)
    if not P.On(key) then return end
    if K.layout.Active() then
        local e=K.layout.entries[key]
        if e then local old=arg1; arg1=delta; e.handle:GetScript("OnMouseWheel")(); arg1=old end
        return
    end
    local range=P.counts[key] or {0,1}
    P.offsets[key]=(P.offsets[key] or 0)+(delta>0 and -1 or 1)
    P.Range(key,range[1],range[2]); P.Refresh(key)
end
function P.Register(key,frame,name,refresh)
    P.entries[key]={frame=frame,name=name,refresh=refresh,baseWidth=frame:GetWidth()}; P.frames[frame]=key
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel",function() P.Scroll(key,arg1) end)
    local native=frame.SetScale
    frame.SetScale=function(self,scale)
        native(self,scale)
        if P.Custom(key) then P.Refresh(key) end
    end
end
-- Shared two-line label/value geometry, including artwork rebuilt at its new width.
local function Remember(objects,obj)
    if objects[obj] then return end
    local points={}
    for i=1,obj:GetNumPoints() do points[i]={obj:GetPoint(i)} end
    local parent=obj.GetParent and obj:GetParent()
    local hp=parent and parent.headerPoints and parent.headerPoints[obj]
    objects[obj]={width=obj:GetWidth(),height=obj:GetHeight(),points=points,labelWidth=obj.labelWidth,
        header=hp and {hp[1],hp[2],hp[3],hp[4]} or nil}
end
function P.Restore(key)
    local e=P.entries[key]
    if not e or not e.original then return end
    for obj,g in pairs(e.original) do
        obj:SetWidth(g.width); obj:SetHeight(g.height)
        if g.labelWidth then obj.labelWidth=g.labelWidth end
        if obj~=e.frame then
            obj:ClearAllPoints()
            for _,point in ipairs(g.points) do obj:SetPoint(unpack(point)) end
            local parent=obj.GetParent and obj:GetParent()
            if parent and parent.headerPoints then parent.headerPoints[obj]=g.header end
        end
    end
    for _,row in ipairs(e.rows or {}) do if row.ResizeArtwork then row:ResizeArtwork() end end
    e.frame:SetWidth(e.baseWidth); e.frame.title:SetWidth(e.baseWidth-26)
    e.original=nil; e.frame.sizingMinimum=nil
    if K.headers.Apply then K.headers.Apply(e.frame) end
end
function P.List(key,rows,total,fallback,baseStep,footer)
    local e=P.entries[key]; local f=e.frame
    -- Explicit row settings reserve space even when no data fills it.
    local visible=P.Config(key).rows or math.min(total,P.Rows(key,fallback)); visible=math.max(1,visible)
    local offset=P.Range(key,total,visible)
    if not P.Custom(key) then P.Restore(key); return visible,offset,baseStep end
    if not e.original then
        e.original={}; e.rows=rows
        Remember(e.original,f); Remember(e.original,f.title); Remember(e.original,f.strip)
        for _,row in ipairs(rows) do
            Remember(e.original,row); Remember(e.original,row.label); Remember(e.original,row.value)
            if row.dps then Remember(e.original,row.dps) end
        end
    end
    P.Fonts(key)
    local q,step,pad=P.Metrics(key,baseStep)
    local available=P.AvailableHeight(key)
    visible=math.max(1,math.min(visible,math.floor((available-42-pad-(footer or 0))/step)))
    offset=P.Range(key,total,visible)
    local sample=rows[1]
    local value=math.max(64,P.Measure(sample.value,key=="statistics" and "999.9k / 999.9k" or "999.9k"))+10
    local dps=sample.dps and math.max(62,P.Measure(sample.dps,"999.9k DPS"))+8 or 0
    local labelMin=P.Measure(sample.label,"MMMMMMMM")+10
    local icon=sample.icon and sample.iconSize+3 or 0
    local width=P.Width(key,30+value+dps+labelMin+icon)
    f.title:SetHeight(math.max(17,15*q)); f.strip:SetHeight(math.max(23,18*q))
    for i,row in ipairs(rows) do
        K.HeaderPoint(row,f,"TOPLEFT",10,-33-pad-(i-1)*step)
        row:SetWidth(width-20); row:SetHeight(step-2)
        row.value:ClearAllPoints(); row.value:SetPoint("RIGHT",row,"RIGHT",-5-dps,0)
        row.value:SetWidth(value); row.value:SetHeight(step-4); row.value:SetJustifyH("RIGHT")
        row.labelWidth=width-35-value-dps
        row.label:SetWidth(row.labelWidth-icon); row.label:SetHeight(step-4)
        row:EnableMouseWheel(true)
        if not row.sizingWheel then
            row.sizingWheel=key
            row:SetScript("OnMouseWheel",function() P.Scroll(this.sizingWheel,arg1) end)
        end
        if row.dps then row.dps:SetWidth(dps-6); row.dps:SetHeight(step-4) end
        if row.ResizeArtwork then row:ResizeArtwork() end
    end
    f:SetHeight(42+pad+visible*step+(footer or 0))
    return visible,offset,step
end
local refreshing
function P.Refresh(key)
    if refreshing then return end
    refreshing=true
    for name,e in pairs(P.entries) do
        if (not key or name==key) and P.On(name) then
            P.Fonts(name)
            if e.refresh then e.refresh() end
        end
    end
    refreshing=nil
    if K.layout.SyncFollowers then K.layout.SyncFollowers() end
end
function P.Set(key,field,value,live)
    if not P.entries[key] or (field~="width" and field~="rows" and field~="font") then return false end
    if value~=nil and not Finite(value) then return false end
    local db=K.DB()
    if type(db.panelSizing)~="table" then db.panelSizing={} end
    if type(db.panelSizing[key])~="table" then db.panelSizing[key]={} end
    local low,high=180,1200
    if field=="rows" then low,high=1,P.Maximum(key) elseif field=="font" then low,high=8,20 end
    if value and (field=="rows" or field=="width") then value=math.floor(value+.5) end
    db.panelSizing[key][field]=value and Bound(value,low,high,nil) or nil
    P.Refresh(key); if not live then K.layout.Place(key) end
    if not live and K.layoutSizing then K.layoutSizing.Changed(key) end
    return true
end
function P.Reset(key)
    local all=K.DB().panelSizing
    if type(all)=="table" then if key then all[key]=nil else K.DB().panelSizing=nil end end
    if key then P.offsets[key]=nil else P.offsets={} end
    for name in pairs(P.entries) do if not key or name==key then P.Restore(name) end end
    P.Refresh(key)
    if K.layoutSizing then
        if key then K.layoutSizing.Changed(key)
        else for name in pairs(P.entries) do K.layoutSizing.Changed(name) end end
    end
end
local setHeaders=K.headers.Set
K.headers.Set=function(mode) setHeaders(mode); P.Refresh() end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then P.Refresh() end end)
K.OnLang(function() P.Refresh() end)
-- A changed effective UI scale changes font compensation even without a local SetScale.
local scales={}
table.insert(K.updates,function()
    for key,e in pairs(P.entries) do
        local scale=e.frame:GetEffectiveScale()
        if P.On(key) and scale~=scales[key] then scales[key]=scale; if P.Custom(key) then P.Refresh(key) end end
    end
end)
