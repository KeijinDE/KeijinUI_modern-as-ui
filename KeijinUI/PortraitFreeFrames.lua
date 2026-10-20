-- Compact closed unit frame without portrait (170 x 48). Geometry only: it is built once inside the
-- stable outer frame of Units.lua, which keeps the data, colours, clicks, tooltip and layout entry.
local K=KeijinUI
-- The artwork is drawn for 206 points; the fixed ends keep that scale, only the middle is shortened.
local P={W=170,H=48,HEAD=20,ART=206}
K.PortraitFree=P
local PATH="Interface\\AddOns\\KeijinUI\\media\\portraitfree\\"
local W,H,HEAD=P.W,P.H,P.HEAD
-- Three pieces with fixed 16 point ends; width and texture coordinates are cropped together.
local function Pieces(parent,layer,file,height,mirror)
    local art={parts={}}
    local edge=16/P.ART
    local spans={{16,0,edge},{W-32,edge,1-edge},{16,1-edge,1}}
    local start=0
    for _,span in ipairs(spans) do
        local t=parent:CreateTexture(nil,layer)
        t:SetTexture(PATH..file); t:SetHeight(height)
        t:SetPoint(mirror and "RIGHT" or "LEFT",parent,mirror and "RIGHT" or "LEFT",mirror and -start or start,0)
        t:SetWidth(span[1])
        t:SetTexCoord(mirror and span[3] or span[2],mirror and span[2] or span[3],0,1)
        table.insert(art.parts,{texture=t,start=start,width=span[1],u=span[2],v=span[3]})
        start=start+span[1]
    end
    function art:SetVertexColor(r,g,b,a)
        for _,part in ipairs(self.parts) do part.texture:SetVertexColor(r,g,b,a or 1) end
    end
    return art
end
-- Builds the geometry inside parent and returns its fields: root, body, bar, rim, label, level, health, percent.
function P.Build(parent,name,mirror)
    local g={mirror=mirror}
    local root=CreateFrame("Frame",nil,parent)
    root:SetWidth(W); root:SetHeight(H); root:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0)
    root:SetFrameLevel(parent:GetFrameLevel()+1)
    g.root=root
    g.body=Pieces(root,"BACKGROUND","Back.tga",H,mirror)
    local bar=CreateFrame("Frame",name.."CleanHealth",root)
    bar:SetWidth(W); bar:SetHeight(H-HEAD)
    bar:SetPoint("TOPLEFT",root,"TOPLEFT",0,-HEAD)
    bar:SetFrameLevel(root:GetFrameLevel()+1)
    local fill=Pieces(bar,"ARTWORK","Health.tga",H-HEAD,mirror)
    bar.parts=fill.parts
    function bar:SetValue(value)
        self.value=math.max(0,math.min(1,tonumber(value) or 0))
        for _,part in ipairs(self.parts) do
            local visible=math.min(part.width,math.max(0,W*self.value-part.start))
            if visible>0 then
                local stop=part.u+(part.v-part.u)*visible/part.width
                part.texture:SetWidth(visible)
                part.texture:SetTexCoord(mirror and stop or part.u,mirror and part.u or stop,0,1)
                part.texture:Show()
            else part.texture:Hide() end
        end
    end
    function bar:GetValue() return self.value end
    function bar:SetStatusBarColor(r,g,b) self.color={r,g,b}; fill:SetVertexColor(r,g,b,1) end
    function bar:GetStatusBarColor() return unpack(self.color) end
    bar:SetStatusBarColor(1,1,1); bar:SetValue(0)
    g.bar=bar
    local rimLayer=CreateFrame("Frame",nil,root)
    rimLayer:SetAllPoints(root); rimLayer:SetFrameLevel(bar:GetFrameLevel()+2)
    g.rim=Pieces(rimLayer,"OVERLAY","Rim.tga",H,mirror)
    g.rim:SetVertexColor(0.78,0.69,0.50,1)
    local text=CreateFrame("Frame",nil,root)
    text:SetAllPoints(root); text:SetFrameLevel(rimLayer:GetFrameLevel()+1)
    local function Label(left,size,w,y,right)
        local fs=K.Text(text,"",size,"TOPLEFT",mirror and W-left-w or left,y,w)
        fs:SetJustifyH((mirror and not right or not mirror and right) and "RIGHT" or "LEFT")
        fs:SetHeight(14)
        return fs
    end
    g.label=Label(12,11,W-70,-4,false); g.label:SetTextColor(1,0.82,0.28)
    g.level=Label(W-45,10,31,-5,true); g.level:SetTextColor(1,0.82,0.28)
    g.health=Label(12,10,W-80,-28,false)
    g.percent=Label(W-50,10,36,-28,true)
    root:Hide()
    return g
end
