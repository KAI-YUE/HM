local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local Y = true

local M = {}

--- Helper: each_textfx
local function _each_textfx(widget, fn) for _, fx in ipairs((widget and widget.page_card_textfx) or {}) do fn(fx) end; end

--- Helper: cache_textfx_alpha
local function _cache_textfx_alpha(fx)
    local cfg = fx and fx.config;                     if not cfg then return end
    if fx.page_switch_textfx_alpha == nil then fx.page_switch_textfx_alpha = cfg.textfx_alpha == nil and 1 or cfg.textfx_alpha end
    return fx.page_switch_textfx_alpha
end

---____________________________
--- main: set_textfx
---______________________________________
function M.set_textfx(widget, alpha)
    _each_textfx(widget, function(fx)
        local cfg = fx.config;     if not cfg then return end
        _cache_textfx_alpha(fx)
        cfg.options_tab_switch_fade, cfg.textfx_alpha = Y, alpha
    end)
end

---____________________________
--- main: fade_textfx
---______________________________________
function M.fade_textfx(gm, widget, alpha, delay)
    _each_textfx(widget, function(fx)
        local cfg = fx.config;     if not cfg then return end
        _cache_textfx_alpha(fx)
        cfg.options_tab_switch_fade = Y
        Common.ease(gm, cfg, "textfx_alpha", alpha, delay)
    end)
end

---____________________________
--- main: fade_textfx_in
---______________________________________
function M.fade_textfx_in(gm, widget, delay) _each_textfx(widget, function(fx) local cfg = fx.config; if cfg then Common.ease(gm, cfg, "textfx_alpha", _cache_textfx_alpha(fx), delay) end; end); end

---____________________________
--- main: clear_textfx_switch_fade
---______________________________________
function M.clear_textfx_switch_fade(widget)
    _each_textfx(widget, function(fx) if fx.config then fx.config.options_tab_switch_fade = nil end end)
    for _, child in ipairs((widget and widget.children) or {}) do M.clear_textfx_switch_fade(child) end
end

return M
