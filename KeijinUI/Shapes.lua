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
            local shape=self.chamfer
            local c=shape.background
            if c and c[1]==r and c[2]==g and c[3]==b and c[4]==(a or 1) then return end
            if c then c[1],c[2],c[3],c[4]=r,g,b,a or 1 else shape.background={r,g,b,a or 1} end
            for _,t in ipairs(shape.back) do t:SetVertexColor(r,g,b,a or 1) end
        end
        frame.SetBackdropBorderColor=function(self,r,g,b,a)
            local shape=self.chamfer
            local c=shape.border
            if c and c[1]==r and c[2]==g and c[3]==b and c[4]==(a or 1) then return end
            if c then c[1],c[2],c[3],c[4]=r,g,b,a or 1 else shape.border={r,g,b,a or 1} end
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
    if K.ApplyWindow then K.ApplyWindow(frame) end
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


-- Only the run timeline uses this raster. One local unit is one display pixel;
-- all rows, insets and checkpoint rectangles therefore share the same grid.
function K.PixelProgress(bar)
    local face=CreateFrame("Frame",nil,bar)
    face:SetFrameLevel(bar:GetFrameLevel()+1)
    bar.pixelBar=face
    bar:SetBackdrop({}); bar:SetStatusBarColor(0,0,0,0)
    local rows={}
    local function ResolutionHeight()
        local resolution
        if GetScreenResolutions and GetCurrentResolution then
            local list={GetScreenResolutions()}
            resolution=list[GetCurrentResolution()]
        end
        if not resolution and GetCVar then resolution=GetCVar("gxResolution") end
        local _,_,height=string.find(resolution or "","%d+%s*[xX]%s*(%d+)")
        return tonumber(height) or 768
    end
    local function Round(v) return math.floor(v+0.5) end
    local function Span(t,x,y,width,color)
        if width<=0 then t:Hide(); return end
        t:ClearAllPoints(); t:SetPoint("TOPLEFT",face,"TOPLEFT",x,-y)
        t:SetWidth(width); t:SetHeight(1); t:SetVertexColor(unpack(color)); t:Show()
    end
    local bronze={0.62*245/255,0.57*245/255,0.43*245/255,1}
    local dark={0.025,0.025,0.03,1}
    function face:Paint()
        local display=ResolutionHeight()/768
        local scale=bar:GetEffectiveScale()*display
        if scale<=0 then return end
        local left,top=bar:GetLeft(),bar:GetTop()
        if not left or not top then return end
        local width=math.max(4,Round(bar:GetWidth()*scale))
        local height=math.max(4,Round(bar:GetHeight()*scale))
        if self.layoutScale~=scale or self.layoutLeft~=left or self.layoutTop~=top or self.layoutWidth~=width or self.layoutHeight~=height then
            self:SetScale(1/scale)
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT",bar,"TOPLEFT",Round(left*scale)-left*scale,Round(top*scale)-top*scale)
            self:SetWidth(width); self:SetHeight(height)
            self.layoutScale,self.layoutLeft,self.layoutTop,self.layoutWidth,self.layoutHeight=scale,left,top,width,height
        end
        local cut=math.min(Round(4*scale),math.floor((height-1)/2))
        local stroke=math.max(1,Round(scale))
        self.pixelsPerUnit=scale; self.stroke=stroke; self.cut=cut
        local low,high=bar:GetMinMaxValues()
        local share=high>low and math.max(0,math.min(1,((tonumber(bar:GetValue()) or low)-low)/(high-low))) or 0
        local finish=stroke+Round((width-2*stroke)*share)
        -- Layout can move during dragging, while unchanged row geometry stays cached.
        if self.drawWidth==width and self.drawHeight==height and self.drawCut==cut and self.drawStroke==stroke and self.finish==finish then return end
        self.drawWidth,self.drawHeight,self.drawCut,self.drawStroke,self.finish=width,height,cut,stroke,finish
        for y=0,height-1 do
            local row=rows[y+1]
            if not row then
                row={face:CreateTexture(nil,"BACKGROUND"),face:CreateTexture(nil,"BORDER"),face:CreateTexture(nil,"ARTWORK")}
                for _,t in ipairs(row) do t:SetTexture(K.flat) end
                rows[y+1]=row
            end
            local cy=y+0.5
            local edge=math.max(0,cut-cy,cut-height+cy)
            local x=math.max(0,math.ceil(edge-0.5))
            Span(row[1],x,y,width-2*x,bronze)
            local inside=cy>=stroke and cy<=height-stroke
            local inset=math.max(stroke,cut+stroke*math.sqrt(2)-cy,cut+stroke*math.sqrt(2)-height+cy)
            local ix=math.max(stroke,math.ceil(inset-0.5))
            local length=inside and math.max(0,width-2*ix) or 0
            Span(row[2],ix,y,length,dark)
            local shade=0.96-0.27*y/math.max(1,height-1)
            Span(row[3],ix,y,math.min(length,math.max(0,finish-ix)),{0.24*shade,0.56*shade,0.83*shade,1})
        end
        for i=height+1,table.getn(rows) do for _,t in ipairs(rows[i]) do t:Hide() end end
    end
    face:Paint()
    return face
end
