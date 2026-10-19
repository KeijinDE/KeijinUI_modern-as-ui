-- The native boss loot notice is drawn outside the Lua frame layout.
-- Replace it from the game's localized self-loot chat, retaining the chat itself.
-- Four displays in the same panel: the 8 second notice (default), a list of the run's drops,
-- a compact list and an icon grid with a check mark (new) or a cross (collected).
local K=KeijinUI
-- Resolve the real width before registration or a later saved-layout application clamps it.
local function Width()
    local mode=K.DB().lootMode
    return mode=="small" and 184 or (mode=="icons" and 188 or 300)
end
local notice=K.Panel("KeijinUILoot","Beute",Width(),76)
-- "Grow upwards": the header sits at the bottom edge and the bottom edge stays put while the list grows.
local function Grow() return K.DB().lootGrow=="up" end
K.layout.Register("loot",notice,"Beutemeldung",function(f)
    -- Anchored to the run overview below the minimap, independent of the encounter group at the top.
    local relative=KeijinUITracker
    f:ClearAllPoints()
    if relative then
        if Grow() then f:SetPoint("BOTTOMRIGHT",relative,"BOTTOMRIGHT",0,-86)
        else f:SetPoint("TOPRIGHT",relative,"BOTTOMRIGHT",0,-10) end
    else f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-24,40) end
end,{hidden=true,grow=Grow,width=Width})
local loot={}
K.loot=loot
local rows,lines,cells,icon,label,detail,empty
icon=notice:CreateTexture(nil,"ARTWORK")
icon:SetWidth(32); icon:SetHeight(32); K.HeaderPoint(icon,notice,"TOPLEFT",12,-33)
label=K.Text(notice,"",11,"TOPLEFT",52,-32,234)
label:SetHeight(18); K.HeaderPoint(label,notice,"TOPLEFT",52,-32)
detail=K.Text(notice,"",9,"TOPLEFT",52,-51,234)
detail:SetHeight(19); detail:SetTextColor(0.72,0.7,0.64); K.HeaderPoint(detail,notice,"TOPLEFT",52,-51)
-- Prefixes from the installed client's localization dictionaries.
local prefixes={"You receive loot:","Du erhältst Beute:","Otrzymujesz łup:",
    "Você recebe saque:","Recibes botín:","Vous recevez du butin :","Ganimet aldın:",
    "Вы получаете добычу:","你获得了战利品：","전리품을 받았습니다:"}
local MAX_ROWS,MAX_STORED=8,100
local PER_ROW,SMALL_ROWS,CELL=6,4,24
-- Compact list: 16 px lines, 14 px symbol, 9 pt name, up to 12 lines.
local MAX_LINES,LINE=12,16
local MARK_NEW,MARK_OLD="Interface\\Buttons\\UI-CheckBox-Check","Interface\\Buttons\\UI-GroupLoot-Pass-Up"
local current,lastMode,offset,previousReported,arranged,laidOut=nil,nil,0,nil,nil,nil
local function Enabled()
    return AZS_SetHudShown and AZS_IsHudShown and GetItemInfo and AZS_GetPhase and AZS_GetPhase()
end
local function Plain(text)
    text=string.gsub(text,"|c%x%x%x%x%x%x%x%x","")
    return string.gsub(text,"|r","")
end
local function Trim(text) return string.gsub(text,"^%s*(.-)%s*$","%1") end
-- Settings: "notice" (default), "list", "small" (compact list) or "icons"; the filter applies to all of them.
-- A saved "small" from 2.2.0 test builds keeps its key and now means the compact list.
function loot.Mode()
    local mode=K.DB().lootMode
    if mode=="list" or mode=="small" or mode=="icons" then return mode end
    return "notice"
end
function loot.SetMode(mode)
    if mode~="list" and mode~="small" and mode~="icons" then mode=nil end
    K.DB().lootMode=mode; offset=0
