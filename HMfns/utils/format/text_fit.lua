local UTF8 = require("HMfns.utils.format.utf8_utils")

local M = {}

local _lang_char_w_factors = {
    ja = 1.05,
    ko = 1.05,
    zh_CN = 1.05,
    zh_TW = 1.05,
}

--- Helper: text_len | base_scale | lang_key
local function text_len(text)   local n = 0; for _ in UTF8.chars(tostring(text or "")) do n = n + 1 end; return n end
local function base_scale(args) return args and (args.text_scale or args.scale) or 0.5 end
local function lang_key(lang)   return type(lang) == "table" and (lang.key or lang.id or lang.code) or lang end

--- Helper: lang_char_w_factor
local function lang_char_w_factor(args)
    local key = lang_key(args and args.lang)
    local factors = args and args.lang_char_w_factors or _lang_char_w_factors
    return (key and factors and factors[key]) or args.char_w_factor or 0.6
end

--- Helper: font_text_w
local function font_text_w(text, args)
    local font_cfg, tile_size = args and args.lang and args.lang.font, args and args.tile_size
    local font = font_cfg and font_cfg.FONT
    if not (font and font.getWidth and tile_size and tile_size > 0) then return end
    return font:getWidth(tostring(text or "")) * (font_cfg.squish or 1) * (font_cfg.font_scale or 1) * base_scale(args) / tile_size
end

--- Helper: clamp
local function clamp(value, min_v, max_v) return math.min(max_v, math.max(min_v, value)) end

--- Helper: estimated_w
function M.estimated_w(text, args)
    args = args or {}
    local font_w = font_text_w(text, args)
    if font_w then return args.stretch_factor and font_w * args.stretch_factor or font_w end
    local w = text_len(text) * base_scale(args) * lang_char_w_factor(args)
    if args.stretch_factor then w = w * args.stretch_factor end
    return w
end

--- Helper: fit_w
function M.fit_w(text, args)
    args = args or {}
    if args.w then return args.w end
    return clamp(M.estimated_w(text, args), args.min_w or 1.6, args.max_w or 4.2)
end

--- Helper: fit_scale
function M.fit_scale(text, args)
    args = args or {}
    local estimated_w, fitted_w = M.estimated_w(text, args), M.fit_w(text, args)
    if estimated_w <= 0 then return base_scale(args) end
    if estimated_w <= fitted_w then return base_scale(args) end
    return base_scale(args) * fitted_w / estimated_w
end

--- Helper: layout
function M.layout(text, args)
    return { w = M.fit_w(text, args), text_scale = M.fit_scale(text, args), estimated_w = M.estimated_w(text, args) }
end

return M
