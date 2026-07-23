local I18N        = require("HMfns.utils.format.i18n_utils")
local DashedBtn   = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.dashed_btn")

local i18n        = I18N.i18n

local Y, N = true, false

local M = {}

local _btn_x,  _btn_y  = 3, 6.3
local _btn_w,  _btn_h  = 2, 0.15
local _btn_gap         = 1.2

--- Helper: menu_item_text | sab_lang
local function menu_item_text(gm, key, fallback)  local text = i18n(gm, { type = "menu", key = "items." .. key }); return text or fallback end
local function sab_lang(gm)                       return { key = "sab", font_type = "SAB", font = gm and gm.g_fonts and gm.g_fonts.SAB } end

--- Helper: title_icon_btn
local function title_icon_btn(key, text, y, hook_fn, args)
    args = args or {}
    return DashedBtn.build({
        --- basics
        id        = key,                                    T = { x = _btn_x, y = y, w = _btn_w, h = _btn_h },
        room_ref  = Y,

        --- label & icon
        label  = text,                                      icon_quad_key  = args.icon_quad_key or "log",

        --- hit settings
        hit_scale   = { x = 2.4, y = 7 },                   hit_offset  = { x = 1.5, y = 0.6 },
        active      = args.active ~= N,                     hook_fn     = hook_fn,
        widget_dist = args.widget_dist or 0.5, 

        --- sprite settings
        bg_w       = _btn_w,                                icon_x   = 0.20,
        icon_y     = 0.13,                                  icon_w   = 0.46,
        -- dot_x      = 0.78,                               -- dot_y    = 0.31,
        -- dot_count  = 5,                                  -- dot_gap  = 0.08,

        --- label settings
        label_x           = 1.24,                           label_y      = 0.12,
        label_w           = 0.92,                           label_h      = 0.38,
        label_text_scale  = 0.60,                           label_lang   = args.label_lang,
        bg_sprite_color   = args.bg_sprite_color,            bg_shadow    = args.bg_shadow,
        bg_shadow_color   = args.bg_shadow_color,            paint_seed_entry = args.paint_seed_entry,
    })
end

----------------------------------------
--- title_menu_widgets
----------------------------------------
function M.title_menu_widgets(gm)
    local Fs = gm.Fs 
    local can_continue = Fs.title_page_can_continue(gm)
    local label_lang = sab_lang(gm)
    return {
        title_icon_btn("new_game", menu_item_text(gm, "new_game", "New Game"), _btn_y, "title_page_new_game", { label_lang = label_lang }),
        title_icon_btn("continue", menu_item_text(gm, "continue", "Continue"), _btn_y + _btn_gap, can_continue and "title_page_continue", { active = can_continue, label_lang = label_lang }),
        title_icon_btn("options",  menu_item_text(gm, "options", "Options"),   _btn_y + 2*_btn_gap, "title_page_options", { label_lang = label_lang }),
        title_icon_btn("quit",     menu_item_text(gm, "quit", "Quit"),         _btn_y + 3*_btn_gap +0.05, "title_page_quit", { label_lang = label_lang }),
    }
end

return M

----------------------------------
--- deprecated (for sprite-based btns)
-- local _btn_w, _btn_h  = 6, 0.6
-- local _btn_gap        = 1.5
