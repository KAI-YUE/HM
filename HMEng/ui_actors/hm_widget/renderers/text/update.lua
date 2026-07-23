local C           = require("HMfns.animate.color.color_const")
local TextParser  = require("HMEng.ui_actors.hm_widget.renderers.text.text_parser")
local TextReveal  = require("HMEng.ui_actors.hm_widget.renderers.text.text_reveal")
local UTF8        = require("HMfns.utils.format.utf8_utils")

local LG = love.graphics

local Y, N = true, false

local M = {}

--- Helper: font lang
local function _font_lang(gm, cfg)
    local font_type = cfg.font_type;                         if not font_type then return cfg.lang or gm.selected_lang end
    if cfg._font_type_lang and cfg._font_type_lang.font_type == font_type then return cfg._font_type_lang end
    local font = gm.g_fonts and gm.g_fonts[font_type];       if not font then return cfg.lang or gm.selected_lang end
    cfg._font_type_lang = { key = "font_" .. font_type, font_type = font_type, font = font, glyph_ban = gm.selected_lang and gm.selected_lang.glyph_ban }
    return cfg._font_type_lang
end

-----------------------------
--- Update text: Update text if reference or ref_table changes
----------------------------------
--- Helper: update text source from a ref table
local function _sync_ref_text(cfg)
    local rt, rv = cfg.ref_table, cfg.ref_value
    if not rt or not rv or rt[rv] == cfg.prev_value then return end
    cfg.text, cfg.prev_value = tostring(rt[rv]), rt[rv]
end

--- Helper: glyph rule
local function _glyph_rule(lang, font_cfg, char)
    local lang_ban = lang and lang.glyph_ban and font_cfg and lang.glyph_ban[font_cfg.name]
    local rule = lang_ban and lang_ban[char]
    if rule ~= nil then return rule end

    rule = font_cfg and font_cfg.glyph_ban and font_cfg.glyph_ban[char]
    if rule ~= nil then return rule end
    for _, v in ipairs(lang_ban or {}) do if v == char then return Y end end
    for _, v in ipairs((font_cfg and font_cfg.glyph_ban) or {}) do if v == char then return Y end end
end

--- Helper: _new_text_drawable
local function _new_text_drawable(font, text, line_spacing)
    if not (font and font.setLineHeight and font.getLineHeight and line_spacing) then return LG.newText(font, { C.WHITE, text }) end

    local old_line_h = font:getLineHeight()
    font:setLineHeight(line_spacing)
    local drawable = LG.newText(font, { C.WHITE, text })
    font:setLineHeight(old_line_h)
    return drawable
end

