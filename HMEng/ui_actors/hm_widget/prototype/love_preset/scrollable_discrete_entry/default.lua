local base = require("HMEng.ui_actors.hm_widget.prototype.love_preset.base")

local N = false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

cfg.type              = "scrollable_discrete_entry"
cfg.renderer          = "scrollable_discrete_entry"

cfg.button            = N
cfg.can_hover         = N
cfg.can_collide       = N
cfg.can_drag          = N
cfg.can_click         = N

cfg.axis              = "vertical"
cfg.page_start        = 1
cfg.visible_count     = 4
cfg.page_step         = 4
cfg.item_gap          = 0
cfg.x_bias            = 0
cfg.y_bias            = 0
cfg.loop              = N
cfg.child_widgets     = {}

return cfg
