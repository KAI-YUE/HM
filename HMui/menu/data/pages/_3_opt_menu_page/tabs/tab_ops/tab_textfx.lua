local MiniPage        = require("HMui.menu.data.pages._3_opt_menu_page.mini_pages._3_1_tab_header")
local TabSwitchAnims  = require("HMui.menu.data.pages._3_opt_menu_page.anims.anim_tab_switch")
local TextFx          = require("HMEng.ui_actors.hm_widget.renderers.page_brew.textfx")
local Common          = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local _pull_out = TabSwitchAnims.pull_out
local _drop_in  = TabSwitchAnims.drop_in

local Y, N = true, false
local _gap = TabSwitchAnims.gap_time

local M = {}

-----------------------------------------
--- tab replace 
-----------------------------------------
--- Helper: _after | _list_by_key | _disable_list | _remove_list
local function _after(gm, at, fn)             return Common.after(gm, at, fn) end
local function _list_by_key(list)             local out = {}; for _, fx in ipairs(list or {}) do local key = fx and fx.config and fx.config.key; if key then out[key] = fx end end; return out; end
local function _disable_list(list, disabled)  for _, fx in ipairs(list or {}) do fx.disable_button = disabled and Y; Common.disable_hover(fx, disabled); end end
local function _remove_list(list)             for _, fx in ipairs(list or {}) do fx:remove() end end

--- Helper: _build_textfx_bounds
local function _build_textfx_bounds(fx)
    if not (fx and fx.build and fx.config) then return fx end
    fx:build(tostring(fx.config.text or ""))
    return fx
end

--- Helper: _retarget_textfx
local function _retarget_textfx(fx, target)
    if not (fx and target and fx.T and fx.VT and target.T and target.config) then return fx end
    _build_textfx_bounds(target)

    local VT,  T    = fx.VT, fx.T

    local visual_x  = (VT.x or T.x or 0) + (fx.draw_offset_x or 0)
    local visual_y  = (VT.y or T.y or 0) + (fx.draw_offset_y or 0)
    local visual_r  = (VT.r or T.r or 0) + (fx.draw_rotate or 0)
    fx.config       = target.config

    for _, k in ipairs({ "x", "y", "w", "h", "r", "scale" }) do T[k], VT[k] = target.T[k], (target.VT and target.VT[k]) or target.T[k] end
    fx.draw_offset_x = visual_x - (VT.x or T.x or 0)
    fx.draw_offset_y = visual_y - (VT.y or T.y or 0)
    fx.draw_rotate   = visual_r - (VT.r or T.r or 0)

    _build_textfx_bounds(fx)
    fx.draw_offset_x = visual_x - (VT.x or T.x or 0)
    fx.draw_offset_y = visual_y - (VT.y or T.y or 0)
    fx.draw_rotate   = visual_r - (VT.r or T.r or 0)
    return fx
end

--- Helper: _adopt_textfx_target
local function _adopt_textfx_target(fx, target)
    if not (fx and target and fx.T and fx.VT and target.T and target.config) then return fx end

    _build_textfx_bounds(target)
    fx.config = target.config
    for _, k in ipairs({ "x", "y", "w", "h", "r", "scale" }) do fx.T[k], fx.VT[k] = target.T[k], target.VT and target.VT[k] or target.T[k] end
    fx.draw_offset_x, fx.draw_offset_y, fx.draw_rotate = 0, 0, 0
    _build_textfx_bounds(fx)
    return fx
end

--- Helper: _idle_slot_index
local function _idle_slot_index(state, key)  for i, item_key in ipairs((state and state.queue) or {}) do if item_key == key then return i end end end

--- Helper: _persistent_tab_actors
local function _persistent_tab_actors(mini)
    local actors = {}
    for _, fx in ipairs((mini and mini.page_card_textfx) or {}) do local key = fx and fx.config and fx.config.key; if key then actors[key] = fx end; end
    mini.opt_tab_actors_by_key = actors
    return actors
end

--- Helper: _target_tab_actors
local function _target_tab_actors(gm, mini, state)
    local current_list = mini.page_card_textfx
    local target_list = TextFx.replace_card_textfx(mini, gm, MiniPage.build_card_textfx(state, gm))
    local target_by_key, order = {}, {}

    for i, fx in ipairs(target_list or {}) do
        _build_textfx_bounds(fx)
        local key = fx and fx.config and fx.config.key
        if key then target_by_key[key] = fx; order[i] = key end
    end

    mini.page_card_textfx = current_list
    return target_by_key, order, target_list
end

--- Helper: _apply_persistent_targets
local function _apply_persistent_targets(gm, mini, actors_by_key, target_by_key, order, old_state, new_state, picked_key)
    local out, old_active_key = {}, old_state and old_state.active_key

    for _, key in ipairs(order or {}) do
        local fx, target = actors_by_key[key], target_by_key[key]
        if not fx or not target then goto continue end 
        if key == picked_key or key == old_active_key then  _adopt_textfx_target(fx, target)
        elseif _idle_slot_index(old_state, key) ~= _idle_slot_index(new_state, key) then _retarget_textfx(fx, target); TabSwitchAnims.realign(gm, fx) end
        out[#out + 1] = fx
        ::continue::
    end

    mini.page_card_textfx = out
    return _list_by_key(out), out
end

--- Helper: _finish_tab_textfx
local function _finish_tab_textfx(panel, mini, new_list, token)
    if panel.stroked_page_switch_token ~= token then return Y end
    _disable_list(new_list, N)
    if mini then mini.page_card_textfx = new_list end
    return Y
end

---_________________________________
--- main: replace
---_________________________________
function M.replace(gm, panel, mini, old_state, new_state, picked_key, token)
    local old_list        = mini.page_card_textfx or {}
    local old_by_key      = _persistent_tab_actors(mini)
    local old_active_key  = old_state and old_state.active_key

    _disable_list(old_list, Y)
    _pull_out(gm, old_by_key[old_active_key], 0)
    _pull_out(gm, old_by_key[picked_key], _gap)

    local build_at = TabSwitchAnims.pull_duration() + _gap + 0.02
    _after(gm, build_at, function()
        if panel.stroked_page_switch_token ~= token then return Y end

        local target_by_key, order, target_list = _target_tab_actors(gm, mini, new_state)
        local new_by_key, new_list = _apply_persistent_targets(gm, mini, old_by_key, target_by_key, order, old_state, new_state, picked_key)
        _disable_list(new_list, Y)
        _remove_list(target_list)

        _drop_in(gm, new_by_key[picked_key], 0)
        _drop_in(gm, new_by_key[old_active_key], TabSwitchAnims.drop_duration() + _gap)
        _after(gm, TabSwitchAnims.switch_delay - build_at, function() return _finish_tab_textfx(panel, mini, new_list, token) end)
        return Y
    end)
end

return M
