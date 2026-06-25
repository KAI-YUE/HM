local Y = true

local M = {}

---____________________________
--- main: button_hook
---______________________________________
function M.button_hook(on_click) return function(gm, widget) if on_click then on_click(gm, widget, Y) end; return Y end end

return M
