local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")
local DrawAlpha = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.draw_alpha")
local PaintRect = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.page_bg_paint_rect")

local M = {}

function M.new(policy)
    policy = policy or {}
    local FadeTree = {}

    --- set_tree_alpha
    function FadeTree.set_tree_alpha(widget, alpha)
        if not widget then return end
        if policy.before_set then policy.before_set(widget, alpha) end

        PaintRect.set_paint_rect_alpha(widget, alpha, policy.fade_paint_rect_textfx)
        PaintRect.set_paint_rect_bg_alpha(widget, alpha)
        DrawAlpha.set_draw_alpha(widget, alpha)

        if policy.set_alpha then policy.set_alpha(widget, alpha) end
        for _, child in ipairs(widget.children or {}) do FadeTree.set_tree_alpha(child, alpha) end
    end

    --- fade_tree_to
    function FadeTree.fade_tree_to(widget, gm, alpha, delay)
        if not widget then return end

        PaintRect.fade_paint_rect_child(gm, widget, alpha, delay)
        PaintRect.fade_paint_rect_bg(gm, widget, alpha, delay)
        DrawAlpha.fade_draw_alpha(gm, widget, alpha, delay)

        if policy.fade_to then policy.fade_to(widget, gm, alpha, delay) end
        for _, child in ipairs(widget.children or {}) do FadeTree.fade_tree_to(child, gm, alpha, delay) end
    end

    --- fade_tree_in
    function FadeTree.fade_tree_in(widget, gm, delay)
        if not widget or (policy.skip_fade_in and policy.skip_fade_in(widget)) then return end
        if PaintRect.paint_rect_child(widget) then
            local textfx_alpha = policy.paint_rect_textfx_alpha and policy.paint_rect_textfx_alpha(widget)
            PaintRect.fade_paint_rect_child(gm, widget, PaintRect.paint_rect_alpha(widget), delay, textfx_alpha)
        end
        if policy.before_fade_in then policy.before_fade_in(widget, gm, delay) end

        local bg = PaintRect.paint_rect_bg(widget)
        if bg then Common.ease(gm, bg, "paint_alpha", PaintRect.bg_paint_alpha(widget, bg), delay) end
        if widget.draw_alpha ~= nil then Common.ease(gm, widget, "draw_alpha", DrawAlpha.target_draw_alpha(widget), delay) end
        if policy.fade_in then policy.fade_in(widget, gm, delay) end
        for _, child in ipairs(widget.children or {}) do FadeTree.fade_tree_in(child, gm, delay) end
    end

    return FadeTree
end

return M
