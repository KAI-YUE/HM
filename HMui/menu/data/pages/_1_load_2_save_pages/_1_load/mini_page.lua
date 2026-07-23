local C          = require("HMfns.animate.color.color_const")
local CUtils     = require("HMfns.animate.color.color_utils")
local SeedLists  = require("HMui.menu.data.pages._1_load_2_save_pages._shared.sampling_seed_lists")

local tint_alpha = CUtils.tint_with_alpha

local ck = C.BLACK
local ccrm, csteel  = C.CREAM, C.STEEL
local tstroke       = tint_alpha(ccrm, 0.93)
local tsteel        = tint_alpha(csteel, 0.9)
local cdisk_shadow  = { 0, 0, 0, 0.22 }
local _zc           = { 0, 0, 0, 0 }

local Y, N = true, false

--- Helper: roll_load_folder_param
local function roll_load_folder_param(_, source)
    local roll   = math.random()
    local value  = roll < 0.5 and -1 or 1
    if source and source.set_param then source:set_param("Param", value, -1, 1) end

    local move = source and source.anim_gust_move
    if move then move.value, move.velocity, move.shove = value, 0, 0 end
end

return {
    --- child widget base style
    style     = "stroked_page",                T = { x = 21, y = 4.5, w = 3.5, h = 0.2 }, 
    id        = "load_menu_mini_page",         widget_style = "stroked_page",

    --- color settings
    fill_color = N,                             stroke_color = tstroke,
    shadow     = Y,                             shadow_color = { 0, 0, 0, 0.25 },

    --- region and seam
    seam_shader = "_0_seam_feather",            seam_feather = 5,
    page_colors = {  _zc,  tsteel, },           widget_dist  = 2,

    --- split with stroke settings
    split = {
        x  = 0.1,  y = 0,  r  = 4,
        region = { axis        = "vertical",    ox = -0.6, oy = -0.8, oy_base = "w", ["or"] = 0. },
        stroke = {  stroke_key = "h-stroke-3",  ox  = 0,   oy = 0.,   oy_base = "w", scale = 0.08 },
    },

    --- Decorators
    child_widgets = {
        {   --- basic settings
            actor     = "anim_decorator",       id = "load_folder_icon",
            room_ref  = Y,                      T  = { x = 19.35, y = 2.2, w = 1.65, h = 1.65, r = 0.2 },

            --- description
            key = "iam_done",                   description_key = "iam_done",

            --- hit settings
            button      = Y,                    can_click  = Y,
            can_collide = Y,                    can_drag   = N,
            can_hover   = Y,
            hook_fn     = "quick_resume_menu",  hover_hook_fn = roll_load_folder_param,

            --- sprite settings
            model_def    = "resources/textures/ui/anim/folder/folder.model3.json",
            anim_gust    = { id = "Param", lo = -1, hi = 1, amp = 0.12, gust_amp = 0.82, offset = 0.18 },
            hover_jitter = { amount = 0.12, rot = 0.06 },

            --- background settings
            bg = {
                renderer = "paint_rect",          T = { x = -1.3, y = 0.2, w = .62, h = .25, r = 0.1 },
                fill_color = ck,                  shadow_color = cdisk_shadow,    
                paint = { shader = "_1_watercolor_edge", seed = 40, wobble = 0.8, bleed = 1, feather_px = 1, widget_dist = 2.55 },
            },
        },
    },

    card_textfx = {
        { text    = "Loading",                  room_ref = Y,                  textfx_static = Y,
          x      = 0.87,       y = 0.01,        text_align = { x = "center", y = "middle" },
          sampling_seed_list = SeedLists.load_mini_title,
          r      = 0.1,
          shadow = Y,          button = N,     hook_fn = "load2pause_menu",
          text_hint = { color = tstroke, stroke_y = 0.78, h = 0.16 },
        },
    },
}
