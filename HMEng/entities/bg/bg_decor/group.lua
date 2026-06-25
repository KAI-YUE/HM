local floor = math.floor
local min, max = math.min, math.max

local Y, N  = true, false

return function (BgDecor)
--------------------------------------------
--- init group states
--------------------------------------------
function BgDecor:init_group_states() 
    self.group_states = {}
    for group_idx = 1, max(self.num_groups or 1, 1) do self.group_states[group_idx] = { phase = "hidden", t = 0, alpha = 0 }; end
end

--------------------------------------------
--- sync_group_states
--------------------------------------------
--- Helper: group_selected, selected visibility from current selectors
local function _group_selected(self, group_idx) if self.active_group ~= nil then return group_idx == self.active_group end; return Y end

--- Helper: clamp_group_idx s
local function _clamp_group_idx(self, group_idx)
    local n_groups = max(self.num_groups or 1, 1)
    local idx      = tonumber(group_idx or 1) or 1
    if idx < 1 then return 1 elseif idx > n_groups then return n_groups end
    return floor(idx)
end

--- Helper: _group_state, fetch or create group state
local function _group_state(self, group_idx)
    local idx = _clamp_group_idx(self, group_idx)
    self.group_states       = self.group_states or {}
    self.group_states[idx]  = self.group_states[idx] or { phase = "hidden", t = 0, alpha = 0 }
    return self.group_states[idx], idx
end

--- Helper: set_group_state, write one group state
local function _set_group_state(self, group_idx, phase, alpha)
    local st = _group_state(self, group_idx)
    st.phase, st.t = phase or st.phase, 0
    if alpha ~= nil then st.alpha = alpha end
    return st
end

---____________________________________
--- main: sync_group_states
---____________________________________
function BgDecor:sync_group_states()
    for group_idx = 1, max(self.num_groups or 1, 1) do
        local alpha = _group_selected(self, group_idx) and 1 or 0
        _set_group_state(self, group_idx, alpha > 0 and "visible" or "hidden", alpha)
    end
end

-----------------------------------------------
--- get group alpha | groups fading
-----------------------------------------------
function BgDecor:get_group_alpha(group_idx) local st = _group_state(self, group_idx); return st.alpha or 0 end
function BgDecor:groups_fading()            for _, st in pairs(self.group_states or {}) do if st.phase == "fade_in" or st.phase == "fade_out" then return Y end end; return N; end

---______________________________________
--- main: start_single_group_fade
---______________________________________
function BgDecor:start_single_group_fade(group_idx)
    local next_idx  = _clamp_group_idx(self, group_idx)
    local prev_idx  = self.active_group

    self.active_group = next_idx
    if prev_idx and prev_idx ~= next_idx then _set_group_state(self, prev_idx, "fade_out", self:get_group_alpha(prev_idx)) end
    
    _set_group_state(self, next_idx, "fade_in", self:get_group_alpha(next_idx))
    if self:get_group_alpha(next_idx) >= 1 then _set_group_state(self, next_idx, "visible", 1) end
end

------------------------------------------------
--- set active group
------------------------------------------------
function BgDecor:set_active_group(group_idx)
    self.active_group = _clamp_group_idx(self, group_idx)
    self:sync_group_states()
    return self.active_group
end

------------------------------------------------
--- clear max visible group | clear_active_group
------------------------------------------------
function BgDecor:clear_max_visible_group() self:sync_group_states() end
function BgDecor:clear_active_group()      self.active_group = nil; self:sync_group_states() end

end
