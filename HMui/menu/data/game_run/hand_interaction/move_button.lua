local FoldedCornerBtn = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn")

local M = {}

M.id      = "card_go_btn"
M.T       = { x = 0,       y = 0,      w = 2.12,      h = 1.02 }
M.shift   = { x_shift = 0, y_shift = -2 }
M.label_key, M.label_pack = "board_state.go_steps", "gameplay"

local _btn_type = "type4"

----------------------------------
--- prototype
----------------------------------
--- Helper: prototype args
local function _prototype_args(args)
    args = args or {}
    return {
        id       = M.id,                  T                = args.T,
        x_shift  = M.shift.x_shift,       y_shift          = M.shift.y_shift,
        label    = args.label,            label_lang       = args.lang,
        hook_fn  = args.hook_fn,          folded_btn_type  = _btn_type,
    }
end

--- Helper: live args
local function _live_args(text, anchor_T, lang)
    return {
        id               = M.id,                  anchor_T    = anchor_T,
        x_shift          = M.shift.x_shift,       y_shift     = M.shift.y_shift,
        label            = text,                  label_lang  = lang,
        folded_btn_type  = _btn_type,
    }
end

----------------------------------------
--- label_id
----------------------------------------
function M.label_id() return FoldedCornerBtn.label_id(M.id) end

----------------------------------------
--- prototype
----------------------------------------
function M.prototype(args)
    args    = args or {}
    args.T  = args.T or M.T
    return FoldedCornerBtn.build(_prototype_args(args))
end

------------------------------------------
--- relayout
------------------------------------------
function M.relayout(panel, text, anchor_T, lang) return FoldedCornerBtn.relayout(panel, _live_args(text, anchor_T, lang)) end

------------------------------------------
--- anchor_T
------------------------------------------
function M.anchor_T(T, text, lang)
    local args      = _live_args(text, T, lang)
    local layout    = FoldedCornerBtn.layout(args)
    args.w, args.h  = layout.w, layout.h
    return FoldedCornerBtn.anchor_T(T, args)
end

return M
