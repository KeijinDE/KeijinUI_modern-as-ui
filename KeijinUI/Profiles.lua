-- Share layout and appearance as a text code (Settings, Administration).
-- Format: "KUI1:" records "~" checksum. Records are separated by ";", fields by ",", and use only letters, digits,
-- "_", "." and "-". The text is parsed field by field against a whitelist; it is never run as Lua code.
-- Never included: runs, collection, logs, native restore values, key bindings, language, client settings.
local K=KeijinUI
local O=K.settings
local S={}
K.profiles=S
S.PREFIX,S.VERSION,S.MAX_LENGTH,S.MAX_RECORDS="KUI",1,6000,160
-- Window keys of K.layout.Register (some are registered late, so the list is fixed here).
local KEYS={}
for key in string.gfind("achievements analysisOverview attributes bosses buffs build cachearrow characterwindow chat combattext combattextlist crits effects fps guardianOverview guardianarrow healtext levels loot meter minimap party player resources skills statistics summons takentext tally target tooltip tracker worldmap xp","%S+") do KEYS[key]=true end
S.windowKeys=KEYS
-- Same lists as SettingsReset.lua: what a backup leaves out of the options.
local KEEP={lang=true,runs=true,runSnapshots=true,snapshotSerial=true,runTrace=true,
    paceHistory=true,itemDiary=true,autoWalkKey=true,autoWalkSet=true,autoWalkPrevious=true,
    autoWalkHeld=true,shortcuts=true,shortcutsHeld=true}
local TRANSIENT={settingsBackup=true,native=true,originalCombatDamage=true,originalShowCombatText=true}
local function Finite(v) return type(v)=="number" and v==v and math.abs(v)<1e15 end
local function Clamp(v,low,high) return math.max(low,math.min(high,v)) end
local function Sorted(t)
    local keys={}
    for key in pairs(t) do table.insert(keys,key) end
    table.sort(keys)
    return keys
end
local function Copy(value)
    if type(value)~="table" then return value end
    local out={}
    for key,item in pairs(value) do out[key]=Copy(item) end
    return out
end
local function Num(v)
    local s=string.format("%.4f",v)
    s=string.gsub(s,"0+$",""); s=string.gsub(s,"%.$","")
    if s=="" or s=="-0" then s="0" end
    return s
end
local function Bit(on) return on and "1" or "0" end
local function Sum(text)
    local h=7
    for i=1,string.len(text) do h=math.mod(h*31+string.byte(text,i),2147483629) end
    return h
end
local function FontKnown(key)
    for _,choice in ipairs(K.fontChoices or {}) do if choice[1]==key then return true end end
    return false
end
local function Sizing(key)
    for _,v in ipairs(K.panelSizing.order) do if v[1]==key then return true end end
    return false
end
local function Bounded(c,field,low,high)
    local v=type(c)=="table" and c[field]
    if not Finite(v) then return nil end
    return Clamp(v,low,high)
end

-- Reads the current settings into a plain table; only whitelisted keys, every value clamped into its range.
function S.Collect(withModules)
    local db=K.DB()
    local p={w=math.floor(K.UIWidth()+.5),h=math.floor(K.UIHeight()+.5),layout={},sizing={},frameless={},modules=withModules and {} or nil}
    for key,v in pairs(db.layout) do
        if KEYS[key] and type(v)=="table" and Finite(v.x) and Finite(v.y) and Finite(v.scale) and v.scale>0 then
            local item={x=Clamp(v.x,-.5,1.5),y=Clamp(v.y,-.5,1.5),scale=Clamp(v.scale,.5,1.8),ref=v.ref=="bar",bottom=v.bottom==true}
            local d=v.dock
            if type(d)=="table" and KEYS[d.target] and d.target~=key and (d.edge=="above" or d.edge=="below") and Finite(d.x) then
                item.dock={target=d.target,edge=d.edge,x=Clamp(d.x,-4000,4000),ref=d.ref=="bar"}
            end
            p.layout[key]=item
        end
    end
    for _,v in ipairs(K.panelSizing.order) do
        local c=type(db.panelSizing)=="table" and db.panelSizing[v[1]]
        local item={width=Bounded(c,"width",180,1200),rows=Bounded(c,"rows",1,K.panelSizing.Maximum(v[1])),font=Bounded(c,"font",8,20)}
        if item.width or item.rows or item.font then p.sizing[v[1]]=item end
    end
    if type(db.fontFace)=="string" and FontKnown(db.fontFace) then p.font=db.fontFace end
    if Finite(db.bgAlpha) then p.alpha=Clamp(db.bgAlpha,.2,1) end
    if db.panelHeaders=="thin" or db.panelHeaders=="off" then p.headers=db.panelHeaders end
    if type(db.frameless)=="table" then
        for key,v in pairs(db.frameless) do if KEYS[key] and v==true then p.frameless[key]=true end end
    end
    local lines,size=db.combatTextListLines,db.combatTextListSize
    if db.combatTextList==true or K.Number(lines) or K.Number(size) then
        p.list={on=db.combatTextList==true,lines=K.Number(lines) and Clamp(math.floor(lines+.5),2,12) or nil,
            size=K.Number(size) and Clamp(size,.5,2) or nil}
    end
    if withModules then
        for _,key in ipairs(K.modules.order) do p.modules[key]=K.ModuleOn(key) end
    end
    return p
