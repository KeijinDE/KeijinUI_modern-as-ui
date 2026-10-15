-- Native 1.12 plates are anonymous Button children of WorldFrame (benilla-reference
-- nameplate.rs): six regions in creation order (border, glow, name, level, skull, raid icon),
-- then one StatusBar child, the health bar, whose fill is its own ARTWORK region. The plate's
-- art and the bar are separate frames, so both are masked. Plates are pooled and never destroyed.
local K=KeijinUI
local plates,known={},{}
K.nameplates=plates
local BORDER="interface\\tooltips\\nameplate-border"
local nativeShow,nativeHide=ShowNameplates,HideNameplates
local scanned,scanErrors,lastError=0,0,nil
local function Mode()
    local value=K.DB().nameplates
    if value~="off" and value~="bosses" and value~="all" then value="bosses"; K.DB().nameplates=value end
    return value
end
function K.SetNameplates(mode)
    if mode~="off" and mode~="bosses" and mode~="all" then return end
    K.DB().nameplates=mode
    if mode=="off" then
        if nativeHide then nativeHide() end
        if HideFriendNameplates then HideFriendNameplates() end
        NAMEPLATES_ON=nil
    else
        K.DB().platesOn=mode
        if nativeShow then nativeShow() end; NAMEPLATES_ON=1
    end
    if K.UpdateNameplateLabels then K.UpdateNameplateLabels() end
end
-- Keep the game's V binding and the explicit setting in agreement; V returns to the last visible mode.
if nativeShow then ShowNameplates=function() local m=K.DB().platesOn; K.SetNameplates(m=="bosses" and "bosses" or "all") end end
if nativeHide then HideNameplates=function() K.SetNameplates("off") end end
local rareNames={}
local function ByKind(kind)
    if kind=="boss" or kind=="final" then return "boss" end
    if kind=="rare" then return "rare" end
    if kind=="elite" or kind=="guardian" then return "elite" end
    return "normal"
end
local function Kind(name,isTarget)
    -- Only the target can be identified for certain; other plates only by name.
    if isTarget and UnitClassification then
        local class=UnitClassification("target")
        if class=="rare" or class=="rareelite" then rareNames[name]=true; return "rare" end
        if class=="worldboss" then return "boss" end
    end
    if isTarget and AZS_UnitKind then
        local kind=AZS_UnitKind("target")
        if kind then return ByKind(kind) end
    end
    if isTarget and AZS_TARGET and AZS_TARGET.name==name and AZS_TARGET.kind then return ByKind(AZS_TARGET.kind) end
    for _,u in ipairs(AZS_UNITS or {}) do
        if u.name==name then return ByKind(u.kind) end
    end
    -- Rares are not in AZS_UNITS: remembered by name once seen as a target.
    if rareNames[name] then return "rare" end
    for _,u in ipairs(K.Schedule()) do
        if u.name==name and u.state~="dead" and u.state~="due" then return "boss" end
    end
    return "normal"
end
local layers={"BACKGROUND","BORDER","ARTWORK","OVERLAY","HIGHLIGHT"}
-- Hide or give back every native layer: the plate's art and the health bar's fill.
local function Mask(p,hidden)
    if p.masked==hidden then return end
    p.masked=hidden
    for _,layer in ipairs(layers) do
        if hidden then p.plate:DisableDrawLayer(layer); p.health:DisableDrawLayer(layer)
        else p.plate:EnableDrawLayer(layer); p.health:EnableDrawLayer(layer) end
    end
    p.health:SetAlpha(hidden and 0 or p.healthAlpha)
end
-- Clicks go through the hit rectangle only: freelook toggles the mouse flag itself.
local function Click(p,blocked)
    if p.blocked==blocked then return end
    p.blocked=blocked
    if blocked then p.plate:SetHitRectInsets(10000,10000,10000,10000)
    else p.plate:SetHitRectInsets(unpack(p.insets)) end
end
function K.ReleaseNameplates()
    K.targetPlateShown=false
    for _,p in ipairs(plates) do Mask(p,false); Click(p,false); p.frame:Hide() end
