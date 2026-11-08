-- Native 1.12 plates are anonymous Button children of WorldFrame (benilla-reference
-- nameplate.rs): six regions in creation order (border, glow, name, level, skull, raid icon),
-- then one StatusBar child, the health bar, whose fill is its own ARTWORK region. The plate's
-- art and the bar are separate frames, so both are masked. Plates are pooled and never destroyed.
local K=KeijinUI
local plates,known={},{}
local pending,anchors={},{} -- reused; only unseen native frames need a per-frame visibility probe
K.nameplates=plates
local BORDER="interface\\tooltips\\nameplate-border"
local RAID_ATLAS="interface\\targetingframe\\ui-raidtargetingicons"
local nativeShow,nativeHide=ShowNameplates,HideNameplates
local scanned,scanErrors,lastError=0,0,nil
local elapsed,fullDue,activeMode=0,true,nil
local lastTargetName,targetDirty=nil,false
local function Mode()
    local value=K.DB().nameplates
    if value~="off" and value~="bosses" and value~="all" then value="bosses"; K.DB().nameplates=value end
    return value
end
function K.SetNameplates(mode)
    if mode~="off" and mode~="bosses" and mode~="all" then return end
    K.DB().nameplates=mode
    if mode=="off" then
        if activeMode~="off" and K.ReleaseNameplates then K.ReleaseNameplates(); activeMode="off" end
        if nativeHide then nativeHide() end
        if HideFriendNameplates then HideFriendNameplates() end
        NAMEPLATES_ON=nil
    else
        fullDue=true
        K.DB().platesOn=mode
        if nativeShow then nativeShow() end; NAMEPLATES_ON=1
    end
    if K.UpdateNameplateLabels then K.UpdateNameplateLabels() end
end
-- Keep the game's V binding and the explicit setting in agreement; V returns to the last visible mode.
if nativeShow then ShowNameplates=function() if not K.ModuleOn("nameplates") then nativeShow(); return end; local m=K.DB().platesOn; K.SetNameplates(m=="bosses" and "bosses" or "all") end end
if nativeHide then HideNameplates=function() if not K.ModuleOn("nameplates") then nativeHide(); return end; K.SetNameplates("off") end end
local rareNames={}
local function ByKind(kind)
    if kind=="boss" or kind=="final" then return "boss" end
    if kind=="rare" then return "rare" end
    if kind=="elite" or kind=="guardian" then return "elite" end
    return "normal"
end
-- Unit lists are replaced or stamped by the client. Schedule rows can also change in place.
local unitNames,scheduleNames={},{}
local units,unitsUpdated,indexVersion=nil,nil,0
local scheduleRows={}
local function RefreshKinds()
    -- Unit index invalidation relies on AZS_UNITS table identity and the AZS_UNITS_UPDATED stamp.
    if units~=AZS_UNITS or unitsUpdated~=AZS_UNITS_UPDATED then
        units=AZS_UNITS; unitsUpdated=AZS_UNITS_UPDATED; unitNames={}
        for _,u in ipairs(units or {}) do
            if u.name and not unitNames[u.name] then unitNames[u.name]=ByKind(u.kind) end
        end
        indexVersion=indexVersion+1
    end
    local schedule=K.Schedule()
    local changed=table.getn(scheduleRows)~=table.getn(schedule)
    for i,u in ipairs(schedule) do
        local old=scheduleRows[i]
        if not old or old.name~=u.name or old.state~=u.state then changed=true; break end
    end
    if changed then
        scheduleNames={}; scheduleRows={}
        for i,u in ipairs(schedule) do
            scheduleRows[i]={name=u.name,state=u.state}
            if u.name and u.state~="dead" and u.state~="due" then scheduleNames[u.name]="boss" end
        end
        indexVersion=indexVersion+1
    end
end
local function TargetKind(name)
    if UnitClassification then
        local class=UnitClassification("target")
        if class=="rare" or class=="rareelite" then
            return "rare",true
        end
        if class=="worldboss" then return "boss" end
    end
    if AZS_UnitKind then
        local kind=AZS_UnitKind("target")
        if kind then return ByKind(kind) end
    end
    if AZS_TARGET and AZS_TARGET.name==name and AZS_TARGET.kind then return ByKind(AZS_TARGET.kind) end
