local shared   = require("HMEng.controller.update.shared")
local Card     = require("HMEng.entities.card")
local Pawn     = require("HMEng.entities.pawn")
local xf_dist  = require("HMfns.utils.math.math_utils").xf_dist

local enqueue_after = shared.enqueue_after

local Y, N = true, false

return function(Controller)
-----------------------------
--- wake layout
----------------------------
--- Helper: wake zone layout
local function _wake_zone_layout(node)
    local zone = node and node.zone
    if node and node.is and node:is(Pawn) and zone and zone.config and zone.config.type == "field" then return end
    if node and node.is and node:is(Pawn) and zone and zone.mark_pawn_layout_dirty then zone:mark_pawn_layout_dirty(); return end
    if zone and zone.mark_card_layout_dirty then zone:mark_card_layout_dirty() end
end

-----------------------------------------------------------
--- handle controller input
-----------------------------------------------------------
--- Helper: handle cursor context stack
local function _handle_cursor_context_stack(self, stack, layer, inter)
    local _context = stack[layer]
    local n        = _context.node
    local _n, _T   = n and not n.REMOVED and n, _context.cursor_pos

    self:snap_to({ node = _n, T = _T })
    inter.stack, stack[layer] = _context.interrupt, nil
end

---____________________________________________________
--- main: _handle_controller
---____________________________________________________
function Controller:_handle_controller()
    local ccontext      = self.cursor_context
    local stack, layer  = ccontext.stack, ccontext.layer
    local inter, dr     = self.interrupt, self.dragging

    if stack[layer] then _handle_cursor_context_stack(self, stack, layer, inter) end

    local _p, _t = dr.prev_target, dr.target
    if _p and not _t and _p.is(Card) and not _p.REMOVED and (not self.field_scope_allows_node or self:field_scope_allows_node(_p)) then if not self.coyote_fcs then self:snap_to({ node = dr.prev_target }) else self.coyote_fcs = nil end; end

    local snap, f, snode = self.snap_cursor_to, self.focused, nil; if not snap then return end

    inter.focus, inter.stack, snode = self.interrupt.stack, N, snap.node
    if     snap.type == "node" and not snode.REMOVED and (not self.field_scope_allows_node or self:field_scope_allows_node(snode)) then f.prev_target, f.target = f.target, snode; self:update_cursor()
    elseif snap.type == "transform"                  then self:update_cursor(snap.T) end

    if f.prev_target ~= f.target and f.prev_target then f.prev_target.states.focus.is = N; _wake_zone_layout(f.prev_target) end
    if f.prev_target ~= f.target then _wake_zone_layout(f.target) end
    self.snap_cursor_to = nil
end

-----------------------------------------------------------
--- handle cursor down
-----------------------------------------------------------
function Controller:_handle_cursor_down()
    local dr, cdown  = self.dragging, self.cursor_down
    local ct       = cdown.target
    local drag     = ct.states.drag
    cdown.handled  = Y

    if not drag.can then return end
    drag.is = Y
    _wake_zone_layout(ct)
    ct:set_offset(cdown.T, "Click")
    dr.target, dr.handled = ct, Y
end

--- Helper: handle cursor up
local function _clear_drag_target(drt, dr) drt:stop_drag(); drt.states.drag.is = N; _wake_zone_layout(drt); dr.target = nil; end

-----------------------------------------------------------
--- handle cursor up
-----------------------------------------------------------
function Controller:_handle_cursor_up()
    local dr = self.dragging
    local drt, cdown, cup = dr.target,    self.cursor_down, self.cursor_up
    local cdt, cut,   sf  = cdown.target, cup.target,       self.SET.sf
    
    cup.handled = Y
    if drt then _clear_drag_target(drt, dr) end
    if not cdt then return end

    local timeout   = cdt.click_timeout
    local _dt, _ut  = cdown.time, cup.time
    local cdT, cuT  = cdown.T, cup.T

    if timeout and (_ut and _dt) and (timeout * sf <= _ut - _dt) then return end

    local cl, ro = self.clicked, self.released_on
    if xf_dist(cdT, cuT) < self.min_cdist                        then if not cdt.states.click.can then return end; cl.target, cl.handled = cdt, N
    elseif dr.prev_target and cut and cut.states.release_on.can  then ro.target, ro.handled = cut, N end
end

-----------------------------------------------------------
--- handle cursor hover
-----------------------------------------------------------
--- Helper: hover target conditions | should clear hover target | _clear_hover_target
local function _can_set_hover_target(chtarget, HID, is_cursor_down)               return chtarget and chtarget.states.hover.can and (not HID.touch or is_cursor_down) end
local function _should_clear_hover_target(chtarget, htarget, HID, is_cursor_down) return htarget and not _can_set_hover_target(chtarget, HID, is_cursor_down) end
local function _clear_hover_target(h) local ht = h.target; if not ht then return end; ht.states.hover.is = N; _wake_zone_layout(ht); h.target = nil end

--- Helper: _set_hover_target
local function _set_hover_target(h, ch)
    local chtarget = ch.target
    local hpt      = h.prev_target

    h.target = chtarget
    if hpt and hpt ~= chtarget then hpt.states.hover.is = N; _wake_zone_layout(hpt) end
    chtarget.states.hover.is = Y
    _wake_zone_layout(chtarget)
    chtarget:set_offset(ch.T, "Hover")
end

---____________________________________________________
--- main: handle cursor hover 
---____________________________________________________
function Controller:_handle_cursor_hover()
    local h,   ch,   HID   = self.hovering, self.cursor_hover, self.HID
    local chtarget, cdown  = ch.target, self.is_cursor_down

    if     _can_set_hover_target(chtarget, HID, cdown)                then _set_hover_target(h, ch)
    elseif _should_clear_hover_target(chtarget, h.target, HID, cdown) then _clear_hover_target(h) end
end

-----------------------------------------------------------
--- handle hover target
-----------------------------------------------------------
--- Helper: _hover_target_now
local function _hover_target_now(ht, hpt, dt, gm) if ht ~= dt then ht:hover(gm) end; if hpt then hpt:stop_hover() end end

function Controller:_handle_hover_target(gm)
    local h, dr, ch, HID  = self.hovering, self.dragging, self.cursor_hover, self.HID
    local ht,  hpt,  dt   = h.target,      h.prev_target, dr.target

    ht:set_offset(ch.T, "Hover");          if hpt == ht then return end

    if not HID.touch then _hover_target_now(ht, hpt, dt, gm); return; end

    local _ID = ht.ID
    enqueue_after(gm.E_MANAGER, self.min_ht, function() if ht and _ID == ht.ID then ht:hover() end; return Y; end, { blocking = N })
    if hpt then hpt:stop_hover() end
end

-----------------------------------------------------------
--- handle release on
-----------------------------------------------------------
function Controller:_handle_release_on()
    local h,  dr  = self.hovering, self.dragging
    local ht, ro  = h.target, self.released_on

    if dr.prev_target == ht then ht:stop_hover(); h.target = nil end
    ro.target:release(dr.prev_target)
    ro.handled = Y
end

end
