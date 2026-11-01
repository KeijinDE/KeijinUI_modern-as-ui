-- The native BannerRoot is a Bevy entity, not a Lua frame. Only payload and boss style are exposed.
-- Font, fades, lifetime and stack pitch below are an approximation: no native template was extracted.
local K=KeijinUI
-- Central switch: true hides the whole feature from users (settings page, search, module list,
-- layout window) and keeps it inert. The code stays; set false to bring it back once a native
-- source for the messages is known.
local B={queue={},rows={},Hidden=KeijinUIGameMessagesHidden~=false}
local EMPTY={}
local previewBanner={boss=false}
K.gameMessages=B
local frame=CreateFrame("Frame","KeijinUIGameMessages",UIParent)
B.frame=frame
frame:SetWidth(520); frame:SetHeight(72); frame:SetFrameStrata("HIGH"); frame:SetClampedToScreen(true); frame:Hide()
function B.On() return not B.Hidden and K.ModuleOn("gameMessages") and not B.failed end
-- Screenshots prove that hudBanners=0 alone does not establish renderer ownership.
-- No public API reports actual BannerRoot visibility in this client. Keep live
-- replacement unavailable until a working native suppression path is verified.
-- The layout preview remains useful and never contains live game messages.
function B.LiveSupported() return false end
function B.Font() return (K.DB().gameMessages or EMPTY).font or "original" end
function B.Size() return (K.DB().gameMessages or EMPTY).size or 18 end
function B.Color(boss,kind)
    local c=K.DB().gameMessages or EMPTY
    local rgb=c.color
    if boss then rgb=c.bossColor end
    if rgb then return rgb[1],rgb[2],rgb[3] end
    if kind=="cache" or kind=="error" then return 1,.15,.1 end
    return 1,boss and .15 or .82,boss and .1 or .28
end
function B.Set(field,value)
    local db=K.DB(); if not db.gameMessages then db.gameMessages={} end
    db.gameMessages[field]=value; B.Draw()
end
if not B.Hidden then
K.layout.Register("gameMessages",frame,"Spielmeldungen",function(f)
    K.Anchor(f,"TOP",UIParent,"TOP",0,-K.UIHeight()*.13)
end,{hidden=true,scaleGrips=true,minScale=.3,inactive=function() return not B.On() end})
end
local driver=CreateFrame("Frame","KeijinUIGameMessagesDriver",UIParent)
B.driver=driver
local registered=false
local elapsed=0
local function Row(i)
    if B.rows[i] then return B.rows[i] end
    local fs=frame:CreateFontString(nil,"OVERLAY")
    fs:SetWidth(520); fs:SetHeight(36); fs:SetPoint("TOP",frame,"TOP",0,-(i-1)*36)
    fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE"); fs:SetFont(K.font,22,"OUTLINE")
    if fs.SetShadowColor then fs:SetShadowColor(0,0,0,1) end
    if fs.SetShadowOffset then fs:SetShadowOffset(1,-1) end
    B.rows[i]=fs; return fs
end
local function Draw()
    if not B.On() then K.Shown(frame,false); return end
    local now=GetTime()
    for i=table.getn(B.queue),1,-1 do if now-B.queue[i].time>=5 then table.remove(B.queue,i) end end
    local preview=K.layout.Active() and table.getn(B.queue)==0
    local n=preview and 1 or table.getn(B.queue)
    for i=1,n do
        if preview then previewBanner.text=K.T("Spielmeldungen"); previewBanner.time=now end
        local b=preview and previewBanner or B.queue[i]
        local fs=Row(i)
        -- The game language can differ from the addon language. Wide text must remain readable.
        local choice=B.Font()
        local font=K.ResolveFont(K.lang,choice=="original" and "friz" or choice)
        if fs.bannerText==b.text and fs.bannerChoice==choice and fs.bannerLang==K.lang then
            font=fs.bannerFont
        else font=K.windowTools.FontForText(b.text,K.WideFont,font) end
        fs.bannerChoice,fs.bannerLang=choice,K.lang
        local size=B.Size()*(b.boss and 28/18 or 1)
        local r,g,blue=B.Color(b.boss,b.kind)
        if fs.bannerText~=b.text or fs.bannerFont~=font or fs.bannerSize~=size
            or fs.bannerR~=r or fs.bannerG~=g or fs.bannerB~=blue then
            fs:SetFont(font,size,"OUTLINE"); fs:SetTextColor(r,g,blue); fs:SetText(b.text)
            fs.bannerText,fs.bannerFont,fs.bannerSize=b.text,font,size
            fs.bannerR,fs.bannerG,fs.bannerB=r,g,blue
        end
        local age=now-b.time
        local alpha=preview and 1 or math.min(1,age/.15,(5-age)/.5)
        if fs.bannerAlpha~=alpha then fs.bannerAlpha=alpha; fs:SetAlpha(alpha) end
        K.Shown(fs,true)
    end
    for i=n+1,table.getn(B.rows) do K.Shown(B.rows[i],false) end
    K.Shown(frame,B.On() and n>0)
