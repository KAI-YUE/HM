local base = require("HMEng.ui_actors.hm_widget.prototype.sprite_preset.stroke.default")

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

cfg.type     = "stroked_page"
cfg.renderer = "stroked_page"
cfg.strokes  = nil

return cfg
