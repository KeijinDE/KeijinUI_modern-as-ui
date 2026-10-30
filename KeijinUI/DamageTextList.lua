-- 4.5.0: list mode of the outgoing damage numbers (option "Als Liste anzeigen", off by default).
-- Instead of numbers rising from the enemy or a fixed point, hits appear as rows of one list with fixed
-- line spacing and a limited number of visible lines. The list is its own movable layout element
-- KeijinUICombatTextList (Alt to move, Alt and mouse wheel to scale) with its own font size.
-- Rows never overlap: every row has the same fixed height, a critical hit only slides in and is coloured,
-- it does not grow. Long numbers are shortened (12.3k, 1.2M) so a row stays inside the list width.
-- Load: new hits wait in a finite queue. Equal hits are bundled, older waiting hits are dropped when the
-- queue is full and no hit is shown later than MAX_AGE seconds after it happened.
-- Bundling: the same spell, school, critical and periodic kind within BUNDLE seconds is one row
-- ("123 x3"). With "Flächentreffer bündeln" (default) this also holds for different targets, otherwise
-- only for the same target.
local K=KeijinUI
local L={}
K.damageText.list=L
L.QUEUE=12        -- waiting hits at most
L.MAX_AGE=1.2     -- seconds a hit may wait before it is dropped instead of shown late
L.BUNDLE=0.4      -- seconds in which equal hits are one row
L.GAP=0.08        -- minimum time between two new rows
L.LIFE=3.0        -- seconds a row stays
L.FADE=0.8        -- seconds of the fade out at the end of the life
L.BASE=14         -- base font size before the list size factor
L.WIDTH=190       -- minimum list width; grows with the font so translated texts and "123k x99+!" fit
L.TEXT_EM=13.5    -- widest row text in font heights (bundled translated miss with " x99+", Russian "immune" needs about 12.2)
L.DEFAULT_LINES=6
local ICON_GAP=2
local now=0
local lastSpawn=-10
L.queue={}; L.rows={}; L.dropped=0
local queue,rows=L.queue,L.rows

local frame=CreateFrame("Frame","KeijinUICombatTextList",UIParent)
frame:SetFrameStrata("BACKGROUND"); frame:EnableMouse(false)
frame:SetWidth(L.WIDTH); frame:SetHeight(L.DEFAULT_LINES*18)
L.frame=frame

-- Settings. Absent keys keep the defaults, so nothing changes for existing players.
local OWN={compact=true,scroll=true,rise=true}
function L.Enabled() return K.DB().combatTextList==true end
function L.SetEnabled(on)
    K.DB().combatTextList=on and true or nil
    if not L.On() then L.Clear() else K.layout.Activated("combattextlist") end
end
-- True while hits go to the list instead of the floating numbers.
function L.On() return L.Enabled() and K.ModuleOn("combatText") and OWN[K.CombatTextMode()] and true or false end
function L.Lines()
    local v=K.DB().combatTextListLines
    if not K.Number(v) then return L.DEFAULT_LINES end
    return math.max(2,math.min(12,math.floor(v+.5)))
end
function L.SetLines(v)
    v=tonumber(v)
    if not K.Number(v) then return end
    v=math.max(2,math.min(12,math.floor(v+.5)))
    K.DB().combatTextListLines=v~=L.DEFAULT_LINES and v or nil
    L.Refresh()
end
function L.Size()
    local v=K.DB().combatTextListSize
    if not K.Number(v) then return 1 end
    return math.max(0.5,math.min(2,v))
end
function L.SetSize(v)
    v=tonumber(v)
    if not K.Number(v) then return end
    v=math.max(0.5,math.min(2,v))
    K.DB().combatTextListSize=math.abs(v-1)>0.001 and v or nil
    L.Refresh()
