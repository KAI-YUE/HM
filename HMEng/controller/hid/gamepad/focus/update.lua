local Card = require("HMEng.entities.card")
local Pawn = require("HMEng.entities.pawn")

local push = table.insert
local abs, floor = math.abs, math.floor
local max, min   = math.max, math.min

local TITLE_FOCUS_IDS = { "new_game", "continue", "options", "quit", "press_any", "back" }
local PAUSE_FOCUS_IDS = { "continue", "load", "save", "options", "return_title" }

local Y, N = true, false

return function(Controller)
-----------------------------
--- Wake layout
----------------------------
--- Helper: wake zone layout
local function _wake_zone_layout(node)
    local zone = node and node.zone
    if node and node.is and node:is(Pawn) and zone and zone.config and zone.config.type == "field" then return end
    if node and node.is and node:is(Pawn) and zone and zone.mark_pawn_layout_dirty then zone:mark_pawn_layout_dirty(); return end
    if zone and zone.mark_card_layout_dirty then zone:mark_card_layout_dirty() end
end

--- Helper: active icon button
local function _active_icon_btn(node)
    local cfg = node and node.config
    local st = node and node.states
    return cfg and cfg.type == "icon_btn" and cfg.button and cfg.can_hover ~= N and not node.REMOVED and not node.disable_button and (not st or st.visible ~= N)
end

--- Helper: first active node
local function _first_active_node(self, node, prefer_icon)
    if node and ((prefer_icon and _active_icon_btn(node)) or ((not prefer_icon) and self:is_focusable(node))) then return node end
    for _, child in ipairs((node and node.children) or {}) do local found = _first_active_node(self, child, prefer_icon); if found then return found end end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do local found = _first_active_node(self, child, prefer_icon); if found then return found end end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do local found = _first_active_node(self, child, prefer_icon); if found then return found end end
end

--- Helper: find node by id
local function _find_node_by_id(node, id)
    local cfg = node and node.config
    if cfg and (cfg.id == id or cfg.key == id) then return node end
    for _, child in ipairs((node and node.children) or {}) do local found = _find_node_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do local found = _find_node_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do local found = _find_node_by_id(child, id); if found then return found end end
end

--- Helper: find panel node by id
local function _find_panel_node_by_id(panel, id)
    if not panel then return end
    return _find_node_by_id(panel.widget, id) or _find_node_by_id(panel.attached_panel, id)
end

--- Helper: clear child hover
local function _clear_child_hover(node)
    local st = node and node.states
    local hst = st and st.hover
    if hst then if hst.is and node.stop_hover then node:stop_hover() else hst.is = N end end
    local fst = st and st.focus;                                      if fst then fst.is = N end
    for _, child in ipairs((node and node.children) or {}) do _clear_child_hover(child) end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do _clear_child_hover(child) end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do _clear_child_hover(child) end
end

--- Helper: apply row focus fx
local function _apply_row_focus_fx(node)
    local args = node and node.config and node.config.focus_args;    if not (args and args.type == "slider_row") then return end
    local knob = _find_node_by_id(node, args.knob_id);               if not knob then return end
    local st = knob.states;                                          if st and st.focus then st.focus.can, st.focus.is = Y, Y end
    knob.last_hovered = nil
    if knob.hover then knob:hover() end
end

--- Helper: apply hand card focus hover
local function _apply_hand_card_focus_hover(self, node)
    local gm, zone = self.gm, node and node.zone
    if self.navigate_field then return end
    if not (gm and zone and zone == gm.hand and node.is and node:is(Card)) then return end
    local hst = node.states and node.states.hover;       if not hst then return end
    if not hst.is and node.hover then node:hover() end
    hst.can, hst.is = Y, Y
    _wake_zone_layout(node)
end

