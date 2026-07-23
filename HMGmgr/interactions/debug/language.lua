local I18N     = require("HMfns.utils.format.i18n_utils")
local Controls = require("HMEng.ui_actors.hm_panel.prototype.control_panel")

local i18n = I18N.i18n
local Y, N = true, false

local M = {}

-----------------------------
--- language options
----------------------------------
--- Helper: sab lang | debug language options
local function sab_lang(gm) return { key = "sab", font_type = "SAB", font = gm and gm.g_fonts and gm.g_fonts.SAB } end

local function language_options(gm)
    local display_lang = sab_lang(gm)
    local langs = { { key = "auto", value = "auto", label = "Auto", lang = display_lang } }
    for _, lang in pairs(gm.Langs or {}) do if not lang.omit then langs[#langs + 1] = { key = lang.key, value = lang.key, label = lang.label, lang = display_lang } end end
    table.sort(langs, function(a, b) if a.key == "auto" then return true end; if b.key == "auto" then return false end; return (a.label or "") < (b.label or "") end)
    return langs
end

-----------------------------
--- live text refresh
----------------------------------
--- Helper: clear text cache 
local function clear_text_cache(cfg)
    cfg.prev_raw_text, cfg.prev_text, cfg.prev_text_drawable_key, cfg.text_fit_drawable_key = nil, nil, nil, nil
    cfg.text_drawable, cfg.text_drawable_runs, cfg.text_fit_drawable, cfg.text_fit_drawable_runs = nil, nil, nil, nil
    cfg.card_textfx_cache = nil
end

--- Helper: i18n_text
local function i18n_text(gm, cfg)
    if not cfg.text_i18n_key then return end
    local scope = cfg.text_i18n_scope or "items"
    local text = i18n(gm, { type = cfg.text_i18n_type or cfg.i18n_type or "menu", key = scope .. "." .. cfg.text_i18n_key })
    cfg.text = text or text
end

--- Helper: refresh lang node
local function refresh_lang_node(gm, node, old_lang, seen)
    if not node or seen[node] then return end; seen[node] = Y
    local cfg, old_key = node.config, old_lang and old_lang.key
    if cfg then
        if type(cfg.lang) == "table" and (cfg.lang == old_lang or cfg.lang.key == old_key) then cfg.lang = gm.selected_lang end
        i18n_text(gm, cfg)
        clear_text_cache(cfg)
    end
    refresh_lang_node(gm, node.widget, old_lang, seen)
    refresh_lang_node(gm, node.attached_panel, old_lang, seen)
    for _, child in ipairs(node.children or {}) do refresh_lang_node(gm, child, old_lang, seen) end
end

--- Helper: refresh live text
local function refresh_live_text(gm, old_lang)
    local seen = {}
    for _, panel in ipairs((gm.R and gm.R.UIPANEL) or {}) do refresh_lang_node(gm, panel, old_lang, seen); if panel.FR then panel.FR.f_dr = -1 end end
    refresh_lang_node(gm, gm.UI and gm.UI.overlay_menu, old_lang, seen)
    refresh_lang_node(gm, gm.debug_tools, old_lang, seen)
end

-----------------------------
--- selector
----------------------------------
function M.selector(gm, x, y)
    return Controls.lr_selector.make({
        id = "debug_lang_selector",          T = { x = x, y = y+3, w = 1.16, h = 0.22 },
        label = "Language",                  value = gm.SET.language or (gm.selected_lang and gm.selected_lang.key) or "auto",
        options = language_options(gm),
        lang = gm.selected_lang,             label_w = 0.92,
        value_text_scale = 0.38,             value_char_w_factor = 0.24,
        value_max_w = 1.65,                  value_text_box_w_factor = 0.78,
        value_text_inset = 0.12,             value_text_wrap = N,
        control_gap = 0.05,                  widget_dist = 0.72,
        label_box_T = { x = 0.05, y = -0.54, w = 0.88, h = 2.08 },
        control_box_T = { x = 0.9, y = 0.11, w = 2.08, h = 2.08 },
        hover_edge = N,                      shadow = N,
        fill_color = { 0, 0, 0, 0 },
        on_change = function(_gm, _, value) return _gm:_debug_apply_language(value) end,
    })
end

-----------------------------
--- install
----------------------------------
function M.install(GMgr)
--- Helper: debug apply language
function GMgr:_debug_apply_language(value)
    local old_lang = self.selected_lang
    self.SET.language = value
    if self.set_language then self:set_language() end
    refresh_live_text(self, old_lang)
    if self.debug_tools and self._debug_remake_tools then self:_debug_remake_tools() end
    return Y
end

--- Helper: debug language step
function GMgr:_debug_language_step(step)
    local SET, langs = self.SET, language_options(self);   if #langs == 0 then return end
    local cur, idx = SET.language or (self.selected_lang and self.selected_lang.key) or "auto", 1
    for i, option in ipairs(langs) do if option.value == cur then idx = i; break end end
    return self:_debug_apply_language(langs[((idx - 1 + (step or 1)) % #langs) + 1].value)
end
end

return M