end
function L.FontSize() return math.max(1,math.floor(L.BASE*L.Size()+0.5)) end
function L.LineHeight() return math.floor(L.FontSize()*1.3+0.5) end
-- Width of the list: icon, gap and text budget grow with the font size, never below L.WIDTH.
function L.Width() return math.max(L.WIDTH,math.ceil(L.FontSize()*(L.TEXT_EM+1)+ICON_GAP+8)) end

K.layout.Register("combattextlist",frame,"Kampftext Liste",function(f)
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",300,50)
end,{hidden=true,inactive=function() return not (L.Enabled() and K.ModuleOn("combatText")) end})
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.layout.Place("combattextlist"); L.Refresh() end end,"combatText")

-- 12345 -> 12345, 123456 -> 123k, 1234567 -> 1.2M. Keeps the longest row narrower than the list.
function L.Format(n)
    if n>=1000000000000 then return ">999B" end
    if n>=1000000000 then return string.format("%.1fB",n/1000000000) end
    if n>=1000000 then return string.format("%.1fM",n/1000000) end
    if n>=100000 then return string.format("%.0fk",n/1000) end
    return string.format("%.0f",n)
end
local function RowText(row)
    local text=row.label or L.Format(row.amount)
    if row.hits>99 then text=text.." x99+" elseif row.hits>1 then text=text.." x"..row.hits end
    if row.crit then text=text.."!" end
    return text
end

local pool,iconPool={}, {}
local function Release(row)
    row.fs:Hide(); table.insert(pool,row.fs)
    if row.icon then row.icon:Hide(); table.insert(iconPool,row.icon) end
end
-- Lay out the visible rows: fixed spacing, newest on top. Row i sits at i*line height.
local function Layout()
    local font,line=L.FontSize(),L.LineHeight()
    local n=L.Lines()
    frame:SetWidth(L.Width()); frame:SetHeight(n*line)
    for i,row in ipairs(rows) do
        local age=now-row.born
        local slide=(1-math.min(1,age/0.15))*(row.crit and 16 or 6)
        local alpha=row.alpha
        local remain=L.LIFE-age
        if remain<L.FADE then alpha=alpha*math.max(0,remain/L.FADE) end
        local y=-(i-1)*line
        if row.size~=font or row.font~=K.font then row.fs:SetFont(K.font,font,"OUTLINE"); row.size=font; row.font=K.font end
        row.fs:SetWidth(L.Width()-font-ICON_GAP-8); row.fs:SetHeight(line)
        row.fs:SetJustifyH("LEFT"); row.fs:SetText(RowText(row))
        row.fs:ClearAllPoints(); row.fs:SetPoint("TOPLEFT",frame,"TOPLEFT",font+ICON_GAP+slide,y)
        row.fs:SetAlpha(alpha); row.fs:Show()
        row.y=y; row.index=i
        if row.icon then
            row.icon:SetWidth(font); row.icon:SetHeight(font)
            row.icon:ClearAllPoints(); row.icon:SetPoint("TOPLEFT",frame,"TOPLEFT",slide,y-(line-font)/2)
            row.icon:SetAlpha(alpha); row.icon:Show()
        end
    end
end
function L.Refresh()
    while table.getn(rows)>L.Lines() do Release(table.remove(rows)) end
    Layout()
end
function L.Clear()
    while table.getn(rows)>0 do Release(table.remove(rows)) end
    while table.getn(queue)>0 do table.remove(queue) end
end

local function NewRow(entry)
    local fs=table.remove(pool)
    if not fs then fs=frame:CreateFontString(nil,"OVERLAY"); fs:SetFont(K.font,L.FontSize(),"OUTLINE") end
    local row={fs=fs,born=now,first=entry.t or now,key=entry.key,amount=entry.amount,hits=entry.hits,crit=entry.crit,
        label=entry.label,alpha=entry.alpha,targetName=entry.targetName}
    fs:SetTextColor(entry.r,entry.g,entry.b)
    if entry.icon then
        local tex=table.remove(iconPool) or frame:CreateTexture(nil,"OVERLAY")
        tex:SetTexture(entry.icon); tex:SetTexCoord(0.08,0.92,0.08,0.92)
        row.icon=tex
    end
    return row