end
function B.Fail()
    B.failed=true; B.queue={}; driver:SetScript("OnUpdate",nil); frame:Hide()
    if registered then AZS_UnregisterBannerHandler(B.Receive); registered=false end
    -- A rendering failure must not leave the native renderer suppressed.
    K.NativeFollow("banners",false)
end
function B.Draw()
    local ok=pcall(Draw)
    if not ok then B.Fail() end
    return ok
end
local function Tick()
    elapsed=elapsed+(tonumber(arg1) or 0)
    if elapsed<.03 then return end
    elapsed=0; if not pcall(B.Draw) then B.Fail() end
    if table.getn(B.queue)==0 then driver:SetScript("OnUpdate",nil) end
end
local function ReceiveBody(b)
    if not B.On() or not B.LiveSupported() or type(b)~="table" or type(b.text)~="string" or b.text=="" then return end
    -- The game can restore HUD CVars after login or an Interface settings change.
    -- Never draw a second banner if the public suppression API refuses ownership.
    if not B.SuppressNative() then B.Fail(); return end
    -- Copy, never mutate the shared API payload; equal text with different IDs remains a separate banner.
    table.insert(B.queue,{text=b.text,kind=b.kind,boss=b.boss and true or false,time=GetTime()})
    while table.getn(B.queue)>2 do table.remove(B.queue,1) end
    B.Draw(); if not B.failed then driver:SetScript("OnUpdate",Tick) end
end
local function Receive(b)
    if not pcall(ReceiveBody,b) then B.Fail() end
end
B.Receive=Receive
function B.SuppressNative()
    if type(AZS_SetHudShown)~="function" or type(AZS_IsHudShown)~="function" then return false end
    K.Native("banners",true)
    return AZS_IsHudShown("banners")==false
end
function B.Refresh()
    if B.Hidden or not K.ModuleOn("gameMessages") then B.failed=nil end
    local available=type(AZS_RegisterBannerHandler)=="function" and type(AZS_UnregisterBannerHandler)=="function"
        and type(AZS_SetHudShown)=="function" and type(AZS_IsHudShown)=="function"
    if B.On() and available and B.LiveSupported() then
        if not registered then AZS_RegisterBannerHandler(Receive); registered=true end
        if not B.SuppressNative() then B.Fail() end
    else
        if registered then AZS_UnregisterBannerHandler(Receive); registered=false end
        -- Hidden: a test install may still have the native banner switched off by an earlier build; give it back.
        if B.Hidden then K.NativeFollow("banners",false) else K.Native("banners",false) end
        B.queue={}; driver:SetScript("OnUpdate",nil)
    end
    B.Draw()
end
function B.Original()
    K.DB().gameMessages=nil; B.failed=nil
    K.modules.Set("gameMessages",false)
end
K.On("PLAYER_ENTERING_WORLD",B.Refresh)
K.On("PLAYER_LEAVING_WORLD",function()
    B.queue={}; driver:SetScript("OnUpdate",nil); K.Shown(frame,false)
end)
if not B.Hidden then
K.modules.definitions.gameMessages={key="gameMessages",label="Spielmeldungen",text="Spielmeldungen im Layoutmodus verschieben. Aus: ursprüngliche Banneranzeige.",drivers={},stop=B.Refresh,resume=B.Refresh}
table.insert(K.modules.order,"gameMessages")
end
