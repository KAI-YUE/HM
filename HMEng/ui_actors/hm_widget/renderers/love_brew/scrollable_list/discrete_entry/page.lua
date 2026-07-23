local Core     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.core")
local Controls = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.controls")
local Layout   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.layout")

local max, floor = math.max, math.floor

local Y, N = true, false

local M = {}

-----------------------------
--- Paging
----------------------------------
function M.page(self, dir, count)
    local cfg, n = self.config, #(self.scrollable_items or {});                      if n <= 0 or cfg.page_transition then return N end

    local raw_dir     = dir or 1
    local page_dir    = (raw_dir >= 0 and 1) or -1
    local step, from  = count or cfg.page_step or 1, Core.clamp_start(cfg, n)
    local gm,   to    = self.gm, Controls.set_start(cfg, from + page_dir * step, n);  if to == from then return N end

    local dur  = cfg.page_duration or 0.26
    local tr   = { from = from, to = to, dir = page_dir, step = step, progress = 0, dur = dur }
    local indexes = Core.transition_indexes(cfg, n, from, to, Core.slot_count(cfg, n))

    cfg.page_start, cfg.page_transition = from, tr
    Controls.lock_slot_controls(self)
    local transition_dur  = Core.start_slot_fx(self, tr, indexes)
    tr.transition_dur     = transition_dur
    Core.ease(gm.E_MANAGER, tr, "progress", 1, transition_dur, cfg.page_ease or "sine")

    return Y
end

function M.scroll(self, Ctrl, dir, count)
    if self.save_menu_enter_lock then return N end
    return M.page(self, dir, Core.scroll_count(self.config, count))
end

-----------------------------
--- Progress
----------------------------------
function M.set_progress(self, progress)
    local cfg, n = self.config, #(self.scrollable_items or {})
    if n <= 0 or cfg.page_transition or self.save_menu_enter_lock then return N end

    local range = cfg.loop and max(1, n - 1) or max(1, n - Core.visible_count(cfg, n))
    local start = Controls.set_start(cfg, 1 + floor(Core.clamp01(progress) * range + 0.5), n)
    if start == cfg.page_start then return N end

    cfg.page_start = start
    Layout.layout_visible(self)
    Core.update_slide_bar(self)
    return Y
end

function M.get_progress(self)
    local cfg, n = self.config, #(self.scrollable_items or {})
    if n <= 0 then return 0 end
    return Core.page_progress(cfg, n, Core.clamp_start(cfg, n))
end

-----------------------------
--- Update
----------------------------------
function M.update(self)
    local tr = self.config.page_transition
    if tr and Core.clamp01(tr.progress) >= 1 then Layout.finish_transition(self) end
    Core.update_slide_bar(self)
end

-----------------------------
--- Draw
----------------------------------
function M.draw(self) Layout.draw_children(self); end

function M.hit_test(self, cursor_trans) return N end

return M