end
local function Kind(p,name,target,targetKind,targetRare)
    if target and targetRare and not rareNames[name] then rareNames[name]=true; indexVersion=indexVersion+1 end
    if p.kindName~=name or p.kindVersion~=indexVersion then
        p.kindName=name; p.kindVersion=indexVersion
        p.baseKind=unitNames[name] or (rareNames[name] and "rare") or scheduleNames[name] or "normal"
    end
    return target and targetKind or p.baseKind
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
    -- The native raid texture belongs to this plate, even for duplicate names.
    -- Keep its ARTWORK layer alive, masking the other regions individually.
    -- Never Show/Hide the marker: the client owns its index and removal state.
    if p.raidMarker then
        if hidden then p.plate:EnableDrawLayer("ARTWORK") end
        for _,entry in ipairs(p.maskRegions) do entry.region:SetAlpha(hidden and 0 or entry.alpha) end
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
-- Own visibility flags avoid redundant native calls, including after a pooled plate returns.
local function FrameShown(p,shown)
    if p.frameShown==shown then return end
    p.frameShown=shown
    if shown then p.frame:Show() else p.frame:Hide() end
end
local function ClearDebuffs(p)
    if p.debuffs and p.debuffs.shown>0 then K.UpdateDebuffRow(p.debuffs,nil) end
    p.debuffCount=nil
end
function K.ReleaseNameplates()
    fullDue=true; elapsed=0; lastTargetName=nil
    for name in pairs(anchors) do anchors[name]=nil end
    for i=table.getn(pending),1,-1 do table.remove(pending,i) end
    for _,p in ipairs(plates) do
        Mask(p,false); Click(p,false); FrameShown(p,false); ClearDebuffs(p)
        p.visible=false; p.target=false
        table.insert(pending,p)
    end
    K.targetPlateShown=false
    if K.RefreshTargetDebuffs then K.RefreshTargetDebuffs() end
    K.targetPlateShown=false
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
-- Native OnShow also runs when our own child is hidden (friendly/bosses mode).
-- Chain the client script; this identifies the plate without a per-plate closure.
local function PlateShown()
    local p=known[this]
    if not p then return end
    if p.nativeOnShow then p.nativeOnShow() end
    if p.target then targetDirty=true end
    p.seenName=nil
    if p.visible then
        p.visible=false
        table.insert(pending,p)
    end
end
local function Skin(plate,how)
    local health=plate:GetChildren()
    if not health or not health.GetMinMaxValues then return end
    local name,raidMarker
    local regions={plate:GetRegions()}
    for _,r in ipairs(regions) do
        if r:GetObjectType()=="FontString" and not name then name=r end
        if r:GetObjectType()=="Texture" and Norm(r:GetTexture())==RAID_ATLAS then raidMarker=r end
    end
    if not name then return end
    local f=CreateFrame("Frame",nil,plate)
    f:SetAllPoints(plate); f:EnableMouse(false)
    local bar=CreateFrame("StatusBar",nil,f)
    bar:SetWidth(100); bar:SetHeight(10); bar:SetPoint("CENTER",f,"CENTER",0,-4)
    bar:SetMinMaxValues(0,1); bar:SetBackdrop({bgFile=K.flat}); bar:SetBackdropColor(0.02,0.02,0.025,0.9)
    K.MetalBar(bar,bar)
    local textLayer=CreateFrame("Frame",nil,bar); textLayer:SetAllPoints(bar); textLayer:SetFrameLevel(bar:GetFrameLevel()+3)
    local label=K.Text(textLayer,"",9,"BOTTOM",0,13)
    label:ClearAllPoints(); label:SetPoint("BOTTOM",bar,"TOP",0,2)
    local value=K.Text(textLayer,"",8,"RIGHT",-3,0)
    -- Debuffs of the current target only (UnitDebuff exists for the target, not for any plate).
    local left,right,top,bottom=plate:GetHitRectInsets()
    local p={plate=plate,health=health,nativeName=name,frame=f,bar=bar,label=label,value=value,how=how,
        raidMarker=raidMarker,maskRegions={},healthAlpha=health:GetAlpha() or 1,insets={left or 0,right or 0,top or 0,bottom or 0}}
    if raidMarker then
        for _,r in ipairs(regions) do
            if r~=raidMarker then table.insert(p.maskRegions,{region=r,alpha=r:GetAlpha()}) end
        end
    end
    p.order=table.getn(plates)+1
    known[plate]=p; table.insert(plates,p); table.insert(pending,p)
    p.nativeOnShow=plate:GetScript("OnShow")
    plate:SetScript("OnShow",PlateShown)
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
-- The shared debuff renderer writes every icon. Call it only when its visible data changed.
local function RefreshDebuffs(p)
    local count,changed=0,false
    if UnitDebuff then
        for i=1,table.getn(p.debuffs.icons) do
            local texture,amount=UnitDebuff("target",i)
            if not texture then break end
            count=count+1
            local icon=p.debuffs.icons[i]
            if icon.plateTexture~=texture or icon.plateCount~=amount then
                icon.plateTexture=texture; icon.plateCount=amount; changed=true
            end
        end
    end
    if changed or p.debuffCount~=count then
        p.debuffCount=count
        K.UpdateDebuffRow(p.debuffs,"target")
    end