end
local function Norm(path)
    if type(path)~="string" then return nil end
    local lower=string.lower(path)
    return (string.gsub(lower,"/","\\"))
end
local function IsPlate(child)
    if not child.GetRegions or not child.GetChildren or not child.GetObjectType then return false end
    local region=child:GetRegions()
    if region and region.GetObjectType and region:GetObjectType()=="Texture" and Norm(region:GetTexture())==BORDER then return true,"border" end
    -- Fallback when the border path is reported differently: Button, no name, StatusBar child, a FontString.
    if child:GetObjectType()=="Button" and not child:GetName() then
        local health=child:GetChildren()
        if health and health.GetObjectType and health:GetObjectType()=="StatusBar" then
            for _,r in ipairs({child:GetRegions()}) do
                if r.GetObjectType and r:GetObjectType()=="FontString" then return true,"structure" end
            end
        end
    end
    return false
end
local function Skin(plate,how)
    local health=plate:GetChildren()
    if not health or not health.GetMinMaxValues then return end
    local name
    for _,r in ipairs({plate:GetRegions()}) do if r:GetObjectType()=="FontString" then name=r; break end end
    if not name then return end
    local f=CreateFrame("Frame",nil,plate)
    f:SetAllPoints(plate); f:EnableMouse(false)
    local bar=CreateFrame("StatusBar",nil,f)
    bar:SetWidth(100); bar:SetHeight(10); bar:SetPoint("CENTER",f,"CENTER",0,-4)
    bar:SetMinMaxValues(0,1); bar:SetBackdrop({bgFile=K.flat}); bar:SetBackdropColor(0.02,0.02,0.025,0.9)
    K.MetalBar(bar,bar)
    local textLayer=CreateFrame("Frame",nil,bar); textLayer:SetAllPoints(bar); textLayer:SetFrameLevel(bar:GetFrameLevel()+3)
    local label=K.Text(textLayer,"",9,"BOTTOM",0,13)
    local value=K.Text(textLayer,"",8,"RIGHT",-3,0)
    -- Debuffs of the current target only (UnitDebuff exists for the target, not for any plate).
    local debuffs=K.DebuffRow(f,14,true)
    debuffs:SetPoint("TOP",bar,"BOTTOM",0,-2)
    local left,right,top,bottom=plate:GetHitRectInsets()
    local p={plate=plate,health=health,nativeName=name,frame=f,bar=bar,label=label,value=value,debuffs=debuffs,how=how,
        healthAlpha=health:GetAlpha() or 1,insets={left or 0,right or 0,top or 0,bottom or 0}}
    known[plate]=p; table.insert(plates,p)
end
local function Discover()
    local count=WorldFrame.GetNumChildren and WorldFrame:GetNumChildren()
    if count and count==scanned then return end
    local children={WorldFrame:GetChildren()}
    for i=(count and scanned or 0)+1,table.getn(children) do
        local child=children[i]
        if child and not known[child] then
            local ok,how=IsPlate(child)
            if ok then Skin(child,how) end
        end
    end
    scanned=count or 0