--- Helper: first in-game hand focus
local function _first_ingame_hand_focus(self)
    local gm = self.gm;                              if not (gm and gm.hand and gm.hand.cards) then return end
    if self.navigate_field then return end
    if gm.SET and gm.SET.pause then return end
    if self.UI and self.UI.overlay_menu then return end
    if gm.stages and gm.g_stage == gm.stages.title_page then return end
    self.gamepad_focus_scope = self.gamepad_focus_scope or "hand"
    if self.gamepad_focus_scope ~= "hand" then return end
    return gm.hand.cards[1]
end

--- Helper: in-game field scope
local function _ingame_field_scope(self)
    local gm = self.gm;                              if not (self.navigate_field or self.gamepad_focus_scope == "field") or not (gm and gm.gridzone) then return end
    if gm.SET and gm.SET.pause then return end
    if self.UI and self.UI.overlay_menu then return end
    if gm.stages and gm.g_stage == gm.stages.title_page then return end
    return gm
end

--- Helper: field scope allows node
local function _field_scope_allows_node(self, node)
    local gm = _ingame_field_scope(self);             if not gm then return Y end
    return node and node.zone == gm.gridzone
end

--- Helper: field scope allows node
function Controller:field_scope_allows_node(node) return _field_scope_allows_node(self, node) end

--- Helper: first panel focus target
local function _first_panel_focus_target(self, panel)
    if not panel then return end
    return _first_active_node(self, panel.widget, Y) or _first_active_node(self, panel.attached_panel, Y) or _first_active_node(self, panel.widget, N) or _first_active_node(self, panel.attached_panel, N)
end

--- Helper: title panel
local function _title_panel(self)
    local gm, UI = self.gm, self.UI or {}
    return (gm and gm.title_page_UI) or UI.title_page_panel
end

--- Helper: auto snap focus target
local function _auto_snap_focus_target(self)
    local gm, UI, panel = self.gm, self.UI or {}, _title_panel(self)
    for _, id in ipairs(TITLE_FOCUS_IDS) do
        local node = _find_panel_node_by_id(panel, id)
        if node and self:is_focusable(node) then return node end
    end
    local node = _first_panel_focus_target(self, UI.overlay_menu) or _first_panel_focus_target(self, panel) or _first_panel_focus_target(self, gm and gm.debug_tools)
    if node then return node end
    for _, actor in pairs(self.t_actors or {}) do if self:is_focusable(actor) then return actor end end
end

--- Helper: title page
local function _on_title_page(self)
    local gm = self.gm
    return gm and gm.stages and gm.g_stage == gm.stages.title_page
end

--- Helper: pause page
local function _on_pause_page(self)
    local gm, OM = self.gm, self.UI and self.UI.overlay_menu
    return gm and gm.SET and gm.SET.pause and OM and _find_panel_node_by_id(OM, "return_title")
end

--- Helper: ordered focus node by step
local function _ordered_focus_index(ids, node)
    local cfg = node and node.config;        if not cfg then return end
    local current = cfg.id or cfg.key;       if not current then return end
    for i, id in ipairs(ids) do if id == current then return i end end
end

