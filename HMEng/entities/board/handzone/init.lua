local CardZone = require("HMEng.entities.board.cardzone")
local HandZone = CardZone:extend()

local function install(mod) mod(HandZone) end
local install_list = { "ops", "align", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.handzone." .. pkg)) end

-------------------------------------------------------
-- HandZone: init & methods 
-------------------------------------------------------
function HandZone:init(gm, x, y, w, h, config)
    HandZone.super.init(self, gm, x, y, w, h, config)

    local cfg = self.config
    cfg.fan_grab_jitter_deg, cfg.fan_grab_pad  = cfg.fan_grab_jitter_deg or 0, cfg.fan_grab_pad or 0
    cfg.fan_anchor_x,        cfg.fan_anchor_y   = cfg.fan_anchor_x or cfg.fan_anchor or "left", cfg.fan_anchor_y or "top"
    cfg.fan_offset_x,        cfg.fan_offset_y   = cfg.fan_offset_x or 0, cfg.fan_offset_y or 0
    cfg.x_shift,             cfg.y_shift       = cfg.x_shift or 0, cfg.y_shift or gm.Ccfg.hand_H 

    self.fan_anchor_x_by_size,      self.fan_anchor_y_by_size   = {}, {}
    self.fan_grab_angle_jitter_deg, self.fan_grab_pad_by_index  = {}, {}
end

return HandZone
