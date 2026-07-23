local max, min, floor = math.max, math.min, math.floor

local Y, N = true, false

local M = {}

--- Helper: _items
local function _items(cfg)
    local items = cfg.child_widgets
    if not items then return {} end
    if not items[1] and not (items.style or items.renderer or items.T) then return {} end
    return items[1] and items or { items }
end

--- Helper: Slot math, visible_count | _clamp01
local function _visible_count(cfg, n) return min(max(floor(cfg.visible_count or n or 1), 1), max(n, 1)) end
local function _clamp01(v) return min(max(v or 0, 0), 1) end

--- Helper: _clamp_start
local function _clamp_start(cfg, n)
    n = n or 0;                      if n <= 0 then return 1 end
    if cfg.loop then return ((floor(cfg.page_start or 1) - 1) % n) + 1 end
    return min(max(floor(cfg.page_start or 1), 1), max(1, n - _visible_count(cfg, n) + 1))
end

--- Helper: _slot_count | _raw_slot
local function _slot_count(cfg, n)            return _visible_count(cfg, n) end
local function _raw_slot(cfg, n, start, idx)  if cfg.loop then return ((idx - start) % n) + 1 end; return idx - start + 1; end

--- Helper: _display_slot
local function _display_slot(cfg, n, start, idx, count)
    local slot = _raw_slot(cfg, n, start, idx)
    return slot >= 1 and slot <= count and slot or nil
end

--- Helper: _slot_index
local function _slot_index(cfg, n, start, slot)
    local idx = start + slot - 1;              if cfg.loop then return ((idx - 1) % n) + 1 end
    return idx >= 1 and idx <= n and idx or nil
end

--- Helper: _scroll_count
local function _scroll_count(cfg, mag) return ((mag or 0) >= (cfg.scroll_fast_threshold or 1)) and 2 or 1; end

--- Helper: _page_progress
local function _page_progress(cfg, n, start)
    if n <= 1    then return 0 end
    if cfg.loop  then return ((start or 1) - 1) / max(1, n - 1) end
    local range = max(1, n - _visible_count(cfg, n))
    return ((start or 1) - 1) / range
end

--- Helper: _transition_progress
local function _transition_progress(cfg, n, tr)
    local from, to  = _page_progress(cfg, n, tr.from), _page_progress(cfg, n, tr.to)
    local p         = from + (to - from) * _clamp01(tr.progress)
    return _clamp01(p)
end

--- Helper: _transition_indexes
local function _transition_indexes(cfg, n, from_start, to_start, count)
    local seen, list = {}, {}
    local function add(idx)
        if not idx or seen[idx] then return end
        seen[idx] = Y
        list[#list + 1] = idx
    end

    for slot = 1, count do
        add(_slot_index(cfg, n, from_start, slot))
        add(_slot_index(cfg, n, to_start, slot))
    end

    table.sort(list)
    return list
end

--- Helper: _slot_transition_kind
local function _slot_transition_kind(cfg, n, tr, idx, count)
    local from_slot  = _display_slot(cfg, n, tr.from, idx, count)
    local to_slot    = _display_slot(cfg, n, tr.to,   idx, count);      if not from_slot and to_slot then return "incoming" end
    if from_slot and not to_slot then return "outgoing" end
end

--- Helper: _slot_fx_rank
local function _slot_fx_rank(cfg, n, tr, idx, count, kind)
    local slot = kind == "incoming" and _display_slot(cfg, n, tr.to, idx, count) or _display_slot(cfg, n, tr.from, idx, count)
    if not slot then return 1 end
    return tr.dir >= 0 and slot or count - slot + 1
end

function M.items(cfg)                              return _items(cfg) end
function M.visible_count(cfg, n)                   return _visible_count(cfg, n) end
function M.clamp01(v)                              return _clamp01(v) end
function M.clamp_start(cfg, n)                     return _clamp_start(cfg, n) end
function M.slot_count(cfg, n)                      return _slot_count(cfg, n) end
function M.raw_slot(cfg, n, start, idx)            return _raw_slot(cfg, n, start, idx) end
function M.display_slot(cfg, n, start, idx, count) return _display_slot(cfg, n, start, idx, count) end
function M.slot_index(cfg, n, start, slot)         return _slot_index(cfg, n, start, slot) end
function M.scroll_count(cfg, mag)                  return _scroll_count(cfg, mag) end
function M.page_progress(cfg, n, start)            return _page_progress(cfg, n, start) end
function M.transition_progress(cfg, n, tr)         return _transition_progress(cfg, n, tr) end

function M.transition_indexes(cfg, n, from_start, to_start, count) return _transition_indexes(cfg, n, from_start, to_start, count) end
function M.slot_transition_kind(cfg, n, tr, idx, count)            return _slot_transition_kind(cfg, n, tr, idx, count) end
function M.slot_fx_rank(cfg, n, tr, idx, count, kind)              return _slot_fx_rank(cfg, n, tr, idx, count, kind) end
function M.is_entry_item(self, target)                             if not target then return N end; for _, child in ipairs(self.scrollable_items or {}) do if child == target then return Y end; end; return N; end

return M
