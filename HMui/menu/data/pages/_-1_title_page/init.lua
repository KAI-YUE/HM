local C          = require("HMfns.animate.color.color_const")
local PrepEnter  = require("HMui.menu.data.pages._-1_title_page.anims.preparation_enter")
local TitlePress = require("HMui.menu.data.pages._-1_title_page.anims.title_press")
local TitleArt   = require("HMui.menu.data.pages._-1_title_page.strs.title_kanji")
local TitleBtns  = require("HMui.menu.data.pages._-1_title_page.title_btns")
local Preparation = require("HMui.menu.data.pages._-1_title_page.preparation")

local CUI    = C.UI
local ctl    = CUI.TEXT_LIGHT

local Y, N = true, false

local M = {}

local preparation_states = { press = Y, preparation = Y, prep = Y }
local title_states       = { title = Y, menu = Y, options = Y }

--- Helper: normalize_state
local function normalize_state(state)
    if title_states[state]       then return "title" end
    if preparation_states[state] then return "preparation" end
    return "preparation"
end

--- Helper: append_widgets
local function append_widgets(dst, src)
    for _, item in ipairs(src or {}) do dst[#dst + 1] = item end
    return dst
end

--- Helper: base_page
local function base_page(opts)
    return {
        --- basics 
        style    = "art_page",                  widget_style = "art_page",
        fit_axis = "none",

        --- color settings
        shadow = N,                             widget_dist = 2,

        --- descriptions (text basics)
        i18n_type    = "menu",                  text        = "",
        text_color   = ctl,                     text_scale  = 0.62,
        text_shadow  = N,                       text_wrap   = Y,
        text_reveal  = Y,                       text_reveal_rate = 45,

        --- text alignments
        text_padding  = { x = 0, y = 0 },       text_box_T  = { x = 0, y = 0, w = 0, h = 0 },
        text_maxw     = 6,                      text_align  = { x = "middle", y = "top" },
        text_offset   = { x = 0, y = 0 },

        child_widgets = TitleArt.child_widgets(opts),
    }
end

--- Helper: preparation_page | title_page| page
function M.preparation_page(gm)  local out = base_page(); out.switch_anim = { enter = PrepEnter.enter }; append_widgets(out.child_widgets, Preparation.preparation_widgets(gm)); return out end
function M.title_page(gm)        local out = base_page({ press_decorators = Y, title_stage = Y }); out.switch_anim = { enter = TitlePress.enter }; append_widgets(out.child_widgets, TitleBtns.title_menu_widgets(gm)); return out end
function M.page(gm, state)       if normalize_state(state) == "title" then return M.title_page(gm) end; return M.preparation_page(gm); end

return M.page
