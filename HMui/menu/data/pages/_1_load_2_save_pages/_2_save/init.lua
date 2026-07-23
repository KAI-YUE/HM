local C, CUtils     = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local mini_page     = require("HMui.menu.data.pages._1_load_2_save_pages._2_save.mini_page")
local saving_slots  = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.presets.saving_slots")
local SeedLists     = require("HMui.menu.data.pages._1_load_2_save_pages._shared.sampling_seed_lists")
local Anims         = require("HMui.menu.data.pages._1_load_2_save_pages._2_save.anims")
local HintBtns      = require("HMui.menu.data.pages._shared.hint_btns")

local tint_alpha    = CUtils.tint_with_alpha

local ccrm, csteel  = C.CREAM, C.STEEL
local tstroke       = tint_alpha(ccrm, 0.93)
local tcrm, tsteel  = tint_alpha(ccrm, 0.4), tint_alpha(csteel, 0.9)
local ctl           = C.UI.TEXT_LIGHT

local Y, N = true, false

--- Helper: back_hint
local function back_hint()
    return HintBtns.back({
        id = "save_back_button_hint",
        hook_fn = "save2pause_menu",
    })
end

--- Helper: save_menu_page
local function save_menu_page(gm)
    return {
        --- child widget base style
        style = "stroked_page",                     widget_style = "stroked_page",

        --- Renderer & Sprite
        scroll_target_id = "save_slot_list",
        hit_area = "world",

        --- color settings
        fill_color = N,                             stroke_color = tstroke,
        shadow = Y,                                 shadow_color = { 0, 0, 0, 0.25 },

        --- region and seam
        seam_shader = "_0_seam_feather",            seam_feather = 5,
        page_colors = { tsteel,  tcrm,  },          widget_dist = 2,

        ------------------------------------------
        --- hover description text
        --- basic settings
        i18n_type             = "menu",             text             = "",
        text_color            = ctl,                text_scale       = 0.62,
        text_shadow           = N,

        --- text revealing
        text_wrap             = Y,                  text_reveal      = Y,
        text_reveal_rate      = 45,                 hover_dwell_desc = 1,

        --- text box settings
        text_padding          = { x = .0, y = .0 },     text_box_T    = { x = -2.3, y = 7.8, w = 7, h = 3.35 },
        text_line_spacing     = 1.14,                   text_align    = { x = "middle", y = "top" },
        text_maxw             = 6.,                     text_offset   = { x = 0, y = 0 },
       
        ----------------------------------------
        --- split with stroke settings
        split = {
            x = 0., r  = 4.4,
            region = { axis = "vertical",          ox = 0.28,   oy = 0.6, oy_base = "w", ["or"] = -0.01 },
            stroke = { stroke_key = "h-stroke-1",  ox = 0.25,  oy = 0.55,  oy_base = "w", scale = 0.1 },
        },

        --- Textfx
        card_textfx = {
            { key    = "back",                     text = "Back",                  description_key = "load_back", room_ref = Y,
              x      = 0.19,       y = 0.78,       text_align = { x = "center", y = "middle" },
              sampling_seed_list = SeedLists.back,
              r      = -0.33,
              shadow = Y,          button = Y,     gamepad_focus = N,               hook_fn = "save2pause_menu",
              text_hint = { color = tstroke, stroke_y = 0.78, h = 0.16 }, text_hint_show_when = "pointer",
              runtime_child_widgets = { back_hint() },
            },
        },

        child_widgets = saving_slots.child_widgets(gm),

        attached_panel = mini_page,
        switch_anim    = { enter = Anims.enter },
    }
end

return save_menu_page