end
local function RefreshPlate(p,name,mode,target,targetKind,targetRare)
    local red,green,blue=p.health:GetStatusBarColor()
    red,green,blue=red or 1,green or 0,blue or 0
    local enemy=not (green>red+0.1 and green>blue+0.1) and not (blue>red+0.1 and blue>green+0.1)
    local kind=Kind(p,name,target,targetKind,targetRare)
    Mask(p,enemy)
    local show=enemy and (mode=="all" or kind~="normal")
    if show then
        local low,high=p.health:GetMinMaxValues(); local value=p.health:GetValue()
        local share=high>low and math.max(0,math.min(1,(value-low)/(high-low))) or 0
        -- Values are remembered per plate; native setters run only when their input changed.
        local width=kind=="boss" and 154 or ((kind=="elite" or kind=="rare") and 124 or 100)
        local height=kind=="boss" and 14 or 10
        if p.cWidth~=width then p.cWidth=width; p.bar:SetWidth(width) end
        -- Native marker is anchored RIGHT to the plate's LEFT (nameplate.rs).
        -- Grow wider bars to the right while marked, leaving that native area clear.
        local offset=p.raidMarker and p.raidMarker:IsShown() and math.max(0,(width-p.plate:GetWidth())/2+4) or 0
        if p.cOffset~=offset then
            p.cOffset=offset; p.bar:ClearAllPoints(); p.bar:SetPoint("CENTER",p.frame,"CENTER",offset,-4)
        end
        if p.cLabelWidth~=width then p.cLabelWidth=width; p.label:SetWidth(width) end
        if p.cHeight~=height then p.cHeight=height; p.bar:SetHeight(height) end
        if p.cShare~=share then
            p.cShare=share; p.bar:SetValue(share)
            local percent=string.format("%.0f%%",share*100)
            if p.cPercent~=percent then p.cPercent=percent; p.value:SetText(percent) end
        end
        local execute=K.DB().executeMarker==true
        local executeLow=share<=.30
        if p.executeLow~=executeLow or p.executeWidth~=width or p.executeHeight~=height or p.executeEnabled~=execute then
            p.executeLow=executeLow; p.executeWidth=width; p.executeHeight=height; p.executeEnabled=execute
            K.combatDetails.Execute(p.frame,p.bar,share,false)
        end
        if p.cKind~=kind then
            p.cKind=kind
            if kind=="boss" then p.bar:SetStatusBarColor(0.65,0.3,0.72)
            elseif kind=="elite" then p.bar:SetStatusBarColor(0.85,0.45,0.13)
            elseif kind=="rare" then p.bar:SetStatusBarColor(0.62,0.72,0.86)
            else p.bar:SetStatusBarColor(0.7,0.15,0.13) end
        end
        if p.cName~=name then p.cName=name; p.label:SetText(name) end
        local isTarget=target and true or false
        if p.cTarget~=isTarget then
            p.cTarget=isTarget
            p.label:SetTextColor(target and 1 or 0.9,target and 0.82 or 0.88,target and 0.28 or 0.8)
        end
        local labelShown=kind~="normal" or target
        if p.labelShown~=labelShown then
            p.labelShown=labelShown
            if labelShown then p.label:Show() else p.label:Hide() end
        end
        FrameShown(p,true)
        Click(p,false)
        if target then
            if not p.debuffs then
                p.debuffs=K.DebuffRow(p.frame,14,true)
                p.debuffs:SetPoint("TOP",p.bar,"BOTTOM",0,-2)
            end
            RefreshDebuffs(p)
        else ClearDebuffs(p) end
    else
        FrameShown(p,false)
        Click(p,enemy)
        ClearDebuffs(p)
    end
