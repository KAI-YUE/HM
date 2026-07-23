local C         = require("HMfns.animate.color.color_const")
local Layout    = require("HMui.menu.data.pages._-1_title_page.strs.title_layout")
local Shared    = require("HMui.menu.data.pages._-1_title_page.shared.title_shared")

local tint_alpha    = Shared.tint_alpha
local sprite_widget = Shared.sprite_widget
local push          = table.insert

local CUI = C.UI
local ck  = C.BLACK
local ctd = CUI.TEXT_DARK

local M = {}

local _paper_letter_margin          = 0.35
local _first_letter_offset          = 0.35
local _eng_letter_w                 = 0.5
local _letter_gap   = 0.0

----------------------------------------------
--- Helper: english_letter_layout
----------------------------------------------
local english_letter_tabs = {
    [1]  = { step_w = 0.70, w = 0.50, x_offset = 0.33, y_offset = 0.0 },   -- "H"
    [2]  = { step_w = 0.70, w = 0.38, x_offset = 0.22, y_offset = 0.22 },  -- "e"
    [3]  = { step_w = 0.50, w = 0.38, x_offset = 0,    y_offset = 0.21 },  -- "n"
    [4]  = { step_w = 0.40, w = 0.29, x_offset = 0,    y_offset = 0.2 },   -- "s"
    [5]  = { step_w = 0.50, w = 0.38, x_offset = 0,    y_offset = -0.1 },  -- "h"
    [6]  = { step_w = 0.22, w = 0.14, x_offset = 0.0,  y_offset = 0.0 },   -- "i"
    [7]  = { step_w = 0.90, w = 0.38, x_offset = 0,    y_offset = 0.15 },  -- "n"

    [8]  = { step_w = 0.7,  w = 0.61, x_offset = 0,    y_offset = -0.07 }, -- "M"
    [9]  = { step_w = 0.50, w = 0.38, x_offset = 0,    y_offset = 0.13 },  -- "e"
    [10] = { step_w = 0.4,  w = 0.3,  x_offset = 0,    y_offset = 0.1 },   -- "s"
    [11] = { step_w = 0.4,  w = 0.36, x_offset = 0,    y_offset = -0.16 }, -- "h"
    [12] = { step_w = 0.4,  w = 0.14, x_offset = 0.15, y_offset = -0.04 }, -- "i"
}

--- Helper: english_letter_layout
local function english_letter_layout(i)
    local tab = english_letter_tabs[i]
    if tab then return tab.w, tab.x_offset, tab.y_offset end
    return _eng_letter_w, 0, 0.13
end

----------------------------------------------
--- main: english_letter_widgets
----------------------------------------------
function M.english_letter_widgets(out)
    local paper = Layout.english.paper
    local paper_T = { x = paper.x, y = paper.y, w = paper.w, r = paper.r }
    
    push(out, sprite_widget(paper.id, paper.atlas, paper.key, paper_T, {
        sprite_color = paper.tint,
        shadow_color = tint_alpha(ck, paper.shadow_alpha),
        widget_dist  = paper.dist,
        paint        = paper.paint,
    }))

    local x = paper.x + _paper_letter_margin + _first_letter_offset
    local y = paper.y + _paper_letter_margin
    
    for i, key in ipairs(Layout.english.letters) do
        local tab                    = english_letter_tabs[i] or {}
        local w, x_offset, y_offset  = english_letter_layout(i)
        local step_w                 = tab.step_w or 0.70
        push(out, sprite_widget("title_eng_letter_" .. i, "title_pack", key, {
            x = x + x_offset,
            y = y + y_offset,
            w = w,
            r = 0,
        }, {
            sprite_color = ctd,
            shadow_color = tint_alpha(ck, 0.22),
            widget_dist = 0.9,
        }))
        x = x + step_w + _letter_gap
    end
end

return M
