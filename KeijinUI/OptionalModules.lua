-- Disabled engines lose their frame scripts and combat event subscriptions. Shared run telemetry stays active.
local K=KeijinUI
local M={definitions={}}
K.modules=M
local function Bind(key,label,drivers,stop,resume,events)
    local entry={key=key,label=label,drivers={},stop=stop,resume=resume,events=events}
    for _,frame in ipairs(drivers or {}) do
        table.insert(entry.drivers,{frame=frame,update=frame:GetScript("OnUpdate"),event=frame:GetScript("OnEvent")})
    end
    M.definitions[key]=entry
end
function M.Apply(key)
    local entry=M.definitions[key]; if not entry then return end
    local enabled=K.ModuleOn(key)
    for _,d in ipairs(entry.drivers) do
        d.frame:SetScript("OnUpdate",enabled and d.update or nil)
        d.frame:SetScript("OnEvent",enabled and d.event or nil)
        for ev in pairs(d.event and entry.events or {}) do
            if enabled then d.frame:RegisterEvent(ev) else d.frame:UnregisterEvent(ev) end
        end
    end
    if enabled then if entry.resume then entry.resume() end
    elseif entry.stop then entry.stop() end
end
function M.Set(key,on)
    if not M.definitions[key] then return false end
    local db=K.DB(); if type(db.modules)~="table" then db.modules={} end
    db.modules[key]=on and true or false; M.Apply(key); return true
end
Bind("cursor","Cursortracker",{K.cursor.frame},function() K.cursor.frame:Hide() end,K.cursor.Apply)
Bind("attributes","Charakterwerte",{},function() K.characterStats.frame:Hide() end,K.characterStats.Update)
Bind("damageText","Schadenszahlen",K.damageText.drivers,K.damageText.Stop,K.ApplyCombatText,K.tools.CombatEvents)
Bind("nameplates","Namensplaketten",{KeijinUIPlates},K.ReleaseNameplates,function() K.SetNameplates(K.DB().nameplates or "bosses") end)
Bind("caches","Caches",{},K.caches.Stop,K.caches.Update)
Bind("guardianNav","Wächternavigation",{},K.guardianNav.Update,K.guardianNav.Update)
Bind("collection","Schmucksammlung",{K.collection.driver},function() K.collection.panel:Hide() end)
Bind("insights","XP und Zusatzressourcen",{},function() K.xpRate.label:Hide(); K.tally.UpdateExtras() end,function() K.xpRate.Reset(); K.tally.UpdateExtras() end)
Bind("resourceText","Heilung und eingehender Kampftext",{},K.resourceText.Clear,K.resourceText.Clear)
Bind("jewelry","Schmuckcooldowns",{})
K.On("ADDON_LOADED",function(_,name) if name=="KeijinUI" then for key in pairs(M.definitions) do M.Apply(key) end end end)
