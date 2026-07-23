local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local N = false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

cfg.type              = "scrollable_continuous"
cfg.renderer          = "scrollable_continuous"

cfg.button            = N
cfg.can_hover         = N
cfg.can_collide       = N
cfg.can_drag          = N
cfg.can_click         = N

cfg.axis              = "vertical"
cfg.item_gap          = 0
cfg.scroll_offset     = 0
cfg.scroll_speed      = 18
cfg.scroll_epsilon    = 0.001
cfg.overscan          = 1
cfg.clip_mode         = "scissor"
cfg.x_bias            = 0
cfg.y_bias            = 0
cfg.child_widgets     = {}

return cfg
