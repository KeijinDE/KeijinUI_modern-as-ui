-- Isolated preview: real presentation rules, no combat messages or world statistics.
local K=KeijinUI
function K.CreateCombatPreview(parent,x,y)
    local f=CreateFrame("Frame",nil,parent)
    f:SetWidth(516); f:SetHeight(140); f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    K.Chamfer(f,4,{.025,.025,.03,1},{.28,.25,.18,1})
    local examples={
        {text="84",crit=false,school="Fire",spell="Fireball",column=1},
        {text="246",crit=true,school="Shadow",spell="Shadow Bolt",column=2},
        {text="20 x2",school="Fire",spell="Fireball",column=3},
        {text="10",school="Fire",spell="Fireball",column=3,extra=true},
    }
    for i,label in ipairs({"Normaler Treffer","Kritischer Treffer","Zwei Flächentreffer"}) do
        local fs=K.LText(f,label,10,"TOPLEFT",(i-1)*172+5,-114,162)
        fs:SetJustifyH("CENTER"); fs:SetTextColor(.7,.68,.61)
    end
    f.status=K.Text(f,"",11,"CENTER",0,0,480); f.status:SetTextColor(.75,.73,.66)
    f.items={}; f.age=0
    for _,example in ipairs(examples) do
        local item={example=example}
        item.fs=K.Text(f,"",12,"BOTTOMLEFT",0,0)
        item.fs:SetJustifyH("CENTER"); item.fs:SetHeight(80)
        item.icon=f:CreateTexture(nil,"OVERLAY"); item.icon:SetTexCoord(.08,.92,.08,.92)
        -- Anchor next to the actual glyphs rather than the fixed sample column.
        item.icon:SetPoint("RIGHT",item.fs,"LEFT",-2,0)
        table.insert(f.items,item)
    end
    function f:Draw()
        local mode=K.CombatTextMode()
        for _,item in ipairs(self.items) do
            local e=item.example
            local visible=(mode=="compact" or mode=="scroll") and (not e.extra or K.DB().combatTextMerge==false)
            if visible then
                local s,r,g,b,icon,scroll,pop=K.damageText.Describe(mode,e.crit,e.school,false,e.spell)
                local age=self.age
                local t=math.min(1,age/s.life)
                local size=pop and math.floor(s.size*K.damageText.PopFactor(age)+.5) or s.size
                local text=e.text
                if e.column==3 and K.DB().combatTextMerge==false then text="10" end
                item.fs:SetText(text); item.fs:SetFont(K.font,size,"OUTLINE"); item.fs:SetTextColor(r,g,b)
                item.fs:SetHeight(size*1.3)
                local split=e.column==3 and K.DB().combatTextMerge==false
                local dx=split and (e.extra and 26 or -26) or 0
                if scroll then dx=dx+(e.column==2 and 1 or -1)*12*(1-(1-t)*(1-t)) end
                local dy=scroll and s.rise*(2.4*t-1.9*t*t) or s.rise*t
                item.fs:ClearAllPoints(); item.fs:SetPoint("BOTTOM",self,"TOPLEFT",(e.column-.5)*172+dx,-101+dy)
                local alpha=age>=s.life and 0 or (scroll and (s.alpha or 1)*(t<.7 and 1 or (1-t)/.3) or (t<.6 and 1 or (1-t)/.4))
                item.fs:SetAlpha(alpha); item.fs:Show()
                if icon then
                    item.icon:SetTexture(icon); item.icon:SetWidth(size); item.icon:SetHeight(size)
                    item.icon:SetAlpha(alpha); item.icon:Show()
                else item.icon:Hide() end
            else item.fs:Hide(); item.icon:Hide() end
        end
    end
    function f:Refresh()
        local mode=K.CombatTextMode()
        local signature=mode..tostring(K.DB().combatTextIcons~=false)..tostring(K.DB().combatTextMerge~=false)
        if signature~=self.signature then self.signature=signature; self.age=0 end
        if mode=="off" or mode=="native" then
            self.status:SetText(K.T(mode=="off" and "Schadenszahlen ausgeschaltet." or "Die Darstellung übernimmt das Spiel.")); self.status:Show()
        else self.status:Hide() end
        self:Draw()
    end
    f:SetScript("OnUpdate",function()
        f.age=f.age+(tonumber(arg1) or 0)
        if f.age>=2 then f.age=math.mod(f.age,2) end
        f:Draw()
    end)
    f:SetScript("OnShow",function() f.age=0; f:Refresh() end)
    f:Refresh(); return f
end
