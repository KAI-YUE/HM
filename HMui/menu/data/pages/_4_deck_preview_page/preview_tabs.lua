local C         = require("HMfns.animate.color.color_const")
local I18N      = require("HMfns.utils.format.i18n_utils")
local IconBtn   = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Tree      = require("HMEng.ui_actors.common.tree")
local Data      = require("HMui.menu.data.pages._4_deck_preview_page.preview_layout")
local Floating  = require("HMui.menu.data.pages._4_deck_preview_page.anims.floating_tabs")
local TabBtn    = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.tab_color_var_btn")

local i18n  = I18N.i18n

local Y, N  = true, false

local M = {}

--------------------------------------------------
--- deck preview tabs
--------------------------------------------------
--- Helper: tab_hook
local function tab_hook(hook, key) return function(gm) if hook then return hook(gm, key) end end end

--- Helper: label_text
local function label_text(gm, label)
    if type(label) ~= "table" then return tostring(label or "") end
    local text = i18n(gm, { type = label.i18n_type, key = label.i18n_scope .. "." .. label.i18n_key })
    return text or label.fallback
end

--- Helpers: label bounds | label font type
local function label_bounds(label, T) return label.T or { x = 0, y = 0, w = T.w, h = T.h } end
local function label_font_type(gm, label)
    if label.font_type then return label.font_type end
    local font_type = gm.selected_lang and gm.selected_lang.font_type
    return font_type and label.font_variant and font_type .. "_" .. label.font_variant
end

--- Helper: hover float
local function hover_float(_, widget) return Floating.hover(widget) end

--- Helper: tab_btn
local function tab_btn(gm, def, hook, selected)
    local active, T, label = selected == def.key, def.T, def.label
    return TabBtn.build({
        --- basics
        id = "deck_view_" .. def.key,                T = T,
        
        --- hit setting 
        active = active,                             hook_fn = tab_hook(hook, def.key),
        hover_hook_fn = hover_float,

        --- visual setting
        bg_quad_key          = def.mask,             label             = label_text(gm, label),
        label_T              = label_bounds(label, T),                    label_text_scale = label.scale,
        label_align          = label.align,                               label_lang        = gm.selected_lang,
        label_font_type      = label_font_type(gm, label),                 label_text_offset = label.offset,
        label_parent_hover_tint = N,
        label_text_line_spacing = label.line_spacing,                     label_i18n_type = label.i18n_type,
        label_i18n_scope     = label.i18n_scope,     label_i18n_key    = label.i18n_key,
        label_i18n_fallback  = label.fallback,
    })
end

--- Helper: close_btn
local function close_btn(def, hook)
    local T = def.T
    local args = {
        --- basics
        id           = "deck_view_" .. def.key,     T = T,

        --- bg setting
        bg_style     = "rbox",                      bg_atlas_key  = "ui_pack",
        bg_quad_key  = def.mask,                    bg_w          = T.w,
        bg_h         = T.h,                         bg_shadow     = Y,

        --- icon setting
        icon_quad_key  = def.icon,                  icon_x  = 0.14,
        icon_y         = 0.10,                      icon_w  = 0.34,

        --- label setting
        label          = def.label,                 label_x           = 0.58,
        label_y        = 0.08,                      label_w           = T.w - 0.66,
        label_h        = 0.36,                      label_text_scale  = 0.28,
        label_color    = C.UI.TEXT_DARK,        
        
        --- hit setting 
        hover_arrow  = N,
        button       = Y,                           can_hover  = Y,
        can_click    = Y,                           hook_fn    = tab_hook(hook, def.key),
    }
    args.style = IconBtn(args)
    return args
end

---________________________________
--- main: build
---________________________________
function M.build(gm, selected, hooks)
    local hooks, widgets = hooks or {}, {}
    for idx, def in ipairs(Data.ordered) do widgets[idx] = tab_btn(gm, def, hooks.switch_page, selected) end
    widgets[#widgets + 1] = close_btn(Data.close, hooks.close)
    return widgets
end

--- Helper: set_selected
local function set_selected(root, def, selected)
    local btn = Tree.find_child_by_id(root, "deck_view_" .. def.key);      if not btn then return end
    TabBtn.set_active(btn, selected, def)
    Floating.set_active(btn, selected, def.float_phase)
end

---________________________________
--- main: select
---________________________________
function M.select(root, selected) for _, def in ipairs(Data.ordered) do set_selected(root, def, def.key == selected) end end

return M
