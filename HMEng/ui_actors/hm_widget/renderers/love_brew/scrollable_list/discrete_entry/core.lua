local Slot       = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.slot")
local Placement  = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.placement")
local SlideBar   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.slide_bar")
local Transition = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.transition_fx")

local M = {}

-----------------------------
--- Compatibility aggregator
----------------------------------
for _, mod in ipairs({ Slot, Placement, SlideBar, Transition }) do for k, v in pairs(mod) do M[k] = v end; end

return M
