local TabUtils = require("HMfns.utils.table_utils")
local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local copy = TabUtils.deep_copy

local M = {}

--- Helper: each_page_color
local function _each_page_color(widget, fn)
    local colors = widget.config and widget.config.page_colors;    if type(colors) ~= "table" then return end
    for i, color in ipairs(colors) do if type(color) == "table" then fn(i, color) end end
end

--- Helper: cache_page_color
local function _cache_page_color(widget, i, color)
    widget.page_switch_page_color_alpha = widget.page_switch_page_color_alpha or {}
    if widget.page_switch_page_color_alpha[i] == nil then widget.page_switch_page_color_alpha[i] = Common.color_alpha(color) end
    return widget.page_switch_page_color_alpha[i]
end

---____________________________
--- main: set_page_colors
---______________________________________
function M.set_page_colors(widget, alpha)
    _each_page_color(widget, function(i, color)
        local owned = copy(color)
        widget.config.page_colors[i] = owned
        _cache_page_color(widget, i, owned)
        owned[4] = alpha
    end)
end

---____________________________
--- main: fade_page_colors
---______________________________________
function M.fade_page_colors(gm, widget, alpha, delay)
    _each_page_color(widget, function(i, color)
        local owned = copy(color)
        widget.config.page_colors[i] = owned
        _cache_page_color(widget, i, owned)
        Common.ease(gm, owned, 4, alpha, delay)
    end)
end

---____________________________
--- main: fade_page_colors_in
---______________________________________
function M.fade_page_colors_in(gm, widget, delay) _each_page_color(widget, function(i, color) Common.ease(gm, color, 4, widget.page_switch_page_color_alpha and widget.page_switch_page_color_alpha[i] or Common.color_alpha(color), delay) end); end

return M
