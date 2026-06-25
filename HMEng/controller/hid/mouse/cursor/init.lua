local push = table.insert

local Y, N = true, false

return function(Controller)
-----------------------------------------------------
--- Helpers
-----------------------------------------------------
--- Helper: clear child focus hover
local function clear_child_focus_hover(node)
    local st = node and node.states
    if st and st.focus then st.focus.is = N end
    if st and st.hover then st.hover.is = N end
    for _, child in ipairs((node and node.children) or {}) do clear_child_focus_hover(child) end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do clear_child_focus_hover(child) end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do clear_child_focus_hover(child) end
end

-----------------------------------------------------
--- Set cursor pos: Sets the current position of the cursor
-----------------------------------------------------
function Controller:set_cursor_position()
    local tsize, tscale  = self.rcfg.tile_size, self.rcfg.tile_scale
    local norm           = tsize * tscale

    if not self.HID.mouse and not self.HID.touch then return end
    self.interrupt.focus = N

    local fc  = self.focused
    local fct = fc.target
    if fct then
        clear_child_focus_hover(fct)
        fct.states.focus.is = N; fc.target = nil
    end

    local cp, c    = self.cursor_position, self.p_cursor
    local cT, cVT  = c.T, c.VT

    cp.x,  cp.y  = love.mouse.getPosition()
    cT.x,  cT.y  = cp.x/norm, cp.y/norm
    cVT.x, cVT.y = cT.x, cT.y
end

--------------------------------------------------------
-- mod_cursor_context_layer: Add or remove layers from the context for the cursor.
-------------------------------------------------------
function Controller:mod_cursor_context_layer(delta)
    local C,  ctxt         = self.p_cursor, self.cursor_context
    local CT, stack, l     = C.T, ctxt.stack, ctxt.layer
    local n,  pos,   _ifc  = self.focused.target, { x = CT.x, y = CT.y }, self.interrupt.focus

    if     delta == 1      then ctxt.layer, stack[l]    = l + 1, { node = n, cursor_pos = pos, interrupt = _ifc }
    elseif delta == -1     then stack[l],   ctxt.layer  = nil,   l - 1
    elseif delta == -1000  then ctxt.layer, ctxt.stack  = 1, { stack[1] }
    elseif delta == -2000  then ctxt.layer, ctxt.stack  = 1, {}    end
    self:navigate_focus()
end

------------------------------------------------------------
-- Snap to
------------------------------------------------------------
function Controller:snap_to(args) self.snap_cursor_to = { node = args.node, T = args.T, type = args.node and "node" or "transform" } end

--------------------------------------------------------
--- Cursor collision
--------------------------------------------------------
-- Helper: determine if the cursor is out of boundary
local function _out_bound(cursor_trans, RT, buff, tw, th)
    local ct      = cursor_trans
    local dx, dy  = ct.x - RT.x, ct.y - RT.y
    if dx > -buff or dx < tw + buff then return N end
    if dy > -buff or dy < th + buff then return N end
    return Y
end

--- Helper: field nav blocks hand node
local function _field_nav_blocks_hand_node(self, node)
    local gm = self.gm
    return self.navigate_field and gm and gm.hand and node and node.zone == gm.hand
end

--- Helper: clear hover node
local function _clear_hover_node(node)
    if not node then return end
    if node.stop_hover then node:stop_hover(); return end
    if node.states and node.states.hover then node.states.hover.is = N end
end

--__________________________________________________________________
--- Main: add drawable nodes to collision list
--__________________________________________________________________
function Controller:get_cursor_collision(cursor_trans)
    local drawable, R,     rcfg  = self.t_drawable, self._room,            self.rcfg
    local RT,       drt,   wipe  = R.T,             self.dragging.target,  self.Fs.wipe
    local tw,       th,    buff  = rcfg.tile_w,     rcfg.tile_h,           rcfg.d_buff

    self.collision_list   = wipe(self.collision_list)
    self.nodes_at_cursor  = wipe(self.nodes_at_cursor)

    if self.coyote_fcs then return end
    if drt and not _field_nav_blocks_hand_node(self, drt) then
        drt.states.collide.is = Y
        push(self.nodes_at_cursor, drt)
        push(self.collision_list, drt)
    end
    if not next(drawable) or _out_bound(cursor_trans, RT, buff, tw, th) then return end

    for i = #drawable, 1, -1 do
        local v        = drawable[i]
        local collide  = v:hit_test(cursor_trans)

        if not collide or v.REMOVED then goto continue end
        if _field_nav_blocks_hand_node(self, v) then goto continue end
        push(self.nodes_at_cursor, v)

        if not v.states.collide.can then goto continue end
        v.states.collide.is = Y
        push(self.collision_list, v)
        ::continue::
    end
end