end

function S.Encode(p)
    local r={"s,"..p.w..","..p.h}
    for _,key in ipairs(Sorted(p.layout)) do
        local v=p.layout[key]
        local line="l,"..key..","..Num(v.x)..","..Num(v.y)..","..Num(v.scale)..","..Bit(v.ref)..","..Bit(v.bottom)
        if v.dock then line=line..","..v.dock.target..","..(v.dock.edge=="above" and "a" or "b")..","..Num(v.dock.x)..","..Bit(v.dock.ref) end
        table.insert(r,line)
    end
    for _,key in ipairs(Sorted(p.sizing)) do
        local v=p.sizing[key]
        table.insert(r,"z,"..key..","..(v.width and Num(v.width) or "")..","..(v.rows and Num(v.rows) or "")..","..(v.font and Num(v.font) or ""))
    end
    if p.font then table.insert(r,"f,"..p.font) end
    if p.alpha then table.insert(r,"a,"..Num(p.alpha)) end
    if p.headers then table.insert(r,"h,"..p.headers) end
    for _,key in ipairs(Sorted(p.frameless)) do table.insert(r,"n,"..key) end
    if p.list then table.insert(r,"t,"..Bit(p.list.on)..","..(p.list.lines and Num(p.list.lines) or "")..","..(p.list.size and Num(p.list.size) or "")) end
    for _,key in ipairs(Sorted(p.modules or {})) do table.insert(r,"m,"..key..","..Bit(p.modules[key])) end
    local body=table.concat(r,";")
    return S.PREFIX..S.VERSION..":"..body.."~"..Sum(body)
end
function S.Export(withModules) return S.Encode(S.Collect(withModules)) end

local function Split(text,separator,limit)
    local out,start={},1
    while true do
        local at=string.find(text,separator,start,true)
        if not at then table.insert(out,string.sub(text,start)); return out end
        table.insert(out,string.sub(text,start,at-1)); start=at+1
        if table.getn(out)>=limit then return out end
    end
end
-- Plain decimal only: tonumber alone would also accept hex, "inf" and "nan".
local function Number(text,low,high)
    if type(text)~="string" or string.len(text)>12 or not string.find(text,"^%-?%d+%.?%d*$") then return nil end
    local v=tonumber(text)
    if not v or v<low or v>high then return nil end
    return v
end
local function Flag(text)
    if text=="1" then return true elseif text=="0" then return false end
end
local function Optional(text,low,high)
    if text=="" then return nil,true end
    local v=Number(text,low,high)
    return v,v~=nil
end

-- Record readers. Each returns false for a value of the wrong form or range, which rejects the whole code.
local READ={}
function READ.s(p,f)
    p.w,p.h=Number(f[2],320,16384),Number(f[3],320,16384)
    return table.getn(f)==3 and p.w and p.h and true or false
end
function READ.l(p,f)
    local n=table.getn(f)
    if n~=7 and n~=11 then return false end
    local x,y,scale=Number(f[3],-.5,1.5),Number(f[4],-.5,1.5),Number(f[5],.5,1.8)
    local ref,bottom=Flag(f[6]),Flag(f[7])
    if not x or not y or not scale or ref==nil or bottom==nil then return false end
    local dock
    if n==11 then
        local dx,dref=Number(f[10],-4000,4000),Flag(f[11])
        if (f[9]~="a" and f[9]~="b") or not dx or dref==nil then return false end
        dock={target=f[8],edge=f[9]=="a" and "above" or "below",x=dx,ref=dref}
    end
    if not KEYS[f[2]] then p.unknown=p.unknown+1; return true end
    p.layout[f[2]]={x=x,y=y,scale=scale,ref=ref,bottom=bottom,dock=dock}
    return true
