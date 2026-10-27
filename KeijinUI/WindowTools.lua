-- Reversible changes to native windows. Only ordinary 1.12 region/frame APIs.
local K=KeijinUI
local W={}
K.windowTools=W
function W.Points(f)
    local out={}
    for i=1,f:GetNumPoints() do table.insert(out,{f:GetPoint(i)}) end
    return out
end
function W.Place(f,points)
    f:ClearAllPoints()
    for _,point in ipairs(points) do f:SetPoint(unpack(point)) end
end
function W.Remember(list,f)
    if not f or list[f] then return end
    local path,size,flags
    if f.GetFont then path,size,flags=f:GetFont() end
    list[f]={points=W.Points(f),width=f:GetWidth(),height=f:GetHeight(),scale=f.GetScale and f:GetScale(),
        alpha=f:GetAlpha(),font=path and {path,size,flags or ""} or nil}
end
function W.Anchor(list,f,parent,point,relative,x,y,width,height)
    if not f then return end
    W.Remember(list,f)
    f:ClearAllPoints(); f:SetPoint(point,parent,relative,x,y)
    if width then f:SetWidth(width) end
    if height then f:SetHeight(height) end
end
function W.Font(list,fs,size)
    if not fs or not fs.SetFont then return end
    W.Remember(list,fs)
    local original=list[fs].font
    if not original then return end
    local path=W.FontForText(fs:GetText(),original[1])
    local points=size or original[2]
    points=path==K.font and K.FontSize(points) or points
    local current,currentSize,flags=fs:GetFont()
    if current~=path or currentSize~=points or flags~=original[3] then fs:SetFont(path,points,original[3]) end
end
local function Glyph(entry,cp)
    if cp==9 or cp==10 or cp==13 then return true end
    local ranges=entry and entry.ranges
    if not ranges then return false end
    local lo,hi=1,table.getn(ranges)/2
    while lo<=hi do
        local mid=math.floor((lo+hi)/2)
        if cp<ranges[mid*2-1] then hi=mid-1
        elseif cp>ranges[mid*2] then lo=mid+1
        else return true end
    end
    return false
end
local function Covers(entry,text)
    if not entry then return false end
    local i,length=1,string.len(text or "")
    while i<=length do
        local cp=string.byte(text,i)
        local bytes=1
        if cp>=194 and cp<=223 then bytes=2; cp=cp-192
        elseif cp>=224 and cp<=239 then bytes=3; cp=cp-224
        elseif cp>=240 and cp<=244 then bytes=4; cp=cp-240
        elseif cp>=128 then return false end
        for j=1,bytes-1 do
            local b=string.byte(text,i+j)
            if not b or b<128 or b>191 then return false end
            cp=cp*64+b-128
        end
        if not Glyph(entry,cp) then return false end
        i=i+bytes
    end
    return true
end
-- Native labels and player names may use a different language from K.lang.
-- Check their actual glyphs rather than assuming the chosen interface language.
function W.FontForText(text,original)
    local chosen,wide
    for _,entry in ipairs(KeijinFontCatalog or {}) do
        if entry.path==K.font then chosen=entry end
        if entry.path==K.WideFont then wide=entry end
    end
    if Covers(chosen,text) then return K.font end
    if Covers(wide,text) then return K.WideFont end
    return original or K.WideFont
end
function W.Restore(list)
    for f,s in pairs(list) do
        W.Place(f,s.points); f:SetWidth(s.width); f:SetHeight(s.height)
        if s.scale then f:SetScale(s.scale) end
        f:SetAlpha(s.alpha)
        if s.font then f:SetFont(unpack(s.font)) end
        if s.nativeText~=nil then f:SetText(s.nativeText) end
        if s.windowSkin then s.windowSkin:Hide() end
        if s.restoreShown~=nil then
            if s.restoreShown then f:Show() else f:Hide() end
        end
    end
