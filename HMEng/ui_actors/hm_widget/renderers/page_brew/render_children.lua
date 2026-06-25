local DrawOrder = require("HMEng.ui_actors.hm_widget.draw_order")

local M = {}

-----------------------------
--- main: draw
----------------------------------
function M.draw(self)
    DrawOrder.draw(self.children)
end

return M
