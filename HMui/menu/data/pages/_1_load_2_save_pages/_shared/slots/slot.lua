local C           = require("HMfns.animate.color.color_const")
local HintBtns    = require("HMui.menu.data.pages._shared.hint_btns")
local SlotText    = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.text")
local SlotTextFx  = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.textfx")
local SlotSeeds   = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.slot_seeds")
local TabUtils    = require("HMfns.utils.table_utils")
local FontData    = require("HMGmgr.data.fonts_lang.fonts")

local rand_pick   = TabUtils.random_pick
local _summary    = SlotText.summary_text

local _seed       = rand_pick(SlotSeeds)
local ck, cw      = C.BLACK, C.WHITE
local ctl         = C.UI.TEXT_LIGHT

local Y,    N     = true, false

local _save_x,        _save_y        = 11,      0.28
local _del_x,         _del_y         = _save_x, 1.1
local _save_label_x,  _save_label_y  = 1,       0.2
local _del_label_x,   _del_label_y   = 1,       0.2
local M = {}

local default_icon        = { atlas_key = "icon_pack", quad_key = "question_mark" }
local inactive_hint_color = C.UI.INACTIVE
local inactive_hint_text_color = C.UI.TEXT_DARK
local inactive_hint_bg_color   = { 0.72, 0.71, 0.69, 0.92 }

--- Helper: sab_lang | sab_textfx_sampling | slot_summary_line_spacing
local function sab_lang(gm)                 return { key = "sab", font_type = "SAB", font = gm and gm.g_fonts and gm.g_fonts.SAB } end
local function sab_textfx_sampling()        return { ransom_sampling_rate = 0, normal = { SAB_textfx = 1 } } end
local function slot_summary_line_spacing()  return FontData.line_spacing("SAB", "save_slot_summary", 1.6) end

--- Helper: slot_icon
local function slot_icon(meta)
    local icon       = (type(meta) == "table" and type(meta.icon) == "table" and meta.icon) or default_icon
    local atlas_key  = icon.atlas_key or default_icon.atlas_key

    return {
        --- basics
        style      = "sprite_in_page",                  id        = "save_slot_profile_icon",
        atlas_key  = atlas_key,                         quad_key  = icon.quad_key  or default_icon.quad_key,

        --- hit settings
        button     = N,                                 can_click  = N, 
        can_hover  = N,                                 can_drag   = N,
        
        --- color settings
        shadow = Y,                                     tint  = cw, 
        sprite_color = cw,                              paint = { shader = "_-3_slot_wipe" },   
        slot_enter_shader = "_-1_page_wipe",            slot_enter_delay = 0.5,
        T = { x = 8.35, y = .45, w = 0.68 },
    }
end

------------------------------------------
--- Helper: slot hint
------------------------------------------
local function slot_hint(kind, id, x, y, label_x, label_y, parent_mode, inactive, label_key)
    local args = {
        --- basics
        id = id,                        T = { x = x, y = y, w = 2.7, h = 0.6 },
        label_x = label_x,              label_y = label_y,
        label_textfx = Y,
        page_draw_layer = N,            show_when_parent = parent_mode,
        parent_cut_in_sync = Y,          parent_cut_in_delay = 0.14,
        parent_press_squash = kind ~= "delete",

        --- hit settings
        button         = N,             can_click    = N,
        can_hover      = N,             can_collide  = N,
        gamepad_focus  = N,
    }

    if label_key then args.label,    args.hint_label_i18n_key = label_key == "save" and "Save" or "Load", label_key end
    if inactive  then args.icon_tint, args.text_color, args.idle_text_color, args.label_textfx_bg_color = inactive_hint_color, inactive_hint_text_color, inactive_hint_text_color, inactive_hint_bg_color end

    return HintBtns[kind](args)
end

