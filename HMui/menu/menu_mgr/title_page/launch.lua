local HMPanel        = require("HMEng.ui_actors.hm_panel")
local TitlePageData  = require("HMui.menu.data.pages._-1_title_page.init")
local Common         = require("HMui.menu.menu_mgr.title_page.common")
local Wallpaper      = require("HMui.menu.menu_mgr.title_page.wallpaper")

local Y, N = true, false

local M = {}

-------------------------------------------------
--- Launch title page
-------------------------------------------------
--- Helper: title_page_launch_state
local function title_page_launch_state(state) return (state == "title" or state == "menu" or state == "options") and "title" or "preparation" end

--- Helper: title_page_run_launch_anim
local function title_page_run_launch_anim(gm, page)
    local fn = page.switch_anim and page.switch_anim.enter
    if type(fn) == "function" then fn(gm, gm.title_page_UI, page, {}) end
end

---_________________________________________
--- main: launch_title_page
---_________________________________________
function M.launch_title_page(gm, state)
    if gm.ensure_asset_group then gm:ensure_asset_group("title") end
    local launch_state = title_page_launch_state(state)
    local page = TitlePageData(gm, launch_state)
    local args = Common.title_page_panel_args(gm, page)

    gm.title_page_options_snapshot, gm.title_page_options_snapshot_shader = nil, nil
    gm.title_page_options_snapshot_blur_radius, gm.title_page_options_snapshot_dim_color, gm.title_page_options_snapshot_shader_time = nil, nil, nil
    Wallpaper.spawn_base(gm)
    if launch_state == "preparation" then Wallpaper.spawn_blur(gm) else Wallpaper.clear_blur(gm) end

    local gUI = gm.UI

    gUI.title_page_press_any  = launch_state == "preparation" and Y
    gUI.title_page_options    = nil
    gm.title_page_UI          = HMPanel(gm, args)
    gUI.title_page_panel      = gm.title_page_UI
    title_page_run_launch_anim(gm, page)
    Common.title_page_snap_to(gm, launch_state == "title" and "new_game" or "press_any")
    return true
end

return M
