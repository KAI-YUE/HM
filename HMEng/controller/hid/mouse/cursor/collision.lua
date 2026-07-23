local Common = require("HMEng.controller.hid.mouse.cursor.common")

local push = table.insert
local N = false

local M = {}

--- Helper: out bound
local function _out_bound(cursor_trans, RT, buff, tw, th)
    local ct, dx, dy = cursor_trans, cursor_trans.x - RT.x, cursor_trans.y - RT.y
    if dx > -buff or dx < tw + buff then return N end
    if dy > -buff or dy < th + buff then return N end
    return true
end

---____________________________
--- main: install
---______________________________________
function M.install(Controller)
    function Controller:get_cursor_collision(cursor_trans)
        local drawable, R,     rcfg  = self.t_drawable, self._room,            self.rcfg
        local RT,       drt,   wipe  = R.T,             self.dragging.target,  self.Fs.wipe
        local tw,       th,    buff  = rcfg.tile_w,     rcfg.tile_h,           rcfg.d_buff

        self.collision_list   = wipe(self.collision_list)
        self.nodes_at_cursor  = wipe(self.nodes_at_cursor)

        if self.coyote_fcs then return end
        if drt and Common.modal_cursor_allows_node(self, drt) and not Common.field_nav_blocks_hand_node(self, drt) and Common.gamepad_scope_allows_node(self, drt) then
            drt.states.collide.is = true
            push(self.nodes_at_cursor, drt); push(self.collision_list, drt)
        end
        if not next(drawable) or _out_bound(cursor_trans, RT, buff, tw, th) then return end

        for i = #drawable, 1, -1 do
            local v        = drawable[i]
            local collide  = v:hit_test(cursor_trans)
            if not collide or v.REMOVED then goto continue end
            if not Common.modal_cursor_allows_node(self, v) then goto continue end
            if Common.field_nav_blocks_hand_node(self, v) then goto continue end
            if not Common.gamepad_scope_allows_node(self, v) then goto continue end
            push(self.nodes_at_cursor, v)

            if not v.states.collide.can then goto continue end
            v.states.collide.is = true
            push(self.collision_list, v)
            ::continue::
        end
    end
end

return M
