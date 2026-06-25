local base = require("HMEng.ui_actors.hm_widget.prototype.sprite_preset.stroke.default")

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

cfg.type     = "art_page"
cfg.renderer = "art_page"
cfg.strokes  = nil
cfg.fit_axis = "none"

return cfg
