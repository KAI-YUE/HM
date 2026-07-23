local C        = require("HMfns.animate.color.color_const")
local I18N     = require("HMfns.utils.format.i18n_utils")
local IconBtn  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Suits    = require("HMGplay.cards.card_data.suits")
local Data     = require("HMui.menu.data.pages._4_deck_preview_page.preview_layout")

local i18n     = I18N.i18n

local Inf      = math.huge
local Y, N     = true, false

local M = { list_id = "deck_view_suit_list", slide_bar_id = "deck_view_suit_slide_bar", row_id_prefix = "deck_view_suit_" }

M.row_h, M.row_gap, M.visible_count = Data.body.row_h, Data.body.row_gap, Data.body.visible_count

--------------------------------------------------
--- suit rows
--------------------------------------------------
--- Helper: suit_label
local function suit_label(gm, suit)
    local fallback  = Suits.names[suit] or tostring(suit or "?")
    local text      = i18n(gm, { type = "ui", key = "deck_preview.suits." .. tostring(suit) })
    return text or fallback
end

--- Helper: suit label font type
local function suit_label_font_type(gm, cfg)
    local font_type = gm.selected_lang and gm.selected_lang.font_type
    return font_type and cfg.font_variant and font_type .. "_" .. cfg.font_variant
end

--- Helper: suit_tag
local function suit_tag(gm, suit)
    local cfg, key, fallback = Data.body.suit_tag, tostring(suit), Suits.names[suit] or tostring(suit or "?")
    local args = {
        --- basics 
        style  = "rbox",                                      id        = M.row_id_prefix .. key .. "_label",
        T      = cfg.T,                                       bg_style  = "rbox",
        
        --- bg setting
        bg_atlas_key     = "ui_pack",                         bg_quad_key  = "tag_paper",
        bg_w             = cfg.T.w,                           bg_shadow    = Y,
        bg_sprite_color  = C.CREAM,

        --- icon setting
        show_icon        = N,                                 show_dots    = N,

        --- label setting
        label             = suit_label(gm, suit),             label_T              = cfg.label_T,
        label_x           = cfg.label_T.x,                    label_y              = cfg.label_T.y,
        label_w           = cfg.label_T.w,                    label_h              = cfg.label_T.h,
        label_text_scale  = cfg.text_scale,                   label_color          = C.UI.TEXT_DARK,
        label_idle_color  = C.UI.TEXT_DARK,                   label_lang           = gm.selected_lang,
        label_font_type   = suit_label_font_type(gm, cfg),
        label_i18n_type   = "ui",                             label_i18n_scope     = "deck_preview.suits",
        label_i18n_key    = key,                              label_i18n_fallback  = fallback,
        label_align       = { x = "center", y = "middle" },   label_shadow         = N,

        --- hit setting
        button       = N,                                     can_hover  = N, 
        can_click    = N,                                     can_drag   = N,
        hover_arrow  = N,
    }
    args.style = IconBtn(args)
    return args
end

--- Helper: suit_row
local function suit_row(gm, suit, width)
    return {
        style  = "empty_container",                          T = { x = 0, y = 0, w = width, h = M.row_h },
        id     = M.row_id_prefix .. suit,
        
        --- child widgets 
        child_widgets = { suit_tag(gm, suit) },
    }
end

--- Helper: slide_bar
local function slide_bar(T)
    return {
        --- basics
        style     = "sprite_in_page",                         T          = T,
        id        = M.slide_bar_id,                           atlas_key  = "ui_pack", 
        quad_key  = "btn_mask",

        --- hit setting
        button    = N,                                        can_hover  = N, 
        can_click = N,                                        can_drag   = N,

        --- color setting
        shadow    = Y,                                        tint = C.CREAM, 
        sprite_color = C.CREAM,
    }
end

---________________________________
--- main: suits
---________________________________
function M.suits(cards)
    local present, out = {}, {}
    for _, card in ipairs(cards or {})    do present[tostring((card.base and card.base.suit) or "other")] = Y end
    for suit in pairs(present)            do out[#out + 1] = suit end

    table.sort(out, function(a, b)
        local ai, bi = Suits.sort_values[a] or Inf, Suits.sort_values[b] or Inf
        if ai ~= bi then return ai < bi end
        return a < b
    end)
    
    return out
end

---________________________________
--- main: build
---________________________________
function M.build(gm, suits)
    local RT,   cfg    = gm._room.T, Data.body
    local rows, width  = {},         RT.w - cfg.T.w_trim
    for idx, suit in ipairs(suits or {}) do rows[idx] = suit_row(gm, suit, width) end

    local bar, list_h  = cfg.slide_bar, M.visible_count*M.row_h + (M.visible_count - 1)*M.row_gap
    local can_scroll   = #rows > M.visible_count
    local x, y1, y2    = cfg.T.x + width + bar.x_pad, cfg.T.y + bar.y_pad, cfg.T.y + list_h - bar.y_pad
    
    local widgets = {
        {
            style  = "scrollable_continuous",                   T     = { x = cfg.T.x, y = cfg.T.y, w = width, h = list_h },
            id     = M.list_id,                                 axis  = "vertical",

            --- continuous scroll setting
            item_gap       = M.row_gap,                         scroll_step     = (M.row_h + M.row_gap)*cfg.scroll_step_ratio,
            scroll_speed   = cfg.scroll_speed,                  overscan        = 1,
            slide_bar_id   = can_scroll and M.slide_bar_id,     slide_bar_track = { x1 = x, y1 = y1, x2 = x, y2 = y2 },
            child_widgets  = rows,
        },
    }
    widgets[#widgets + 1] = slide_bar({ x = x, y = y1, w = bar.w, r = bar.r })
    return widgets
end

return M
