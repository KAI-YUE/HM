local Common = require("HMEng.controller.hid.mouse.cursor.common")

local M = {}

---____________________________
--- main: install
---______________________________________
function M.install(Controller)
    function Controller:set_cursor_position()
        local tsize, tscale  = self.rcfg.tile_size, self.rcfg.tile_scale
        local norm           = tsize * tscale
        if not self.HID.mouse and not self.HID.touch then return end
        self.interrupt.focus = false

        local fc, cp, c = self.focused, self.cursor_position, self.p_cursor
        local fct = fc.target
        if fct then Common.clear_child_focus_hover(fct); fct.states.focus.is = false; fc.target = nil end

        local cT, cVT = c.T, c.VT
        cp.x,  cp.y  = love.mouse.getPosition()
        cT.x,  cT.y  = cp.x/norm, cp.y/norm
        cVT.x, cVT.y = cT.x, cT.y
    end

    function Controller:mod_cursor_context_layer(delta)
        local C,  ctxt         = self.p_cursor, self.cursor_context
        local CT, stack, l     = C.T, ctxt.stack, ctxt.layer
        local n,  pos,   _ifc  = self.focused.target, { x = CT.x, y = CT.y }, self.interrupt.focus

        if     delta == 1      then ctxt.layer, stack[l]    = l + 1, { node = n, cursor_pos = pos, interrupt = _ifc }
        elseif delta == -1     then stack[l],   ctxt.layer  = nil,   l - 1
        elseif delta == -1000  then ctxt.layer, ctxt.stack  = 1, { stack[1] }
        elseif delta == -2000  then ctxt.layer, ctxt.stack  = 1, {} end
        self:navigate_focus()
    end

    function Controller:snap_to(args) self.snap_cursor_to = { node = args.node, T = args.T, type = args.node and "node" or "transform" } end

    function Controller:update_cursor(hard_set_T)
        local C,  cpos  = self.p_cursor, self.cursor_position
        local CT, CVT   = C.T, C.VT
        local ft, rcfg  = self.focused.target, self.rcfg
        local norm      = rcfg.tile_size*rcfg.tile_scale

        if hard_set_T then
            CT.x,   CT.y    = hard_set_T.x, hard_set_T.y
            cpos.x, cpos.y  = CT.x*norm,    CT.y*norm
            CVT.x,  CVT.y   = CT.x,         CT.y
            return
        end
        if ft then
            cpos.x, cpos.y  = ft:put_focused_cursor()
            CT.x,   CT.y    = cpos.x/norm, cpos.y/norm
            CVT.x,  CVT.y   = CT.x, CT.y
        end
    end
end

return M