end
function READ.z(p,f)
    if table.getn(f)~=5 then return false end
    if not Sizing(f[2]) then p.unknown=p.unknown+1; return true end
    local width,okWidth=Optional(f[3],180,1200)
    local rows,okRows=Optional(f[4],1,K.panelSizing.Maximum(f[2]))
    local font,okFont=Optional(f[5],8,20)
    if not (okWidth and okRows and okFont) then return false end
    p.sizing[f[2]]={width=width,rows=rows,font=font}
    return true
end
function READ.f(p,f)
    if table.getn(f)~=2 or string.len(f[2])>24 or not string.find(f[2],"^%a[%a%d]*$") then return false end
    if FontKnown(f[2]) then p.font=f[2] elseif table.getn(p.missingFonts)<3 then table.insert(p.missingFonts,f[2]) else p.missingFonts.more=true end
    return true
end
function READ.a(p,f)
    p.alpha=Number(f[2],.2,1)
    return table.getn(f)==2 and p.alpha~=nil
end
function READ.h(p,f)
    if table.getn(f)~=2 or (f[2]~="normal" and f[2]~="thin" and f[2]~="off") then return false end
    p.headers=f[2]~="normal" and f[2] or nil
    return true
end
function READ.n(p,f)
    if table.getn(f)~=2 then return false end
    if KEYS[f[2]] then p.frameless[f[2]]=true else p.unknown=p.unknown+1 end
    return true
end
function READ.t(p,f)
    if table.getn(f)~=4 then return false end
    local on=Flag(f[2])
    local lines,okLines=Optional(f[3],2,12)
    local size,okSize=Optional(f[4],.5,2)
    if on==nil or not okLines or not okSize then return false end
    p.list={on=on,lines=lines and math.floor(lines+.5) or nil,size=size}
    return true
end
function READ.m(p,f)
    local on=Flag(f[3])
    if table.getn(f)~=3 or on==nil then return false end
    p.hasModules=true
    if K.modules.definitions[f[2]] then p.modules[f[2]]=on else p.unknownModules=p.unknownModules+1 end
    return true
end

-- A dock is kept only when its target has a position of its own and the chain of docks never returns.
local function Docks(layout)
    for key,item in pairs(layout) do
        local d=item.dock
        if d and (d.target==key or not layout[d.target]) then item.dock=nil end
    end
    for key,item in pairs(layout) do
        local at,steps=item,0
        while at and at.dock and steps<40 do
            if at.dock.target==key then item.dock=nil; break end
            at=layout[at.dock.target]; steps=steps+1
        end
    end
end

-- Returns the profile table, or nil and a reason: empty, long, format, newer, old, damaged, invalid.
function S.Decode(code)
    if type(code)~="string" then return nil,"format" end
    if string.len(code)>S.MAX_LENGTH*3 then return nil,"long" end
    code=string.gsub(code,"%s","")
    if code=="" then return nil,"empty" end
    if string.len(code)>S.MAX_LENGTH then return nil,"long" end
    local _,_,digits,rest=string.find(code,"^"..S.PREFIX.."(%d+):(.*)$")
    if not digits or string.len(digits)>3 then return nil,"format" end
    local version=tonumber(digits)
    if version>S.VERSION then return nil,"newer" elseif version<S.VERSION then return nil,"old" end
    local _,_,body,check=string.find(rest,"^([^~]*)~(%d+)$")
    if not body or string.len(check)>10 then return nil,"format" end
    if string.find(body,"[^%w_%.,;%-]") or tonumber(check)~=Sum(body) then return nil,"damaged" end
    local p={layout={},sizing={},frameless={},modules={},missingFonts={},unknown=0,unknownModules=0}
    local records=Split(body,";",S.MAX_RECORDS+1)
    if table.getn(records)>S.MAX_RECORDS then return nil,"long" end
    for _,record in ipairs(records) do
        local f=Split(record,",",14)
        local read=READ[f[1]]
        if not read then p.unknown=p.unknown+1
        elseif not read(p,f) then return nil,"invalid" end
    end
    if not p.w then return nil,"invalid" end
    Docks(p.layout)
    -- An unknown font must not wipe the font chosen here.
    p.keepFont=not p.font and (table.getn(p.missingFonts)>0 or p.missingFonts.more) and true or nil
    if not p.hasModules then p.modules=nil end
    return p
