local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local Y, N = true, false

local M = {}

local _text_scale         = 0.52  -- requested label scale before fit clamps long language names
local _char_w_factor      = 0.22  -- estimated glyph width for TextFit; lower narrows layout.w
local _max_w              = 4.8   -- max estimated label width before TextFit scales text down
local _text_box_w_factor  = 1.1   -- visual text box width multiplier used for arrow placement
local _text_inset         = 0.16  -- inner text safety margin so long labels stay off arrows
local _control_gap_bias   = 0.55  -- ad-hoc language row bias to pull selector closer to label

local T_asian_font_langs = { ja = Y, ko = Y, zh_CN = Y, zh_TW = Y }

--- Helper: language_options
local function language_options(gm)
    local display_lang = Common.sab_lang(gm)
    local langs = { { key = "auto", value = "auto", label = "Auto", lang = display_lang } }
    for _, lang in pairs(gm.Langs) do if not lang.omit then langs[#langs + 1] = { key = lang.key, value = lang.key, label = lang.label, lang = display_lang } end end
    table.sort(langs, function(a, b) if a.key == "auto" then return true end; if b.key == "auto" then return false end; return (a.label or "") < (b.label or "") end)
    return langs
end

--- Helper: preview_language | language_value | set_pending_language
local function preview_language(gm)             if gm.set_language then gm:set_language() end end
local function language_value(gm)               return (gm.SET.language) or (gm.selected_lang.key) or "auto" end
local function set_pending_language(gm, value)  ControlState.set_preview(gm, "language", value, preview_language) end

--- Helper: control_gap_bias
local function control_gap_bias(gm) local lang = gm and gm.selected_lang; return T_asian_font_langs[lang and lang.key] and 0 or _control_gap_bias end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args  = Common.base_args(gm, entry)

    args.value,             args.options                  = language_value(gm), language_options(gm)
    args.value_text_scale,  args.value_char_w_factor      = _text_scale, _char_w_factor
    args.value_max_w,       args.value_text_box_w_factor  = _max_w,      _text_box_w_factor
    args.value_text_inset,  args.value_text_wrap          = _text_inset, N
    args.control_gap                                      = control_gap_bias(gm)

    args.on_change  = function(_gm, _, value) return set_pending_language(_gm, value) end
    return args
end

return M