end
-- Move waiting hits into the list: drop hits that waited too long, then show the oldest remaining one
-- if the minimum gap since the last new row has passed.
function L.Pump()
    local i=1
    while i<=table.getn(queue) do
        if now-queue[i].t>L.MAX_AGE then table.remove(queue,i); L.dropped=L.dropped+1 else i=i+1 end
    end
    i=1
    while i<=table.getn(rows) do
        if now-rows[i].born>=L.LIFE then Release(table.remove(rows,i)) else i=i+1 end
    end
    if table.getn(queue)>0 and now-lastSpawn>=L.GAP then
        local entry=table.remove(queue,1)
        table.insert(rows,1,NewRow(entry)); lastSpawn=now
        while table.getn(rows)>L.Lines() do Release(table.remove(rows)) end
    end
    Layout()
end

-- Add one hit. Returns "bundled", "queued" or nil (list not active).
function L.Push(entry)
    if not L.On() then return end
    entry.t=now; entry.hits=entry.hits or 1; entry.alpha=entry.alpha or 1
    local base=entry.base
    entry.key=K.DB().combatTextMerge~=false and base or (base..":"..tostring(entry.targetName))
    -- Bundle into a waiting hit, otherwise into a recent row of the same kind.
    for i=table.getn(queue),1,-1 do
        local q=queue[i]
        if q.key==entry.key and now-q.t<=L.BUNDLE then
            q.amount=q.amount+entry.amount; q.hits=q.hits+1; return "bundled"
        end
    end
    for _,row in ipairs(rows) do
        if row.key==entry.key and now-row.first<=L.BUNDLE then
            row.amount=row.amount+entry.amount; row.hits=row.hits+1; row.born=now
            Layout(); return "bundled"
        end
    end
    table.insert(queue,entry)
    -- Over the limit: the oldest waiting hits go (a critical hit is kept longer than an ordinary one).
    while table.getn(queue)>L.QUEUE do
        local drop=1
        for i,q in ipairs(queue) do if not q.crit then drop=i; break end end
        table.remove(queue,drop); L.dropped=L.dropped+1
    end
    L.Pump()
    return "queued"
end

function L.PushDamage(amount,crit,targetName,school,periodic,spell)
    local mode=K.CombatTextMode()
    local style,r,g,b,icon=K.damageText.Describe(mode,crit,school,periodic,spell)
    L.Push({base="d:"..tostring(spell or "melee")..":"..tostring(school)..":"..tostring(crit and true or false)..":"..tostring(periodic and true or false),
        amount=amount,crit=crit and true or false,targetName=targetName,r=r,g=g,b=b,icon=icon,alpha=style and style.alpha or 1})
end
function L.PushMiss(text,targetName,spell,missType)
    local icon
    if spell and K.DB().combatTextIcons~=false then icon=K.SpellIcon(spell) end
    L.Push({base="m:"..tostring(missType)..":"..tostring(spell),amount=0,label=text,crit=false,
        targetName=targetName,r=1,g=0.82,b=0.1,icon=icon})
end

local driver=CreateFrame("Frame",nil,UIParent)
driver:SetScript("OnUpdate",function()
    now=now+(tonumber(arg1) or 0)
    -- Left the list mode (list off, style changed): nothing waits or stays visible.
    if not L.On() then
        if table.getn(rows)>0 or table.getn(queue)>0 then L.Clear() end
        return
    end
    if table.getn(rows)==0 and table.getn(queue)==0 then return end
    L.Pump()
end)
table.insert(K.damageText.drivers,driver)
K.On("PLAYER_LEAVING_WORLD",function() L.Clear() end,"combatText")
local stop=K.damageText.Stop
function K.damageText.Stop() L.Clear(); stop() end
