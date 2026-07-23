local C      = require("HMfns.animate.color.color_const")
local CUtils = require("HMfns.animate.color.color_utils")
local SeedLists = require("HMui.menu.data.pages._1_load_2_save_pages._shared.sampling_seed_lists")

local tint_alpha = CUtils.tint_with_alpha

local ck = C.BLACK
local ccrm, csteel  = C.CREAM, C.STEEL
local tstroke       = tint_alpha(ccrm, 0.93)
local tcrm, tsteel  = tint_alpha(ccrm, 0.4), tint_alpha(csteel, 0.9)
local cdisk_shadow  = { 0, 0, 0, 0.22 }
local _zc           = { 0, 0, 0, 0 }

local Y, N = true, false

--- Helper: reverse_save_disk_rotation
local function reverse_save_disk_rotation(gm, source)
    local cfg = source and source.config;        if not cfg then return end
    local now = gm._T.real_s or 0
    local speed = cfg.sprite_rotate_speed or 0.8
    local phase = cfg.sprite_rotate_phase or 0
    local current = phase + now * speed
    local next_speed = -speed * (cfg.reverse_slowdown or 0.45)

    if math.abs(next_speed) < 0.08 then next_speed = speed < 0 and 0.18 or -0.18 end
    cfg.sprite_rotate_phase, cfg.sprite_rotate_speed = current - now * next_speed, next_speed
end

return {
    --- child widget base style
    style = "stroked_page",                     widget_style = "stroked_page",
    id = "save_menu_mini_page",                 T = { x = 21, y = 4.5, w = 3.5, h = 0.2 },

    --- color settings
    fill_color = N,                             stroke_color = tstroke,
    shadow = Y,                                 shadow_color = { 0, 0, 0, 0.25 },

    --- region and seam
    seam_shader = "_0_seam_feather",            seam_feather = 5,
    page_colors = {  _zc,  tsteel, },           widget_dist = 2,

    --- split with stroke settings
    split = {
        x  = 0.1,  y = 0,  r  = 4,
        region = { axis        = "vertical",    ox = -0.6, oy = -0.8, oy_base = "w", ["or"] = 0. },
        stroke = {  stroke_key = "h-stroke-3",  ox  = 0,   oy = 0.,   oy_base = "w", scale = 0.08 },
    },

    --- Decorators 
    child_widgets = {
        {   --- basic settings
            style = "sprite_in_page",       T = { x = 19.5, y = 2.2, w = 1.35 },
            id = "save_disk_icon",          quad_key = "disk",
            room_ref = Y,  

            --- description 
            key = "iam_done",       description_key = "iam_done",

            --- hit settings
            button = Y,                     can_click = Y, 
            can_hover = Y,                  hook_fn = "quick_resume_menu", 
            can_collide = Y,                hover_hook_fn = reverse_save_disk_rotation,

            --- sprite settings
            shadow = N,                sprite_scale = 1,        sprite_rotate_speed = 0.8,
            no_press_squash = Y,
            hover_jitter = { amount = 0.12, rot = 0.06 },
            
            --- background settings
            bg = { 
                renderer = "paint_rect",   T = { x = -3, y = -0.2, w = .62, h = .25, r = 0.1 },
                fill_color = ck,           shadow_color = cdisk_shadow,
                paint = { shader = "_1_watercolor_edge", seed = 40, wobble = 0.8, bleed = 1, feather_px = 1, widget_dist = 2.55 },
            },
        },
    },

    card_textfx = {
        { text    = "Saving",  room_ref = Y,    textfx_static = Y, 
          x      = 0.87,       y = 0.01,        text_align = { x = "center", y = "middle" }, 
          sampling_seed_list = SeedLists.save_mini_title,
          r      = 0.1,      
          shadow = Y,          button = N,      hook_fn = "save2pause_menu",
          text_hint = { color = tstroke, stroke_y = 0.78, h = 0.16 },
        },
    },
}
