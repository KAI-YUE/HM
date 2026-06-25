local C, CUtils     = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local TabUtils      = require("HMfns.utils.table_utils")
local mini_page     = require("HMui.menu.data.pages._3_opt_menu_page.mini_page")
local Anims         = require("HMui.menu.data.pages._3_opt_menu_page.anims")
local Tabs          = require("HMui.menu.data.pages._3_opt_menu_page.tabs")
local SeedLists     = require("HMui.menu.data.pages._3_opt_menu_page.sampling_seed_lists")

local copy          = TabUtils.deep_copy
local tint_alpha    = CUtils.tint_with_alpha

local ccrm, csteel  = C.CREAM, C.STEEL
local tstroke       = tint_alpha(ccrm, 0.93)
local tcrm, tsteel  = tint_alpha(ccrm, 0.4), tint_alpha(csteel, 0.9)
local ctl           = C.UI.TEXT_LIGHT

local Y, N = true, false

local page_region_polygons = {
    { color   = tsteel,
      paint   = { shader = "_0_polygon_edge_feather", feather_px = 5 },
      points  = { { x = 0.04, y = -3 },  { x = 1.05, y = -3 }, { x = 1.05, y = 0.4 }, { x = 0.115, y = 3.8 } },
    },
}

--- Helper: _scaled_page_region_polygons
local function _scaled_page_region_polygons(scale_y)
    local out = copy(page_region_polygons)
    for _, polygon in ipairs(out) do for _, point in ipairs(polygon.points or polygon) do if type(point) == "table" then point.y = (point.y or point[2] or 0)*scale_y end end end
    return out
end

local title_page_region_polygons = _scaled_page_region_polygons((86*2506)/(2528*96))

local page = {
    --- child widget base style
    style = "stroked_page",                         widget_style = "stroked_page",
    quad_key = "h-stroke-3",                        switch_textfx_ordered_reveal = Y,       

    --- color settings
    fill_color  = N,                                stroke_color  = tstroke,
    shadow      = Y,                                shadow_color  = { 0, 0, 0, 0.25 },

    --- region and seam
    seam_shader  = "_0_seam_feather",               seam_feather  = 5,
    page_colors  = { tsteel,  tcrm,  },             widget_dist   = 2,
    page_region_polygons = page_region_polygons,

    --- split with stroke settings
    split = {
        r  = 4.4,
        region = { axis = "vertical",          ox = 0.28,  oy = 0.6,  oy_base = "w", ["or"] = -0.01 },
        stroke = { stroke_key = "h-stroke-2",  ox = 0.25,  oy = 0.55, oy_base = "w", scale = 0.1 },
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
        { --- i18n settings
            key = "back",                           text_i18n_key = "back",  
            description_key = "load_back",          room_ref = Y,
            
        --- text pos and alignment
            x = 0.19,            y = 0.78,          text_align = { x = "center", y = "middle" },
            r = -0.33,           shadow = Y,        sampling_seed_list = SeedLists.back,
        
        --- hit settings
            button = Y,          can_hover = Y,        can_click = Y,
            gamepad_focus = N,   hook_fn = "options2pause_menu",
            text_hint = { stroke_key = "profile_stroke_2", color = tstroke, stroke_y = 0.78, h = 0.16 },
        },
    },

    --- child_widgets and control lock 
    child_widgets = {
        {
            style = "hid_hint",                    id = "opt_back_button_hint",
            T = { x = 0.35, y = 1.42, w = 2.8, h = 0.52 },
            hid_action = "controller",             label = "B Back",
            quad_key = "btn_mask",                 button_w = 0.42, label_w = 1.9,
        },
    },                                             child_control_lock_delay = 2,

    --- mini_page and switch animate
    attached_panel = mini_page,                     switch_anim    = { enter = Anims.enter },
}

--- Helper: _remembered_tab_state
local function _remembered_tab_state(gm)
    if not gm then return Tabs.default_state() end
    gm.opt_menu_tab_state = gm.opt_menu_tab_state or Tabs.default_state()
    return gm.opt_menu_tab_state
end

--- Helper: _page_region_polygons
local function _page_region_polygons(opts) return opts and opts.region_polygons == "title" and title_page_region_polygons or page_region_polygons end

--- Helper: _page_for_tab_state
local function _page_for_tab_state(gm, opts)
    local state, out = _remembered_tab_state(gm), copy(page)
    out.page_region_polygons       = copy(_page_region_polygons(opts))
    out.child_widgets              = Tabs.selected_child_widgets(state, gm)
    out.child_control_lock_delay   = Tabs.child_control_lock_delay(out.child_widgets)
    out.attached_panel             = copy(mini_page)
    out.attached_panel.card_textfx = mini_page.build_card_textfx(state)
    return out
end

return _page_for_tab_state
