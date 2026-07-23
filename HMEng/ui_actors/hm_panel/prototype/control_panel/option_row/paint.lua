local C          = require("HMfns.animate.color.color_const")
local Layout     = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row.layout")
local PaintSeeds = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row.paint_seeds")
local TabUtils   = require("HMfns.utils.table_utils")

local CUI     = C.UI
local ck, ctl = C.BLACK, CUI.TEXT_LIGHT
local ccrm    = C.CREAM
local copy, rand_pick = TabUtils.deep_copy, TabUtils.random_pick

local M = {}

local _bleed_w_scale = 0.4
local _row_pad       = 0.32

---____________________________
--- main: row_T
---______________________________________
function M.row_T(args, row_h)
    if args.T then return args.T end
    local w = args.w or (Layout.control_x(args) + (args.control_w or 2.5) + (args.row_pad_w or _row_pad))
    return { w = _bleed_w_scale*w, h = row_h }
end

---____________________________
--- main: paint_seed_entry
---______________________________________
function M.paint_seed_entry(args) return (args and args.paint_seed_entry) or rand_pick(PaintSeeds) end

---____________________________
--- main: default_paint
---______________________________________
function M.default_paint(seed_entry, args)
    seed_entry = seed_entry or {}
    args       = args or {}
    return {
        shader     = "_-4_watercolor_slot_wipe",     seed        = seed_entry.seed,
        wobble     = seed_entry.wobble or 1.2,       bleed       = seed_entry.bleed or 1.6,
        feather_px = seed_entry.feather_px or 1,     widget_dist = args.widget_dist or 1.4,
        paint_seed_entry = seed_entry,

        --- fx_mask
        fx_mask_ref = "fx_mask",                     fx_mask_dir_ref = "fx_mask_dir",
    }
end

---____________________________
--- main: resolve_paint
---______________________________________
function M.resolve_paint(args)
    args = args or {}
    local seed_entry = M.paint_seed_entry(args)
    if not args.paint then return M.default_paint(seed_entry, args), seed_entry end

    local paint = copy(args.paint)
    paint.paint_seed_entry = paint.paint_seed_entry or seed_entry
    paint.seed             = paint.seed or seed_entry.seed
    return paint, paint.paint_seed_entry
end

---____________________________
--- main: idle_color
---______________________________________
function M.idle_color(fill_color) return { fill_color = fill_color or ck, text_color = ctl } end

return M
