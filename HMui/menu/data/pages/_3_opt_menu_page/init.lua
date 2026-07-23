local C, CUtils     = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local TabUtils      = require("HMfns.utils.table_utils")
local HintBtns      = require("HMui.menu.data.pages._shared.hint_btns")

local _pages_dir    = "HMui.menu.data.pages._3_opt_menu_page."
local Tabs          = require(_pages_dir .. "tabs")
local Anims         = require(_pages_dir .. "anims")
local MiniPages     = require(_pages_dir .. "mini_pages")
local SeedLists     = require(_pages_dir .. "sampling_seed_lists")

local copy          = TabUtils.deep_copy
local tint_alpha    = CUtils.tint_with_alpha

local CUI = C.UI
local ccrm, csteel  = C.CREAM, C.STEEL
local tstroke       = tint_alpha(ccrm, 0.93)
local tcrm, tsteel  = tint_alpha(ccrm, 0.4), tint_alpha(csteel, 0.9)
local ctl           = CUI.TEXT_LIGHT

local Y, N = true, false

--------------------------------------------------------------------------
--- mini_pages' regions (polygons) are controlled by the main page
--------------------------------------------------------------------------
local page_region_polygons = {
    {   color = tsteel, room_ref = Y, fade_start_key = "polygon",
        -- enter_points = { { x = 0.00, y = -2.72 }, { x = 21.7, y = -3.35 }, { x = 21.7, y = -3.10 }, { x = 19.75, y = -3.65 }, { x = 3.7, y = -2.72 } },
        
        points       = { { x = 2.00, y = -0.7 }, { x = 21.7, y = -0.75 }, { x = 21.7, y = 6 }, { x = 18.5, y = 1.2 },  { x = 3.7, y = 3 }  },
        paint        = { shader = "_0_polygon_edge_feather", feather_px = 5 },
    },
}

local page = {
    --- child widget base style
    style = "stroked_page",                         widget_style = "stroked_page",
    switch_textfx_ordered_reveal = Y,       

    --- color settings
    fill_color  = N,                                stroke_color  = tstroke,
    shadow      = Y,                                shadow_color  = { 0, 0, 0, 0.25 },

    --- region and seam
    seam_shader  = "_0_seam_feather",               seam_feather  = 5,
    page_colors  = { tsteel,  tcrm,  },             widget_dist   = 2,

    --- split with stroke settings
    split = {
        r  = 4.4,
        region = { axis = "vertical",               ox = 0.28,  oy = 0.6,  oy_base = "w", ["or"] = -0.01 },
        stroke = { stroke_key = "h-stroke-2",       ox = 0.25,  oy = 0.55, oy_base = "w", scale = 0.1 },
    },

    ------------------------------------------
    --- hover description text
    --- basic settings
    i18n_type             = "menu",                 text          = "",
    text_color            = ctl,                    text_scale    = 0.62,
    text_shadow           = N,

    --- text revealing
    text_wrap             = Y,                      text_reveal   = Y,
    text_reveal_rate      = 45,                     hover_dwell_desc = 1,

    --- text box settings
    text_padding          = { x = .0, y = .0 },     text_box_T    = { x = -2.6, y = 7, w = 7, h = 3.35 },
    text_line_spacing     = 1.14,                   text_align    = { x = "middle", y = "top" },
    text_maxw             = 6.,                     text_offset   = { x = 0, y = 0 },

    ----------------------------------------
    card_textfx = {
        { --- text settings
            key = "back",                           text = "Back",
            description_key = "load_back",          room_ref       = Y,
            
        --- text pos and alignment
            x = 0.19,                               y           = 0.78,         
            r = -0.33,                              shadow      = Y,       
            sampling_seed_list = SeedLists.back,    text_align  = { x = "center", y = "middle" },

        --- hit settings
            button     = Y,                         can_hover      = Y,        
            can_click  = Y,                         gamepad_focus  = N,  
            hook_fn    = "options2pause_menu",      text_hint      = { color = tstroke, stroke_y = 0.78, h = 0.16 },
            text_hint_show_when = "pointer",

            runtime_child_widgets = {
                HintBtns.back({
                    id                 = "opt_back_button_hint",
                    hook_fn            = "options2pause_menu",
                }),
            },
        },
    },
    child_control_lock_delay = 2,

    --- mini_page and switch animate
    attached_panel = MiniPages.root,                switch_anim    = { enter = Anims.enter },
}

--- Helper: _remembered_tab_state
local function _remembered_tab_state(gm)
    if not gm then return Tabs.default_state() end

    gm.opt_menu_tab_state = gm.opt_menu_tab_state or Tabs.default_state()
    return gm.opt_menu_tab_state
end

--- Helper: _page_for_tab_state
local function _page_for_tab_state(gm, opts)
    local state, out = _remembered_tab_state(gm), copy(page)
    local back, back_hook = out.card_textfx and out.card_textfx[1], opts and opts.back_hook

    if back and back_hook then
        back.hook_fn = back_hook
        for _, hint in ipairs(back.runtime_child_widgets or {}) do hint.hook_fn = back_hook; if hint.style then hint.style.hook_fn = back_hook end end
    end

    out.page_region_polygons       = copy(page_region_polygons)
    out.child_widgets              = Tabs.selected_child_widgets(state, gm)
    out.child_control_lock_delay   = Tabs.child_control_lock_delay(out.child_widgets)
    out.attached_panel             = copy(MiniPages.root)

    for _, child in ipairs(out.attached_panel.child_widgets or {}) do
        if child.id == "opt_menu_mini_page" then
            child.card_textfx = MiniPages.tab_header.build_card_textfx(state, gm)
        end
    end
    return out
end

return _page_for_tab_state
