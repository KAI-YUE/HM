local Card = require("HMEng.entities.card")

local abs, floor  = math.abs, math.floor
local max, min    = math.max, math.min

local Y, N = true, false

local M = {}

---------------------------------------------------
--- push_current: push current focus to list
---------------------------------------------------
function M.push_current(self)
    local args  = self.args
    local node  = self.focused.target or args.focusables[1]
    table.insert(args.focus_list, { node = node, dist = 0 })
end

--------------------------------------------------
--- final target
--------------------------------------------------
--- Helper: scrollable parent
local function _scrollable_variant(cfg)
    local name = cfg and cfg.renderer
    if name == "scrollable_continuous"      then return "continuous" end
    if name == "scrollable_discrete_entry"  then return "discrete_entry" end
end

--- Helper: scrollable_parent_item
local function _scrollable_parent_item(node)
    local cur = node
    while cur and cur.parent do
        local p, pcfg = cur.parent, cur.parent.config
        if _scrollable_variant(pcfg) then return p, cur, _scrollable_variant(pcfg) end
        cur = p
    end
end

--- Helper: scrollable page focus step
local function _visible_count(cfg, n)               return min(max(floor(cfg.visible_count or n or 1), 1), max(n, 1)) end
local function _clamp_start(cfg, n, visible)        if cfg.loop then return ((floor(cfg.page_start or 1) - 1) % n) + 1 end; return min(max(floor(cfg.page_start or 1), 1), max(1, n - visible + 1)) end
local function _slot_for_index(cfg, n, start, idx)  if cfg.loop then return ((idx - start) % n) + 1 end; return idx - start + 1 end
local function _index_step(cfg, n, idx, step)       if cfg.loop then return ((idx - 1 + step) % n) + 1 end; local out = idx + step; return out >= 1 and out <= n and out or nil end

--- Helper: scrollable page edge step
local function _scrollable_edge_step(self, list, idx, step, n, visible)
    local cfg = list.config or {};                                      if n <= visible or list.save_menu_enter_lock or cfg.page_transition then return end
    local items, target_idx = list.scrollable_items or {}, _index_step(cfg, n, idx, step)
   
    if not (target_idx and items[target_idx])      then return end
    if list.scroll and list:scroll(self, step, 0)  then return items[idx] end
end

--- Helper: scrollable item focus step
local function _scrollable_item_step(self, list, item, variant, idx, step, n)
    local items = list.scrollable_items or {}
    if variant == "continuous" then
        for offset = 1, n do
            local next_item = items[idx + step*offset]; if not next_item then return item end
            if self:is_focusable(next_item) then list:ensure_visible(next_item); return next_item end
        end
        return item
    end

    local cfg = list.config or {}
    if list.save_menu_enter_lock or cfg.page_transition then return item end
    local visible  = _visible_count(cfg, n)
    local slot     = _slot_for_index(cfg, n, _clamp_start(cfg, n, visible), idx)
    
    if (step > 0 and slot == visible) or (step < 0 and slot == 1) then
        local node = _scrollable_edge_step(self, list, idx, step, n, visible)
        if node then return node end
    end
    
    for offset = 1, n do
        local next_idx = ((idx - 1 + step*offset) % n) + 1
        local next_item = items[next_idx]
        if self:is_focusable(next_item) then return next_item end
    end
    return item
end

--- Helper: scrollable page focus step
local function _scrollable_focus_step(self, fct, step)
    local list, item, variant = _scrollable_parent_item(fct);      if not (list and item) then return end
    
    local items  = list.scrollable_items or {}
    local n      = #items;                                         if n == 0 then return end
    for i, child in ipairs(items) do if child == item then return _scrollable_item_step(self, list, item, variant, i, step, n) end end
end

--- Helper: default focus target
local function _default_focus_target(self, Scope)
    local args = self.args
    local node = (not self.focused.target) and Scope.first_ingame_hand_focus(self)
    if node then args.focus_list[1] = { node = node, dist = 0 }; return end
    return M.push_current(self)
end

--- Helper: unfocused target
local function _unfocused_target(self, Scope, Targets)
    local args, gm = self.args, self.gm
    if gm.opt_menu_tab_state and args.focusables[1] then args.focus_list[1] = { node = args.focusables[1], dist = 0 }; return Y end
    local node = Scope.first_ingame_hand_focus(self) or Targets.auto_snap_focus_target(self)
    if node then args.focus_list[1] = { node = node, dist = 0 }; return Y end
end

