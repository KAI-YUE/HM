local C         = require("HMfns.animate.color.color_const")
local CUtils    = require("HMfns.animate.color.color_utils")
local TextFit   = require("HMfns.utils.format.text_fit")
local Tabs      = require("HMui.menu.data.pages._3_opt_menu_page.tabs")
local TabTitle  = require("HMEng.ui_actors.card_textfx.presets.tab_title")
local SeedLists = require("HMui.menu.data.pages._3_opt_menu_page.sampling_seed_lists")

local tint_alpha = CUtils.tint_with_alpha

local ck            = C.BLACK
local ccrm          = C.CREAM
local ctl           = C.UI.TEXT_LIGHT

local tstroke       = tint_alpha(ccrm, 0.93)
local cdisk_shadow  = { 0, 0, 0, 0.22 }
local _zc           = { 0, 0, 0, 0 }

local Y, N = true, false

--- Helper: opt_tab_textfx | opt_tab_textfx_list
local function opt_tab_textfx(tab, i)      return TabTitle.textfx(tab, { selected = (i == 1), gamepad_focus = N, sampling_seed_list = SeedLists.tabs[tab.key] }) end
local function opt_tab_textfx_list(state)  local list = {}; for i, tab in ipairs(Tabs.layout_tabs(state)) do list[i] = opt_tab_textfx(tab, i) end; return list end

--- Helper: desc_fit
local function desc_fit(text) return TextFit.layout(text, { text_scale = 0.62, min_w = 5.8, max_w = 8.1, char_w_factor = 0.28 }) end
local desc_layout = desc_fit("Passe die Steuerungseinstellungen an.")

local M = {
    --- child widget base style
    style = "stroked_page",                     widget_style = "stroked_page",
    id = "opt_menu_mini_page",                  T = { x = 4, y = 0.5, w = 15, h = 2 },

    --- Renderer & Sprite
    quad_key = "h-stroke-3",                    draw_order = "card_textfx_shadow_first",

    --- color settings
    fill_color = N,                             stroke_color = tstroke,
    shadow     = Y,                             shadow_color = { 0, 0, 0, 0.25 },

    --- region and seam
    seam_shader = N,                            seam_feather = 5,
    page_colors = { _zc, _zc, },                widget_dist  = 2,

    ------------------------------------------
    --- hover description text
    --- basic settings
    text_color            = ctl,                text_scale    = desc_layout.text_scale,
    text_shadow           = N,

    --- text revealing
    text_wrap             = N,                  text_reveal   = Y,
    text_reveal_rate      = 45,                 hover_dwell_desc = .6,

    --- text box settings
    text_padding          = { x = 0, y = 0 },   text_box_T    = { x = .4, y = -0.55, w = desc_layout.w, h = 3.35 },
    text_line_spacing     = 1.14,               text_align    = { x = "left", y = "top" },
    text_maxw             = desc_layout.w,      text_offset   = { x = 0, y = 0 },

    ----------------------------------------
    --- split with stroke settings
    split = {
        x = 0.,    y = 1,     r = -0.1,
        region = { axis = "vertical",           ox = 0,  oy = 0,   oy_base = "w", ["or"] = 0. },
        stroke = { stroke_key = "h-stroke-3",   ox = 0,  oy = 0,   oy_base = "w", scale = 0.12 },
    },

    --- Decorators
    child_widgets = {
        {
            style = "hid_hint",                id = "opt_tabs_bumper_hint",
            T = { x = 1.0, y = 1.34, w = 3.1, h = 0.52 },
            hid_action = "controller",         label = "LB / RB",
            quad_key = "btn_mask",             button_w = 0.42, label_w = 2.2,
        },
        {
            style = "hid_hint",                id = "opt_done_button_hint",
            T = { x = 16.75, y = 1.34, w = 3.0, h = 0.52 },
            hid_action = "controller",         label = "Options Done",
            quad_key = "btn_mask",             button_w = 0.42, label_w = 2.2,
        },
        {   --- basics 
            style    = "sprite_in_page",        id = "save_disk_icon",    
            quad_key = "gear",                  T  = { x = 19.6, y = .8, w = 1.35 },
            room_ref = Y,                       sprite_scale = 1, 
            sprite_rotate_speed = 0.2,          shadow    = N, 

            --- description
            key = "iam_done",                   description_key = "iam_done",

            --- hit settings
            button      = Y,                    hook_fn = "open_system_settings_confirm", 
            gamepad_focus = N,
            can_click   = Y,                    hover_hook_fn = reverse_save_disk_rotation,
            can_hover   = Y,                    hover_jitter = { amount = 0.12, rot = 0.06 },
            can_collide = Y,                
            
            bg = { renderer = "paint_rect",     T = { x = -3, y = -0.2, w = .62, h = .25, r = -0.2 },
                fill_color  = ck,               shadow_color = cdisk_shadow,
                paint = { shader = "_1_watercolor_edge", seed = 40, wobble = 0.8, bleed = 1, feather_px = 1, widget_dist = 2. },
            },
        },
    },

    build_card_textfx = opt_tab_textfx_list,
    card_textfx = opt_tab_textfx_list(),
}

return M
