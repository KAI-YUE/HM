local TextFx = require("HMEng.ui_actors.hm_widget.renderers.page_brew.textfx")
local MenuTransitions = require("HMfns.animate.transitions.menu_transitions")
local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local Y, N = true, false

local M = {}
local _switch_textfx_stagger = 0.28

-----------------------------
--- switch stroked_page textfx: fade old card_textfx out and new card_textfx in.
----------------------------------
--- Helper: remove_list
local function _remove_list(list) for _, fx in ipairs(list or {}) do fx:remove() end end

--- Helper: disable_list
local function _disable_list(list, disabled)
    for _, fx in ipairs(list or {}) do
        fx.disable_button = disabled and Y
        Common.disable_hover(fx, disabled)
    end
end

--- Helper: set_slot_alpha | fade_list | ordered_reveal
local function _set_slot_alpha(list, alpha) for _, fx in ipairs(list or {}) do if fx.config then fx.config.slot_enter_alpha = alpha end end end
local function _fade_list(gm, list, key, alpha, delay) for _, fx in ipairs(list or {}) do local cfg = fx.config; if cfg then Common.ease(gm, cfg, key, alpha, delay) end end end
local function _ordered_reveal(gm, list) MenuTransitions.fade_in_textfx(gm, { page_card_textfx = list }, { stagger = _switch_textfx_stagger }) end

--- Helper: finish
local function _finish(panel, widget, old_list, new_list, token)
    if panel.stroked_page_switch_token ~= token then return Y end
    _remove_list(old_list)
    _disable_list(new_list, N)
    _set_slot_alpha(new_list, nil)
    if widget then widget.page_card_textfx = new_list end
    return Y
end

function M.start(widget, gm, page, delay)
    local fade_key  = page.switch_textfx_fade_key or "textfx_alpha"
    local old_list  = widget.page_card_textfx or {}

    _disable_list(old_list, Y)
    _fade_list(gm, old_list, fade_key, 0, delay)

    local new_list = TextFx.replace_card_textfx(widget, gm, page.card_textfx, fade_key == "textfx_alpha" and 0)
    if fade_key == "slot_enter_alpha" then _set_slot_alpha(new_list, 0) end
    _disable_list(new_list, Y)
    _fade_list(gm, new_list, fade_key, 1, delay)
    if page.switch_textfx_ordered_reveal then _ordered_reveal(gm, new_list) end

    local draw_list = {}
    Common.append_list(draw_list, old_list)
    Common.append_list(draw_list, new_list)
    widget.page_card_textfx = draw_list

    return old_list, new_list
end

function M.queue_finish(panel, gm, widget, old_list, new_list, token, delay) Common.queue_after(gm, delay, function() return _finish(panel, widget, old_list, new_list, token) end); end

return M
