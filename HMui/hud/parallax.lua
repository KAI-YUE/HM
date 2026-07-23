local Theme = require("HMui.hud.cfg_data.theme")

local M = {}

local PANEL = Theme.panel or {}

-----------------------------
--- HUD parallax
----------------------------
--- Helper: set HUD parallax
local function _set_hud_parallax(child, sp)
    if not (child and sp) then return end
    child.hud_shadow_parallax = { x = sp.x or 0, y = sp.y or -1.15 }
    child.calculate_parallax  = function(self)
        local hsp = self.hud_shadow_parallax or {}
        self.shadow_parallax.x, self.shadow_parallax.y = hsp.x or 0, hsp.y or -1.15
    end
    child:calculate_parallax()
end

---______________________________
--- main: apply panel
---______________________________
function M.apply_panel(panel)
    local sp = PANEL.shadow_parallax; if not sp then return end
    for _, child in ipairs((panel.widget and panel.widget.children) or {}) do if child.config and child.config.id == "hud_panel_pass" then _set_hud_parallax(child, sp) end end
end

return M