end
local function Run()
    if not WorldFrame then return end
    Discover()
    local mode=Mode()
    local targetShown=false
    for _,p in ipairs(plates) do
        if p.plate:IsShown() then
            local name=p.nativeName:GetText() or ""
            local red,green,blue=p.health:GetStatusBarColor()
            red,green,blue=red or 1,green or 0,blue or 0
            local enemy=not (green>red+0.1 and green>blue+0.1) and not (blue>red+0.1 and blue>green+0.1)
            local target=UnitExists("target") and UnitName("target")==name and p.plate:GetAlpha()>=0.99
            local kind=Kind(name,target)
            Mask(p,enemy)
            local show=enemy and mode~="off" and (mode=="all" or kind~="normal")
            if show then
                local low,high=p.health:GetMinMaxValues(); local value=p.health:GetValue()
                local share=high>low and math.max(0,math.min(1,(value-low)/(high-low))) or 0
                p.bar:SetWidth(kind=="boss" and 154 or ((kind=="elite" or kind=="rare") and 124 or 100))
                p.bar:SetHeight(kind=="boss" and 14 or 10)
                p.bar:SetValue(share)
                if kind=="boss" then p.bar:SetStatusBarColor(0.65,0.3,0.72)
                elseif kind=="elite" then p.bar:SetStatusBarColor(0.85,0.45,0.13)
                elseif kind=="rare" then p.bar:SetStatusBarColor(0.62,0.72,0.86)
                else p.bar:SetStatusBarColor(0.7,0.15,0.13) end
                p.label:SetText(name); p.label:SetTextColor(target and 1 or 0.9,target and 0.82 or 0.88,target and 0.28 or 0.8)
                if kind=="normal" and not target then p.label:Hide() else p.label:Show() end
                p.value:SetText(string.format("%.0f%%",share*100)); p.frame:Show()
                Click(p,false)
                if target then targetShown=true; K.UpdateDebuffRow(p.debuffs,"target")
                elseif p.debuffs.shown>0 then K.UpdateDebuffRow(p.debuffs,nil) end
            else
                p.frame:Hide()
                Click(p,enemy)
                if p.debuffs.shown>0 then K.UpdateDebuffRow(p.debuffs,nil) end
            end
        else
            p.frame:Hide()
            if p.debuffs.shown>0 then K.UpdateDebuffRow(p.debuffs,nil) end
        end
    end
    if K.targetPlateShown~=targetShown then K.targetPlateShown=targetShown; if K.RefreshTargetDebuffs then K.RefreshTargetDebuffs() end end
end
-- Screen position (UIParent units) above the visible plate of a named enemy, for floating numbers.
-- The target's plate (alpha 1) wins over same named plates; nil when no plate is shown.
function K.PlateAnchor(name)
    local best,bestTarget
    for _,p in ipairs(plates) do
        if p.plate:IsShown() and p.plate.GetCenter and p.nativeName:GetText()==name then
            local isTarget=p.plate:GetAlpha()>=0.99
            if not best or (isTarget and not bestTarget) then best,bestTarget=p,isTarget end
        end
    end
    if not best then return nil end
    local x,y=best.plate:GetCenter()
    if not K.Number(x) or not K.Number(y) then return nil end
    local ratio=best.plate:GetEffectiveScale()/UIParent:GetEffectiveScale()
    return x*ratio,y*ratio+22
end
local function Update()
    local ok,err=pcall(Run)
    if not ok then
        scanErrors=scanErrors+1
        if err~=lastError then lastError=err; K.Say("Plaketten Fehler: "..tostring(err)) end
    end
end
-- /kui plates debug: what the client really hands out, to compare against the expected structure.
function K.PlateDebug()
    local count=WorldFrame and WorldFrame.GetNumChildren and WorldFrame:GetNumChildren() or -1
    local shown,masked,visible=0,0,0
    for _,p in ipairs(plates) do
        if p.plate:IsShown() then shown=shown+1 end
        if p.masked then masked=masked+1 end
        if p.frame:IsShown() then visible=visible+1 end
    end
    K.Say(string.format("Plaketten: WorldFrame Kinder %d, erkannt %d, aktiv %d, nativ maskiert %d, eigene sichtbar %d, Fehler %d, Modus %s",
        count,table.getn(plates),shown,masked,visible,scanErrors,Mode()))
    local p=plates[1]
    if p then
        local parts={}
        for _,r in ipairs({p.plate:GetRegions()}) do
            table.insert(parts,tostring(r:GetObjectType())..(r:GetObjectType()=="Texture" and "("..tostring(r:GetTexture())..")" or ""))
        end
        K.Say("Erste Plakette ("..tostring(p.how).."): "..p.plate:GetObjectType()..", Regionen "..table.concat(parts,", ")
            ..", Kind "..tostring(p.health:GetObjectType()))
    end
end
table.insert(K.updates,Update)
K.On("PLAYER_ENTERING_WORLD",function() K.SetNameplates(Mode()); Update() end)
K.On("PLAYER_LEAVING_WORLD",function() K.ReleaseNameplates() end)
K.On("PLAYER_LOGOUT",function() K.ReleaseNameplates() end)
K.SetNameplates(Mode())
