local LabelChip   = require("HMEng.ui_actors.card_textfx.presets.label_chip")
local RansomTitle = require("HMEng.ui_actors.card_textfx.presets.ransom_title")
local SlotText    = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.text")

local M = {}

--- Helper: slot_title | slot_textfx_seed
function M.slot_title(slot_idx) return ("DATA %d"):format(tonumber(slot_idx) or 1) end
function M.slot_textfx_seed(slot_idx) return 7000 + (tonumber(slot_idx) or 1)*101 end

--- Helper: title_textfx
function M.title_textfx(slot_idx, T, args)
    args = args or {}
    args.textfx_seed = args.textfx_seed or M.slot_textfx_seed(slot_idx)
    local cfg = RansomTitle.textfx(M.slot_title(slot_idx), T, args)
    cfg.lang = args.lang
    return cfg
end

--- Helper: playtime_textfx
function M.playtime_textfx(slot_idx, meta, T, args)
    args = args or {}
    args.textfx_seed      = args.textfx_seed or M.slot_textfx_seed(slot_idx) + 43
    args.slot_enter_delay = args.slot_enter_delay or 0.22
    
    local _T = { x = T.x + 4, y = T.y - 0.2, w = T.w }

    local cfg = LabelChip.textfx(SlotText.playtime_text(meta), _T, args)
    cfg.lang = args.lang
    return cfg
end

return M
