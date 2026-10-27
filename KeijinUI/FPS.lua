-- Client evidence: benilla-ui/src/script/client.rs, GetFramerate returns
-- the renderer's smoothed FPS. Never derive FPS from this addon's updates.
local K=KeijinUI
local F={}
K.fps=F
local frame=CreateFrame("Frame","KeijinUIFPS",UIParent)
frame:SetWidth(84); frame:SetHeight(24); frame:SetFrameStrata("MEDIUM")
frame:EnableMouse(false); frame.noOpacity=true
local text=K.Text(frame,"? FPS",12,"CENTER",0,0)
F.frame,F.text=frame,text
local lastSample
local function Range(value,fallback,low,high)
    return K.Number(value) and math.max(low,math.min(high,value)) or fallback
end
function F.On() return K.ModuleOn("fps") and K.DB().fps~=false end
function F.Framed() return K.DB().fpsFrame==true end
function F.Alpha() return Range(K.DB().fpsAlpha,.6,0,1) end
function F.Opacity() return Range(K.DB().fpsOpacity,1,0,1) end
function F.Size() return Range(K.DB().fpsSize,1,.75,2) end
function F.Color()
    local c=K.DB().fpsColor
    if type(c)=="table" and K.Number(c[1]) and K.Number(c[2]) and K.Number(c[3]) then
        return math.min(1,c[1]),math.min(1,c[2]),math.min(1,c[3])
    end
    return .94,.91,.82
end
local function Fit()
    local _,size=text:GetFont()
    frame:SetWidth(math.max(76,text:GetStringWidth()+16))
    frame:SetHeight(math.ceil(size or 12)+12)
end
local function Sample(force)
    local now=GetTime()
    if not force and lastSample and now>=lastSample and now-lastSample<.5 then return end
    lastSample=now
    local ok,value=false,nil
    if type(GetFramerate)=="function" then ok,value=pcall(GetFramerate) end
    text:SetText(ok and K.Number(value) and (string.format("%.0f",value).." FPS") or "? FPS")
    Fit()
end
function F.Refresh()
    if not F.On() then frame:Hide(); K.layout.EndMove("fps"); return end
    K.SetFontSize(text,12*F.Size())
    text:SetTextColor(F.Color())
    frame:SetAlpha(F.Opacity())
    local bg=F.Framed() and {.055,.055,.065,F.Alpha()} or nil
    K.Chamfer(frame,4,bg,{.62,.57,.43,F.Framed() and 1 or 0})
    if F.On() then frame:Show(); Sample(true) else frame:Hide() end
end
function F.Set(on)
    K.DB().fps=on and true or false; F.Refresh(); K.layout.Update()
end
function F.SetFrame(on) K.DB().fpsFrame=on and true or false; F.Refresh() end
function F.SetAlpha(value)
    if K.Number(value) then K.DB().fpsAlpha=Range(value,.6,0,1); F.Refresh() end
end
function F.SetOpacity(value)
    if K.Number(value) then K.DB().fpsOpacity=Range(value,1,0,1); F.Refresh() end
end
function F.SetSize(value)
    if K.Number(value) then K.DB().fpsSize=Range(value,1,.75,2); F.Refresh() end
end
function F.SetColor(r,g,b)
    if not K.Number(r) or not K.Number(g) or not K.Number(b) then return end
    K.DB().fpsColor={math.min(1,r),math.min(1,g),math.min(1,b)}; F.Refresh()
end
K.layout.Register("fps",frame,"FPS",function(f)
    f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",16,8)
end,{inactive=function() return not F.On() end})
K.On("ADDON_LOADED",F.Refresh)
K.On("PLAYER_ENTERING_WORLD",F.Refresh)
K.OnLang(F.Refresh)
K.Update("fps",function() if F.On() then frame:Show(); Sample(false) else frame:Hide() end end)
F.Refresh()

K.moduleRefresh.fps=F.Refresh