end
-- Symbols (list and compact list) and the collection status (all lists); both on by default, stored only when off.
function loot.Icons() return K.DB().lootNoIcons~=true end
function loot.SetIcons(on) K.DB().lootNoIcons=(not on) and true or nil end
function loot.Status() return K.DB().lootNoStatus~=true end
function loot.SetStatus(on) K.DB().lootNoStatus=(not on) and true or nil end
-- Header and content at the top (default) or the header at the bottom with the newest entry just above it.
-- Children get both anchors in Arrange; the mirrored values keep the same distances to the header strip.
local function Arrange()
    local up=Grow()
    arranged=up; notice.growUp=up
    local point=up and "BOTTOMLEFT" or "TOPLEFT"
    K.HeaderPoint(icon,notice,point,12,up and 43 or -33)
    K.HeaderPoint(label,notice,point,52,up and 58 or -32)
    K.HeaderPoint(detail,notice,point,52,up and 38 or -51)
    for i,row in ipairs(rows) do K.HeaderPoint(row,notice,point,8,up and 32+(i-1)*22 or -32-(i-1)*22) end
    for i,line in ipairs(lines) do K.HeaderPoint(line,notice,point,8,up and 32+(i-1)*LINE or -32-(i-1)*LINE) end
    K.HeaderPoint(empty,notice,point,14,up and 36 or -36)
    for i,cell in ipairs(cells) do
        local column,line=math.mod(i-1,PER_ROW),math.floor((i-1)/PER_ROW)
        K.HeaderPoint(cell,notice,point,12+column*(CELL+4),up and 34+line*(CELL+4) or -34-line*(CELL+4))
    end
    K.headers.Apply(notice)
end
-- The bottom edge is the anchor while growing upwards; a frame left on another point by a move is re-anchored first.
local function Height(h)
    if Grow() and K.DB().layout.loot and not K.layout.IsMoving("loot") and notice:GetPoint()~="BOTTOMLEFT" then
        local left,bottom=notice:GetLeft(),notice:GetBottom()
        if K.Number(left) and K.Number(bottom) then
            notice:ClearAllPoints(); notice:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",left,bottom)
        end
    end
    notice:SetHeight(h)
end
function loot.GrowMode() return Grow() and "up" or "down" end
-- Switching keeps the panel where it is on screen: the current edge (bottom for "up", top for "down") is anchored
-- and saved as the new layout position, so the panel does not jump. This also pins a still unsaved default position.
function loot.SetGrow(mode)
    local up=(mode=="up")
    if up==Grow() then return end
    local left,bottom,top=notice:GetLeft(),notice:GetBottom(),notice:GetTop()
    K.DB().lootGrow=up and "up" or nil; offset=0
    if rows then Arrange() end
    if K.Number(left) and K.Number(bottom) and K.Number(top) then
        notice:ClearAllPoints()
        if up then notice:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",left,bottom)
        else notice:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top) end
        K.layout.Save("loot")
    end
end
function loot.NewOnly() return K.DB().lootNewOnly==true end
function loot.SetNewOnly(on) K.DB().lootNewOnly=on and true or nil end
-- The list of the run in progress, newest first. id names the run (zone, character and start time of runs.open),
-- so a reload keeps the entries and a new run drops them.
local function Run()
    local db=K.DB()
    if type(db.lootRun)~="table" or type(db.lootRun.entries)~="table" then db.lootRun={entries={}} end
    return db.lootRun
end
local function RunId()
    local runs=type(KeijinUIDB)=="table" and KeijinUIDB.runs
    local open=type(runs)=="table" and runs.open
    if type(open)=="table" then return tostring(open.zone)..":"..tostring(open.char)..":"..tostring(open.start) end
end
function loot.Clear()
    local run=Run()
    run.entries={}; run.id=RunId(); offset=0
end
-- Item ids of linked loot per character, only for /kui loot debug; "new" comes from the game's own note.
local function CharKey()
    local name=UnitName and UnitName("player") or "?"
    local realm=GetRealmName and GetRealmName() or ""
    return tostring(name).."-"..tostring(realm)
end
local function Seen()
    local db=K.DB()
    if type(db.lootSeen)~="table" then db.lootSeen={} end
    local key=CharKey()
    if type(db.lootSeen[key])~="table" then db.lootSeen[key]={} end
    return db.lootSeen[key]
end
local function SeenCount()
    local n=0
    for _ in pairs(Seen()) do n=n+1 end
    return n
end
local function Visible()
    local out={}
    for _,e in ipairs(Run().entries) do if not loot.NewOnly() or e.new then table.insert(out,e) end end
    return out
