local PhysicsMotion = require("HMEng.ui_actors.common.physics_motion")
local Common        = require("HMui.menu.data.pages._-1_title_page.anims.common")
local Timeline      = require("HMui.menu.data.pages._-1_title_page.anims.timeline")

local _cache  = Common.cache_widget
local _ease   = Common.ease
local _after  = Common.after

local Y = true

local M = {}

local _prep_key   = "_title_prep_kanji_part"
local _roof_key   = "_title_roof_with_pivot"
local _swing_key  = "_title_roof_swing_token"
local _roof_id    = "title_part_meshi_kanji_roof"

local prep_part_ids = {
    "title_part_shin_kanji_stroke",
    "title_part_meshi_kanji_dot",
}

--- Helper: _set_alpha
local function _set_alpha(widget, alpha) if widget then widget.draw_alpha = alpha end; end

--- Helper: _fade_part_in
local function _fade_part_in(gm, widget, delay)
    if not widget then return end
    _cache(widget, _prep_key)
    _set_alpha(widget, 0)
    _after(gm, delay, function()
        if widget.REMOVED then return Y end
        _ease(gm, widget, "draw_alpha", widget[_prep_key].draw_alpha or 1, Timeline.stage1.kanji_part_fade, "lerp")
        return Y
    end)
end

--- Helper: _fade_old_part_out
local function _fade_old_part_out(gm, old_children, id)
    local widget = Common.find_in_list(old_children, id)
    if widget then _ease(gm, widget, "draw_alpha", 0, Timeline.stage2.old_part_fade, "lerp") end
end

--- Helper: _find_new_or_root
local function _find_new_or_root(panel, ctx, id) return Common.find_in_list(ctx and ctx.new_children, id) or Common.find(panel and panel.widget, id); end

--- Helper: _roof_pivot_swing
local function _roof_pivot_swing(gm, roof, normal_o, normal, cfg)
    if not (gm and gm.E_MANAGER and roof and normal_o and normal) then return end
    
    roof[_swing_key] = (roof[_swing_key] or 0) + 1
    local token = roof[_swing_key]
    local _T    = gm._T
    local start = _T.game_s or 0

    local function tick()
        if roof.REMOVED or roof[_swing_key] ~= token then return Y end
        local now      =  _T.game_s or start
        local x, y, r  = PhysicsMotion.roof_with_pivot_idle_offset(cfg, now - start)

        roof.draw_offset_x  = normal_o.x + x
        roof.draw_offset_y  = normal_o.y + y
        roof.draw_rotate    = (normal.draw_rotate or 0) + r
        _after(gm, Common.step, tick)
        return Y
    end

    _after(gm, Common.step, tick)
end

--- Helper: _start_roof_with_pivot
local function _start_roof_with_pivot(gm, roof, cfg)
    if not roof then return end
    
    cfg = cfg or Timeline.roof_with_pivot
    _cache(roof, _roof_key)

    roof[_swing_key] = (roof[_swing_key] or 0) + 1

    local normal_o = roof[_roof_key .. "_offset"]; if not normal_o then return end
    local normal   = roof[_roof_key]
    local ax, ay   = roof.draw_anchor_x or 0.5, roof.draw_anchor_y or 0.5

    roof._debug_pivot = {
        x = roof.VT.w * ax - (cfg.pivot_rel_x or 0),
        y = roof.VT.h * ay - (cfg.pivot_rel_y or 0),
    }

    roof.draw_alpha = normal.draw_alpha or 1
    _roof_pivot_swing(gm, roof, normal_o, normal, cfg)
end

----------------------------------------------
--- preparation_enter
----------------------------------------------
function M.preparation_enter(gm, panel)
    local root = panel and panel.widget;        if not root then return end
    for i, id in ipairs(prep_part_ids) do
        _fade_part_in(gm, Common.find(root, id), Timeline.stage1.kanji_part_start + Timeline.stage1.kanji_part_step*(i - 1))
    end
    _start_roof_with_pivot(gm, Common.find(root, _roof_id))
end

----------------------------------------------
--- title_enter
----------------------------------------------
function M.title_enter(gm, panel, ctx)
    _fade_old_part_out(gm, ctx and ctx.old_children, "title_part_shin_kanji_stroke")
    _fade_old_part_out(gm, ctx and ctx.old_children, _roof_id)
    _fade_old_part_out(gm, ctx and ctx.old_children, "title_part_meshi_kanji_dot")
    _start_roof_with_pivot(gm, _find_new_or_root(panel, ctx, _roof_id))
end

return M