-----------------------------------------------------
--- Set Cursor Hover
--------------------------------------------------
-- Helper: hand gamepad hover
function Controller:_handle_gamepad_hover(HID, fct, chover)
    if (HID.dpad or HID.axis_cursor) and fct.states.collide.is and not _field_nav_blocks_hand_node(self, fct) then chover.target = fct; return; end
    for _, v in ipairs(self.collision_list) do if v.states.hover.can and not _field_nav_blocks_hand_node(self, v) then chover.target = v; break end; end
end

-- Helper: general hover
function Controller:_handle_general_hover(HID, chover) for _, v in ipairs(self.collision_list) do local states = v.states; if states.hover.can and (not states.drag.is or HID.touch) and not _field_nav_blocks_hand_node(self, v) then chover.target = v; break end; end end

--_________________________________________________-
--- Main: set the cursor_hover target
--_________________________________________________
function Controller:set_cursor_hover()
    local chover, C,      dr  = self.cursor_hover, self.p_cursor, self.dragging
    local HID,    R,      fc  = self.HID,          self._room,    self.focused
    local fct,    _T, cT  = fc.target,         self._T,       C.T

    chover.T, chover.time  = chover.T or {}, _T.game_s
    local hT, locked       = chover.T, self:_locked()

    if _field_nav_blocks_hand_node(self, self.hovering.target) then _clear_hover_node(self.hovering.target); self.hovering.target = nil end
    hT.x,               hT.y           = cT.x, cT.y
    chover.prev_target, chover.target  = chover.target, nil

    if self.interrupt.focus or locked or self.CFOCUS    then chover.target = R; return; end
    if HID.controller and fct and fct.states.hover.can  then self:_handle_gamepad_hover(HID, fct, chover) else self:_handle_general_hover(HID, chover) end

    if not chover.target or (dr.target and not HID.touch) then chover.target = R end
    if chover.target ~= chover.prev_target then chover.handled = N end
end

-------------------------------------------------
--- Queue L cursor
-------------------------------------------------
function Controller:queue_L_cursor_press(x, y)
    if self:_locked() then return end
    if self.g_state == self.g_states.splash then self:key_press("escape") end
    self.L_cursor_queue = { x = x, y = y }
end

-------------------------------------------------
--- Queue R cursor
-------------------------------------------------
function Controller:queue_R_cursor_press()
    if self:_locked() then return end
    if self.cancel_hand_btn_choice and self:cancel_hand_btn_choice() then return end
    local hand, play, stop_use = self.hand, (self.play and #self.play.cards > 0), self.stop_use and self.stop_use > 0

    if self.SET.pause or not hand or not hand.highlighted[1] then return end
    if play or stop_use then return end
    hand:unhighlight_all()
end

-------------------------------------------------
--- L Cursor press
--- ---------------------------------------------
function Controller:L_cursor_press(x, y)
    if self:_locked() then return end
    if self.UI and self.UI.title_page_press_any then self.frame_buttonpress = Y; self:emit_intent("title_page_press_any"); return end

    local cpos,   cdown   = self.cursor_position, self.cursor_down
    local _T, R       = self._T,              self._room
    local chover, rcfg    = self.cursor_hover,    self.rcfg
    local tsize,  tscale  = rcfg.tile_size,       rcfg.tile_scale
    local norm,   HID     = tsize*tscale,         self.HID

    x,             y             = x or cpos.x, y or cpos.y
    cdown.T,       cdown.time    = { x = x/norm, y = y/norm }, _T.game_s
    cdown.handled, cdown.target  = N, nil
    self.is_cursor_down = Y

    local press_node = chover.target or self.hovering.target or self.focused.target
    if press_node then
        local drag_node = press_node:can_drag()
        cdown.target = press_node.states.click.can and press_node or (drag_node == Y and press_node or drag_node)
    end
    if not cdown.target then cdown.target = R end
end

-------------------------------------------------
--- L Cursor release
--- ---------------------------------------------
function Controller:L_cursor_release(x, y)
    if self:_locked() then return end

    local cpos,  cup     = self.cursor_position, self.cursor_up
    local R,     rcfg    = self._room,           self.rcfg
    local tsize, tscale  = rcfg.tile_size,       rcfg.tile_scale
    local norm,  _T  = tsize*tscale,         self._T

    x, y = x or cpos.x, y or cpos.y
    cup.T,       cup.time    = { x = x / norm, y = y / norm }, _T.game_s
    cup.handled, cup.target  = N, nil
    self.is_cursor_down = N

    cup.target = self.hovering.target or self.focused.target
    if not cup.target then cup.target = R end
end

------------------------------------------------
--- Update cursor: Updated the location of the cursor, either with a specific T or if there is a GameObj target
------------------------------------------------
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
