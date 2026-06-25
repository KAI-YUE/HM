local C, CUtils   = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local I18N        = require("HMfns.utils.format.i18n_utils")
local IconBtn     = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local PaintSeeds  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.paint_seeds")
local TabUtils    = require("HMfns.utils.table_utils")

local tint_alpha  = CUtils.tint_with_alpha
local rand_pick   = TabUtils.random_pick
local i18n        = I18N.i18n

local CUI         = C.UI
local ccrm,    ctd         = C.CREAM,                   CUI.TEXT_DARK
local corange, btn_shadow  = C.ORANGE,                  tint_alpha(C.BLACK, 0.30)
local cddim                = tint_alpha(ctd, 0.38)

local Y, N = true, false

local M = {}

local _btn_x,  _btn_y  = 3, 6.3
local _btn_w,  _btn_h  = 2, 0.15
local _btn_gap         = 1.2

--- Helper: menu_item_text | title_btn_paint_seed
local function menu_item_text(gm, key, fallback)  local text = i18n(gm, { type = "menu", key = "items." .. key }); return text or fallback end
local function title_btn_paint_seed(args)         return (args and args.paint_seed_entry) or rand_pick(PaintSeeds) end

--- Helper: title button paint config
local function title_btn_paint(seed_entry, args)
    seed_entry,  args  = seed_entry or {}, args or {}
    local widget_dist  = args.widget_dist or 1
    return {
        shader      = "_1_watercolor_edge",          seed         = seed_entry.seed,
        wobble      = seed_entry.wobble or 1,        bleed        = seed_entry.bleed or 1,
        feather_px  = seed_entry.feather_px or 1,    widget_dist  = widget_dist,
    }
end

--- Helper: title_icon_btn
local function title_icon_btn(key, text, y, hook_fn, args)
    args = args or {}
    local active            = (args.active ~= N)
    local dark              = (active and ctd) or cddim
    local paint_seed_entry  = title_btn_paint_seed(args)

    local btn = {
        --- basics
        id        = key,                                    T = { x = _btn_x, y = y, w = _btn_w, h = _btn_h },
        room_ref  = Y,

        --- label & icon
        label  = text,                                      icon_quad_key  = args.icon_quad_key or "log",

        --- hit settings
        hit_scale   = { x = 2.4, y = 7 },                   hit_offset  = { x = 1.5, y = 0.6 },
        button      = active,                               can_hover   = active,
        can_click   = active,                               hook_fn     = hook_fn,
        widget_dist = args.widget_dist or 0.5, 

        --- sprite settings
        bg_w       = _btn_w,                                icon_x   = 0.20,
        icon_y     = 0.13,                                  icon_w   = 0.46,
        -- dot_x      = 0.78,                               -- dot_y    = 0.31,
        -- dot_count  = 5,                                  -- dot_gap  = 0.08,

        --- label settings
        label_x           = 1.24,                           label_y      = 0.12,
        label_w           = 0.92,                           label_h      = 0.38,
        label_text_scale  = 0.60,                           label_color        = dark,
        label_hover_color = corange,

        --- color settings
        icon_tint        = ccrm,                            dot_tint        = ccrm,
        icon_hover_color = corange,                         dot_hover_color = corange,

        --- background style 
        bg_style   = "paint_rect",                          bg_sprite_color  = args.bg_sprite_color or ctd,
        bg_shadow  = args.bg_shadow ~= N,                   bg_shadow_color  = args.bg_shadow_color or btn_shadow,
        bg_paint = title_btn_paint(paint_seed_entry, args),
    }

    btn.style = IconBtn(btn)
    return btn
end

----------------------------------------
--- title_menu_widgets
----------------------------------------
function M.title_menu_widgets(gm)
    local Fs = gm.Fs 
    local can_continue = Fs.title_page_can_continue(gm)
    return {
        title_icon_btn("new_game", menu_item_text(gm, "new_game", "New Game"), _btn_y, "title_page_new_game"),
        title_icon_btn("continue", menu_item_text(gm, "continue", "Continue"), _btn_y + _btn_gap, can_continue and "title_page_continue", { active = can_continue }),
        title_icon_btn("options",  menu_item_text(gm, "options", "Options"), _btn_y + 2*_btn_gap, "title_page_options"),
        title_icon_btn("quit",     menu_item_text(gm, "quit", "Quit"),       _btn_y + 3*_btn_gap +0.05, "title_page_quit"),
    }
end

return M

----------------------------------
--- deprecated (for sprite-based btns)
-- local _btn_w, _btn_h  = 6, 0.6
-- local _btn_gap        = 1.5
