local K=KeijinUI
-- Native game fonts only. No additional font file is redistributed.
K.fontChoices={{"friz","Friz Quadrata"},{"arial","Arial Narrow"}}
local fonts={friz="Fonts\\FRIZQT__.TTF",arial="Fonts\\ARIALN.TTF"}
-- The font option is not offered for now: a saved choice is ignored and Friz Quadrata is always used.
function K.FontChoice() return "friz" end
function K.SetFontChoice(key)
    if not fonts[key] then return end
    K.DB().fontFace=key; K.font=fonts[key]
    for _,v in ipairs(K.fontStrings or {}) do
        local old,size,flags
        if v[1].GetFont then old,size,flags=v[1]:GetFont() end
        v[1]:SetFont(K.font,size or v[2],flags or "OUTLINE")
    end
end
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then K.SetFontChoice(K.FontChoice()) end end)
