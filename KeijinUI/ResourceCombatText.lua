-- Native total deltas are interval summaries, never described as individual hits.
local K=KeijinUI
local R={}
K.resourceText=R
function R.Active()
    local mode=K.CombatTextMode()
    return K.ModuleOn("combatText") and (mode=="compact" or mode=="scroll" or mode=="rise")
end
local priorTaken,priorHealing,lastStart
local function Lane(name,label,x)
    local f=CreateFrame("Frame",name,UIParent); f:SetWidth(190); f:SetHeight(90)
    K.layout.Register(label=="Heiltext" and "healtext" or "takentext",f,label,function(frame) frame:SetPoint("CENTER",UIParent,"CENTER",x,0) end)
    f.rows={}; for i=1,4 do f.rows[i]=K.Text(f,"",12,"BOTTOM",0,(i-1)*21,190); f.rows[i]:SetJustifyH("CENTER"); f.rows[i]:Hide() end
    return f
end
local healing=Lane("KeijinUIHealingText","Heiltext",-180)
local taken=Lane("KeijinUITakenText","Eingehender Kampftext",180)
local function Push(frame,text,r,g,b)
    for i=4,2,-1 do
        local from,to=frame.rows[i-1],frame.rows[i]
        to:SetText(from:GetText() or ""); to.at=from.at; to:SetTextColor(r,g,b)
        if to.at then to:Show() else to:Hide() end
    end
    local row=frame.rows[1]; row:SetText(text); row:SetTextColor(r,g,b); row.at=GetTime(); row:Show()
end
function R.Observe()
    if K.DB().healingText~=true and K.DB().incomingText~=true then priorTaken=nil; priorHealing=nil; return end
    if lastStart~=K.runStart then priorTaken=nil; priorHealing=nil; lastStart=K.runStart end
    local phase=AZS_GetPhase and AZS_GetPhase()
    local t=type(AZS_RUN)=="table" and AZS_RUN.taken
    local h
    if type(AZS_GetHealing)=="function" then local lines,total=AZS_GetHealing(); h=total end
    if phase=="playing" and R.Active() then
        if K.DB().incomingText==true and K.Number(t) and K.Number(priorTaken) and t>priorTaken then Push(taken,K.T("Schaden: −%s",K.Short(t-priorTaken)),1,.35,.25) end
        if K.DB().healingText==true and K.Number(h) and K.Number(priorHealing) and h>priorHealing then Push(healing,K.T("Heilung: +%s",K.Short(h-priorHealing)),.4,1,.4) end
    end
    priorTaken=K.Number(t) and t or nil; priorHealing=K.Number(h) and h or nil
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then priorTaken=nil; priorHealing=nil
    elseif prefix=="AZSRUN" or prefix=="AZSHEAL" then R.Observe() end
end,"combatText")
function R.Clear()
    priorTaken=nil; priorHealing=nil
    for _,f in ipairs({healing,taken}) do for _,row in ipairs(f.rows) do row.at=nil; row:Hide() end end
end
K.Update("combatText",function()
    for _,f in ipairs({healing,taken}) do
        local enabled=f==healing and K.DB().healingText==true or f==taken and K.DB().incomingText==true
        for _,row in ipairs(f.rows) do
            local age=row.at and GetTime()-row.at
            if enabled and R.Active() and age and age<1.4 then row:SetAlpha(math.min(1,(1.4-age)/.4)); K.Shown(row,true) else K.Shown(row,false) end
        end
    end
end)
