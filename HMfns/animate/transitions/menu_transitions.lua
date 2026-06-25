local Y, N = true, false

local M = {}

local _page_fade_time               = 1.58
local _textfx_bg_fade_time          = 0.34
local _textfx_text_fade_time        = 0.42
local _textfx_bg_after_page_delay   = 0.16
local _textfx_text_after_bg_delay   = 0.32

local _textfx_stagger               = 0.39
local _textfx_lock                  = 1

function M.textfx_timing(overrides)
    overrides = overrides or {}
    return {
        bg_fade_time        = overrides.bg_fade_time        or _textfx_bg_fade_time,
        text_fade_time      = overrides.text_fade_time      or _textfx_text_fade_time,
        bg_after_page_delay = overrides.bg_after_page_delay or _textfx_bg_after_page_delay,
        text_after_bg_delay = overrides.text_after_bg_delay or _textfx_text_after_bg_delay,
        stagger             = overrides.stagger             or _textfx_stagger,
        lock                = overrides.lock                or _textfx_lock,
    }
end

-------------------------------------------------
--- open_pause_menu
-------------------------------------------------
--- Helper: ease | after | fade_in_page 
local function _ease(EM, ref_table, ref_value, ease_to, delay, ease) EM:enqueue_event({ trigger = "ease", ease = ease or "lerp", blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to, delay = delay }); return Y end
local function _after(EM, delay, fn) EM:enqueue_event({ trigger = "after", blockable = N, delay = delay, func = fn }) end
local function _fade_in_page(gm, widget) widget.fx_mask = 1; _ease(gm.E_MANAGER, widget, "fx_mask", 0, _page_fade_time) end

--- Helper: _unlock_textfx_hover
local function _unlock_textfx_hover(fx)
    if fx.REMOVED then return Y end
    local cfg = fx.config or {}
    cfg.textfx_reveal_lock_count = math.max((cfg.textfx_reveal_lock_count or 1) - 1, 0)
    cfg.textfx_reveal_lock = cfg.textfx_reveal_lock_count > 0 and Y or N
    return Y
end

--- Helper: _lock_textfx_interaction
local function _lock_textfx_interaction(fx, st)
    local cfg = fx.config
    cfg.textfx_reveal_lock_count = (cfg.textfx_reveal_lock_count or 0) + 1
    cfg.textfx_reveal_lock = Y
    if st and st.hover then st.hover.is = N end
end

---____________________________
--- main: fade_in_textfx 
---____________________________
function M.fade_in_textfx(gm, widget, opts)
    local list = widget.page_card_textfx;        if not list then return end
    local EM, timing = gm.E_MANAGER, M.textfx_timing(opts)

    for i, fx in ipairs(list) do
        local start_delay = timing.bg_after_page_delay + (i - 1)*timing.stagger
        local st          = fx.states

        fx.text_bg_fx_mask = 1
        fx.fx_mask         = 1
        _lock_textfx_interaction(fx, st)

        fx.config.fx_mask_shader = fx.config.fx_mask_shader or "_-2_stroke_wipe"
        _after(EM, start_delay, function() if fx.REMOVED then return Y end; return _ease(EM, fx, "text_bg_fx_mask", 0, timing.bg_fade_time) end)
        _after(EM, start_delay + timing.text_after_bg_delay, function() if fx.REMOVED then return Y end; return _ease(EM, fx, "fx_mask", 0, timing.text_fade_time) end)
        _after(EM, start_delay + math.max(timing.lock, timing.text_after_bg_delay + timing.text_fade_time), function() return _unlock_textfx_hover(fx) end)
    end
end

---________________________________________
--- main: open_pause_menu
---________________________________________
function M.open_pause_menu(gm, panel)
    local widget = panel and panel.widget;       if not widget then return end
    _fade_in_page(gm, widget)
    M.fade_in_textfx(gm, widget)
end

return M
