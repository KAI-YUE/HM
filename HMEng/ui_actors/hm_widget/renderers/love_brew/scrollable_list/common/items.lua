local TabUtils = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy

local M = {}

-----------------------------
--- item definitions
-----------------------------
function M.definitions(cfg)
    local items = cfg.child_widgets
    if not items then return {} end
    if not items[1] and not (items.style or items.renderer or items.T) then return {} end
    return items[1] and items or { items }
end

-----------------------------
--- item tree
-----------------------------
function M.set_clip_parent(child, parent)
    child.scrollable_clip_parent = parent
    for _, sub in ipairs(child.children or {}) do M.set_clip_parent(sub, parent) end
end

-----------------------------
--- item initialization
-----------------------------
local function _init_child(self, gm, item, clipped)
    local HMWidget   = require("HMEng.ui_actors.hm_widget")
    local child_args = copy(item)
    local T          = child_args.T or {}

    child_args.T = copy(T)
    local child  = HMWidget(gm, child_args)

    child.parent = self
    child.scrollable_item_base = { x = T.x or 0, y = T.y or 0, w = T.w or child.T.w, h = T.h or child.T.h }
    child.scrollable_item_disabled = child.disable_button
    if clipped then M.set_clip_parent(child, self) end

    child:set_role({
        role_type  = "Minor",       offset  = { x = T.x or 0, y = T.y or 0 },
        major      = self,           xy_bond = "Strong",
        wh_bond    = "Strong",      r_bond  = "Strong",
        scale_bond = "Strong",
    })

    self.children[#self.children + 1] = child
    self.scrollable_items[#self.scrollable_items + 1] = child
    return child
end

function M.init(self, gm, opts)
    self.scrollable_items = {}
    for _, item in ipairs(M.definitions(self.config)) do
        local child = _init_child(self, gm, item, opts and opts.clipped)
        if opts and opts.slot_fx then child.fx_mask, child.fx_mask_dir = child.fx_mask or 0, child.fx_mask_dir or 1 end
    end
end

return M
