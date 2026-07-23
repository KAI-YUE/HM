local Tabs           = require("HMui.menu.data.pages._3_opt_menu_page.tabs")
local TabTitle       = require("HMEng.ui_actors.card_textfx.presets.tab_title")
local C, CUtils      = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local TextFit        = require("HMfns.utils.format.text_fit")
local SeedLists      = require("HMui.menu.data.pages._3_opt_menu_page.sampling_seed_lists")
local HintBtns       = require("HMui.menu.data.pages._shared.hint_btns")
local ConsoleLabels  = require("HMEng.controller.hid.gamepad.console_labels")

local tint_alpha     = CUtils.tint_with_alpha
local _bumper        = HintBtns.bumper

--- color short hands
local _zc            = { 0, 0, 0, 0 }     
local ccrm, ctl      = C.CREAM, C.UI.TEXT_LIGHT
local tstroke        = tint_alpha(ccrm, 0.93)
local tyellow        = { 1, 0.92, 0.05, 0.84 }

local lb_x,   rb_x   = -2,     15.5  --- x in relative pos
local lb_y,   rb_y   = 1.5,    -0.4
local lb_r,   rb_r   = -0.1,  -0.1
local info_T         = { x = -4.5, y = .7, w = 2.8, h = 0.52, r = 0. }
local label_offset   = { es_419 = -0.55, es_ES = -0.55, ko = -0.3, pt_BR = -0.55 }

local Y,    N        = true, false

-----------------------------
--- helpers
-----------------------------
--- Helper: fixed info hint | opt_tab_textfx | opt_tab_textfx_list | desc_fit
local function fixed_info_hint()               return HintBtns.info({ id = "opt_tab_info_hint", T = info_T, label_x_offset_by_lang = label_offset, button = Y, can_click = N, can_hover = N, can_collide = N, page_draw_layer = "overlay" }); end
local function opt_tab_textfx(tab, i, gm)      return TabTitle.textfx(tab, { selected = (i == 1), gamepad_focus = N, sampling_seed_list = SeedLists.tabs[tab.key], paint_seed_entry = SeedLists.tab_paint_seed_entries[tab.key] });   end
local function opt_tab_textfx_list(state, gm)  local list = {}; for i, tab in ipairs(Tabs.layout_tabs(state)) do list[i] = opt_tab_textfx(tab, i, gm) end; return list end
local function desc_fit(text)                  return TextFit.layout(text, { text_scale = 0.62, min_w = 5.8, max_w = 8.1, char_w_factor = 0.28 }) end

local desc_layout = desc_fit("Passe die Steuerungseinstellungen an.")

local M = {
    --- child widget base style
    style         = "stroked_page",                                T   = { x = 4, y = 0.5, w = 15, h = 2 },
    widget_style  = "stroked_page",                                id  = "opt_menu_mini_page",

    --- Renderer & Sprite
    draw_order  = "card_textfx_shadow_first",

    --- color settings
    fill_color  = N,                                               stroke_color  = tstroke,
    shadow      = Y,                                               shadow_color  = { 0, 0, 0, 0.25 },

    --- region and seam
    seam_shader  = N,                                              seam_feather  = 5,
    page_colors  = { _zc, _zc, },                                  widget_dist   = 2,

    ------------------------------------------
    --- hover description text
    --- basic settings
    text_color            = ctl,                                   text_scale    = desc_layout.text_scale,
    text_shadow           = N,

    --- text revealing
    text_wrap             = N,                                     text_reveal       = Y,
    text_reveal_rate      = 45,                                    hover_dwell_desc  = .6,

    --- text box settings
    text_padding          = { x = 0, y = 0 },                      text_box_T    = { x = .4, y = -0.55, w = desc_layout.w, h = 3.35 },
    text_line_spacing     = 1.14,                                  text_align    = { x = "left", y = "top" },
    text_maxw             = desc_layout.w,                         text_offset   = { x = 0, y = 0 },

    ----------------------------------------
    --- split with stroke settings
    split = {
        x = 0.,    y = 1,     r = -0.1,
        region = { axis        = "vertical",     ox = 0,  oy = 0,   oy_base = "w", ["or"] = 0. },
        stroke = { stroke_key  = "h-stroke-3",   ox = 0,  oy = 0,   oy_base = "w", scale = 0.12 },
    },

    --- Decorators of hint_btns
    child_widgets = {
        fixed_info_hint(),
        {   --- basics
            style  = "empty_container",                            T = { x = 0, y = 0, w = 15, h = 2 },
            id     = "tab_shoulders",  

            --- hit settings
            can_hover = N,                                         can_collide = N,

            --- Two hint_btns of bumpers 
            child_widgets = {
                _bumper({ id = "opt_tabs_prev_hint", T = { x = lb_x, y = lb_y, w = 2.1, h = 0.52, r = lb_r }, icon = "lb_btn", labels = ConsoleLabels.bumper.left,  hid_action = "scope_field", step = -1, page_draw_layer = N }),
                _bumper({ id = "opt_tabs_next_hint", T = { x = rb_x, y = rb_y, w = 2.1, h = 0.52, r = rb_r }, icon = "rb_btn", labels = ConsoleLabels.bumper.right, hid_action = "scope_hand",  step = 1,  page_draw_layer = N }),
            },
        },
    },

    build_card_textfx          = opt_tab_textfx_list,
    card_textfx                = opt_tab_textfx_list(),
}

return M
