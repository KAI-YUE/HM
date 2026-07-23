local card_textfx_fonts = require("HMEng.ui_actors.card_textfx.data.fonts")
local FontDefs          = require("HMGmgr.data.fonts_lang.ui_font_defs")
local font_glyph_ban    = require("HMGmgr.data.fonts_lang.font_glyph_ban")
local LF, LG = love.filesystem, love.graphics

local M = {}

M.dir_ft = "resources/fonts/"

M.font_files = {
    "ZCOOLXW", "Gsans", "HachiMaruPop", "SAB",
    FontDefs.Gsans_hint, FontDefs.SAB_hint,
    FontDefs.ZCOOLXW_small_ui, FontDefs.Gsans_small_ui, FontDefs.HachiMaruPop_small_ui, FontDefs.SAB_small_ui,
}

M.lang_defs = {
    de        = { font_type = "SAB" },
    en_us     = { font_type = "ZCOOLXW" },
    es_419    = { font_type = "SAB" },
    es_ES     = { font_type = "SAB" },
    fr        = { font_type = "SAB" },
    it        = { font_type = "SAB" },
    ja        = { font_type = "SAB" },
    ko        = { font_type = "SAB" },
    pt_BR     = { font_type = "SAB" },
    ru        = { font_type = "SAB" },
    zh_CN     = { font_type = "ZCOOLXW" },
    zh_TW     = { font_type = "SAB" },
}

M.text_line_spacing = {
    save_slot_summary = {
        default = 1.6,
        ZCOOLXW = 1.6,
        SAB = 1.4,
    },
}

M.glyph_ban = font_glyph_ban

local Y = true

--- Helper: font_name | font_title | font_ext | resolve_font_value | global_ban 
local function _font_name(file)    return type(file) == "table" and (file.name or file.file) or file end
local function _font_file(file)    return type(file) == "table" and (file.file or file.name) or file end
local function _font_ext(file)     return "ttf" end
local function _resolve_font_value(v, tz)   return type(v) == "function" and v(tz) or v end
local function _global_ban(name, file_name) local global = font_glyph_ban.global or font_glyph_ban; return global[name] or global[file_name] or {} end

--- Helper: font_cfg
local function _font_cfg(tz, file)
    local name       = _font_name(file)
    local file_name  = _font_file(file)
    local cfg = { name = name, file = M.dir_ft..file_name..".".._font_ext(file), render_scale = 2*tz, font_hl_scale = 1, font_offset = { x = 0, y = 0 }, font_scale = 0.4, squish = 1, descale = 1 }
    if type(file) == "table" then for k, v in pairs(file) do if k ~= "name" and k ~= "file" then cfg[k] = _resolve_font_value(v, tz) end end end
    cfg.glyph_ban = _global_ban(name, file_name)
    return cfg
end

--- Helper: link_rule_fallbacks | link_font_fallbacks | link_lang_font_bans 
local function _link_rule_fallbacks(ban, fonts) for _, rule in pairs(ban or {}) do if type(rule) == "table" and rule.fallback then rule.fallback_font = fonts[rule.fallback] end end end
local function _link_font_fallbacks(fonts) for _, cfg in ipairs(fonts) do _link_rule_fallbacks(cfg.glyph_ban, fonts) end end
local function _link_lang_font_bans(langs, fonts) for _, lang in pairs(langs or {}) do for _, ban in pairs(lang.glyph_ban or {}) do _link_rule_fallbacks(ban, fonts) end end end

-----------------------------
--- init fonts 
----------------------------------
function M.init_fonts(tz)
    local fonts, seen = {}, {}
    local function add(file)
        local name = _font_name(file)
        if seen[name] then return end
        seen[name] = Y
        local cfg = _font_cfg(tz, file); fonts[#fonts + 1] = cfg; fonts[name] = cfg
    end

    for _, file in ipairs(M.font_files) do add(file) end
    for _, file in ipairs(card_textfx_fonts.font_files or {}) do add(file) end
    _link_font_fallbacks(fonts)
    return fonts
end

-----------------------------
--- apply_lang_fonts
----------------------------------
function M.apply_lang_fonts(langs, fonts)
    for _, v in pairs(langs or {}) do v.font = fonts[v.font] or fonts["Gsans"] end
    _link_lang_font_bans(langs, fonts)
end

-----------------------------
--- load_font_files  | lang glyph_ban
----------------------------------
function M.load_font_files(fonts) for _, v in ipairs(fonts or {}) do if LF.getInfo(v.file) then v.FONT = LG.newFont(v.file, v.render_scale) end end end
function M.lang_glyph_ban(lang_id) return (font_glyph_ban.langs and font_glyph_ban.langs[lang_id]) end
function M.line_spacing(font_type, key, fallback)
    local group = M.text_line_spacing and M.text_line_spacing[key]
    if not group then return fallback end
    return group[font_type] or group.default or fallback
end

return M