end

function S.Counts(p)
    local windows,sizes,looks,modules=0,0,0,0
    for _ in pairs(p.layout) do windows=windows+1 end
    for _ in pairs(p.sizing) do sizes=sizes+1 end
    for _ in pairs(p.frameless) do looks=looks+1 end
    for _ in pairs(p.modules or {}) do modules=modules+1 end
    if p.font then looks=looks+1 end
    if p.alpha then looks=looks+1 end
    if p.headers then looks=looks+1 end
    if p.list then looks=looks+1 end
    return windows,sizes,looks,modules
end
function S.Describe(p)
    local windows,sizes,looks,modules=S.Counts(p)
    local lines={K.T("Fensterpositionen: %d",windows),K.T("Fenstergrößen: %d",sizes),K.T("Darstellung: %d Einstellungen",looks)}
    table.insert(lines,p.modules and K.T("Modulzustände: %d",modules) or K.T("Modulzustände sind nicht enthalten und bleiben unverändert."))
    local w,h=math.floor(K.UIWidth()+.5),math.floor(K.UIHeight()+.5)
    if math.abs(p.w-w)>w*.01 or math.abs(p.h-h)>h*.01 then
        table.insert(lines,K.T("Hinweis: Andere Bildschirmgröße (Code %dx%d, hier %dx%d). Positionen werden angepasst.",p.w,p.h,w,h))
    end
    if p.keepFont then
        table.insert(lines,K.T("Hinweis: Schrift nicht vorhanden, deine Schrift bleibt erhalten: %s",table.concat(p.missingFonts,", ")..(p.missingFonts.more and ", ..." or "")))
    end
    if p.unknownModules>0 then table.insert(lines,K.T("Hinweis: Unbekannte Module übersprungen: %d",p.unknownModules)) end
    if p.unknown>0 then table.insert(lines,K.T("Hinweis: Unbekannte Einträge übersprungen: %d",p.unknown)) end
    local resets=S.Resets(p)
    if table.getn(resets)>0 then table.insert(lines,K.T("Auf Standard zurückgesetzt: %s",table.concat(resets,", "))) end
    return table.concat(lines,"\n")
end
-- Areas the code does not carry: applying returns them to the default.
function S.Resets(p)
    local windows,sizes=S.Counts(p)
    local names={}
    if windows==0 then table.insert(names,K.T("Fensterpositionen")) end
    if sizes==0 then table.insert(names,K.T("Fenstergrößen")) end
    if not p.font and not p.keepFont then table.insert(names,K.T("Schrift")) end
    if not p.alpha then table.insert(names,K.T("Hintergrund-Deckkraft")) end
    if not p.headers then table.insert(names,K.T("Abschnittstitel")) end
    if not next(p.frameless) then table.insert(names,K.T("Fenster ohne Rahmen")) end
    if not p.list then table.insert(names,K.T("Kampftextliste")) end
    return names
end
-- Always visible below the scrolling preview.
function S.Notice()
    return K.T("Ersetzt dein Layout und deine Darstellung. Nicht enthaltene Werte werden auf Standard zurückgesetzt.").."\n\n"
        ..K.T("Vor dem Übernehmen wird eine Sicherung angelegt, die die letzte ersetzt. Unter Verwaltung stellst du sie wieder her. Die Oberfläche wird danach neu geladen. Sprache, Tastenbelegungen, Runhistorie und Sammlung bleiben unverändert.")
end
local REASONS={
    format="Das ist kein KeijinUI Code.",
    long="Der Code ist zu lang.",
    damaged="Der Code ist beschädigt oder wurde verändert.",
    newer="Der Code stammt aus einer neueren KeijinUI Version und lässt sich hier nicht lesen.",
    old="Der Code hat ein veraltetes Format und lässt sich nicht lesen.",
    invalid="Der Code enthält ungültige Werte."}
function S.Reason(reason) return K.T(REASONS[reason] or REASONS.format) end

-- Same layout as the backup of SettingsReset.lua, so "Sicherung wiederherstellen" takes it back.
function S.Backup()
    local db=K.DB()
    local options={}
    for key,value in pairs(db) do
        if not KEEP[key] and not TRANSIENT[key] then options[key]=Copy(value) end
    end
    local achievements=Copy(KeijinUIAchievementsDB or {}); achievements.log=nil
    db.settingsBackup={schema=1,options=options,build=Copy(KeijinUIBuildDB or {}),achievements=achievements}
