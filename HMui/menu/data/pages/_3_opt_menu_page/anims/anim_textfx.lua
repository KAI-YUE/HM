local AnimUtils = require("HMfns.animate.transitions.anim_utils")
local Slots  = require("HMui.menu.data.pages._1_load_2_save_pages._shared.anims.anim_slots")

local Y, N = true, false

local M = {}

local _back_textfx_start = 1.8
local _queue             = "save_menu_enter"

--- Helper: _after | _ease
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end
local function _ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _queue) end

---helper: _back_textfx
local function _back_textfx(ctx)  for _, fx in ipairs((ctx and ctx.text_new) or {}) do if fx.config and fx.config.key == "back" then return fx end end end

---helper: _cache_textfx_enter
local function _cache_textfx_enter(fx)
    if not fx or fx._save_menu_textfx_enter_cached then return end
    local cfg = fx.config or {}
    fx._save_menu_normal_draw_alpha = fx.draw_alpha
    fx._save_menu_normal_fx_shader  = cfg.fx_mask_shader
    fx._save_menu_textfx_enter_cached = Y
end

---helper: _set_textfx_enter
local function _set_textfx_enter(fx)
    if not fx then return end
    _cache_textfx_enter(fx)
    fx.draw_alpha, fx.fx_mask, fx.fx_mask_dir = 0, 1, 1
    if fx.config then fx.config.fx_mask_shader = Slots.enter_text_shader end
end

--- Helper: _lock_textfx_interaction
local function _lock_textfx_interaction(fx)
    if not (fx and fx.config) then return end
    local cfg = fx.config
    cfg.textfx_reveal_lock_count = (cfg.textfx_reveal_lock_count or 0) + 1
    cfg.textfx_reveal_lock = Y
    local hover = fx.states and fx.states.hover;     if hover then hover.is = N end
end

--- Helper: _unlock_textfx_interaction
local function _unlock_textfx_interaction(fx)
    if not (fx and fx.config) then return end
    local cfg = fx.config
    cfg.textfx_reveal_lock_count = math.max((cfg.textfx_reveal_lock_count or 1) - 1, 0)
    cfg.textfx_reveal_lock = cfg.textfx_reveal_lock_count > 0 and Y or N
end

---helper: _restore_textfx_enter
local function _restore_textfx_enter(fx)
    if not fx or not fx._save_menu_textfx_enter_cached then return Y end
    fx.draw_alpha = fx._save_menu_normal_draw_alpha
    if fx.config then fx.config.fx_mask_shader = fx._save_menu_normal_fx_shader end
    _unlock_textfx_interaction(fx)
    fx._save_menu_normal_draw_alpha = nil
    fx._save_menu_normal_fx_shader = nil
    fx._save_menu_textfx_enter_cached = nil
    return Y
end

---helper: _fade_in_textfx
local function _fade_in_textfx(gm, fx, delay)
    if not fx then return end
    _set_textfx_enter(fx)
    _lock_textfx_interaction(fx)
    _after(gm, delay, function()
        if fx.REMOVED then return Y end
        _ease(gm, fx, "draw_alpha", fx._save_menu_normal_draw_alpha or 1, Slots.fade_time, "lerp")
        return _ease(gm, fx, "fx_mask", 0, Slots.fade_time, "lerp")
    end)
    _after(gm, delay + Slots.fade_time + 0.3, function() return _restore_textfx_enter(fx) end)
end

---helper: fade_in_back
function M.fade_in_back(gm, ctx) _fade_in_textfx(gm, _back_textfx(ctx), _back_textfx_start) end

return M
