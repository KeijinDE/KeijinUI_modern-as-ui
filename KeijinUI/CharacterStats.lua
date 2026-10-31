-- Current native character attributes, separate from the run counters.
-- Selection and visibility are independent. Missing values are never guessed.
local K=KeijinUI
local P=K.panelSizing
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
    {key="arm",label="Schadensreduktion",format=WholePercent},
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
    if not S.On() then K.Shown(frame,false); return end
    local selected={}
    for _,def in ipairs(S.Ordered()) do if S.Selected(def.key) then table.insert(selected,def) end end
    local total=table.getn(selected)
    local visible,offset=P.List("attributes",rows,total,29,20)
    local n=0
    for i=1,visible do
        local def=selected[i+offset]
        if def then
            n=n+1; local row=rows[n]
            row.label:SetText(K.T(def.label)); if not P.Custom("attributes") then row.label:SetWidth(frame:GetWidth()-92) end
            row.value:SetText(S.Value(def,fresh and AZS_STATS or nil))
            row.tip=K.T(def.label); row.detail=nil; row:Show(); row.line:Show()
        end
    end
    for i=n+1,table.getn(rows) do rows[i]:Hide() end
    if n>0 then rows[n].line:Hide() end
    if n>0 or P.Config("attributes").rows then
        if not P.Custom("attributes") then frame:SetHeight(42+n*20) end; frame:Show()
    else frame:Hide() end
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
-- ReloadUI (also after a language change) builds a fresh API state with AZS_STATS=nil, and the game sends AZS only
-- when the values change. Until then the character window would show the stock labels and values. The last raw
-- message is therefore kept in memory, saved at PLAYER_LOGOUT (which ReloadUI fires too) and, after the load, replayed
-- once through the game's own parser: same character, at most 30 s (GetTime runs on across a reload) old.
-- A replayed state is unconfirmed until a real AZS message comes; AZSZONE or a detected run restart (K.runStart changes)
-- in the meantime withdraws it again. A chain of unconfirmed restores ends 10 minutes after the last real message.
local lastText,unconfirmed,pending,deadline,stage,origin,runMark
-- Every number AZS_Update and AZS_UpdateMore format or calculate without a nil guard (analysis/embedded/108439656.txt),
-- the g* gear fields included: AZS_Gear gets its text argument already formatted.
local NEEDED={"hp","dmg","cd","crit","cm","arm","area","cnt","echo","spd","reg","pick","lch","heal","thn","liv","xp","gold",
    "luck","bp","dots","doth","big","exe","cc","dotd","shd","auto","pet",
    "ghp","gdmg","gcd","gcrit","gcm","garm","garea","gcnt","gecho","gspd","greg","gpick","ggold"}
-- The stock setters that PaperDollFrame_OnShow runs (PaperDollFrame.lua); the game script wraps them and hands over to
-- the stock version while AZS_STATS is nil, so calling them takes back the run numbers.
local SETTERS={"PaperDollFrame_SetStats","PaperDollFrame_SetResistances","PaperDollFrame_SetArmor","PaperDollFrame_SetDamage",
    "PaperDollFrame_SetAttackPower","PaperDollFrame_SetAttackBothHands","PaperDollFrame_SetRangedAttack",
    "PaperDollFrame_SetRangedDamage","PaperDollFrame_SetRangedAttackPower"}
local function Realm() return GetRealmName and GetRealmName() or "" end
local function Parsed(text)
    if type(text)~="string" or type(AZS_Parse)~="function" then return nil end
    local ok,result=pcall(AZS_Parse,text)
    if not ok or type(result)~="table" then return nil end
    for _,key in ipairs(NEEDED) do if not K.Number(result[key]) then return nil end end
    return result
