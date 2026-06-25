local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

-- basic setting
cfg.type              = "paint_rect"
cfg.renderer          = "paint_rect"
cfg.text_padding      = { x = 0.2, y = 0.7 }

return cfg
