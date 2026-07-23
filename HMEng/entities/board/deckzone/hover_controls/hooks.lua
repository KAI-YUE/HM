local IconBtn     = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local C, CUtils   = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local PaintSeeds  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.paint_seeds")
local TabUtils    = require("HMfns.utils.table_utils")

local tint_alpha = CUtils.tint_with_alpha
local rand_pick  = TabUtils.random_pick

local CUI = C.UI
local ck  = C.BLACK
local ccrm, ctd   = C.CREAM, CUI.TEXT_DARK
local btn_shadow  = tint_alpha(ck, 0.30)

local Y, N = true, false

return function (DeckZone)
--------------------------------------------------
--- _hover_control_widgets
--------------------------------------------------
--- Helper: preview_deck
local function preview_deck(gm)
    local deck    = gm and gm.deck;        if not (deck and deck.view_deck) then return N end
    local opened  = deck:view_deck();      if opened then deck:close_hover_controls() end
    return opened
end

--- Helper: cancel_deck_preview
local function cancel_deck_preview(gm)
    local _deck = gm.deck;                 if not _deck then return N end 
    _deck:cancel_hover_controls(Y);        return Y
end

--- Helper: hover_button_paint_seed
local function hover_button_paint_seed(args) return (args and args.paint_seed_entry) or rand_pick(PaintSeeds); end

--- Helper: hover_button_paint_seed
local function hover_button_paint(seed_entry, args)
    args, seed_entry   =  args or {}, seed_entry or {}
    local widget_dist  = args.widget_dist or 1
    return {
        shader      = "_1_watercolor_edge",           seed         = seed_entry.seed,
        wobble      = seed_entry.wobble or 1,         bleed        = seed_entry.bleed or 1,
        feather_px  = seed_entry.feather_px or 1,     widget_dist  = widget_dist,
    }
end

--- Helper: hover_button
local function hover_button(id, label, x, y, icon_quad_key, hook_fn, args)
    local paint_seed_entry = hover_button_paint_seed(args)
    local btn = {
        --- basic settings
        id = id,                                     T = { x = x, y = y, w = args.button_w or 1.8, h = args.button_h or 0.42 },

        --- hover settings
        label      = label,                          icon_quad_key  = icon_quad_key,
        button     = Y,                              can_hover      = Y,
        can_click  = Y,                              hook_fn        = hook_fn,

        --- bg and icon
        bg_w      = args.button_w or 1.8,            bg_h    = args.button_h or 0.42,
        bg_style  = args.bg_style or "paint_rect",   icon_w  = args.icon_w or 0.28,
        icon_x    = args.icon_x or 0.13,             icon_y  = args.icon_y or 0.08,
        
        --- label settings
        label_x      = args.label_x or 0.56,         label_y           = args.label_y or 0.07,
        label_w      = args.label_w or 1.1,          label_h           = args.label_h or 0.28,
        label_color  = args.label_color or ctd,      label_text_scale  = args.label_text_scale or 0.32,
        
        --- widget_dist & hover tint 
        widget_dist = args.widget_dist or 0.72,      hover_tint = args.hover_tint or 0,

        --- bg sprite and shadow 
        icon_tint  = args.icon_tint or ccrm,         bg_sprite_color = args.bg_sprite_color or ctd,
        bg_shadow  = args.bg_shadow ~= N,            bg_shadow_color = args.bg_shadow_color or btn_shadow,
        bg_paint   = args.bg_paint or hover_button_paint(paint_seed_entry, args),
    }

    btn.style = IconBtn(btn)
    return btn
end

---_______________________________________________
--- main: _hover_control_widgets
---_______________________________________________
function DeckZone:_hover_control_widgets(cfg)
    local cfg    = cfg or self.config
    local bw, bh = cfg.hover_control_button_w or 1.8, cfg.hover_control_button_h or 0.42
    local gap    = cfg.hover_control_gap or 0.12
    local args = {
        button_w          = bw,                                    button_h    = bh, 
        bg_style          = cfg.hover_control_bg_style,            icon_w      = cfg.hover_control_icon_w, 
        label_text_scale  = cfg.hover_control_label_text_scale,    hover_tint  = cfg.hover_control_hover_tint,
        bg_sprite_color   = cfg.hover_control_bg_sprite_color,     bg_shadow   = cfg.hover_control_bg_shadow,
        bg_shadow_color   = cfg.hover_control_bg_shadow_color,     icon_tint   = cfg.hover_control_icon_tint,
        label_color       = cfg.hover_control_label_color,         widget_dist = cfg.hover_control_widget_dist,
    }

    return {
        hover_button("deck_preview_btn", cfg.hover_preview_label or "Preview", 0, 0, cfg.hover_preview_icon or "log", preview_deck, args),
        hover_button("deck_cancel_btn",  cfg.hover_cancel_label  or "Cancel",  0, bh + gap, cfg.hover_cancel_icon or "undo", cancel_deck_preview, args),
    }
end

end
