local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local Y = true

local M = {}

---____________________________
--- main: paint_rect_child
---______________________________________
function M.paint_rect_child(widget)
    local cfg = widget and widget.config
    return cfg and (cfg.renderer == "paint_rect" or cfg.paint_rect_renderer)
end

---____________________________
--- main: paint_rect_bg
---______________________________________
function M.paint_rect_bg(widget)
    local cfg  = widget and widget.config;       if not cfg then return end
    local bg   = cfg.sprite_bg or cfg.bg
    if bg and (bg.renderer == "paint_rect" or bg.paint) then return bg end
end

---____________________________
--- main: paint_rect_alpha
---______________________________________
function M.paint_rect_alpha(widget)
    if widget.page_switch_paint_alpha ~= nil then return widget.page_switch_paint_alpha end
    local cfg = widget.config
    return cfg.paint_alpha == nil and 1 or cfg.paint_alpha
end

---____________________________
--- main: bg_paint_alpha
---______________________________________
function M.bg_paint_alpha(widget, bg)
    widget.page_switch_bg_paint_alpha = widget.page_switch_bg_paint_alpha or {}
    if widget.page_switch_bg_paint_alpha[bg] == nil then widget.page_switch_bg_paint_alpha[bg] = bg.paint_alpha == nil and 1 or bg.paint_alpha end
    return widget.page_switch_bg_paint_alpha[bg]
end

---____________________________
--- main: each_paint_rect_textfx
---______________________________________
function M.each_paint_rect_textfx(widget, fn)
    local seen = {}
    local function visit(fx)
        if not fx or seen[fx] then return end
        seen[fx] = Y
        fn(fx)
    end
    visit(widget and widget.paint_rect_textfx)
    for _, fx in ipairs((widget and widget.paint_rect_textfxs) or {}) do visit(fx) end
end

---____________________________
--- main: set_paint_rect_alpha
---______________________________________
function M.set_paint_rect_alpha(widget, alpha, fade_textfx)
    if not M.paint_rect_child(widget) then return end
    local cfg = widget.config
    if widget.page_switch_paint_alpha == nil then widget.page_switch_paint_alpha = cfg.paint_alpha == nil and 1 or cfg.paint_alpha end
    if not fade_textfx then cfg.paint_alpha = alpha; return end

    widget.page_switch_textfx_alpha = widget.page_switch_textfx_alpha or {}
    M.each_paint_rect_textfx(widget, function(fx)
        local fxcfg = fx.config;     if not fxcfg then return end
        if widget.page_switch_textfx_alpha[fx] == nil then widget.page_switch_textfx_alpha[fx] = fxcfg.textfx_alpha == nil and widget.page_switch_paint_alpha or fxcfg.textfx_alpha end
        fxcfg.textfx_alpha = alpha
    end)

    cfg.paint_alpha = alpha
end

---____________________________
--- main: fade_paint_rect_child
---______________________________________
function M.fade_paint_rect_child(gm, widget, alpha, delay, textfx_alpha)
    if not M.paint_rect_child(widget) then return end
    if widget.page_switch_paint_alpha == nil then widget.page_switch_paint_alpha = widget.config.paint_alpha == nil and 1 or widget.config.paint_alpha end
    Common.ease(gm, widget.config, "paint_alpha", alpha, delay)
    M.each_paint_rect_textfx(widget, function(fx)
        if fx.config then Common.ease(gm, fx.config, "textfx_alpha", (type(textfx_alpha) == "table" and textfx_alpha[fx]) or textfx_alpha or alpha, delay) end
    end)
end

---____________________________
--- main: set_paint_rect_bg_alpha
---______________________________________
function M.set_paint_rect_bg_alpha(widget, alpha)
    local bg = M.paint_rect_bg(widget);          if not bg then return end
    M.bg_paint_alpha(widget, bg)
    bg.paint_alpha = alpha
end

---____________________________
--- main: fade_paint_rect_bg
---______________________________________
function M.fade_paint_rect_bg(gm, widget, alpha, delay)
    local bg = M.paint_rect_bg(widget);          if not bg then return end
    M.bg_paint_alpha(widget, bg)
    Common.ease(gm, bg, "paint_alpha", alpha, delay)
end

return M
