-- Original chamfered geometry. Ordinary 1.12 texture regions, no masks or later-client APIs.
local K=KeijinUI
local PATH="Interface\\AddOns\\KeijinUI\\media\\chamfer\\"
local function Piece(parent,layer,file,index)
    local tex=parent:CreateTexture(nil,layer)
    tex:SetTexture(PATH..file..".tga")
    tex:SetTexCoord(index/8+0.5/256,(index+1)/8-0.5/256,0.5/32,31.5/32)
    return tex
end
local function Position(t,f,cut)
    local corners={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
    for i=1,4 do
        local p=t[i+4]; p:ClearAllPoints(); p:SetWidth(cut); p:SetHeight(cut); p:SetPoint(corners[i],f,corners[i],0,0)
    end
    local ends={{"TOPLEFT",0,-cut,"BOTTOMLEFT",0,cut},{"TOPRIGHT",0,-cut,"BOTTOMRIGHT",0,cut},
        {"TOPLEFT",cut,0,"TOPRIGHT",-cut,0},{"BOTTOMLEFT",cut,0,"BOTTOMRIGHT",-cut,0}}
    for i=1,4 do
        local p,a=t[i],ends[i]; p:ClearAllPoints()
        p:SetPoint(a[1],f,a[1],a[2],a[3]); p:SetPoint(a[4],f,a[4],a[5],a[6])
        if i<=2 then p:SetWidth(cut) else p:SetHeight(cut) end
    end
end
-- A real nine-slice background avoids the rectangular fill poking through cut corners.
-- Colour setters remain compatible with the existing panel, quality and hover code.
function K.Chamfer(frame,cut,bg,border)
    cut=cut or 6
    local s=frame.chamfer
    if not s then
        frame:SetBackdrop({})
        s={back={},rim={},cut=cut}; frame.chamfer=s
        for i=1,8 do s.back[i]=Piece(frame,"BACKGROUND","Back",i-1) end
        local middle=frame:CreateTexture(nil,"BACKGROUND"); middle:SetTexture(K.flat); s.back[9]=middle
        local file=cut<=2 and "IconRim" or (cut<=4 and "BarRim" or "PanelRim")
        for i=1,8 do s.rim[i]=Piece(frame,"OVERLAY",file,i-1) end
        frame.SetBackdropColor=function(self,r,g,b,a)
            local shape=self.chamfer; shape.background={r,g,b,a or 1}
            for _,t in ipairs(shape.back) do t:SetVertexColor(r,g,b,a or 1) end
        end
        frame.SetBackdropBorderColor=function(self,r,g,b,a)
            local shape=self.chamfer; shape.border={r,g,b,a or 1}
            for _,t in ipairs(shape.rim) do t:SetVertexColor(r,g,b,a or 1) end
        end
    end
    if cut~=s.cut then
        s.cut=cut
        local file=cut<=2 and "IconRim" or (cut<=4 and "BarRim" or "PanelRim")
        for _,t in ipairs(s.rim) do t:SetTexture(PATH..file..".tga") end
    end
    Position(s.back,frame,cut); Position(s.rim,frame,cut)
    s.back[9]:ClearAllPoints(); s.back[9]:SetPoint("TOPLEFT",frame,"TOPLEFT",cut,-cut)
    s.back[9]:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-cut,cut)
    for _,t in ipairs(s.back) do if bg then t:Show() else t:Hide() end end
    if bg then frame:SetBackdropColor(unpack(bg)) end
    frame:SetBackdropBorderColor(unpack(border or {0.62,0.57,0.43,1}))
    return s
end

-- A clipped three-piece fill: shrinking geometry AND UVs keeps a partial left end intact.
function K.CutFill(parent)
    local fill={parts={}}
    for i=1,3 do
        local t=parent:CreateTexture(nil,"ARTWORK")
        t:SetTexture("Interface\\AddOns\\KeijinUI\\media\\list\\"..(i==2 and "FillMid.tga" or "FillCap.tga"))
        fill.parts[i]=t
    end
    function fill:Color(r,g,b,a)
        a=a or 1
        if self.r==r and self.g==g and self.b==b and self.a==a then return end
        self.r,self.g,self.b,self.a=r,g,b,a
        for _,t in ipairs(self.parts) do t:SetVertexColor(r,g,b,a or 1) end
    end
    function fill:Paint(width,height,value,x,y)
        if width<=0 or height<=0 then return end
        local cap=math.min(height*0.4,width/2)
        value=math.max(0,math.min(1,tonumber(value) or 0))
        if self.width==width and self.height==height and self.value==value and self.x==x and self.y==y then return end
        self.width,self.height,self.value,self.x,self.y=width,height,value,x,y
        local visible=width*value
        local lengths={math.min(cap,visible),math.max(0,math.min(width-2*cap,visible-cap)),math.max(0,visible-width+cap)}
        local lefts={0,cap,width-cap}
        for i,t in ipairs(self.parts) do
            local n=lengths[i]
            if n>0 then
                t:ClearAllPoints(); t:SetPoint("TOPLEFT",parent,"TOPLEFT",(x or 0)+lefts[i],(y or 0))
                t:SetWidth(n); t:SetHeight(height)
                local u=31.5/32
                if i==1 then t:SetTexCoord(0,u*n/cap,0,1)
                elseif i==3 then t:SetTexCoord(u,u*(1-n/cap),0,1)
                else t:SetTexCoord(0.25,0.75,0,1) end
                t:Show()
            else t:Hide() end
        end
    end
    fill:Color(1,1,1,1)
    return fill
end
