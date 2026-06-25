local shared = require("HMEng.controller.update.shared")
local xf_dist = require("HMfns.utils.math.math_utils").xf_dist

local Y, N = true, false

return function(Controller)
-----------------------------------------------------------
--- Dialogue helpers
-----------------------------------------------------------
function Controller:_modal_dialogue_widget(gm)
    local R = gm.R;            if not R then return end
    local panels = R.UIPANEL;  if not panels then return end

    for i = #panels, 1, -1 do
        local panel  = panels[i]
        local widget = panel and panel.widget
        local cfg    = widget and widget.config
        if panel and widget and cfg.type == "dialogue_box" and panel.modal_cursor_context and panel.states.visible and widget.states.visible then return widget; end
    end
end

-----------------------------------------------------------
--- handle dialogue click-through
-----------------------------------------------------------
local function _is_click_release(self)
    local cdT, cuT = self.cursor_down.T, self.cursor_up.T; if not cdT or not cuT then return N end
    return xf_dist(cdT, cuT) < self.min_cdist
end

-----------------------------------------------------------
--- Main: _handle_dialogue_advance
-----------------------------------------------------------
function Controller:_handle_dialogue_advance(gm)
    if not _is_click_release(self) then return N end

    local widget = self:_modal_dialogue_widget(gm);    if not widget then return N end
    widget:advance_dialogue_page()
    return Y
end

-----------------------------------------------------------
--- handle cursor down/up, including modal dialogue ownership
-----------------------------------------------------------
function Controller:_handle_cursor_press_release(gm)
    local c,   cdown      = self.clicked, self.cursor_down
    local had_cursor_up   = not self.cursor_up.handled
    local modal_dialogue  = self:_modal_dialogue_widget(gm)

    if modal_dialogue then cdown.handled, cdown.target = Y, nil end

    if modal_dialogue and had_cursor_up then
        self.cursor_up.handled = Y
        if self:_handle_dialogue_advance(gm) then c.handled = Y end
        return
    end

    if not self.cursor_down.handled then self:_handle_cursor_down() end
    if not self.cursor_up.handled   then self:_handle_cursor_up() end
end

end