end
-- Completes an entry from the item cache (name, symbol, slot, quality colour) as soon as the client knows the item.
local function Fill(entry)
    if entry.cached or not entry.item or not GetItemInfo then return end
    local name,link,quality,minLevel,itemType,subType,stack,equipLoc,texture=GetItemInfo(entry.item)
    if not name then return end
    entry.cached=true; entry.name=name; entry.icon=texture
    if type(equipLoc)=="string" and equipLoc~="" then entry.slot=equipLoc end
    if not entry.color and type(ITEM_QUALITY_COLORS)=="table" and type(ITEM_QUALITY_COLORS[quality])=="table" then
        local c=ITEM_QUALITY_COLORS[quality]
        if type(c.r)=="number" then
            entry.color=string.format("|cff%02x%02x%02x",math.floor(c.r*255+0.5),math.floor(c.g*255+0.5),math.floor(c.b*255+0.5))
        end
    end
end
local function SlotName(entry)
    return entry.slot and getglobal(entry.slot) or nil
end
local function EntryColor(entry)
    local hex=entry.color and string.sub(entry.color,5,10)
    if hex and string.len(hex)==6 then
        local r,g,b=tonumber(string.sub(hex,1,2),16),tonumber(string.sub(hex,3,4),16),tonumber(string.sub(hex,5,6),16)
        if r and g and b then return r/255,g/255,b/255 end
    end
    return 0.62,0.57,0.43
end
local function ColoredName(entry)
    local name=entry.name or "?"
    if entry.color then return entry.color..name.."|r" end
    return name
end
-- Collection status from the game's loot line: true = new, false = already collected, nil = unknown (shows nothing).
local function StatusText(entry)
    if entry.new==true then return K.T("Neu"),0.45,1,0.35 end
    if entry.new==false then return K.T("Gesammelt"),0.62,0.62,0.62 end
end
-- Reuse the same collection symbols in the compact list and icon grid.
local function StatusMark(mark,entry,enabled)
    if enabled and entry.new==true then mark:SetTexture(MARK_NEW); mark:SetVertexColor(0.45,1,0.35,1); mark:Show()
    elseif enabled and entry.new==false then mark:SetTexture(MARK_OLD); mark:SetVertexColor(1,1,1,1); mark:Show()
    else mark:Hide() end
end
local function Tooltip(frame,entry,withStatus)
    if not entry then return end
    GameTooltip:SetOwner(frame,"ANCHOR_LEFT")
    Fill(entry)
    if entry.cached and entry.item then GameTooltip:SetHyperlink(entry.item)
    else GameTooltip:SetText(entry.name or "?",0.94,0.91,0.82) end
    if withStatus and loot.Status() then
        local text,r,g,b=StatusText(entry)
        if text then GameTooltip:AddLine(text,r,g,b) end
    end
    GameTooltip:Show()
end
local function Wheel()
    if lastMode~="list" and lastMode~="small" and lastMode~="icons" then return end
    local step=lastMode=="icons" and PER_ROW or 1
    -- Older entries are below the newest ones, or above them when growing upwards.
    local older=(arg1 or 0)<=0
    if Grow() then older=not older end
    offset=offset+(older and step or -step)
    if offset<0 then offset=0 end
