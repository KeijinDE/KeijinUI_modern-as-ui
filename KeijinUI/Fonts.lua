local K=KeijinUI
-- Keep native fonts for English/German; Chinese uses the bundled Apache-licensed CJK+Latin font.
K.fontChoices={{"friz","Friz Quadrata"},{"arial","Arial Narrow"}}
local fonts={friz="Fonts\\FRIZQT__.TTF",arial="Fonts\\ARIALN.TTF"}
-- The font option is not offered for now: a saved choice is ignored and Friz Quadrata is always used.
function K.FontChoice() return "friz" end
function K.SetFontChoice(key)
    if not fonts[key] then return end
    K.DB().fontFace=key; K.font=K.lang=="zh" and "Interface\\AddOns\\KeijinUI\\media\\fonts\\KeijinCJK.ttf" or fonts[key]
    for _,v in ipairs(K.fontStrings or {}) do
        local old,size,flags
        if v[1].GetFont then old,size,flags=v[1]:GetFont() end
        v[1]:SetFont(K.font,size or v[2],flags or "OUTLINE")
    end
    if K.lang=="zh" then
        for i=1,30 do
            for _,side in ipairs({"Left","Right"}) do
                local fs=getglobal("GameTooltipText"..side..i)
                if fs and fs.GetFont then
                    local old,size,flags=fs:GetFont()
                    fs:SetFont(K.font,size or 11,flags or "")
                end
            end
        end
    end
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.SetFontChoice(K.FontChoice()) end end)
K.OnLang(function() K.SetFontChoice(K.FontChoice()) end)
if K.lang=="zh" then K.SetFontChoice(K.FontChoice()) end
