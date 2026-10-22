-- Original sculpted unit frames using ordinary 1.12 textures.
local K=KeijinUI
K.UnitFrameShapes={}
local S=K.UnitFrameShapes
local PATH="Interface\\AddOns\\KeijinUI\\media\\soft\\"

-- ConnectedHealth contains the join to the round portrait in its alpha channel.
-- Crop the texture and its geometry together; shrinking only its width would
-- stretch the join and produce the wrong shape at partial health.
function S.ConnectedFill(parent,name,mirror)
    local width,height=parent:GetWidth()+16,28
    local f=CreateFrame("Frame",name,parent)
    f:SetWidth(width); f:SetHeight(height)
    f:SetFrameLevel(parent:GetFrameLevel()+1)
    -- Keep the portrait join and end chamfer at their original size. Only the
    -- straight middle grows, and each segment is cropped as health falls.
    local spans={{28,0,28/174},{width-36,28/174,166/174},{8,166/174,1}}
    f.parts={}
    local start=0
    for _,span in ipairs(spans) do
        local part=f:CreateTexture(nil,"ARTWORK")
        part:SetTexture(PATH.."ConnectedHealth.tga"); part:SetHeight(height)
        part:SetPoint(mirror and "RIGHT" or "LEFT",f,mirror and "RIGHT" or "LEFT",mirror and -start or start,0)
        table.insert(f.parts,{texture=part,start=start,width=span[1],u=span[2],v=span[3]})
        start=start+span[1]
    end
    f.fill=f.parts[1].texture
    function f:SetValue(value)
        self.value=math.max(0,math.min(1,tonumber(value) or 0))
        for _,part in ipairs(self.parts) do
            local w=math.min(part.width,math.max(0,width*self.value-part.start))
            if w>0 then
                part.texture:SetWidth(w)
                local v=part.u+(part.v-part.u)*w/part.width
                if mirror then part.texture:SetTexCoord(v,part.u,0,1)
                else part.texture:SetTexCoord(part.u,v,0,1) end
                part.texture:Show()
            else part.texture:Hide() end
        end
    end
    function f:SetStatusBarColor(r,g,b)
        self.color={r,g,b}
        for _,part in ipairs(self.parts) do part.texture:SetVertexColor(r,g,b,1) end
    end
    function f:GetStatusBarColor() return unpack(self.color) end
    function f:GetValue() return self.value end
    f:SetStatusBarColor(1,1,1); f:SetValue(0)
    return f
end

-- Absorb shield on a health bar of cropped pieces (bar.parts, as in ConnectedFill and the compact frame):
-- a translucent light layer from the current health to the right, cut at the bar end, plus a bright
-- strip at the bar end when health plus shield exceeds the maximum. Both layers reuse the texture of the
-- fill, so they follow the bar's shape (portrait join, chamfered end). Not for mirrored bars.
local SHIELD_COLOR={0.78,0.92,1,0.5}
local OVERFLOW_W=3
function S.AddShield(bar,file)
    local total=bar:GetWidth()
    local bands={shield={},edge={}}
    for key,list in pairs(bands) do
        for i,part in ipairs(bar.parts) do
            local t=bar:CreateTexture(nil,"OVERLAY")
            t:SetTexture(file); t:SetHeight(part.texture:GetHeight())
            if key=="shield" then t:SetVertexColor(SHIELD_COLOR[1],SHIELD_COLOR[2],SHIELD_COLOR[3],SHIELD_COLOR[4])
            else t:SetVertexColor(1,1,1,0.95) end
            t:Hide(); list[i]=t
        end
    end
    bar.shieldBands=bands
    local function Band(list,from,to)
        for i,part in ipairs(bar.parts) do
            local t=list[i]
            local x1,x2=math.max(from,part.start),math.min(to,part.start+part.width)
            if x2>x1 then
                local ul=part.u+(part.v-part.u)*(x1-part.start)/part.width
                local ur=part.u+(part.v-part.u)*(x2-part.start)/part.width
                t:ClearAllPoints(); t:SetPoint("LEFT",bar,"LEFT",x1,0)
                t:SetWidth(x2-x1); t:SetTexCoord(ul,ur,0,1); t:Show()
            else t:Hide() end
        end
    end
    -- health and shield as shares of the maximum health (shield may be missing or zero: layers hidden).
    function bar:SetShield(health,shield)
        health=math.max(0,math.min(1,tonumber(health) or 0))
        if not K.Number(shield) or shield<=0 then
            self.shield=nil; Band(bands.shield,0,0); Band(bands.edge,0,0); return
        end
        local over=health+shield>1
        self.shield={from=health,to=math.min(1,health+shield),over=over}
        Band(bands.shield,health*total,self.shield.to*total)
        if over then Band(bands.edge,total-OVERFLOW_W,total) else Band(bands.edge,0,0) end
    end
    bar:SetShield(0,0)
end

-- Extend the straight shoulder without stretching the round portrait or rim.
function S.Housing(parent,layer,file,width,height,mirror)
    local spans={{60,0,60/206},{width-76,60/206,190/206},{16,190/206,1}}
    local art={parts={}}
    local start=0
    for _,span in ipairs(spans) do
        local tex=S.Texture(parent,layer,file,span[1],height,mirror and width-start-span[1] or start,0)
        tex:SetTexCoord(mirror and span[3] or span[2],mirror and span[2] or span[3],0,1)
        table.insert(art.parts,tex); start=start+span[1]
    end
    function art:SetVertexColor(r,g,b,a)
        self.color={r,g,b,a}
        for _,part in ipairs(self.parts) do part:SetVertexColor(r,g,b,a) end
    end
    return art
end

function S.Texture(parent,layer,file,width,height,x,y)
    local tex=parent:CreateTexture(nil,layer)
    tex:SetTexture(PATH..file)
    tex:SetWidth(width); tex:SetHeight(height)
    tex:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    return tex
end
