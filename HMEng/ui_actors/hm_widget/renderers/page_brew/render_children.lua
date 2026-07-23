local DrawOrder = require("HMEng.ui_actors.hm_widget.draw_order")

local M = {}

-----------------------------
--- main: draw
----------------------------------
local function _layer_child(child, layer)
    local child_layer = child and child.config and child.config.page_draw_layer
    if layer then return child_layer == layer end
    return child_layer ~= "overlay" and child_layer ~= "under_stroke"
end

function M.draw(self, layer)
    local list = {}
    for _, child in ipairs(self.children or {}) do if _layer_child(child, layer) then list[#list + 1] = child end end
    DrawOrder.draw(list)
end

return M
