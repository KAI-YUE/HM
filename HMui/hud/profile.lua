local Adapter = require("HMui.hud.profile.adapter")
local Widgets = require("HMui.hud.profile.widgets")

local M = {}

M.draw_profile_masked  = Adapter.draw_profile_masked
M.attach_profile_draw  = Adapter.attach_profile_draw
M.widgets              = Widgets.widgets

return M
