local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local N = false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

cfg.type              = "conceptual_box"
cfg.renderer          = "conceptual_box"

cfg.button            = N
cfg.can_hover         = N
cfg.can_collide       = N
cfg.can_click         = N
cfg.can_drag          = N
cfg.shadow            = N

return cfg
