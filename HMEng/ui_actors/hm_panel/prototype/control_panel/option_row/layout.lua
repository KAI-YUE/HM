local TextFit = require("HMfns.utils.format.text_fit")

local max = math.max

local M = {}

local _ctrl_gap         = 1
local _label_text_inset = 0.

--- Helper: label_text_scale
function M.label_text_scale(args) return args.label_text_scale or args.text_scale or 0.5 end

--- Helper: label_fit_args
function M.label_fit_args(args)
    return {
        text_scale      = M.label_text_scale(args),                    lang           = args.label_lang or args.lang,
        tile_size       = args.label_tile_size or args.tile_size,      char_w_factor  = args.label_char_w_factor or 0.6,
        stretch_factor  = args.label_stretch_factor,                   min_w          = args.label_min_w or 1.6,
        max_w           = args.label_max_w or 4.2,                     w              = args.label_box_T and args.label_box_T.w or args.label_w,
    }
end

--- Helper: label_w | label_fit_scale | label_x | control_x
function M.label_w(args)         return TextFit.fit_w(args.label, M.label_fit_args(args)) end
function M.label_fit_scale(args) return TextFit.fit_scale(args.label, M.label_fit_args(args)) end
function M.label_x(args)         return args.label_box_T and args.label_box_T.x or args.label_x or 0.62 end
function M.control_x(args)       return args.control_x or (M.label_x(args) + M.label_w(args) + (args.control_gap or _ctrl_gap)) end

---____________________________
--- main: label_text_maxw
---______________________________________
function M.label_text_maxw(args)
    local inset = args.label_text_inset or _label_text_inset
    return max(0.1, (args.w or 3) - 2*inset)
end

return M
