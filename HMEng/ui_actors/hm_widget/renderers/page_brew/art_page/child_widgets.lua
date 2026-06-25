local Y = true

local M = {}

--- Helper: _child_role | _new_child
local function _child_role(gm, self, item, T)
    local major = item.room_ref and gm._room_r or self
    return { role_type = "Minor", major = major, offset = { x = T.x or 0, y = T.y or 0 }, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" }
end

local function _new_child(gm, item)
    local T = item.T or {}
    if item.actor == "anim_decorator" then local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init"); return AnimDecorator(gm, T.x, T.y, T.w, T.h or T.w, item) end
    local HMWidget = require("HMEng.ui_actors.hm_widget")
    return HMWidget(gm, item)
end

-----------------------------
--- main: init
----------------------------------
function M.init(self, gm)
    local cfg    = self.config.child_widgets;       if not cfg then return end
    local items  = cfg[1] and cfg or { cfg }

    self.page_child_widgets = {}
    for _, item in ipairs(items) do
        local T       = item.T or {}
        local child   = _new_child(gm, item)
        child.parent  = self

        child:set_role(_child_role(gm, self, item, T))
        self.children[#self.children + 1] = child
        self.page_child_widgets[#self.page_child_widgets + 1] = child
    end
    return Y
end

return M
