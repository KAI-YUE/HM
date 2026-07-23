local M = {
    paint_rect       = "love_preset",
    round_rect       = "love_preset",
    conceptual_box   = "love_preset",
    btn_container    = "love_preset",
    empty_container  = "love_preset",
    scrollable_discrete_entry = "love_preset",
    scrollable_continuous = "love_preset",
    text_widget      = "love_preset",
    dialogue_box     = "sprite_preset",
    sprite_in_page   = "sprite_preset",
    predrawn_circle  = "sprite_preset",
    rbox             = "sprite_preset",
    stroke           = "sprite_preset",
    stroked_page     = "page_preset",
    art_page         = "page_preset",
}

local StrokeData = require("HMEng.visual.stroked_brush.data.strokes")

--- Helper: M.module_path
function M.module_path(style)
    local brew_name = M[style]
    if brew_name then return "HMEng.ui_actors.hm_widget.prototype." .. brew_name .. "." .. style .. ".default" end
    return "HMEng.ui_actors.hm_widget.prototype." .. style .. ".default"
end

--- Helper: M.defaults
function M.defaults(args, fallback)
    if not args.style then return fallback end
    if type(args.style) == "table" then return args.style end

    local prototype = require(M.module_path(args.style))
    if type(prototype) == "function" then return prototype(args) end
    return prototype
end

--- Helper: M.ratio_quad_key
local function _stroke_quad_key(stroke)
    if not stroke then return end
    local key = stroke.stroke_key or stroke.key or stroke.quad_key
    local data = key and StrokeData[key]
    return stroke.quad_key or (data and data.quad_key) or key
end

local function _split_stroke_quad_key(args)
    local stroke = args.split and args.split.stroke
    return _stroke_quad_key(stroke)
end

function M.ratio_quad_key(args, prototype)
    if args.style == "stroked_page" then
        local split_quad_key = _split_stroke_quad_key(args); if split_quad_key then return split_quad_key end
    end
    if args.quad_key then return args.quad_key end
    if prototype and prototype.quad_key then return prototype.quad_key end

    local strokes = args.strokes or (prototype and prototype.strokes)
    local stroke  = strokes and strokes[1]
    return stroke and stroke.quad_key
end

--- Helper: M.sprite_ratio
function M.sprite_ratio(gm, args, prototype)
    local atlas_key     = args.atlas_key or (prototype and prototype.atlas_key) or "ui"
    local quad_key      = M.ratio_quad_key(args, prototype);                 if not quad_key then return end
    local atlas         = gm.T_atlas and gm.T_atlas[atlas_key];                 if not atlas then return end
    local _, _, qw, qh  = atlas:get_quad(quad_key):getViewport();               if not qw or not qh or qw <= 0 or qh <= 0 then return end
    return qw / qh
end

return M