end
-- List rows (symbol, name in quality colour, status, slot, run time) and compact lines (small symbol, small name, status mark).
-- Positions inside a row depend on the switches and are set in Layout.
local function MakeRow(compact,i)
    local row=CreateFrame("Button",nil,notice)
    row:SetWidth(compact and 168 or 284); row:SetHeight(compact and LINE or 22)
    K.HeaderPoint(row,notice,"TOPLEFT",8,compact and -32-(i-1)*LINE or -32-(i-1)*22)
    row.icon=row:CreateTexture(nil,"ARTWORK")
    local side=compact and 14 or 18
    row.icon:SetWidth(side); row.icon:SetHeight(side); row.icon:SetPoint("LEFT",row,"LEFT",compact and 3 or 4,0)
    row.name=K.Text(row,"",compact and 9 or 11,"LEFT",30,0,118)
    row.tag=K.Text(row,"",9,"LEFT",150,0,46)
    if not compact then
        row.slot=K.Text(row,"",9,"LEFT",196,0,48); row.slot:SetTextColor(0.72,0.7,0.64)
        row.time=K.Text(row,"",9,"LEFT",246,0,36); row.time:SetTextColor(0.72,0.7,0.64); row.time:SetJustifyH("RIGHT")
    else
        row.tag:Hide()
        row.mark=row:CreateTexture(nil,"OVERLAY")
        row.mark:SetWidth(12); row.mark:SetHeight(12); row.mark:SetPoint("RIGHT",row,"RIGHT",-3,0)
        row.mark:Hide()
    end
    row.compact=compact
    row:EnableMouse(true); row:EnableMouseWheel(true)
    row:SetScript("OnEnter",function() Tooltip(row,row.entry,compact) end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    row:SetScript("OnMouseWheel",Wheel)
    row:Hide()
    return row
end
rows,lines={},{}
for i=1,MAX_ROWS do rows[i]=MakeRow(false,i) end
for i=1,MAX_LINES do lines[i]=MakeRow(true,i) end
-- Without symbols the name moves to the left; without status it uses the space of the status column.
local function Layout(mode)
    local key=mode..tostring(loot.Icons())..tostring(loot.Status())
    if laidOut==key then return end
    laidOut=key
    local icons,status=loot.Icons(),loot.Status()
    for _,row in ipairs(mode=="small" and lines or rows) do
        local compact=row.compact
        local x=icons and (compact and 21 or 30) or (compact and 5 or 8)
        local stop
        if compact then stop=status and 149 or 164 else stop=status and 148 or 194 end
        row.name:ClearAllPoints(); row.name:SetPoint("LEFT",row,"LEFT",x,0); row.name:SetWidth(stop-x)
        if not compact then
            row.tag:ClearAllPoints(); row.tag:SetPoint("LEFT",row,"LEFT",150,0); row.tag:SetWidth(44)
        end
        if icons then row.icon:Show() else row.icon:Hide() end
    end
end
empty=K.Text(notice,"",10,"TOPLEFT",14,-36,272)
empty:SetHeight(28); empty:SetTextColor(0.72,0.7,0.64); empty:Hide(); K.HeaderPoint(empty,notice,"TOPLEFT",14,-36)
-- Icon grid: symbols with a quality frame, a green check mark for new items and a red cross for collected ones.
cells={}
for i=1,PER_ROW*SMALL_ROWS do
    local cell=CreateFrame("Button",nil,notice)
    cell:SetWidth(CELL); cell:SetHeight(CELL)
    local column,line=math.mod(i-1,PER_ROW),math.floor((i-1)/PER_ROW)
    K.HeaderPoint(cell,notice,"TOPLEFT",12+column*(CELL+4),-34-line*(CELL+4))
    cell.border=cell:CreateTexture(nil,"BACKGROUND")
    cell.border:SetTexture(K.flat); cell.border:SetAllPoints(cell)
    cell.icon=cell:CreateTexture(nil,"ARTWORK")
    cell.icon:SetPoint("TOPLEFT",cell,"TOPLEFT",2,-2); cell.icon:SetPoint("BOTTOMRIGHT",cell,"BOTTOMRIGHT",-2,2)
    cell.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    cell.mark=cell:CreateTexture(nil,"OVERLAY")
    cell.mark:SetWidth(12); cell.mark:SetHeight(12); cell.mark:SetPoint("TOPRIGHT",cell,"TOPRIGHT",3,3)
    cell:EnableMouse(true); cell:EnableMouseWheel(true)
    cell:SetScript("OnEnter",function() Tooltip(cell,cell.entry,true) end)
    cell:SetScript("OnLeave",function() GameTooltip:Hide() end)
    cell:SetScript("OnMouseWheel",Wheel)
    cell:Hide()
    cells[i]=cell
end
local function Place() if not K.DB().layout.loot then K.layout.Place("loot") end end
local function ApplyMode(mode)
    lastMode=mode; current=nil; offset=0
    for _,row in ipairs(rows) do row:Hide() end
    for _,line in ipairs(lines) do line:Hide() end
    for _,cell in ipairs(cells) do cell:Hide() end
    empty:Hide(); notice:Hide()
    local single=(mode=="notice")
    if single then icon:Show(); label:Show(); detail:Show(); notice:SetWidth(300); Height(76)
    else icon:Hide(); label:Hide(); detail:Hide() end
    notice.title:SetText(K.T("Beute"))
    Place()
end
local function Icon()
    if not current then return end
    local texture
    if current.item then
        local name,link,quality,minLevel,itemType,subType,stack,equipLoc,itemTexture=GetItemInfo(current.item)
        texture=itemTexture
        current.cached=name and true or false
        local slot=equipLoc and getglobal(equipLoc)
        if slot then notice.title:SetText(K.T("Beute").." · "..slot) end
    end
    icon:SetTexture(texture or "Interface\\Icons\\INV_Box_01")
end
local function Receive(_,message)
    if type(message)~="string" then return end
    local plain=Plain(message)
    local body
    for _,prefix in ipairs(prefixes) do
        if string.sub(plain,1,string.len(prefix))==prefix then
            body=Trim(string.sub(plain,string.len(prefix)+1)); break
        end
    end
    if not body or body=="" then return end
    local first,last,item,name=string.find(message,"|H(item:[^|]+)|h(.-)|h")
    local _,_,foundColor=string.find(message,"(|c%x%x%x%x%x%x%x%x)|Hitem:")
    -- Azeroth Survivors sends the line as plain text ("[Name] (already collected)"), without an item link.
    local plainName,tail
    if not item then
        local _,_,bracket,rest=string.find(body,"^%[(.-)%](.*)$")
        plainName,tail=bracket,rest
    else tail=Trim(Plain(string.sub(message,last+1))) end
    -- The game itself marks items that are already in the collection with a trailing "(...)" note
    -- ("(already collected)", "(bereits gesammelt)", ...); a line without it is new to the collection.
    local collected=string.find(Trim(tail or ""),"^%(.+%)%.?$")~=nil
    local isNew=(item or plainName) and not collected
    local _,_,id=string.find(item or "","^item:(%d+)")
    id=tonumber(id)
    if id then Seen()[id]=true end
    if K.collection and K.DB().collectionRecord~=false and (item or plainName) then
        K.collection.Observe({item=item,name=plainName or string.gsub(name or "?","^%[(.*)%]$","%1")},true)
    end
    if not Enabled() then return end
    if item or plainName then
        local entry={item=item,name=plainName or (string.gsub(name or "?","^%[(.*)%]$","%1")),color=foundColor,new=isNew and true or false}
        local seconds=AZS_GetRunTime and AZS_GetRunTime()
        if K.Number(seconds) then entry.time=seconds end
        Fill(entry)
        local run=Run()
        run.id=run.id or RunId()
        table.insert(run.entries,1,entry)
        while table.getn(run.entries)>MAX_STORED do table.remove(run.entries) end
        offset=0
    end
    if loot.Mode()~="notice" then return end
    if loot.NewOnly() and not isNew then return end
    notice.title:SetText(K.T("Beute"))
    local suffix
    if item then
        suffix=Trim(Plain(string.sub(message,last+1)))
        label:SetText((foundColor or "")..name..(foundColor and "|r" or ""))
    else
        label:SetText(body)
        suffix=""
    end
    if suffix=="" or suffix=="." then suffix=K.T("Beute erhalten") end
    detail:SetText(suffix)
    current={item=item,message=message,expires=GetTime()+8}
    Icon()
    Place()
    notice:Show(); K.Native("loot",true)
end
notice:EnableMouse(true); notice:EnableMouseWheel(true)
notice:SetScript("OnMouseWheel",Wheel)
notice:SetScript("OnEnter",function()
    if lastMode~="notice" or not current then return end
    GameTooltip:SetOwner(notice,"ANCHOR_LEFT")
    if current.item and current.cached then GameTooltip:SetHyperlink(current.item)
    else GameTooltip:SetText(current.message,0.94,0.91,0.82) end
    GameTooltip:Show()
end)
notice:SetScript("OnLeave",function() GameTooltip:Hide() end)
-- A run that ended or restarted empties the list: another run id, or the reported run time falling back.
local function CheckRun()
    local run=Run()
    local id=RunId()
    if id and run.id and run.id~=id then loot.Clear()
    elseif id and not run.id and table.getn(run.entries)>0 then run.id=id end
    local reported=K.ReportedRunTime()
    if reported and previousReported and reported<previousReported-K.RUN_BACK then loot.Clear() end
    if reported then previousReported=reported end
end
local function RenderList(mode)
    local show=Enabled() or (IsAltKeyDown and IsAltKeyDown()) or (K.layout.IsEditing and K.layout.IsEditing())
    if not show then notice:Hide(); return end
    local list=Visible()
    local n=table.getn(list)
    local icons=(mode=="icons")
    local perPage=icons and PER_ROW*SMALL_ROWS or (mode=="small" and MAX_LINES or MAX_ROWS)
    local step=icons and PER_ROW or 1
    local maxOffset=math.max(0,n-perPage)
    if icons then maxOffset=math.max(0,(math.ceil(n/PER_ROW)-SMALL_ROWS)*PER_ROW) end
    if offset>maxOffset then offset=maxOffset end
    offset=math.floor(offset/step)*step
    notice.title:SetText(n>0 and (K.T("Beute").." ("..n..")") or K.T("Beute"))
    local shown=math.min(perPage,n-offset)
    local status=loot.Status()
    if icons then
        notice:SetWidth(188)
        for i,cell in ipairs(cells) do
            local entry=i<=shown and list[offset+i] or nil
            cell.entry=entry
            if entry then
                Fill(entry)
                cell.border:SetVertexColor(EntryColor(entry))
                cell.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Box_01")
                StatusMark(cell.mark,entry,status)
                cell:Show()
            else cell:Hide() end
        end
        Height(n>0 and (34+math.ceil(shown/PER_ROW)*(CELL+4)+6) or 70)
    else
        local compact=(mode=="small")
        local set=compact and lines or rows
        local height=compact and LINE or 22
        notice:SetWidth(compact and 184 or 300)
        Layout(mode)
        for i,row in ipairs(set) do
            local entry=i<=shown and list[offset+i] or nil
            row.entry=entry
            if entry then
                Fill(entry)
                row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Box_01")
                row.name:SetText(ColoredName(entry))
                local text,r,g,b=StatusText(entry)
                if compact then
                    row.tag:SetText(""); StatusMark(row.mark,entry,status)
                elseif status and text then row.tag:SetText(text); row.tag:SetTextColor(r,g,b)
                else row.tag:SetText("") end
                if not compact then
                    row.slot:SetText(SlotName(entry) or "")
                    row.time:SetText(K.Number(entry.time) and K.Clock(entry.time) or "")
                end
                row:Show()
            else row:Hide() end
        end
        Height(n>0 and (32+shown*height+8) or 70)
    end
    if n==0 then
        empty:SetText(K.T("Noch keine Beute in diesem Run"))
        empty:SetWidth(mode=="list" and 272 or (mode=="small" and 168 or 164))
        empty:Show()
    else empty:Hide() end
    Place()
    notice:Show()
end
local function Update()
    K.Native("loot",Enabled() and true or false)
    if arranged~=Grow() then Arrange() end
    local mode=loot.Mode()
    if mode~=lastMode then ApplyMode(mode); Arrange() end
    CheckRun()
    if mode~="notice" then RenderList(mode); return end
    if not Enabled() or not current or GetTime()>=current.expires then
        current=nil; notice:Hide(); return
    end
    Icon()
    Place()
end
function loot.Command(rest)
    if rest=="clear" then
        loot.Clear(); Update()
        K.Say(K.T("Beuteliste geleert."))
    elseif rest=="debug" then
        K.Say(K.T("Beute: Modus %s, Einträge %d, Sammlung %d, nur neuer Loot: %s, Run %s",
            K.T(({notice="Meldung",list="Liste",small="Liste klein",icons="Nur Symbole"})[loot.Mode()]),table.getn(Run().entries),SeenCount(),
            K.T(loot.NewOnly() and "An" or "Aus"),tostring(Run().id)))
    else K.Say(K.T("/kui loot clear (Liste leeren), /kui loot debug")) end
end
K.On("CHAT_MSG_LOOT",Receive)
K.On("CHAT_MSG_SYSTEM",Receive)
K.On("CHAT_MSG_ADDON",function(_,prefix)
    if prefix=="AZSZONE" then
        current=nil; notice:Hide()
        local run=Run(); run.entries={}; run.id=nil; offset=0
    end
end)
table.insert(K.updates,Update)
Update()