end
-- Replaces layout and appearance with the profile (a setting missing from the code returns to its default).
-- Modules change only when the code carries them. The interface reloads afterwards.
function S.Apply(p)
    local DEFAULT_LINES=K.damageText and K.damageText.list and K.damageText.list.DEFAULT_LINES or 6
    if type(p)~="table" or type(p.layout)~="table" then return false end
    S.Backup()
    local db=K.DB()
    db.layout={}
    for key,v in pairs(p.layout) do
        local item={x=Clamp(v.x,0,1),y=Clamp(v.y,0,1),scale=v.scale,ref=v.ref and "bar" or nil,bottom=v.bottom or nil}
        if v.dock then item.dock={target=v.dock.target,edge=v.dock.edge,x=v.dock.x,ref=v.dock.ref and "bar" or nil} end
        db.layout[key]=item
    end
    db.panelSizing=nil
    for key,v in pairs(p.sizing) do
        if not db.panelSizing then db.panelSizing={} end
        db.panelSizing[key]={width=v.width,rows=v.rows,font=v.font}
    end
    if not p.keepFont then db.fontFace=p.font end
    db.bgAlpha,db.panelHeaders=p.alpha,p.headers
    db.frameless=nil
    for key in pairs(p.frameless) do
        if not db.frameless then db.frameless={} end
        db.frameless[key]=true
    end
    local list=p.list
    db.combatTextList=list and list.on and true or nil
    db.combatTextListLines=list and list.lines~=DEFAULT_LINES and list.lines or nil
    db.combatTextListSize=list and list.size and math.abs(list.size-1)>0.001 and list.size or nil
    if p.modules then
        if type(db.modules)~="table" then db.modules={} end
        for key,on in pairs(p.modules) do db.modules[key]=on and true or false end
    end
    if type(ReloadUI)=="function" then ReloadUI() end
    return true
end

-- Dialog: export shows the code, import checks a pasted code and waits for the confirmation.
local dialog=K.Panel("KeijinUIProfileDialog","Einstellungen exportieren",560,410)
dialog:SetPoint("CENTER",UIParent,"CENTER",0,0); dialog:SetFrameStrata("FULLSCREEN_DIALOG")
dialog:EnableMouse(true); dialog.noOpacity=true; dialog:SetBackdropColor(.045,.045,.05,1)
table.insert(UISpecialFrames,"KeijinUIProfileDialog")
S.dialog=dialog
local hint=K.Text(dialog,"",11,"TOPLEFT",20,-40,520)
local scroll=CreateFrame("ScrollFrame","KeijinUIProfileScroll",dialog,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",dialog,"TOPLEFT",20,-64); scroll:SetWidth(500); scroll:SetHeight(84)
local edit=CreateFrame("EditBox",nil,scroll); edit:SetWidth(496); edit:SetHeight(84)
K.SetFontSize(edit,11); edit:SetAutoFocus(false); K.fontStrings=K.fontStrings or {}; table.insert(K.fontStrings,{edit,11})
if edit.SetMultiLine then edit:SetMultiLine(true) end
-- Longer pastes are cut here and then refused by Decode as too long.
if edit.SetMaxLetters then edit:SetMaxLetters(S.MAX_LENGTH*3) end
scroll:SetScrollChild(edit); S.edit=edit
-- Import: the details scroll; the replace and backup notice below them never does.
local pscroll=CreateFrame("ScrollFrame","KeijinUIProfilePreviewScroll",dialog,"UIPanelScrollFrameTemplate")
pscroll:SetPoint("TOPLEFT",dialog,"TOPLEFT",20,-158); pscroll:SetWidth(500); pscroll:SetHeight(96)
local pchild=CreateFrame("Frame",nil,pscroll); pchild:SetWidth(480); pchild:SetHeight(96)
local body=K.Text(pchild,"",11,"TOPLEFT",0,0,480); body:SetHeight(96); body:SetJustifyV("TOP")
pscroll:SetScrollChild(pchild); S.preview=body; S.previewScroll=pscroll
pscroll:EnableMouseWheel(true)
pscroll:SetScript("OnMouseWheel",function()
    local bar=getglobal("KeijinUIProfilePreviewScrollScrollBar")
    if bar then bar:SetValue(bar:GetValue()-arg1*20) end
end)
local notice=K.Text(dialog,"",11,"TOPLEFT",20,-262,520); notice:SetHeight(100); notice:SetJustifyV("TOP")
S.notice=notice
local check=CreateFrame("Button",nil,dialog)
check:SetWidth(20); check:SetHeight(20); check:SetPoint("TOPLEFT",dialog,"TOPLEFT",20,-166)
K.Chamfer(check,4,{0.055,0.055,0.065,1},{0.67,0.57,0.36,1})
local mark=check:CreateTexture(nil,"ARTWORK"); mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); mark:SetAllPoints(check); mark:SetVertexColor(.7,1,.4,1)
local checkLabel=K.LText(dialog,"Modulzustände einschließen",11,"TOPLEFT",48,-169,480)
local mode,includeModules,profile
local apply
local function Cut() if edit.HighlightText then edit:HighlightText() end end
local function Fill()
    local code=S.Export(includeModules)
    S.shown=code
    edit:SetText(code); edit:SetHeight(math.max(84,(math.floor(string.len(code)/70)+2)*15))
    if includeModules then mark:Show() else mark:Hide() end
    Cut()
