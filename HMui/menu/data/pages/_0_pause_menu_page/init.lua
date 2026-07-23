local HintBtns           = require("HMui.menu.data.pages._shared.hint_btns")
local C,      CUtils     = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local SamplingSeedLists  = require("HMui.menu.data.pages._0_pause_menu_page.sampling_seed_lists")

local tint_alpha         = CUtils.tint_with_alpha

local CUI                = C.UI
local ccrm,    csteel    = C.CREAM,               C.STEEL
local tstroke            = tint_alpha(ccrm, 0.93)
local tcrm,    tsteel    = tint_alpha(ccrm, 0.4), tint_alpha(csteel, 0.9)
local ctl,     ctd       = CUI.TEXT_LIGHT,        CUI.TEXT_DARK

local PI    = math.pi
local Y, N  = true, false

local pause_confirm_hint_T        = { x = 0,    y = 0,    w = 2.7, h = 0.6 }
local pause_confirm_hint_offset   = { x = -0.4, y = -0.2 }
local pause_confirm_hint_label_T  = { x = 0.9,  y = 0.,  w = 2.2, h = 0.52, r = 0 }

------------------------------------------
--- Helper: pause textfx confirm hint
------------------------------------------
local function pause_textfx_confirm_hint(key)
    return HintBtns.confirm({
        --- basics 
        id       = "pause_" .. key .. "_confirm_hint",    T = pause_confirm_hint_T,
        label_T  = pause_confirm_hint_label_T,
        label_textfx = Y,
        label_textfx_widget_dist = 1,
        
        --- draw settings
        show_when_parent  = "active",                     parent_cut_in_sync = Y, 
        page_draw_layer   = N,
        
        --- hit settings
        parent_press_squash  = Y,                         button         = N, 
        can_click            = N,                         can_hover      = N, 
        can_collide          = N,                         gamepad_focus  = N,
    })
end

--- Helper: pause_menu_textfx
local function pause_menu_textfx(key, x, y, hook_fn, text)
    return {
        --- basics 
        key       = key,                                  text                = text,
        text_i18n_key = not text and key or nil,
        x         = x,                                    y                   = y,               
        room_ref  = Y,                                    sampling_seed_list  = SamplingSeedLists[key],
        
        --- hit settings
        shadow    = Y,                      button   = Y,               
        paint_bg  = Y,                      hook_fn  = hook_fn,

        --- text settings
        text_align  = { x = "center", y = "middle" },
        text_hint   = { color = tstroke, stroke_y = 0.78, h = 0.16 },
        runtime_child_widgets = { pause_textfx_confirm_hint(key) },
        runtime_child_align = { x = "right", y = "bottom", r = "dominant", anchor = { x = 0, y = 0 }, offset = pause_confirm_hint_offset },
    }
end

return {
    --- child widget base style
    style = "stroked_page",                 widget_style  = "stroked_page",
    switch_textfx_ordered_reveal = Y,

    --- color settings 
    fill_color  = N,                        stroke_color  = tstroke,
    shadow      = Y,                        shadow_color  = { 0, 0, 0, 0.25 },

    --- region and seam 
    seam_shader  = "_0_seam_feather",        seam_feather  = 5,
    page_colors  = { tsteel,  tcrm,  },      widget_dist   = 3, 

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
        pause_menu_textfx("load",         0.4,  0.26, "pause2load_menu", "Load"),
        pause_menu_textfx("save",         0.4,  0.44, "pause2save_menu", "Save"),
        pause_menu_textfx("options",      0.42, 0.62, "pause2options_menu"),
        pause_menu_textfx("return_title", 0.37, 0.8,  "return_title"),
    },

    -----------------------------
    --- page hint_btns
    -----------------------------
    child_widgets = {
        HintBtns.back({    id = "pause_cancel_hint",  T = { x = -1.98, y = 10, w = 3.2, h = 0.6 },  label_T = { x = 1, y = 0.2, w = 2.2, h = 0.52, r = 0 }, hook_fn = "close_menu", gamepad_focus = N, page_draw_layer = "overlay" }),
    },

}