local function _ordered_focus_step(self, panel, ids, fct, step)
    local idx = _ordered_focus_index(ids, fct);       if not idx then return end
    for offset = 1, #ids do
        local node = _find_panel_node_by_id(panel, ids[((idx - 1 + step*offset) % #ids) + 1])
        if node and self:is_focusable(node) then return node end
    end
end

--- Helper: push focusable
local function _push_focusable(self, node, list)
    if not self:is_focusable(node) then return end
    node.states.focus.can = Y
    for _, v in ipairs(list) do if v == node then return end end
    push(list, node)
end

--- Helper: collect focusable nodes
local function _collect_focusables(self, node, list)
    _push_focusable(self, node, list)
    local fargs = node and node.config and node.config.focus_args
    if fargs and fargs.type and fargs.type:match("_row$") then return end
    for _, child in ipairs((node and node.children) or {}) do _collect_focusables(self, child, list) end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do _collect_focusables(self, child, list) end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do _collect_focusables(self, child, list) end
end

--- Helper: title focus node by step
local function _title_focus_step(self, fct, step)
    local cfg = fct and fct.config;        if not cfg then return end
    local current = cfg.id or cfg.key;     if not current then return end
    local panel, idx = _title_panel(self), nil
    for i, id in ipairs(TITLE_FOCUS_IDS) do if id == current then idx = i; break end end
    if not idx then return end
    for i = idx + step, step > 0 and #TITLE_FOCUS_IDS or 1, step do
        local node = _find_panel_node_by_id(panel, TITLE_FOCUS_IDS[i])
        if node and self:is_focusable(node) then return node end
    end
end

--- Helper: scrollable page parent
local function _scrollable_parent_item(node)
    local cur = node
    while cur and cur.parent do
        local p, pcfg = cur.parent, cur.parent.config
        if pcfg and pcfg.renderer == "scrollable_pages" then return p, cur end
        cur = p
    end
end

--- Helper: scrollable page focus step
local function _visible_count(cfg, n) return min(max(floor(cfg.visible_count or n or 1), 1), max(n, 1)) end
local function _clamp_start(cfg, n, visible) if cfg.loop then return ((floor(cfg.page_start or 1) - 1) % n) + 1 end; return min(max(floor(cfg.page_start or 1), 1), max(1, n - visible + 1)) end
local function _slot_for_index(cfg, n, start, idx) if cfg.loop then return ((idx - start) % n) + 1 end; return idx - start + 1 end
local function _index_step(cfg, n, idx, step) if cfg.loop then return ((idx - 1 + step) % n) + 1 end; local out = idx + step; return out >= 1 and out <= n and out or nil end

--- Helper: scrollable page edge step
local function _scrollable_edge_step(self, list, idx, step, n, visible)
    local cfg = list.config or {};                                      if n <= visible or list.save_menu_enter_lock or cfg.page_transition then return end
    local target_idx = _index_step(cfg, n, idx, step);                  if not target_idx then return end
    local target = (list.scrollable_page_items or {})[target_idx];       if not target then return end
    if list.scroll and list:scroll(self, step, 0) then return target end
end

--- Helper: scrollable page focus step
local function _scrollable_focus_step(self, fct, step)
    local list, item = _scrollable_parent_item(fct);        if not (list and item) then return end
    local items = list.scrollable_page_items or {}
    local n = #items;                                       if n == 0 then return end
    for i, child in ipairs(items) do
        if child == item then
            local cfg = list.config or {}
            local visible = _visible_count(cfg, n)
            local slot = _slot_for_index(cfg, n, _clamp_start(cfg, n, visible), i)
            if (step > 0 and slot == visible) or (step < 0 and slot == 1) then
                local node = _scrollable_edge_step(self, list, i, step, n, visible)
                if node then return node end
            end
            for offset = 1, n do
                local j = ((i - 1 + step*offset) % n) + 1
                local next_item = items[j]
                if self:is_focusable(next_item) then return next_item end
            end
            return item
        end
    end
end

---------------------------------------------------------
--- Update Focus
---------------------------------------------------------
--- Helper: auto snap focus
function Controller:auto_snap_focus()
    if not _on_title_page(self) then self.debug_gamepad_probe = { snap = "no title" }; return N end
    local node = _auto_snap_focus_target(self);             if not node then self.debug_gamepad_probe = { snap = "no target" }; return N end
    self.interrupt.focus = N
    self:snap_to({ node = node })
    self.debug_gamepad_probe = { button = (self.debug_gamepad_probe and self.debug_gamepad_probe.button), key = (self.debug_gamepad_probe and self.debug_gamepad_probe.key), snap = "queued" }
    return Y
end

--- Helper: decide if the target is focusable
function Controller:_prepare_focus_target(fc, CT, HID)
    local fct = fc.target;          fct.states.focus.is = N
    _wake_zone_layout(fct)
    if not _field_scope_allows_node(self, fct) then fc.target = nil; return end
    if self:is_focusable(fct) and (not HID.axis_cursor or fct:hit_test(CT)) then return end
    fc.target = nil
end

--- Helper: push focusable candidates into args.focusables (afcs)
function Controller:_build_focusable_candidates(dir, fct, args)
    args = args or self.args
    fct  = fct  or self.focused.target
    local afcs = args.focusables
    if not dir and fct then if _field_scope_allows_node(self, fct) then fct.states.focus.can = Y; push(afcs, fct) end; return
    elseif not dir then
        for _, v in ipairs(self.nodes_at_cursor) do
            local vfc = v.states.focus;     vfc.can, vfc.is = N, N
            if not _field_scope_allows_node(self, v) then goto continue end
            if #afcs ~= 0 or not self:is_focusable(v) then goto continue end
            vfc.can = Y;                    push(afcs, v)
            ::continue::
        end
        return
    end
    if _on_title_page(self) then
        local panel = _title_panel(self)
        _collect_focusables(self, panel and panel.widget, afcs)
        _collect_focusables(self, panel and panel.attached_panel, afcs)
    end
    if _on_pause_page(self) then
        local OM = self.UI.overlay_menu
        _collect_focusables(self, OM.widget, afcs)
        _collect_focusables(self, OM.attached_panel, afcs)
    end
    if self.UI and self.UI.overlay_menu then
        _collect_focusables(self, self.UI.overlay_menu.widget, afcs)
        _collect_focusables(self, self.UI.overlay_menu.attached_panel, afcs)
    end
    local gm, field_allowed = self.gm, self.gamepad_focus_scope == "field"
    for _, v in pairs(self.t_actors or {}) do
        local vfc = v.states.focus
        vfc.can, vfc.is = N, N
        if field_allowed and not _field_scope_allows_node(self, v) then goto continue end
        if gm and gm.gridzone and v.zone == gm.gridzone and not field_allowed then goto continue end
        _push_focusable(self, v, afcs)
        ::continue::
    end
end

-- Helper: add a node to the focus_list
function Controller:_push2fcslist()
    local args = self.args
    local node = self.focused.target or args.focusables[1]
    push(args.focus_list, { node = node, dist = 0 })
end

--- Helper: choose the final target
function Controller:_final_target(dir)
    local args = self.args
    if not dir then
        local node = (not self.focused.target) and _first_ingame_hand_focus(self)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return end
        return self:_push2fcslist()
    end
    local fct, hand = self.focused.target, self.hand

    if not fct then
        local gm = self.gm
        if gm and gm.opt_menu_tab_state and args.focusables[1] then args.focus_list[1] = { node = args.focusables[1], dist = 0 }; return end
        local hand_node = _first_ingame_hand_focus(self)
        if hand_node then args.focus_list[1] = { node = hand_node, dist = 0 }; return end
        local node = _auto_snap_focus_target(self)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return end
    end

    if _on_title_page(self) and fct and (dir == "U" or dir == "D") then
        local node = _title_focus_step(self, fct, dir == "D" and 1 or -1)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return end
    end

    if _on_pause_page(self) and fct and (dir == "U" or dir == "D") then
        local node = _ordered_focus_step(self, self.UI.overlay_menu, PAUSE_FOCUS_IDS, fct, dir == "D" and 1 or -1)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return end
    end

    if _on_pause_page(self) and fct and (dir == "L" or dir == "R") and _ordered_focus_index(PAUSE_FOCUS_IDS, fct) then
        args.focus_list[1] = { node = fct, dist = 0 }; return
    end

    if fct and (dir == "U" or dir == "D") then
        local node = _scrollable_focus_step(self, fct, dir == "D" and 1 or -1)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return end
    end

    if (dir == "L" or dir == "R") and fct and fct:is(Card) and hand and fct.zone == hand then
        local nu_rank = fct.rank + (dir == "L" and -1 or 1)
        if nu_rank > #hand.cards then nu_rank = 1 end
        if nu_rank == 0 then nu_rank = #hand.cards end
        if nu_rank ~= fct.rank then args.focus_list[1] = { node = hand.cards[nu_rank] } end
        return
    end

    args.focus_cursor_pos = args.focus_cursor_pos or {}
    local h, rcfg = self.hovering, self.rcfg
    local norm = rcfg.tile_scale * rcfg.tile_size

    local C, R, fcpos = self.p_cursor, self._room, args.focus_cursor_pos
    local afcs, flist = args.focusables, args.focus_list
    local CT, RT, ht = C.T, R.T, h.target
    fcpos.x, fcpos.y = CT.x - RT.x, CT.y - RT.y

    if fct then
        local ft = fct.config.focus_args and fct.config.focus_args.funnel_to or fct
        local ftT = ft.T
        fcpos.x, fcpos.y = ftT.x + 0.5 * ftT.w, ftT.y + 0.5 * ftT.h
    elseif ht and ht.states.focus.can then
        fcpos.x, fcpos.y = ht:put_focused_cursor()
        fcpos.x, fcpos.y = fcpos.x / norm - RT.x, fcpos.y / norm - RT.y
    end

    for _, v in pairs(afcs) do
        if v == ht or v == fct then goto continue end
        local vfargs = v.config.focus_args
        local target = vfargs and vfargs.funnel_to or v
        local tT = target.T
        args.focus_vec = { x = tT.x + 0.5 * tT.w - fcpos.x, y = tT.y + 0.5 * tT.h - fcpos.y }

        local tfargs, fvec, eligible = target.config.focus_args, args.focus_vec, N
        if tfargs and tfargs.nav == "wide" then eligible = (fvec.y > 0.1 and dir == "D") or (fvec.y < -0.1 and dir == "U") or (abs(fvec.y) < tT.h / 2)
        elseif tfargs and tfargs.nav == "tall" then eligible = (fvec.x > 0.1 and dir == "R") or (fvec.x < -0.1 and dir == "L") or (abs(fvec.x) < tT.w / 2)
        elseif abs(fvec.x) > abs(fvec.y) then eligible = (fvec.x > 0 and dir == "R") or (fvec.x < 0 and dir == "L")
        else eligible = (fvec.y > 0 and dir == "D") or (fvec.y < 0 and dir == "U") end

        if not eligible then goto continue end
        table.insert(flist, { node = target, dist = abs(fvec.x) + abs(fvec.y) })
        ::continue::
    end

    if #flist < 1 then if fct then fct.states.focus.is = Y end; return Y end
    table.sort(flist, function(a, b) return a.dist < b.dist end)
end

--____________________________________________________________
-- Main: apply all updates to the controller
--____________________________________________________________
function Controller:update_focus(dir)
    local HID, args, C = self.HID, self.args, self.p_cursor
    local CT, fc, wipe = C.T, self.focused, self.Fs.wipe
    fc.prev_target = fc.target

    if not HID.controller or self.interrupt.focus or self:_locked() then
        if fc.target then _clear_child_hover(fc.target); fc.target.states.focus.is = N end
        fc.target = nil
        return
    end

    args.focus_list, args.focusables = wipe(args.focus_list), wipe(args.focusables)
    if fc.target then self:_prepare_focus_target(fc, CT, HID) end
    self:_build_focusable_candidates(dir)

    local ingame_hand_default = (not dir and not fc.target) and _first_ingame_hand_focus(self)
    if ingame_hand_default or #args.focusables > 0 or (dir and not fc.target) then if self:_final_target(dir) then return end end
    local flist = args.focus_list[1]
    if flist then
        local node = flist.node
        local nfargs = node.config.focus_args
        local next_target = nfargs and nfargs.funnel_from or node
        if _field_scope_allows_node(self, next_target) then fc.target = next_target else _clear_child_hover(fc.prev_target); fc.target = nil end
        if fc.target and fc.target ~= fc.prev_target then _clear_child_hover(fc.prev_target); _wake_zone_layout(fc.prev_target); _wake_zone_layout(fc.target); _apply_row_focus_fx(fc.target); self:emit_intent("vibrate") end
    else _clear_child_hover(fc.prev_target); fc.target = nil end
    if fc.target then fc.target.states.focus.is = Y; _apply_hand_card_focus_hover(self, fc.target) end
end

end