end
-- 1.12 has no GetStringHeight. Every paragraph is measured on an unwrapped, hidden FontString of the same font
-- (GetStringWidth); lines = ceil(width / available) plus one spare line when it wraps, as word wrap can break earlier.
local ruler=K.Text(pchild,"",11,"TOPLEFT",0,0); ruler:Hide(); S.ruler=ruler
local WRAP=480
function S.TextLines(text)
    local _,size=ruler:GetFont()
    size=size or 11
    local total=0
    for _,paragraph in ipairs(Split(text,"\n",200)) do
        ruler:SetText(paragraph)
        local width=ruler.GetStringWidth and ruler:GetStringWidth()
        if not width or width<=0 then width=string.len(paragraph)*size*.6 end
        local lines=math.max(1,math.ceil(width/WRAP))
        total=total+lines+(lines>1 and 1 or 0)
    end
    return total,size+4
end
local function Preview(text)
    body:SetText(text); notice:SetText("")
    local lines,step=S.TextLines(text)
    local height=lines*step
    body:SetHeight(height); pchild:SetHeight(math.max(96,height))
    if pscroll.UpdateScrollChildRect then pscroll:UpdateScrollChildRect() end
    pscroll:SetVerticalScroll(0)
end
local function Verify()
    profile=nil; apply:Hide()
    local text=edit:GetText() or ""
    local p,reason=S.Decode(text)
    Preview("")
    if reason=="empty" then return end
    if not p then body:SetTextColor(1,.45,.4); Preview(S.Reason(reason)); return end
    profile=p; apply:Show()
    body:SetTextColor(0.94,0.91,0.82)
    Preview(S.Describe(p)); notice:SetText(S.Notice())
end
edit:SetScript("OnTextChanged",function()
    if mode=="import" then Verify()
    elseif mode=="export" and edit:GetText()~=S.shown then edit:SetText(S.shown or "") end
end)
edit:SetScript("OnEditFocusGained",function() if mode=="export" then Cut() end end)
edit:SetScript("OnEscapePressed",function() dialog:Hide() end)
check:SetScript("OnClick",function() includeModules=not includeModules; Fill() end)
O.Button(dialog,"Abbrechen",380,-368,160,function() dialog:Hide() end)
apply=O.Button(dialog,"Übernehmen",20,-368,200,function()
    if profile and S.Apply(profile) then dialog:Hide() end
end)
local function Place()
    dialog:SetScale(math.min(O.MenuScale(),math.max(.1,(K.UIWidth()-24)/560),math.max(.1,(K.UIHeight()-24)/410)))
    O.CloseChoice(); dialog:Show()
end
function S.OpenExport()
    mode,includeModules,profile="export",false,nil
    dialog.title:SetText(K.T("Einstellungen exportieren"))
    hint:SetText(K.T("Strg+C kopiert den markierten Code."))
    Preview(""); pscroll:Hide(); apply:Hide(); check:Show(); checkLabel:Show()
    Place(); Fill()
    if edit.SetFocus then edit:SetFocus() end
end
function S.OpenImport()
    mode,profile="import",nil
    dialog.title:SetText(K.T("Einstellungen importieren"))
    hint:SetText(K.T("Füge den Code mit Strg+V ein."))
    check:Hide(); checkLabel:Hide(); mark:Hide(); pscroll:Show()
    edit:SetText(""); edit:SetHeight(1100); Place(); Verify()
    if edit.SetFocus then edit:SetFocus() end
end
