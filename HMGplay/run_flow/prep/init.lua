local gm_prep     = require("HMGplay.run_flow.prep.gm")
local field_prep  = require("HMGplay.run_flow.prep.field")
local card_prep   = require("HMGplay.run_flow.prep.cards_zones")
local scene_prep  = require("HMGplay.run_flow.prep.scene")
local sky_prep    = require("HMGplay.run_flow.prep.sky")

local M = {}

for k, v in pairs(gm_prep)    do M[k] = v end
for k, v in pairs(field_prep) do M[k] = v end
for k, v in pairs(card_prep)  do M[k] = v end
for k, v in pairs(scene_prep) do M[k] = v end
for k, v in pairs(sky_prep)   do M[k] = v end

return M
