local Inf = math.huge

local M = {}

---------------------------------
--- cursor_tab_key
---------------------------------
--- Helper: _tab_center_dist2
local function _tab_center_dist2(fx, p)
    local T = fx and (fx.VT or fx.T);               if not (T and p) then return Inf end
    local cx, cy  = (T.x or 0) + 0.5*(T.w or 0) + (fx.draw_offset_x or 0), (T.y or 0) + 0.5*(T.h or 0) + (fx.draw_offset_y or 0)
    local dx, dy  = cx - (p.x or 0), cy - (p.y or 0)
    return dx*dx + dy*dy
end

---_______________________________________
--- main: cursor_tab_key
---_______________________________________
function M.cursor_tab_key(gm, mini, source)
    local cursor    =  gm.CTRL.p_cursor and gm.CTRL.p_cursor.T
    local fallback  =  source.config and source.config.options_tab_key
    if not (cursor and mini and mini.page_card_textfx) then return fallback end

    local best_key, best_d2 = fallback, Inf
    for _, fx in ipairs(mini.page_card_textfx or {}) do
        local key = fx and fx.config and fx.config.options_tab_key
        if not key or fx.REMOVED or fx.disable_button or not fx:hit_test(cursor) then goto continue end 
        local d2 = _tab_center_dist2(fx, cursor)
        if d2 < best_d2 then best_key, best_d2 = key, d2 end
        ::continue::
    end
    return best_key
end

return M
