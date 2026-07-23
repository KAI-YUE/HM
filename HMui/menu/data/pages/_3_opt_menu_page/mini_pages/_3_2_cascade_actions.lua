local C, CUtils   = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local HintBtns    = require("HMui.menu.data.pages._shared.hint_btns")

local tint_alpha  = CUtils.tint_with_alpha

local CUI         = C.UI
local ctl         = CUI.TEXT_LIGHT

local cw,           ck      = C.WHITE,                C.BLACK
local ccrm,         csteel  = C.CREAM,                C.STEEL
local tstroke,      tsteel  = tint_alpha(ccrm, 0.93), tint_alpha(csteel, 0.9)
local cdisk_shadow, _zc     = { 0, 0, 0, 0.22 },      { 0, 0, 0, 0 }

local Y, N = true, false

local _rot_gear = -0.4

-----------------------------
--- helpers
-----------------------------
--- Helper: reverse_gear_rotation
local function reverse_gear_rotation(gm, source)
    local cfg  = source and source.config;            if not cfg then return end
    local now  = gm._T.real_s or 0

    local speed,   phase       = cfg.sprite_rotate_speed or 0.8, cfg.sprite_rotate_phase or 0
    local current, next_speed  = phase + now*speed,              -speed*(cfg.reverse_slowdown or 0.45)

    if math.abs(next_speed) < 0.08 then next_speed = speed < 0 and 0.18 or -0.18 end
    cfg.sprite_rotate_phase, cfg.sprite_rotate_speed = current - now*next_speed, next_speed
end

--- Helper: done_hint
local function done_hint()
    return HintBtns.done({
        id           = "opt_done_button_hint",    T  = { x = 1.0, y = 1.02, w = 3.14, r = -0.1 },
        text_color   = ctl,                        label_max_w = 1,
    })
end

return {
    --- child widget base style
    style     = "stroked_page",                 widget_style  = "stroked_page",
    id        = "opt_cascade_mini_page",        T             = { x = 21, y = 6, w = 3.5, h = 0.2 },
    room_ref  = Y,

    --- color settings
    fill_color  = N,                            stroke_color  = tstroke,
    shadow      = Y,                            shadow_color  = { 0, 0, 0, 0.25 },
    shadow_parallax = { x = 0.5, y = -1.2 },

    --- region and seam
    seam_shader  = "_0_seam_feather",           seam_feather  = 5,
    page_colors  = { _zc, _zc, },               widget_dist   = 2,

    --- split with stroke settings
    split = {
        x  = 0.1,  y = 0,  r = 4.2,
        region = { axis = "vertical",              ox = -0.15, oy = -0.,  oy_base = "w", ["or"] = 0. },
        stroke = { stroke_key = "long_stroke_2",   ox = 0,     oy = 0.,   oy_base = "w", scale = 0.16 },
    },

    --- Decorators (of gear)
    child_widgets = {
        {   --- basic settings
            style    = "sprite_in_page",        id = "opt_cascade_gear_icon",
            quad_key = "gear",                  T  = { x = 19.1, y = 1.7, w = 1.35 },
            room_ref = Y,                       sprite_scale = 1,
            sprite_rotate_speed = 0.2,          shadow       = N,

            --- description
            key = "iam_done",                   description_key = "iam_done",

            --- hit settings
            button         = Y,                 hook_fn        = "open_system_settings_confirm",
            gamepad_focus  = N,                 can_collide    = Y,
            can_click      = Y,                 hover_hook_fn  = reverse_gear_rotation,
            can_hover      = Y,                 hover_jitter   = { amount = 0.12, rot = 0.06 },

            ---+++++++++++++ actual meaningful background +++++++++++++
            bg = { 
                renderer    = "paint_rect",     T = { x = -3, y = -0.2, w = .62, h = .25, r = _rot_gear },
                fill_color  = ck,                
                
                --- shadow setting
                shadow_color = cdisk_shadow,    shadow_parallax = { x = 1, y = -0.1 },
                
                --- shader settings
                paint = { shader = "_1_watercolor_edge", seed = 40, wobble = 0.8, bleed = 1, feather_px = 1, widget_dist = 2. },
            },

            --- runtime child hint
            runtime_child_widgets = { done_hint() },
        },
    },
}
