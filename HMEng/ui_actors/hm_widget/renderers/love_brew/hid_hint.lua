local Base = require("HMEng.ui_actors.hm_widget.renderers.love_brew.btn_container")

local Y, N = true, false

local M = {
    config_keys   = { "hid_action", "show_when" },
    hit_test      = Base.hit_test,
    hit_test_outer = Base.hit_test_outer,
    draw          = Base.draw,
}

--- Helper: set hint tree visibility
local function set_visible(node, visible)
    if node.states then node.states.visible = visible end
    for _, child in ipairs(node.children or {}) do set_visible(child, visible) end
end

--- Helper: current secondary action
local function current_secondary_action(self)
    local Ctrl = self.gm and self.gm.CTRL
    if not Ctrl or (self.gm.UI and self.gm.UI.modal_backdrop) then return end

    local target = Ctrl:_secondary_action_target()
    local cfg    = target and target.config
    return cfg and cfg.secondary_action
end

-----------------------------
-----------------------------
--- update hint visibility
----------------------------------
-----------------------------
function M.update(self)
    if self.config.hid_action == "controller" or self.config.show_when == "controller" then
        local Ctrl = self.gm and self.gm.CTRL
        set_visible(self, Ctrl and Ctrl.HID and Ctrl.HID.controller and Y or N)
        return
    end
    set_visible(self, current_secondary_action(self) == self.config.hid_action and Y or N)
end

return M
