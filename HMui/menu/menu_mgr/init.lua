local EscapeMenu   = require("HMui.menu.menu_mgr.escape")
local SaveLoadMenu = require("HMui.menu.menu_mgr.save_load")
local TitlePage     = require("HMui.menu.menu_mgr.title_page")
local TitleMenu    = require("HMui.menu.menu_mgr.title")
local QuickResume  = require("HMui.menu.menu_mgr.quick_resume")

local M = {}

--- Helper: export_menu_fns
local function export_menu_fns(src) for k, v in pairs(src) do M[k] = v end end

export_menu_fns(EscapeMenu)
export_menu_fns(SaveLoadMenu)
export_menu_fns(TitlePage)
export_menu_fns(TitleMenu)
export_menu_fns(QuickResume)

return M