end
local function Run()
    local mode=Mode()
    -- No discovery, target queries or plate calls while off, even if the native pool grows.
    if mode=="off" then
        if activeMode~="off" then K.ReleaseNameplates(); activeMode="off" end
        return
    end
    if not WorldFrame then return end
    local full=fullDue or activeMode~=mode or elapsed>=0.1
    if full then elapsed=0; fullDue=false end
    activeMode=mode
    Discover()
    local targetName=table.getn(plates)>0 and UnitExists("target") and UnitName("target")
    local targetChanged=targetDirty or lastTargetName~=targetName
    targetDirty=false; lastTargetName=targetName
    local kindsReady=false
    local targetKind,targetRare
    if full or targetChanged then
        RefreshKinds(); kindsReady=true
        if targetName then targetKind,targetRare=TargetKind(targetName) end
    end
    local scanAll=full or targetChanged
    local list=pending
    local targetShown=K.targetPlateShown and true or false
    if scanAll then
        list=plates; targetShown=false
        for name in pairs(anchors) do anchors[name]=nil end
        for i=table.getn(pending),1,-1 do table.remove(pending,i) end
    end
    local i=1
    while i<=table.getn(list) do
        local p=list[i]
        local advance=true
        if p.plate:IsShown() then
            local name=p.nativeName:GetText() or ""
            -- Alpha disambiguates equal names, including a switch between two pooled twins.
            p.anchorTarget=p.plate:GetAlpha()>=0.99
            local target=(targetName==name and p.anchorTarget) and true or false
            if full or not p.visible or p.seenName~=name or p.target~=target or (targetChanged and (target or p.target)) then
                if not kindsReady then
                    RefreshKinds(); kindsReady=true
                    if targetName then targetKind,targetRare=TargetKind(targetName) end
                end
                RefreshPlate(p,name,mode,target,targetKind,targetRare)
            end
            p.visible=true; p.seenName=name; p.target=target
            local best=anchors[name]
            if p.plate.GetCenter and (not best or best.seenName~=name or not best.plate:IsShown() or (p.anchorTarget and not best.anchorTarget)
                or (p.anchorTarget==best.anchorTarget and p.order<best.order)) then anchors[name]=p end
            if not scanAll then
                -- Swap removal: no table creation or shifting the rest of the pool.
                -- Lua 5.0 remembers the length: a raw nil would leave getn stale.
                local n=table.getn(pending)
                pending[i]=pending[n]; table.remove(pending,n); advance=false
            end
            if target and p.frameShown then targetShown=true end
        else
            if p.visible then
                p.visible=false; p.target=false
                FrameShown(p,false); ClearDebuffs(p)
            end
            if scanAll then table.insert(pending,p) end
        end
        if advance then i=i+1 end
    end
    if full or K.targetPlateShown~=targetShown or targetChanged then
        K.targetPlateShown=targetShown
        if K.RefreshTargetDebuffs then K.RefreshTargetDebuffs() end
    end
end
-- Screen position (UIParent units) above the visible plate of a named enemy, for floating numbers.
-- The target's plate (alpha 1) wins over same named plates; nil when no plate is shown.
function K.PlateAnchor(name)
    local best=anchors[name]
    if not best or best.seenName~=name or not best.plate:IsShown() then return nil end
    local x,y=best.plate:GetCenter()
    if not K.Number(x) or not K.Number(y) then return nil end
    local ratio=best.plate:GetEffectiveScale()/UIParent:GetEffectiveScale()
    return x*ratio,y*ratio+22
end
if K.PerfBind then K.PerfBind("Nameplates.OnUpdate",Run,function(fn) Run=fn end) end
local function Update()
    elapsed=elapsed+(tonumber(arg1) or 0)
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
-- Only unseen plates are probed every frame. OnShow queues pooled plates immediately;
-- continuously visible plates use the 0.1 s pass. Target events also refresh immediately.
local driver=CreateFrame("Frame","KeijinUIPlates")
driver:SetScript("OnUpdate",Update)
K.On("PLAYER_TARGET_CHANGED",function() targetDirty=true end,"nameplates")
K.On("PLAYER_ENTERING_WORLD",function() K.SetNameplates(Mode()); Update() end,"nameplates")
K.On("PLAYER_LEAVING_WORLD",function() K.ReleaseNameplates() end,"nameplates")
K.On("PLAYER_LOGOUT",function() K.ReleaseNameplates() end,"nameplates")
K.SetNameplates(Mode())