end
function W.Art(list,f,pattern)
    if not f or not f.GetRegions then return end
    for _,region in ipairs({f:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType()=="Texture" then
            local path=region:GetTexture()
            if type(path)=="string" and string.find(string.lower(path),pattern,1,true) then
                W.Remember(list,region); region:SetAlpha(0)
            end
        end
    end
end
function W.Hook(f,name,after)
    local original=f:GetScript(name)
    f:SetScript(name,function()
        if original then original() end
        after()
    end)
end
-- Window title bars are draggable without enabling HUD editing or holding a key.
function W.Drag(bar,key,parent)
    bar:EnableMouse(true); bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnMouseDown",function() if arg1=="LeftButton" then K.layout.BeginMove(key,true) end end)
    bar:SetScript("OnDragStart",function() K.layout.BeginMove(key,true) end)
    local function Stop() K.layout.EndMove(key) end
    bar:SetScript("OnMouseUp",function() if arg1=="LeftButton" then Stop() end end)
    bar:SetScript("OnDragStop",Stop); bar:SetScript("OnHide",Stop)
    W.Hook(parent,"OnMouseUp",function() if arg1=="LeftButton" then Stop() end end)
end
local buttonSkins={}
function W.Button(list,button,text,selected)
    if not button then return end
    W.Remember(list,button)
    local skin=buttonSkins[button]
    if not skin then
        skin=CreateFrame("Frame",nil,button)
        skin.keijinWindowArt=true; skin:SetAllPoints(button)
        skin:SetFrameLevel(button:GetFrameLevel()+1); skin:EnableMouse(false)
        K.Chamfer(skin,4,{.055,.055,.065,1},{.67,.57,.36,1})
        skin.label=K.Text(skin,"",11,"CENTER",0,0)
        skin.label:SetJustifyH("CENTER")
        W.Hook(button,"OnEnter",function() skin.hover=true end)
        W.Hook(button,"OnLeave",function() skin.hover=false end)
        buttonSkins[button]=skin
    end
    list[button].windowSkin=skin
    -- Keep the native button and its scripts, replace only its artwork.
    for _,r in ipairs({button:GetRegions()}) do W.Remember(list,r); r:SetAlpha(0) end
    for _,method in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
        if button[method] then
            local r=button[method](button)
            if r then W.Remember(list,r); r:SetAlpha(0) end
        end
    end
    local pressed=button.GetButtonState and button:GetButtonState()=="PUSHED"
    skin:SetBackdropColor(selected and .17 or .055,selected and .13 or .055,.065,1)
    if selected or pressed or skin.hover then skin:SetBackdropBorderColor(1,.82,.35,1)
    else skin:SetBackdropBorderColor(.67,.57,.36,1) end
    skin.label:SetWidth(math.max(8,button:GetWidth()-10))
    skin.label:SetText(text or (button.GetText and button:GetText()) or "")
    local path=W.FontForText(skin.label:GetText(),K.WideFont)
    local points=path==K.font and K.FontSize(11) or 11
    skin.label:SetFont(path,points,"")
    local measured=skin.label:GetStringWidth()
    local available=math.max(8,button:GetWidth()-10)
    if measured>available then skin.label:SetFont(path,math.max(8,math.floor(points*available/measured)),"") end
    skin.label:SetHeight(16)
    skin:Show()
    return skin
end
local slotSkins={}
function W.Slot(list,button)
    if not button then return end
    W.Remember(list,button)
    local skin=slotSkins[button]
    if not skin then
        skin=CreateFrame("Frame",nil,button)
        skin.keijinWindowArt=true; skin:SetAllPoints(button)
        skin:SetFrameLevel(button:GetFrameLevel()+1); skin:EnableMouse(false)
        K.Chamfer(skin,2,nil,{.62,.57,.43,1})
        slotSkins[button]=skin
    end
    local normal=button:GetName() and getglobal(button:GetName().."NormalTexture")
    if normal then W.Remember(list,normal); normal:SetAlpha(0) end
    list[button].windowSkin=skin; skin:Show()
end
