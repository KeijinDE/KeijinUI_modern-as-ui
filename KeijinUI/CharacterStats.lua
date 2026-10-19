-- Current native character attributes, separate from the run counters.
-- Selection and visibility are independent. Missing values are never guessed.
local K=KeijinUI
local S={}
K.characterStats=S
local function Percent(v) return string.format("%.1f%%",v*100) end
local function WholePercent(v) return string.format("%.0f%%",v*100) end
local function Bonus(v) return string.format("%+.0f%%",(v-1)*100) end
S.definitions={
    {key="crit",label="Kritchance",format=Percent,default=true},
    {key="cm",label="Kritischer Schaden",format=WholePercent,default=true},
    {key="cd",label="Tempo",format=function(v) return string.format("%+.0f%%",(1-v)*100) end,default=true},
    {key="lch",label="Lebensraub",format=Percent,default=true},
    {key="reg",label="Regeneration",format=function(v) return string.format("%.1f / s",v) end},
    {key="heal",label="Heilung pro Kill",format=K.Short},
    {key="spd",label="Bewegungstempo",format=Bonus},
    {key="luck",label="Glück",format=Percent},
    {key="dmg",label="Schadensbonus",format=Bonus},
    {key="arm",label="Rüstung",format=WholePercent},
    {key="area",label="Flächenbonus",format=Bonus},
    {key="hp",label="Maximales Leben",format=K.Short},
    {key="echo",label="Echochance",format=Percent},
    {key="cnt",label="Zusätzliche Ziele",format=function(v) return string.format("+%.0f",v) end},
    {key="pick",label="Sammelreichweite",format=function(v) return string.format("%.0f yd",v) end},
    {key="xp",label="XP Bonus",format=Bonus},
    {key="gold",label="Goldbonus",format=Bonus},
    {key="thn",label="Dornen",format=Percent},
    {key="liv",label="Zusatzleben",format=K.Short},
    {key="bp",label="Buffstärke",format=Percent},
    {key="dots",label="DoT Stapel pro Gegner",format=K.Short},
    {key="doth",label="DoT Tempo",format=Percent},
    {key="big",label="Schaden gegen Eliten",format=Percent},
    {key="exe",label="Execute Schaden",format=Percent},
    {key="cc",label="Gegen kontrollierte Gegner",format=Percent},
    {key="dotd",label="Gegen Gegner mit DoTs",format=Percent},
    {key="shd",label="Schaden mit Schild",format=Percent},
    {key="auto",label="Nahkampfschaden",format=Percent},
    {key="pet",label="Begleiterschaden",format=Percent}
}
function S.On() return K.ModuleOn("attributes") and K.DB().characterStats==true end
function S.Ordered()
    local byKey,out,used={},{},{}
    for _,def in ipairs(S.definitions) do byKey[def.key]=def end
    local saved=K.DB().characterStatOrder
    for _,key in ipairs(type(saved)=="table" and saved or {}) do
        if byKey[key] and not used[key] then table.insert(out,byKey[key]); used[key]=true end
    end
    for _,def in ipairs(S.definitions) do if not used[def.key] then table.insert(out,def) end end
    return out
end
function S.Move(key,step)
    local list=S.Ordered(); local at
    for i,v in ipairs(list) do if v.key==key then at=i end end
    if not at then return false end
    local target=at+(step<0 and -1 or 1)
    while target>=1 and target<=table.getn(list) and not S.Selected(list[target].key) do target=target+(step<0 and -1 or 1) end
    if target<1 or target>table.getn(list) then return false end
    list[at],list[target]=list[target],list[at]
    local order={}; for _,def in ipairs(list) do table.insert(order,def.key) end
    K.DB().characterStatOrder=order; S.Update(); return true
end
function S.Selected(key)
    local values=K.DB().characterStatSelection
    if type(values)=="table" and values[key]~=nil then return values[key]==true end
    for _,def in ipairs(S.definitions) do if def.key==key then return def.default==true end end
    return false
end
function S.Value(def,source)
    local value=type(source)=="table" and source[def.key]
    return K.Number(value) and def.format(value) or "?"
end
local frame=K.Panel("KeijinUICharacterStats","Charakterwerte",K.PANEL_WIDTH,132)
S.frame=frame
K.layout.Register("attributes",frame,"Charakterwerte",function(f)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",KeijinUIStatistics,"TOPRIGHT",10,0)
end)
local rows={}
for i=1,table.getn(S.definitions) do rows[i]=K.ValueRow(frame,i,18) end
local fresh=type(AZS_STATS)=="table"
function S.Update()
    if not S.On() then frame:Hide(); return end
    local n=0
    for _,def in ipairs(S.Ordered()) do
        if S.Selected(def.key) then
            n=n+1; local row=rows[n]
            row.label:SetText(K.T(def.label)); row.label:SetWidth(frame:GetWidth()-92)
            row.value:SetText(S.Value(def,fresh and AZS_STATS or nil))
            row.tip=K.T(def.label); row.detail=nil; row:Show(); row.line:Show()
        end
    end
    for i=n+1,table.getn(rows) do rows[i]:Hide() end
    if n>0 then rows[n].line:Hide(); frame:SetHeight(42+n*20); frame:Show() else frame:Hide() end
end
function S.Set(on) K.DB().characterStats=on and true or false; S.Update() end
function S.Select(key,on)
    local known=false
    for _,def in ipairs(S.definitions) do if def.key==key then known=true; break end end
    if not known then return end
    local db=K.DB()
    if type(db.characterStatSelection)~="table" then db.characterStatSelection={} end
    db.characterStatSelection[key]=on and true or false; S.Update()
end
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then fresh=false
    elseif prefix=="AZS" then fresh=true end
end)
K.Update("attributes",S.Update)
S.Update()
