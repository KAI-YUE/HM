local Slot = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.slot")

local max, min = math.max, math.min

local Y, N = true, false

local M = {}

-----------------------------
--- Transition FX helpers
----------------------------------
--- Helper: _ease | _after | queue_slot_fx
local function _ease(EM, ref_table, ref_value, ease_to, delay, ease) EM:enqueue_event({ trigger = "ease", ease = ease or "lerp", blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to, delay = delay }); end
local function _after(EM, delay, fn)                                 if (delay or 0) <= 0 then return fn() end; EM:enqueue_event({ trigger = "after", blockable = N, blocking = N, delay = delay, func = fn }); end
local function _queue_slot_fx(EM, child, ease_to, dur, ease, delay)  _after(EM, delay, function() if child.REMOVED then return Y end; _ease(EM, child, "fx_mask", ease_to, dur, ease); return Y; end); end

--- Helper: _start_slot_fx
local function _start_slot_fx(self, tr, indexes)
    local EM = self.gm.E_MANAGER;                                    if not EM then return tr.dur or 0.26 end

    local items,   cfg        = self.scrollable_items or {},         self.config
    local n,       count      = #items,                              Slot.slot_count(cfg, #items)
    local dur,     ease       = cfg.page_duration or tr.dur or 0.26, "sine"
    local stagger, max_delay  = cfg.page_fx_stagger,                  0

    if type(stagger) ~= "number" then stagger = dur end
    local ranks, first = {}, {}

    for _, idx in ipairs(indexes) do
        local child = items[idx];           if not child then goto continue end
        local kind = Slot.slot_transition_kind(cfg, n, tr, idx, count)
        if kind then
            local rank = Slot.slot_fx_rank(cfg, n, tr, idx, count, kind)
            ranks[#ranks + 1] = { child = child, kind = kind, rank = rank }
            first[kind] = min(first[kind] or rank, rank)
        else
            child.fx_mask, child.fx_mask_dir = 0, 1
        end
        ::continue::
    end

    for _, fx in ipairs(ranks) do
        local child  = fx.child
        local delay  = max(0, (fx.rank - (first[fx.kind] or fx.rank)) * stagger)
        max_delay    = max(max_delay, delay)

        if     fx.kind == "incoming" then child.fx_mask, child.fx_mask_dir = 1, tr.dir; _queue_slot_fx(EM, child, 0, dur, ease, delay)
        elseif fx.kind == "outgoing" then child.fx_mask, child.fx_mask_dir = 0, -tr.dir; _queue_slot_fx(EM, child, 1, dur, ease, delay)
        else                              child.fx_mask, child.fx_mask_dir = 0, 1; end
    end

    return max(dur, max_delay + dur)
end

function M.ease(EM, ref_table, ref_value, ease_to, delay, ease)  return _ease(EM, ref_table, ref_value, ease_to, delay, ease) end
function M.after(EM, delay, fn)                                  return _after(EM, delay, fn) end
function M.queue_slot_fx(EM, child, ease_to, dur, ease, delay)   return _queue_slot_fx(EM, child, ease_to, dur, ease, delay) end
function M.start_slot_fx(self, tr, indexes)                      return _start_slot_fx(self, tr, indexes) end

return M
