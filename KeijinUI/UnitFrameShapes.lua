-- Original sculpted unit frames using ordinary 1.12 textures.
local K=KeijinUI
K.UnitFrameShapes={}
local S=K.UnitFrameShapes
local PATH="Interface\\AddOns\\KeijinUI\\media\\soft\\"

-- ConnectedHealth contains the join to the round portrait in its alpha channel.
-- Crop the texture and its geometry together; shrinking only its width would
-- stretch the join and produce the wrong shape at partial health.
function S.ConnectedFill(parent,name,mirror)
    local width,height=174,28
    local f=CreateFrame("Frame",name,parent)
    f:SetWidth(width); f:SetHeight(height)
    f:SetFrameLevel(parent:GetFrameLevel()+1)
    f.fill=f:CreateTexture(nil,"ARTWORK")
    f.fill:SetTexture(PATH.."ConnectedHealth.tga")
    f.fill:SetHeight(height)
    f.fill:SetPoint(mirror and "RIGHT" or "LEFT",f,mirror and "RIGHT" or "LEFT",0,0)
    function f:SetValue(value)
        self.value=math.max(0,math.min(1,tonumber(value) or 0))
        if self.value<=0 then self.fill:Hide(); return end
        self.fill:SetWidth(width*self.value)
        if mirror then self.fill:SetTexCoord(self.value,0,0,1)
        else self.fill:SetTexCoord(0,self.value,0,1) end
        self.fill:Show()
    end
    function f:SetStatusBarColor(r,g,b)
        self.color={r,g,b}
        self.fill:SetVertexColor(r,g,b,1)
    end
    function f:GetStatusBarColor() return unpack(self.color) end
    function f:GetValue() return self.value end
    f:SetStatusBarColor(1,1,1); f:SetValue(0)
    return f
end

function S.Texture(parent,layer,file,width,height,x,y)
    local tex=parent:CreateTexture(nil,layer)
    tex:SetTexture(PATH..file)
    tex:SetWidth(width); tex:SetHeight(height)
    tex:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    return tex
end
