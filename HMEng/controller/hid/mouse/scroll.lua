local GameObj = require("HMEng.actors.game_obj")

local abs = math.abs

local Y, N = true, false

return function(Controller)
----------------------------------------
--- Queue scroll
----------------------------------------
--- Helper: _scroll_ready
local function _scroll_ready(self, now)
    local gate = self.scroll_gate or {}
    self.scroll_gate = gate
    if gate.active and now <= (gate.quiet_until or 0) then return N end
    gate.active = nil
    return Y
end

--- Helper: _mark_scroll_input
local function _mark_scroll_input(self, now)
    local gate = self.scroll_gate or {}
    self.scroll_gate  = gate
    gate.quiet_until  = now + 0.18
end

---________________________________________
--- main: queue_scroll
---________________________________________
function Controller:queue_scroll(x, y)
    if self:_locked() or (not x and not y) or (x == 0 and y == 0) then return end
    local now    = self._T.session_s or 0
    local ready  = _scroll_ready(self, now)
    _mark_scroll_input(self, now);                   if not ready then return end

    local _scrolled = self.scrolled
    _scrolled.x,       _scrolled.y       = x or 0, y or 0
    _scrolled.handled, _scrolled.target  = N, nil
end

-----------------------------------------
--- Handle scroll
-----------------------------------------
--- Helper: _scroll_renderer
local function _scroll_renderer(name) return name == "scrollable_discrete_entry" or name == "scrollable_continuous" end

--- Helper: _can_scroll
local function _can_scroll(node)
    local cfg = node and node.config;            if not cfg or not node.scroll then return N end
    return _scroll_renderer(cfg.renderer) or cfg.scroll_target_id
end

--- Helper: _scroll_ancestor
local function _scroll_ancestor(node) while node do if _can_scroll(node) then return node end; node = node.parent; end end

--- Helper: _raw_hit
local function _raw_hit(node, cursor_trans)
    if not _can_scroll(node) or not node.states.visible then return N end
    if node.config and node.config.scroll_target_id     then return node:hit_test(cursor_trans) end
    return GameObj.hit_test(node, cursor_trans)
end

--- Helper: _scroll_at_cursor
local function _scroll_at_cursor(self)
    local cT = self.p_cursor and self.p_cursor.T;       if not cT then return end
    for i = #(self.t_drawable or {}), 1, -1 do local node = self.t_drawable[i]; if _raw_hit(node, cT) then return node end; end
end

--- Helper: _scroll_in_tree
local function _scroll_in_tree(node, cursor_trans)
    if not node then return end
    local children = node.children or {}
    for i = #children, 1, -1 do local found = _scroll_in_tree(children[i], cursor_trans); if found then return found end; end
    if _raw_hit(node, cursor_trans) then return node end
end

--- Helper: _scroll_in_panel
local function _scroll_in_panel(panel, cursor_trans) if not panel then return end; return _scroll_in_tree(panel.widget, cursor_trans) or _scroll_in_tree(panel.attached_panel, cursor_trans); end

--- Helper: _scroll_in_active_panels
local function _scroll_in_active_panels(self)
    local cT      = self.p_cursor and self.p_cursor.T;                 if not cT     then return end
    local found   = _scroll_in_panel(self.UI.overlay_menu, cT);        if found      then return found end
    local panels  = self.R and self.R.UIPANEL;                         if not panels then return end

    for i = #panels, 1, -1 do found = _scroll_in_panel(panels[i], cT); if found then return found end end
end

--- Helper: _lock_scroll_gesture
local function _lock_scroll_gesture(self, now)
    local gate        = self.scroll_gate or {}
    self.scroll_gate  = gate
    gate.active, gate.quiet_until = Y, now + 0.18
end

--- Helper: _clear_scroll_event | _scroll_dir
local function _clear_scroll_event(scroll)  scroll.x, scroll.y, scroll.target, scroll.handled = 0, 0, nil, Y; end
local function _scroll_dir(y)               if not y or y == 0 then return end; return y < 0 and 1 or -1; end

--- Helper: _scroll_target
local function _scroll_target(self)
    local target = _scroll_ancestor(self.hovering.target) or _scroll_ancestor(self.cursor_hover.target) or _scroll_ancestor(self.focused.target)
    return target or _scroll_in_active_panels(self) or _scroll_at_cursor(self)
end

---_______________________________________
--- main: _handle_scroll
---_______________________________________
function Controller:_handle_scroll()
    local scroll, now  = self.scrolled, self._T.session_s or 0
    local sy,     mag  = scroll.y,      abs(sy or 0)

    _clear_scroll_event(scroll)
    if self:_locked() then _lock_scroll_gesture(self, now); return end

    local dir = _scroll_dir(sy); if not dir then return end

    local target = _scroll_target(self)
    scroll.target = target;     if not target then return end

    target:scroll(self, dir, mag)
    _lock_scroll_gesture(self, now)
end

end
