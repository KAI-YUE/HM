local Colors      = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.colors")
local FadeTree    = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.fade_tree")
local PageColors  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.attached_panel.page_colors")
local TextFxAlpha = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.attached_panel.textfx_alpha")

local T_widget_color_keys = { "tint", "sprite_color", "fill_color", "stroke_color", "shadow_color" }

--- Helper: each_widget_color
local function _each_widget_color(widget, fn) Colors.each_color_key(widget, T_widget_color_keys, fn) end

---++++++++++++++++++++++++++++++++++++++++++++++++++
--- fade policy
local Policy = {}

---____________________________
--- main: set_alpha
---______________________________________
function Policy.set_alpha(widget, alpha)
    _each_widget_color(widget, function(key) Colors.set_color_alpha(widget, key, alpha) end)
    PageColors.set_page_colors(widget, alpha)
    TextFxAlpha.set_textfx(widget, alpha)
end

---____________________________
--- main: fade_to
---______________________________________
function Policy.fade_to(widget, gm, alpha, delay)
    _each_widget_color(widget, function(key) Colors.fade_color(gm, widget, key, alpha, delay) end)
    PageColors.fade_page_colors(gm, widget, alpha, delay)
    TextFxAlpha.fade_textfx(gm, widget, alpha, delay)
end

---____________________________
--- main: fade_in
---______________________________________
function Policy.fade_in(widget, gm, delay)
    _each_widget_color(widget, function(key) Colors.fade_color(gm, widget, key, Colors.target_alpha(widget, key), delay) end)
    PageColors.fade_page_colors_in(gm, widget, delay)
    TextFxAlpha.fade_textfx_in(gm, widget, delay)
end

local Shared = FadeTree.new(Policy)
local M = {}

-----------------------------
--- set_tree_alpha | fade_tree_to | fade_tree_in
----------------------------------
function M.set_tree_alpha(widget, alpha) Shared.set_tree_alpha(widget, alpha) end
function M.fade_tree_to(gm, widget, alpha, delay) Shared.fade_tree_to(widget, gm, alpha, delay) end
function M.fade_tree_in(gm, widget, delay) Shared.fade_tree_in(widget, gm, delay) end

---____________________________
--- main: clear_textfx_switch_fade
---______________________________________
function M.clear_textfx_switch_fade(widget) TextFxAlpha.clear_textfx_switch_fade(widget) end

return M
