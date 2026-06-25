local Items      = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.items")
local Slot       = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.slot")
local Placement  = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.placement")
local SlideBar   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.slide_bar")
local Transition = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.transition_fx")

local M = {}

-----------------------------
--- Compatibility aggregator
----------------------------------
for _, mod in ipairs({ Items, Slot, Placement, SlideBar, Transition }) do for k, v in pairs(mod) do M[k] = v end; end

return M