end
-- AZS_Row replaces the OnEnter handler of the rows it writes (and marks them with .azs); the stock setters do not
-- bring the stock handler back. The handlers are noted now, while AZS_STATS is nil and AZS_Row has not run yet.
local ROWS={"CharacterStatFrame1","CharacterStatFrame2","CharacterStatFrame3","CharacterStatFrame4","CharacterStatFrame5",
    "CharacterArmorFrame","CharacterAttackFrame","CharacterAttackPowerFrame","CharacterDamageFrame",
    "CharacterRangedAttackFrame","CharacterRangedAttackPowerFrame","CharacterRangedDamageFrame"}
local handlers={}
if type(AZS_STATS)~="table" then
    for _,name in ipairs(ROWS) do
        local row=getglobal(name)
        if row and row.GetScript and row.SetScript then handlers[name]=row:GetScript("OnEnter") or false end
    end
end
-- AZS_Update hid the resistance row and AZS_UpdateMore showed the run panel; the game script takes neither back itself.
-- Frames and tooltips are restored whether the window is open or not; the setters only for an open window.
local function Withdraw()
    if PaperDollFrame and PaperDollFrame:IsVisible() then
        for _,name in ipairs(SETTERS) do
            local fn=getglobal(name)
            if type(fn)=="function" then pcall(fn) end
        end
    end
    if CharacterResistanceFrame then CharacterResistanceFrame:Show() end
    if AZSMoreStats then AZSMoreStats:Hide() end
    for name,handler in pairs(handlers) do
        local row=getglobal(name)
        if row then row:SetScript("OnEnter",handler or nil); row.azs=nil end
    end
end
-- Takes an unconfirmed state back for good.
local function Drop()
    stage="done"; pending=nil; lastText=nil; K.DB().statsSnapshot=nil
    if unconfirmed then unconfirmed=false; AZS_STATS=nil; Withdraw() end
end
function S.Restore()
    if stage=="done" then return end
    local now=GetTime and GetTime()
    if not K.Number(now) then return end
    if not stage then
        stage="try"; deadline=now+10
        local db=K.DB()
        local snap=db.statsSnapshot; db.statsSnapshot=nil
        if type(AZS_STATS)=="table" or type(snap)~="table" or not K.Number(snap.t) then stage="done"; return end
        if snap.player~=UnitName("player") or snap.realm~=Realm() or now<snap.t or now-snap.t>30 then stage="done"; return end
        origin=K.Number(snap.origin) and snap.origin or snap.t
        if now-origin>600 then stage="done"; return end
        pending=snap.text
    end
    if type(AZS_STATS)=="table" then stage="done"; pending=nil; return end
    if now>deadline then stage="done"; pending=nil; return end
    local result=Parsed(pending)
    if result then
        stage="done"; lastText=pending; pending=nil
        AZS_STATS=result; fresh=true; unconfirmed=true; runMark=K.runStart
        if PaperDollFrame and PaperDollFrame:IsVisible() and type(AZS_Update)=="function" and not pcall(AZS_Update) then
            AZS_STATS=nil; fresh=false; unconfirmed=false; lastText=nil
            Withdraw()
        end
    elseif type(pending)~="string" then stage="done"; pending=nil end
end
table.insert(K.updates,S.Restore)
table.insert(K.updates,function() if unconfirmed and K.runStart~=runMark then Drop() end end)
K.On("CHAT_MSG_ADDON",function(_,prefix,message)
    if prefix=="AZSZONE" then
        fresh=false; Drop()
    elseif prefix=="AZS" then
        fresh=true; unconfirmed=false; pending=nil; stage="done"
        if type(message)=="string" then lastText=message; origin=GetTime and GetTime() or nil end
    end
end)
K.On("PLAYER_LOGOUT",function()
    local db=K.DB()
    local now=GetTime and GetTime()
    if type(AZS_STATS)=="table" and type(lastText)=="string" and K.Number(now) and K.Number(origin) and now-origin<=600
        and (not unconfirmed or K.runStart==runMark) then
        db.statsSnapshot={text=lastText,player=UnitName("player"),realm=Realm(),t=now,origin=origin}
    else db.statsSnapshot=nil end
end)
P.Register("attributes",frame,"Charakterwerte",S.Update)
K.Update("attributes",S.Update)
S.Update()
