local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local Y, N = true, false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

-----------------------------
--- basic settings
----------------------------------
cfg.type      = "btn_container"
cfg.renderer  = "btn_container"

-----------------------------
--- hit settings
----------------------------------
cfg.button      = N
cfg.can_hover   = N
cfg.can_collide = N
cfg.can_click   = N
cfg.can_drag    = N
cfg.hit_shape   = "rect"
cfg.hit_padding = { x = 0, y = 0 }

-----------------------------
--- paint settings
----------------------------------
cfg.shadow       = N
cfg.text_overlay = N

return cfg
