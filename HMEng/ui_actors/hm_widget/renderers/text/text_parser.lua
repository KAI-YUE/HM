local M = {}

local floor, max = math.floor, math.max

-----------------------------
--- parse: analyze how long the text chunk is
----------------------------------
--- Helper: split lines, convert  text into a table where each entry is one line
local function _split_lines(text)
    local lines = {}
    text = (tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")) .. "\n"
    for line in text:gmatch("(.-)\n") do lines[#lines + 1] = line end
    return lines
end

--- Helper: font lines
local function _font_lines(font, text, wrap_px)
    if not font or not font.getWrap or not wrap_px or wrap_px < 0 then return { text } end
    local _, lines = font:getWrap(text, wrap_px); return lines
end

--- Helper: fall back char wrap
local function _fallback_char_wrap(font, text, wrap_px)
    if not font or not wrap_px or wrap_px <= 0 then return { text } end

    local lines, line = {}, ""
    for c in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local next_line = line .. c
        if line ~= "" and font:getWidth(next_line) > wrap_px then lines[#lines + 1], line = line, c
        else line = next_line end
    end
    lines[#lines + 1] = line
    return lines
end

--- Helper: push wrapped
local function _push_wrapped(dst, font, raw, wrap_px)
    if raw == "" then  dst[#dst + 1] = ""; return end

    local lines = _font_lines(font, raw, wrap_px)
    for _, line in ipairs(lines) do
        if not font or not wrap_px or wrap_px < 0 or font:getWidth(line) < wrap_px then dst[#dst + 1] = line; goto continue end
        local split = _fallback_char_wrap(font, line, wrap_px)
        for _, v in ipairs(split) do dst[#dst + 1] = v end
        ::continue::
    end
end

--- Helper: paginate
local function _paginate(lines, max_lines)
    local pages, page = {}, {}
    max_lines = max(1, max_lines or #lines)

    for _, line in ipairs(lines) do
        if #page >= max_lines then  pages[#pages + 1] = table.concat(page, "\n"); page = {} end
        page[#page + 1] = line
    end

    if #page > 0 or #pages == 0 then pages[#pages + 1] = table.concat(page, "\n") end
    return pages
end

---____________________________
--- main: parse
---______________________________________
function M.parse(text, args)
    args = args or {}
    local font_cfg, font = args.font_cfg, args.font
    font = font or (font_cfg and font_cfg.FONT)

    local scale, squish        = args.scale or 1, args.squish or (font_cfg and font_cfg.squish) or 1
    local thmul, line_spacing  = args.text_height_scale or (font_cfg and font_cfg.font_hl_scale) or 1, args.line_spacing or 1

    local wrap_px    = args.max_w and args.max_w / max(0.0001, squish * scale)
    local line_h     = font and font:getHeight() * scale * thmul * line_spacing or 1
    local max_lines  = args.max_lines or floor((args.max_h or line_h) / max(0.0001, line_h))

    local wrapped = {}
    for _, raw in ipairs(_split_lines(text)) do _push_wrapped(wrapped, font, raw, wrap_px) end

    return {
        lines = wrapped,     pages  = _paginate(wrapped, max_lines), max_lines = max_lines,
        line_h = line_h,     wrap_px = wrap_px,
    }
end

return M
