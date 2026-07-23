local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local M = {}

---____________________________
--- main: cache_alpha
---______________________________________
function M.cache_alpha(widget, key)
    widget.page_switch_alpha = widget.page_switch_alpha or {}
    if widget.page_switch_alpha[key] == nil then widget.page_switch_alpha[key] = Common.color_alpha(widget.config[key]) end
    return widget.page_switch_alpha[key]
end

---____________________________
--- main: own_color
---______________________________________
function M.own_color(widget, key, keys)
    local cfg   = widget and widget.config
    local color = cfg and cfg[key];                    if type(color) ~= "table" then return end
    local owned = {}
    for k, v in pairs(color) do owned[k] = v end

    keys = keys or { key }
    for _, other_key in ipairs(keys) do
        if cfg[other_key] == color then
            M.cache_alpha(widget, other_key)
            cfg[other_key] = owned
        end
    end
    return owned
end

---____________________________
--- main: set_color_alpha
---______________________________________
function M.set_color_alpha(widget, key, alpha, keys)
    local color = M.own_color(widget, key, keys);       if not color then return end
    color[4] = alpha
end

---____________________________
--- main: fade_color
---______________________________________
function M.fade_color(gm, widget, key, alpha, delay, keys)
    local color = M.own_color(widget, key, keys);       if not color then return end
    Common.ease(gm, color, 4, alpha, delay)
end

---____________________________
--- main: target_alpha
---______________________________________
function M.target_alpha(widget, key) return widget.page_switch_alpha and widget.page_switch_alpha[key] or Common.color_alpha(widget.config[key]) end

---____________________________
--- main: each_color_key
---______________________________________
function M.each_color_key(widget, keys, fn)
    local seen, ordered = {}, {}
    for _, key in ipairs(keys or {}) do
        local color = widget.config and widget.config[key]
        if type(color) == "table" and not seen[color] then
            seen[color] = true
            ordered[#ordered + 1] = key
        end
    end
    for _, key in ipairs(ordered) do fn(key) end
end

return M
