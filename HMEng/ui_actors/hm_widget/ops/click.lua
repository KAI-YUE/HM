local HookRunner = require("HMEng.ui_actors.common.hooks")

local Y = true

return function(HMWidget)

-----------------------------
-- click
-----------------------------
--- Helper: _handle_overlay_menu_context
local function _handle_overlay_menu_context(self, gm)
    local cfg = self.config
    if cfg.type ~= "overlay_menu" or not cfg.hook_fn then return end

    gm.CTRL:mod_cursor_context_layer(-1)
    gm.fix_cursor_stack = Y
end

---____________________________
--- main: click
---______________________________________
function HMWidget:click()
    local cfg  = self.config;       if not cfg.button then return end
    local gm   = self.gm;           local now  = self._T.real_s

    if self.last_clicked and now <= self.last_clicked + 0.1 then return end -- avoid glitch
    if not self.states.visible or self.under_overlay or self.disable_button then return end

    if cfg.one_press then self.disable_button = Y end
    self.last_clicked = now
    if self:advance_dialogue_page() then return end

    _handle_overlay_menu_context(self, gm)
    HookRunner.run_hook(self, gm)
    gm.fix_cursor_stack = nil
end

end
