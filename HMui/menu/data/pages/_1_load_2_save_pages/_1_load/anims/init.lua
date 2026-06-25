local Tree      = require("HMEng.ui_actors.common.tree")
local AnimUtils = require("HMfns.animate.transitions.anim_utils")
local Slots     = require("HMui.menu.data.pages._1_load_2_save_pages._shared.anims.anim_slots")
local Textfx    = require("HMui.menu.data.pages._1_load_2_save_pages._shared.anims.anim_textfx")
local Arrows    = require("HMui.menu.data.pages._1_load_2_save_pages._1_load.anims.anim_arrows")
local MiniPage  = require("HMui.menu.data.pages._1_load_2_save_pages._1_load.anims.anim_mini_page")

local Y = true

local M = {}

local _queue              = "load_menu_enter"
local _region_drop_time   = 0.55
local _region_revive_time = 0.16

--- Helper: _after | ease 
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end
local function _ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _queue) end

--- Helper: _pulse_region_alpha
local function _pulse_region_alpha(gm, widget)
    local cfg = widget and widget.config;         if not cfg then return end
    cfg.page_region_alpha = 1
    _ease(gm, cfg, "page_region_alpha", 0.4, _region_drop_time, "lerp")
    _after(gm, _region_drop_time, function()
        if widget.REMOVED then return Y end
        return _ease(gm, cfg, "page_region_alpha", 1, _region_revive_time, "lerp")
    end)
end

---________________________________
--- main: enter animation
---________________________________
function M.enter(gm, panel, page, ctx)
    local root      = panel and panel.widget
    local slot_list = Tree.find_child_by_id(root, "load_slot_list"); if not slot_list then return end

    _pulse_region_alpha(gm, root)
    Slots.fade_in_slot_items(gm, slot_list)
    Textfx.fade_in_back(gm, ctx)
    Arrows.fade_in(gm, root)
    MiniPage.fade_in(gm, panel.attached_panel)
end

return M