--- Helper: drawable font runs
local function _text_drawable_runs(text, lang, line_spacing)
    local font_cfg = lang and lang.font
    local base_font = font_cfg and font_cfg.FONT;        if not base_font then return end
    local runs, cur_font_cfg, cur_rule, cur_text, has_fallback = nil, nil, nil, nil

    local function flush()
        if not cur_text or cur_text == "" then return end
        runs = runs or {}
        runs[#runs + 1] = { text = cur_text, font_cfg = cur_font_cfg, rule = cur_rule, drawable = _new_text_drawable(cur_font_cfg.FONT, cur_text, line_spacing) }
        cur_text = ""
    end

    for _, char in UTF8.chars(text) do
        local rule = _glyph_rule(lang, font_cfg, char)
        local next_font_cfg = (type(rule) == "table" and rule.fallback_font and rule.fallback_font.FONT) and rule.fallback_font or font_cfg
        if next_font_cfg ~= font_cfg then has_fallback = Y end
        if cur_font_cfg and (cur_font_cfg ~= next_font_cfg or cur_rule ~= rule) then flush() end
        cur_font_cfg = next_font_cfg
        cur_rule = rule
        cur_text = (cur_text or "") .. char
    end
    flush()

    return has_fallback and runs
end

--- Helper: text wrap cache key | _text_drawable_cache_key
local function _text_parse_cache_key(text, cfg, font, maxw, maxh, scale)  return table.concat({ text,    maxw, maxh, scale, font.squish or "", tostring(font.FONT), cfg.text_max_lines or "",  cfg.text_line_spacing or "" }, "|") end
local function _text_drawable_cache_key(text, cfg) return table.concat({ text, tostring(cfg.lang and cfg.lang.font and cfg.lang.font.FONT), cfg.text_line_spacing or "" }, "|") end

--- Helper: wrapped page text
local function _wrapped_page_text(self, cfg, text)
    if not cfg.text_wrap then return text end

    local VT, lang  = self.VT, cfg.lang
    local font      = lang and lang.font;       if not (VT and font) then return text end

    local box,  tz         = self.text_layout_box and self:text_layout_box() or VT, self.rcfg.tile_size
    local pad,  scale      = cfg.text_padding or { x = 0.2, y = 0.1 },  (cfg.text_scale or cfg.scale or 0.5) * font.font_scale / tz
    local maxw, maxh       = cfg.text_maxw or (box.w - 2*(pad.x or 0)), box.h - 2*(pad.y or 0)
    local page, cache_key  = cfg.text_page or 1,                        _text_parse_cache_key(text, cfg, font, maxw, maxh, scale)

    if cache_key ~= cfg.text_parse_cache_key then
        cfg.text_parse = TextParser.parse(text, { font_cfg = font,   max_w = maxw,  max_h = maxh, scale = scale,  max_lines = cfg.text_max_lines,  line_spacing = cfg.text_line_spacing })
        cfg.text_pages, cfg.text_parse_cache_key  = cfg.text_parse.pages, cache_key
        cfg.text_page,  cfg.text_reveal_source    = 1, nil
        page = 1
    end

    local pages = cfg.text_pages
    if not (pages and #pages > 0) then return text end
    if page < 1 then page = 1 elseif page > #pages then page = #pages end
    cfg.text_page = page
    return pages[page]
end

--- Helper: revealed text
local function _revealed_text(gm, cfg, now, text)
    if cfg.text_reveal ~= Y then return text end

    local reveal_key = tostring(cfg.text_page or 1) .. "|" .. text
    if cfg.text_reveal_source ~= reveal_key then
        cfg.text_reveal_source = reveal_key
        TextReveal.reset(cfg, now, text)
    end
    return TextReveal.visible_text(text, cfg, now, gm)
end

--- Helper: drawable text
local function _update_text_drawable(cfg, text)
    local cache_key = _text_drawable_cache_key(text, cfg)
    if cache_key == cfg.prev_text_drawable_key and (cfg.text_drawable or cfg.text_drawable_runs) then return end

    local runs = _text_drawable_runs(text, cfg.lang, cfg.text_line_spacing)
    if runs                      then cfg.text_drawable_runs, cfg.text_drawable = runs, nil
    elseif not cfg.text_drawable then cfg.text_drawable_runs, cfg.text_drawable = nil, _new_text_drawable(cfg.lang.font.FONT, text, cfg.text_line_spacing)
    elseif cfg.text_line_spacing then cfg.text_drawable_runs, cfg.text_drawable = nil, _new_text_drawable(cfg.lang.font.FONT, text, cfg.text_line_spacing)
    else                              cfg.text_drawable_runs = nil; cfg.text_drawable:set(text) end
    cfg.prev_text, cfg.prev_text_drawable_key = text, cache_key
end

--- Helper: _update_text_fit_drawable
local function _update_text_fit_drawable(cfg, text)
    if cfg.text_reveal ~= Y then return end

    local cache_key = _text_drawable_cache_key(text, cfg)
    if cache_key == cfg.text_fit_drawable_key and (cfg.text_fit_drawable or cfg.text_fit_drawable_runs) then return end

    local runs = _text_drawable_runs(text, cfg.lang, cfg.text_line_spacing)
    if runs                          then cfg.text_fit_drawable_runs, cfg.text_fit_drawable = runs, nil
    elseif not cfg.text_fit_drawable then cfg.text_fit_drawable_runs, cfg.text_fit_drawable = nil, _new_text_drawable(cfg.lang.font.FONT, text, cfg.text_line_spacing)
    elseif cfg.text_line_spacing     then cfg.text_fit_drawable_runs, cfg.text_fit_drawable = nil, _new_text_drawable(cfg.lang.font.FONT, text, cfg.text_line_spacing)
    else                                  cfg.text_fit_drawable_runs = nil; cfg.text_fit_drawable:set(text) end
    cfg.text_fit_drawable_key = cache_key
end

function M.update(self)
    local gm, cfg = self.gm, self.config;       if not cfg then return end
    _sync_ref_text(cfg);                        if not cfg.text then return end

    cfg.lang   = _font_lang(gm, cfg)
    local text = tostring(cfg.text)
    if cfg.text_static then
        if text == cfg.prev_raw_text and _text_drawable_cache_key(text, cfg) == cfg.prev_text_drawable_key and (cfg.text_drawable or cfg.text_drawable_runs) then return end
        cfg.prev_raw_text = text
        return _update_text_drawable(cfg, text)
    end

    local now  = gm._T.real_s
    if text == cfg.prev_raw_text and not cfg.text_wrap and not cfg.text_reveal and _text_drawable_cache_key(text, cfg) == cfg.prev_text_drawable_key and (cfg.text_drawable or cfg.text_drawable_runs) then return end
    cfg.prev_raw_text = text

    text = _wrapped_page_text(self, cfg, text)
    _update_text_fit_drawable(cfg, text)

    text = _revealed_text(gm, cfg, now, text)
    _update_text_drawable(cfg, text)
end

return M