------------------------------------------
--- Helper: slot hints
------------------------------------------
local function slot_hints(id, primary_label_key, primary_on_empty)
    local hints = {}
    if primary_on_empty then
        hints[#hints + 1] = slot_hint("confirm", id .. "_confirm_hint", _save_x, _save_y, _save_label_x, _save_label_y, "active", N, primary_label_key)
    else
        hints[#hints + 1] = slot_hint("confirm", id .. "_confirm_hint",          _save_x, _save_y, _save_label_x, _save_label_y, "active_nonempty", N, primary_label_key)
        hints[#hints + 1] = slot_hint("confirm", id .. "_confirm_hint_inactive", _save_x, _save_y, _save_label_x, _save_label_y, "active_empty", Y, primary_label_key)
    end
    hints[#hints + 1] = slot_hint("delete", id .. "_delete_hint", _del_x, _del_y, _del_label_x, _del_label_y, "active_nonempty")
    return hints
end

--- Helper: make
function M.make_slot(i, meta, opts)
    opts = opts or {}

    local display_lang, textfx_sampling  = sab_lang(opts.gm),                        sab_textfx_sampling()
    local has_data,     id               = type(meta) == "table" and not meta.empty, ("%s_%d"):format(opts.slot_id_prefix or "save_slot", i)
    local primary_on_empty               = opts.primary_on_empty == Y

    local children  = slot_hints(id, opts.primary_hint_i18n_key, primary_on_empty)
    table.insert(children, 1, slot_icon(meta))

    return {  --- basics
        style = "paint_rect",                            id  = id,
        save_slot_meta     = meta,                       T   = { w = 4.2, h = 0.34 },
        primary_on_empty   = primary_on_empty,

        --- hit settings
        hit_scale         = { x = 2.48, y = 7 },         hit_offset         = { x = 3.3, y = 1 },
        button            = Y,                           can_click          = has_data or primary_on_empty,
        can_hover         = Y,                           can_drag           = N,
        hover_tint        = 0.1,                         click_visual_time  = 0.2,
        hook_fn           = opts.hook_fn,                slot_idx           = i,
        secondary_action  = has_data and "delete",       secondary_hook_fn  = has_data and "delete_save_slot",
        paint_bg          = Y,

        --- color settings
        fill_color    = ck,                              idle_color  = { fill_color = ck, text_color = ctl },
        shadow_color  = { 0, 0, 0, 0.22 },

        ------------------------------------------
        --- save slot summary text
        --- basic settings
        text               = _summary(meta),
        lang               = display_lang,
        text_color         = ctl,                       text_scale         = 0.43,
        text_shadow        = N,                         text_overlay       = Y,

        --- text wrapping
        text_wrap          = Y,

        --- text box settings
        text_box_T         = { x = 3.9, y = -0.36, w = 12.6, h = 5.04 },
        text_line_spacing  = slot_summary_line_spacing(),
        text_align         = { x = "left", y = "top" },
        text_offset        = { x = 0, y = 0 },

        --- text mask settings
        text_mask_shader   = "_-3_slot_wipe",           text_mask_ref      = "fx_mask",
        text_mask_dir_ref  = "fx_mask_dir",             text_mask_T        = { x = -0.35, y = -0.75, w = 15.3, h = 6 },

        ----------------------------------------
        --- textfx
        textfx         =   SlotTextFx.title_textfx(i, { x = 0.45, y = 0.8, w = 5, h = 0.4 }),
        extra_textfx   = { SlotTextFx.playtime_textfx(i, meta, { x = 0.46, y = 1.25, w = 5.8, h = 0.32 }, { lang = display_lang, card_font_sampling = textfx_sampling }) },
        child_widgets  = children,

        --- paint rect shader related
        paint = { shader = "_-4_watercolor_slot_wipe", wobble = 2, bleed = 2, feather_px = 1, widget_dist = 2, fx_mask_ref = "fx_mask", fx_mask_dir_ref = "fx_mask_dir" },
    }
end

return M
