local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

-- basic setting
cfg.type         = "round_rect"
cfg.renderer     = "round_rect"
cfg.round_radius = 0.4

return cfg
