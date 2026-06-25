local C      = require("HMfns.animate.color.color_const")
local CUtils = require("HMfns.animate.color.color_utils")
local SamplingSeedLists = require("HMui.menu.data.pages._0_pause_menu_page.sampling_seed_lists")

local tint_alpha = CUtils.tint_with_alpha

local ccrm, csteel = C.CREAM, C.STEEL
local tstroke      = tint_alpha(ccrm, 0.93)
local tcrm, tsteel = tint_alpha(ccrm, 0.4), tint_alpha(csteel, 0.9)
local ctl, ctd     = C.UI.TEXT_LIGHT,       C.UI.TEXT_DARK

local PI    = math.pi
local Y, N  = true, false

--- Helper: pause_menu_textfx
local function pause_menu_textfx(key, x, y, hook_fn)
    return {
        key       = key,             text_i18n_key = key,      room_ref   = Y,
        x         = x,               y      = y,               sampling_seed_list = SamplingSeedLists[key],
        
        --- hit settings
        shadow    = Y,               button = Y,               hook_fn    = hook_fn,
        paint_bg  = Y,

        --- text settings
        text_align = { x = "center", y = "middle" },
        text_hint  = { stroke_key = "profile_stroke_2", color = tstroke, stroke_y = 0.78, h = 0.16 },
    }
end

return {
    --- child widget base style
    style = "stroked_page",                 widget_style = "stroked_page",
    switch_textfx_ordered_reveal = Y,

    --- Renderer & Sprite
    quad_key = "h-stroke-2",

    --- color settings 
    fill_color = N,                         stroke_color = tstroke,
    shadow = Y,                             shadow_color = { 0, 0, 0, 0.25 },

    --- region and seam 
    seam_shader = "_0_seam_feather",        seam_feather = 5,
    page_colors = { tsteel,  tcrm,  },      widget_dist = 3, 

    ------------------------------------------
    --- hover description text
    --- basic settings
    i18n_type             = "menu",         text          = "",
    text_color            = ctl,            text_scale    = 0.62,
    text_shadow           = N, 

    --- text revealing
    text_wrap             = Y,              text_reveal   = Y,
    text_reveal_rate      = 45,             hover_dwell_desc = .6,
    
    --- text box settings
    text_padding  = { x = .0, y = .0 },     text_box_T    = { x = -2, y = 1.25, w = 7.5, h = 3.35 },
    text_line_spacing     = 1.14,           text_align    = { x = "left", y = "top" },
    text_maxw             = 7.5,            text_offset   = { x = 0, y = 0 },
    
    ----------------------------------------
    --- split with stroke settings
    split = {
        r = 4.9,          
        region = { axis = "vertical",         ox = 0.21, oy = 0.55, oy_base = "w", ["or"] = -0.01 },
        stroke = { stroke_key = "h-stroke-2", ox = 0.2,  oy = 0.55, oy_base = "w", scale = 0.1,  },
    },

    card_textfx = {
        pause_menu_textfx("continue",     0.5,  0.08, "close_menu"),
        pause_menu_textfx("load",         0.4,  0.26, "pause2load_menu"),
        pause_menu_textfx("save",         0.4,  0.44, "pause2save_menu"),
        pause_menu_textfx("options",      0.42, 0.62, "pause2options_menu"),
        pause_menu_textfx("return_title", 0.37, 0.8,  "return_title"),
    },

}