--- Helper: scoped focus target
local function _scoped_focus_target(self, fct, dir, Scope, Targets)
    local args = self.args
    if Scope.on_pause_page(self) and fct and (dir == "U" or dir == "D") then
        local node = Targets.ordered_focus_step(self, self.UI.overlay_menu, Targets.PAUSE_FOCUS_IDS, fct, dir == "D" and 1 or -1)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return Y end
    end

    if Scope.on_pause_page(self) and fct and (dir == "L" or dir == "R") and Targets.ordered_focus_index(Targets.PAUSE_FOCUS_IDS, fct) then
        args.focus_list[1] = { node = fct, dist = 0 }; return Y
    end

    if Scope.on_title_page(self) and fct and (dir == "U" or dir == "D") then
        local node = Targets.title_focus_step(self, fct, dir == "D" and 1 or -1)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return Y end
    end

    if fct and (dir == "U" or dir == "D") then
        local node = _scrollable_focus_step(self, fct, dir == "D" and 1 or -1)
        if node then args.focus_list[1] = { node = node, dist = 0 }; return Y end
    end
end

--- Helper: hand focus target
local function _hand_focus_target(self, fct, dir)
    local args, hand = self.args, self.hand

    if (dir == "L" or dir == "R") and fct and fct:is(Card) and hand and fct.zone == hand then
        local nu_rank = fct.rank + (dir == "L" and -1 or 1)
        if nu_rank > #hand.cards then nu_rank = 1 end
        if nu_rank == 0          then nu_rank = #hand.cards end
        if nu_rank ~= fct.rank   then args.focus_list[1] = { node = hand.cards[nu_rank] } end
        return Y
    end
end

--- Helper: directional focus targets
local function _directional_focus_targets(self, fct, dir)
    local args = self.args

    args.focus_cursor_pos  = args.focus_cursor_pos or {}
    local h, rcfg          = self.hovering, self.rcfg
    local norm             = rcfg.tile_scale * rcfg.tile_size

    local C,  R,  fcpos    = self.p_cursor, self._room, args.focus_cursor_pos
    local afcs,   flist    = args.focusables, args.focus_list
    local CT, RT, ht       =  C.T, R.T, h.target
    fcpos.x,      fcpos.y  = CT.x - RT.x, CT.y - RT.y

    if fct then
        local ft   = fct.config.focus_args and fct.config.focus_args.funnel_to or fct
        local ftT  = ft.T
        fcpos.x, fcpos.y  = ftT.x + 0.5 * ftT.w, ftT.y + 0.5 * ftT.h
    elseif ht and ht.states.focus.can then
        fcpos.x, fcpos.y  = ht:put_focused_cursor()
        fcpos.x, fcpos.y  = fcpos.x / norm - RT.x, fcpos.y / norm - RT.y
    end

    for _, v in pairs(afcs) do
        if v == ht or v == fct then goto continue end

        local vfargs  = v.config.focus_args
        local target  = vfargs and vfargs.funnel_to or v
        local tT      = target.T
        
        args.focus_vec = { x = tT.x + 0.5 * tT.w - fcpos.x, y = tT.y + 0.5 * tT.h - fcpos.y }
        local tfargs, fvec, eligible = target.config.focus_args, args.focus_vec, N
        
        if     tfargs and tfargs.nav == "wide"  then eligible = (fvec.y > 0.1 and dir == "D") or (fvec.y < -0.1 and dir == "U") or (abs(fvec.y) < tT.h / 2)
        elseif tfargs and tfargs.nav == "tall"  then eligible = (fvec.x > 0.1 and dir == "R") or (fvec.x < -0.1 and dir == "L") or (abs(fvec.x) < tT.w / 2)
        elseif abs(fvec.x) > abs(fvec.y)        then eligible = (fvec.x > 0 and dir == "R") or (fvec.x < 0 and dir == "L")
        else   eligible = (fvec.y > 0 and dir == "D") or (fvec.y < 0 and dir == "U") end

        if not eligible then goto continue end
        table.insert(flist, { node = target, dist = abs(fvec.x) + abs(fvec.y) })
        ::continue::
    end

    if #flist < 1 then if fct then fct.states.focus.is = Y end; return Y end
    table.sort(flist, function(a, b) return a.dist < b.dist end)
end

---______________________________________________________
--- main: final_target
---______________________________________________________
function M.final_target(self, dir, Scope, Targets)
    if not dir then return _default_focus_target(self, Scope) end

    local fct = self.focused.target
    if not fct and _unfocused_target(self, Scope, Targets)  then return end
    if _scoped_focus_target(self, fct, dir, Scope, Targets) then return end
    if _hand_focus_target(self, fct, dir) then return end
    return _directional_focus_targets(self, fct, dir)
end

return M
