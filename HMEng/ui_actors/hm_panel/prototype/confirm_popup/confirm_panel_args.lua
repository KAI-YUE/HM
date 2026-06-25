local Colors  = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup.confirm_colors")
local Widgets = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup.confirm_widgets")

local Y = true

local M = {}

---____________________________
--- main: make
---______________________________________
function M.make(RT, args)
    args = args or {}
    local Rx, Ry,   Rw, Rh = RT.x,   RT.y,   RT.w,          RT.h
    local px, py,   pw     = Rx + 0.25*Rw,   Ry + 0.25*Rh,  0.4*Rw
    local bx1, bx2, by     = 0.1*Rw,         0.2*Rw,        0.24*Rh

    return {
        --- basic settings
        T = { x = px, y = py, w = pw },
        style = "rbox",                           modal_cursor_context = Y,
        quad_key = "rbox1",                       config = { instance_type = "POPUP" },

        --- mask settings
        sprite_mask_key = "rbox1-mask",           sprite_mask_offset = { x = 0, y = 0.003 },
        sprite_mask_scale = 0.96,

        --- color settings
        sprite_color = Colors.cream,              fill_color = Colors.black,
        tint = Colors.white,                      shadow_color = Colors.shadow,

        --- child_widgets
        child_widgets = Widgets.child_widgets(args, bx1, bx2, by, pw),
    }
end

return M
