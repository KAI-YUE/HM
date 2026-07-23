local C = require("HMfns.animate.color.color_const")
local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local Y, N = true, false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

-- basic setting
cfg.type              = "text_widget"
cfg.renderer          = "paint_rect"

-- hit setting
cfg.button            = N
cfg.can_hover         = N
cfg.can_collide       = N
cfg.can_click         = N
cfg.can_drag          = N

-- paint setting
cfg.paint_bg          = N
cfg.shadow            = N

-- text setting
cfg.text_overlay      = Y
cfg.text_static       = Y
cfg.text_wrap         = N
cfg.text_reveal       = N
cfg.text_color        = C.UI.TEXT_DARK
cfg.text_shadow       = N

return cfg
