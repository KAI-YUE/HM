local FontData = require("HMGmgr.data.fonts_lang.fonts")
local LF       = love.filesystem

return function (GMgr)
-----------------------------
--- set_language
----------------------------------
--- Helper: lang dir | load lua | merge
local function _lang_dir(lang)     return "resources/i18n/" .. (lang:gsub("_", "-")) end
local function _load_lua(path)     return assert(loadstring(LF.read(path)))() end
local function _merge(dst, src)    for k, v in pairs(src or {}) do if type(v) == "table" and type(dst[k]) == "table" then _merge(dst[k], v) else dst[k] = v end end; return dst end
local _load_i18n

--- Helper: _locale_candidates
local function _locale_candidates(locale)
    local raw = locale and (locale:gsub("%..*$", ""):gsub("-", "_"))
    if not raw then return {} end
    local a, b = raw:match("^([^_]+)_([^_]+)")
    local c = raw:match("^[^_]+_[^_]+_([^_]+)$")
    local out = { raw, raw:lower() }
    if a and c then out[#out + 1] = a:lower() .. "_" .. c:upper() end
    if a and b then out[#out + 1] = a:lower() .. "_" .. b:upper(); out[#out + 1] = a:lower() .. "_" .. b:lower() end
    if a then out[#out + 1] = a:lower() end
    return out
end

--- Helper: _lang_exists
local function _lang_exists(lang)        return lang and (_load_i18n(lang) ~= nil) end

--- Helper: _system_language
local function _system_language()
    local sys = love and love.system
    if not (sys and sys.getPreferredLocales) then return "en_us" end
    for _, locale in ipairs(sys.getPreferredLocales() or {}) do
        for _, lang in ipairs(_locale_candidates(locale)) do if _lang_exists(lang) then return lang end end
    end
    return "en_us"
end

--- Helper: load i18n
_load_i18n = function(lang)
    local dir = _lang_dir(lang)
    if LF.getInfo(dir .. "/init.lua") then
        local root = _load_lua(dir .. "/init.lua")
        for _, rel in ipairs(root.files or {}) do _merge(root, _load_lua(dir .. "/" .. rel .. ".lua")) end
        root.files = nil
        return root
    end

    local file = "resources/i18n/" .. lang .. ".lua"
    if LF.getInfo(file) then return _load_lua(file) end
end

--- Helper: ui_value 
local function _ui_value(lang, section, key) local L = _load_i18n(lang); return L.ui and L.ui[section] and L.ui[section][key] end

--- Helper: init_langs 
local function _init_langs()
    local langs = {}
    for id, def in pairs(FontData.lang_defs) do
        local font_type = def.font_type or "Gsans"
        langs[id] = { font = font_type, font_type = font_type, key = id, glyph_ban = FontData.lang_glyph_ban(id), label = _ui_value(id, "dictionary", "l_label") or id, warning = _ui_value(id, "text", "warning_text"), l_label = "l_label", warning_text = "warning_text" }
    end
    return langs
end

function GMgr:set_language()
    local SET,   rcfg    = self.SET, self.rcfg               
    local lang,  tz      = SET.language, rcfg.tile_size
    local load_lang      = lang == "auto" and _system_language() or lang
    
    self.dir_ft          = self.dir_ft or FontData.dir_ft
    self.font_glyph_ban  = FontData.glyph_ban

    if not self.Langs then 
        if not (_load_i18n(load_lang)) or self.F.eng_force then SET.language = "en_us"; lang, load_lang = "en_us", "en_us" end
        self.Langs = _init_langs()
        
        --load the font and set filter
        self.g_fonts = FontData.init_fonts(tz)
        FontData.load_font_files(self.g_fonts)
        FontData.apply_lang_fonts(self.Langs, self.g_fonts)
    end

    -- quick overwrite test 
    -- lang = "de"
    -- lang = "es-419"
    -- lang = "zh_CN" 
    -- lang = "ja"
    -- lang = "ko"
    -- lang = "zh_TW"

    self.selected_lang = self.Langs[load_lang] or self.Langs["en_us"]

    self.T_I18N = _load_i18n(load_lang); if not self.T_I18N then return end
    self.Fs.init_i18n_dict(self)
end

end
