local max, min = math.max, math.min
local random = math.random
local Y, N = true, false

return function (BgDecor)
--------------------------------------------------
--- update
--------------------------------------------------
--- Helper: collect fully hidden groups
local function _hidden_groups(self)
    local hidden_groups, n_groups = {}, max(self.num_groups or 1, 1)
    for idx = 1, n_groups do
        local alpha = self.get_group_alpha and self:get_group_alpha(idx) or 0
        if alpha <= 0.001 then hidden_groups[#hidden_groups + 1] = idx end
    end
    return hidden_groups
end

--- Helper: advance visible decor group
local function _advance_group_cycle(self)
    local n_groups  = max(self.num_groups or 1, 1)
    local curr      = self.active_group or 1
    self:start_single_group_fade((curr%n_groups) + 1)
end

--- Helper: redistribute entries from one hidden group
local function _reroll_group_entries(self, group_idx)
    local n_groups      = max(self.num_groups or 1, 1);  if n_groups <= 1 then return end
    local hidden_groups = _hidden_groups(self);          if not hidden_groups[1] then return end

    for _, entry in ipairs(self.entries or {}) do
        if (entry.group_idx or 1) ~= group_idx then goto continue end 
        entry.group_idx = hidden_groups[random(#hidden_groups)]
        ::continue::
    end
end

--- Helper: _wipe_reborn_group_entries
local function _wipe_reborn_group_entries(self, group_idx)
    local rate           = (self.config or {}).wipe_reborn or 0;   if rate <= 0   then return N end
    local hidden_groups  = _hidden_groups(self);                   if not hidden_groups[1] then return N end
    local keys           = self:resolve_entry_keys() or {};        if not keys[1] then return N end

    local changed = N
    for idx, entry in ipairs(self.entries or {}) do
        if (entry.group_idx or 1) ~= group_idx then goto continue end
        if random() > rate                     then goto continue end

        local new_group_idx = hidden_groups[random(#hidden_groups)]
        local new_entry     = self.build_random_gridzone_entry and self:build_random_gridzone_entry(keys, "bg_decor_reborn", new_group_idx)
        if not new_entry then goto continue end

        self.entries[idx] = new_entry
        changed = Y
        ::continue::
    end

    if changed and self.sort_entries then self:sort_entries() end
    return changed
end

--- Helper: finish fade in immediately
local function _finish_group_fade_in(st) st.phase, st.alpha, st.t = "visible", 1, 0; end

--- Helper: finish fade out immediately
local function _finish_group_fade_out(self, group_idx, st)
    st.phase, st.alpha, st.t = "hidden", 0, 0
    _wipe_reborn_group_entries(self, group_idx)
    _reroll_group_entries(self, group_idx)
end

--- Helper: advance fade in
local function _advance_group_fade_in(st, dt, fade_s)
    st.t     = min((st.t or 0) + dt, fade_s)
    st.alpha = min(st.t / fade_s, 1)
    if st.t >= fade_s then _finish_group_fade_in(st) end
end

--- Helper: advance fade out
local function _advance_group_fade_out(self, group_idx, st, dt, fade_s)
    st.t     = min((st.t or 0) + dt, fade_s)
    st.alpha = max(1 - st.t / fade_s, 0)
    if st.t < fade_s then return end
    _finish_group_fade_out(self, group_idx, st)
end

--- Helper: resolve zero-duration fade state
local function _apply_instant_group_fade(self, group_idx, st)
    if     st.phase == "fade_in"  then _finish_group_fade_in(st)
    elseif st.phase == "fade_out" then _finish_group_fade_out(self, group_idx, st) end
end

--- Helper: update fading groups
local function _update_group_fades(self, dt)
    local fade_s = self.group_fade_s or 0       -- initialize the timer 

    for group_idx, st in pairs(self.group_states or {}) do
        if     fade_s <= 0            then _apply_instant_group_fade(self, group_idx, st); goto continue end
        if     st.phase == "fade_in"  then _advance_group_fade_in(st, dt, fade_s);         goto continue
        elseif st.phase ~= "fade_out" then  goto continue; end
        _advance_group_fade_out(self, group_idx, st, dt, fade_s)
        ::continue::
    end
end

---________________________________
--- main: update
---________________________________
function BgDecor:update(dt)
    _update_group_fades(self, dt)

    if not self.perform_cycle      then return end
    if (self.num_groups or 1) <= 1 then return end
    if self:groups_fading()        then return end

    local period       = max(self.group_cycle_s or 0, 0);    if period <= 0 then return end
    self.group_cycle_t = (self.group_cycle_t or 0) + dt
    while self.group_cycle_t >= period do self.group_cycle_t = self.group_cycle_t - period; _advance_group_cycle(self); end
end

end
