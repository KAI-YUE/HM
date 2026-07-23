local N = false

local M = {}

--------------------------------------------------
--- hide
--------------------------------------------------
--- Helper: hide_obj
local function hide_obj(session, obj)
    if not (obj and obj.states) then return end
    session.visibility[obj] = obj.states.visible
    obj.states.visible = N
end

---______________________________
--- main: hide
---______________________________
function M.hide(gm, session)
    if session.visibility_hidden then return end
    session.visibility_hidden = true
    hide_obj(session, gm.field)
    for _, chara in pairs((gm.R.CHARA) or {}) do hide_obj(session, chara) end
    hide_obj(session, gm.HUD)
    hide_obj(session, gm.HUD_blind)
    hide_obj(session, gm.run_loop and gm.run_loop.foe_preview)
    for _, tag in pairs(gm.HUD_tags or {}) do hide_obj(session, tag) end
end

--------------------------------------------------
--- restore
--------------------------------------------------
---______________________________
--- main: restore
---______________________________
function M.restore(session)
    for obj, visible in pairs(session.visibility) do
        if not obj.REMOVED and obj.states then obj.states.visible = visible end
    end
    session.visibility_hidden = nil
end

return M
