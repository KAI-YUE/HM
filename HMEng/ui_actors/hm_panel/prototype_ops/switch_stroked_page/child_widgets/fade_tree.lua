local Colors    = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.colors")
local Common    = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")
local FadeTree  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.fade_tree")

local T_alpha_color_keys = { "tint", "sprite_color", "fill_color", "shadow_color" }

local Y, N = true, false

--- Helper: _uses_draw_alpha_for_color | each_alpha_color
local function _uses_draw_alpha_for_color(widget) local cfg = widget and widget.config; return cfg and cfg.renderer == "single_sprite" and widget.draw_alpha ~= nil; end
local function _each_alpha_color(widget, fn)      if _uses_draw_alpha_for_color(widget) then return end; Colors.each_color_key(widget, T_alpha_color_keys, fn); end

--- Helper: text_alpha | set_text_alpha | fade_text_alpha
local function _text_alpha(widget)                        return widget.page_switch_text_alpha or widget.config.text_alpha end
local function _set_text_alpha(widget, alpha)             if widget.config.text_alpha == nil then return end; widget.page_switch_text_alpha = widget.page_switch_text_alpha or widget.config.text_alpha; widget.config.text_alpha = alpha end
local function _fade_text_alpha(widget, gm, alpha, delay) if widget.config.text_alpha == nil then return end; widget.page_switch_text_alpha = widget.page_switch_text_alpha or widget.config.text_alpha; Common.ease(gm, widget.config, "text_alpha", alpha, delay) end

---++++++++++++++++++++++++++++++++++++++++++++++++++
--- fade policy
local Policy = { fade_paint_rect_textfx = Y }

---____________________________
--- main: before_set
---______________________________________
function Policy.before_set(widget, alpha) if alpha == 0 and widget.config and widget.config.page_switch_wipe then widget.fx_mask, widget.fx_mask_dir = 1, widget.config.page_switch_wipe_dir or 1 end; end

---____________________________
--- main: set_alpha
---______________________________________
function Policy.set_alpha(widget, alpha)
    _set_text_alpha(widget, alpha)
    _each_alpha_color(widget, function(key) Colors.set_color_alpha(widget, key, alpha, T_alpha_color_keys) end)
end

---____________________________
--- main: fade_to
---______________________________________
function Policy.fade_to(widget, gm, alpha, delay)
    _fade_text_alpha(widget, gm, alpha, delay)
    _each_alpha_color(widget, function(key) Colors.fade_color(gm, widget, key, alpha, delay, T_alpha_color_keys) end)
end

-----------------------------
--- skip_fade_in | paint_rect_textfx_alpha | before_fade_in
----------------------------------
function Policy.skip_fade_in(widget)               return widget.page_switch_fading_out end
function Policy.paint_rect_textfx_alpha(widget)    return widget.page_switch_textfx_alpha end
function Policy.before_fade_in(widget, gm, delay)  if widget.config and widget.config.page_switch_wipe then Common.ease(gm, widget, "fx_mask", 0, delay) end; end

---____________________________
--- main: fade_in
---______________________________________
function Policy.fade_in(widget, gm, delay)
    if widget.config and widget.config.text_alpha ~= nil then Common.ease(gm, widget.config, "text_alpha", _text_alpha(widget), delay) end
    _each_alpha_color(widget, function(key)
        local alpha = Colors.target_alpha(widget, key)
        if alpha ~= nil then Colors.fade_color(gm, widget, key, alpha, delay, T_alpha_color_keys) end
    end)
end

return FadeTree.new(Policy)
