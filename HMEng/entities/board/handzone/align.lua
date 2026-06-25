local min, max  = math.min, math.max
local sin, cos  = math.sin, math.cos
local rand, abs = math.random, math.abs
local tsort     = table.sort

local Y, N = true, false

return function (HandZone)
------------------------------------------------------
--- align_cards (fan shape)
------------------------------------------------------
--- Helper: render_highlighted
local function render_highlighted(gm, card, angle, cx, cy)
    if not card.highlighted then card:unhighlighted_tilt(); return cx, cy end
    local highlight_height = gm.rcfg.highlight_h or 0
    card:highlighted_tilt()
    return cx + sin(angle)*highlight_height, cy - cos(angle)*highlight_height
end

--- Helper: is_interacting
local function is_interacting(card)
    local st = card.states
    local drag, focus, hover = st.drag, st.focus, st.hover
    return hover.is or drag.is or focus.is
end

--- Helper: drag sort order | check current drag sort order | set card ranks from hand order
local function drag_sort_less(a, b)   if a.T.x == b.T.x then return (a.rank or a.sort_id or 0) < (b.rank or b.sort_id or 0) end; return a.T.x < b.T.x end
local function needs_drag_sort(cards) for i = 2, #cards do if drag_sort_less(cards[i], cards[i - 1]) then return Y end end; return N; end
local function set_card_ranks(cards)  for k, card in ipairs(cards) do card.rank = k end end

--- Helper: apply hand-sort sluggishness to cards that will settle into new slots
local function apply_sort_sluggishness(cfg, cards)
    local base_smooth = cfg.drag_sort_smooth_time
    local base_speed  = cfg.drag_sort_max_speed

    for _, card in ipairs(cards) do
        local st = card.states
        if (st.drag and st.drag.is) then goto continue end 
        local motion,   mass    = card.motion and card.motion.xy, card.drag_mass or 0
        local response, smooth  = card.drag_response or 1,        base_smooth or (motion and motion.smooth_time) or 0

        if mass > 0 and response > 0 then smooth = max(smooth, mass/response) end
        card.waypoint_landing = { smooth_time = smooth, max_speed = base_speed or card.drag_release_max_speed }
        ::continue::
    end
end

--- Helper: enqueue delayed drag sort
local function enqueue_drag_sort(self, cfg)
    if self.drag_sort_queued then return end

    local EM = self.gm.E_MANAGER
    self.drag_sort_queued = Y
    
    EM:enqueue_event({  trigger = "after", delay = cfg.drag_sort_delay or 0.6, blockable = N,  blocking = N,
        func = function()
            self.drag_sort_queued = N
            if not (self.config and self.config.enable_drag_sort) then return Y end
            if not needs_drag_sort(self.cards) then return Y end

            apply_sort_sluggishness(self.config, self.cards)
            tsort(self.cards, drag_sort_less)
            set_card_ranks(self.cards)
            return Y
        end
    })
end

--- Helper: one-time fan jitter
local function get_or_create_fan_grab_jitter_deg(max_jitter_deg, jitter_by_index, index)
    if max_jitter_deg <= 0 then return 0 end

    local angle_jitter_deg = jitter_by_index[index]
    if angle_jitter_deg == nil then
        angle_jitter_deg = 2*max_jitter_deg*(rand() - 0.5)
        jitter_by_index[index] = angle_jitter_deg
    end
    return angle_jitter_deg
end

--- Helper: get or create fan grab pad 
local function get_or_create_fan_grab_pad(max_pad, pad_by_index, index)
    if max_pad <= 0 then return 0 end

    local pad = pad_by_index[index];    if pad then return pad end 
    pad = 2*max_pad*(rand() - 0.5)
    pad_by_index[index] = pad
    return pad
end

-----------------------------
--- fan geometry
----------------------------
--- Helpers: fan_angle | fan_center | fan_card_xy
local function fan_angle(start_deg, spread_deg, size, index) return math.rad(start_deg + (((size <= 1) and 0) or ((index - 1)/(size - 1)))*spread_deg) end
local function fan_center(angle, fan_center_x, fan_center_y, radius) return fan_center_x + sin(angle)*radius, fan_center_y - cos(angle)*radius end
local function fan_card_xy(T, card, cx, cy, x_fit) return (cx - T.x)*x_fit + T.x, cy - 0.5*card.T.h end

--- Helper: axis anchor shift
local function axis_anchor_shift(mode, zone_pos, zone_size, first_pos, last_pos, last_size, offset)
    if mode == "center" or mode == "middle" then return zone_pos + 0.5*(zone_size - ((last_pos + last_size) - first_pos)) - first_pos + offset end
    if mode == "right" or mode == "bottom" then return zone_pos + zone_size - (last_pos + last_size) + offset end
    return zone_pos - first_pos + offset
end

--- Helper: fan layout anchor
local function fan_layout_anchor(cfg, T, cards, size, fan_center_x, fan_center_y, radius, start_deg, spread_deg, x_fit)
    local first, last             = cards[1], cards[size]
    local first_a, last_a         = fan_angle(start_deg, spread_deg, size, 1), fan_angle(start_deg, spread_deg, size, size)
    local first_cx, first_cy      = fan_center(first_a, fan_center_x, fan_center_y, radius)
    local last_cx,  last_cy       = fan_center(last_a,  fan_center_x, fan_center_y, radius)
    local first_x,  first_y       = fan_card_xy(T, first, first_cx, first_cy, x_fit)
    local last_x,   last_y        = fan_card_xy(T, last,  last_cx,  last_cy,  x_fit)
    local anchor_x                = axis_anchor_shift(cfg.fan_anchor_x or cfg.fan_anchor or "left", T.x, T.w, first_x, last_x, last.T.w, cfg.fan_offset_x or 0)
    local anchor_y                = axis_anchor_shift(cfg.fan_anchor_y or "top", T.y, T.h, first_y, last_y, last.T.h, cfg.fan_offset_y or 0)
    return anchor_x, anchor_y
end

--- Helper: align cards in fan order
function HandZone:_align_cards_in_fan(T, cards, size, fan_center_x, fan_center_y, radius, start_deg, spread_deg, max_jitter_deg, max_grab_pad, x_fit)
    local gm = self.gm
    local jitter_by_index, pad_by_index  = self.fan_grab_angle_jitter_deg, self.fan_grab_pad_by_index
    local anchor_x, anchor_y             = fan_layout_anchor(self.config or {}, T, cards, size, fan_center_x, fan_center_y, radius, start_deg, spread_deg, x_fit)

    for i, card in ipairs(cards) do
        if is_interacting(card) then goto continue end

        local cT, grab_pad         = card.T, get_or_create_fan_grab_pad(max_grab_pad, pad_by_index, i)
        local angle_jitter_deg     = get_or_create_fan_grab_jitter_deg(max_jitter_deg, jitter_by_index, i)
        local angle                = fan_angle(start_deg + angle_jitter_deg, spread_deg, size, i)
        local cx, cy               = fan_center(angle, fan_center_x, fan_center_y, radius)

        cx, cy       = render_highlighted(gm, card, angle, cx, cy)

        cT.r, cT.x, cT.y = angle, (cx - T.x)*x_fit + T.x + anchor_x + grab_pad, cy - 0.5*cT.h + anchor_y + grab_pad

        local sp = card.shadow_parallax
        if sp then cT.x, cT.y = cT.x + sp.x/30, cT.y + sp.y/30 end
        ::continue::
    end
end

---__________________________
--- main: align_cards
---__________________________
function HandZone:align_cards()
    local cfg, cards  = self.config,  self.cards
    local T,   size   = self.T,       #cards
    if size == 0 then return end

    local palm_offset,    max_jitter_deg  = cfg.palm_offset or 40,     cfg.fan_grab_jitter_deg or 0
    local cw, ch,         radius          = self.card_w,               self.card_h,        palm_offset + self.card_h
    local fan_center_x,   fan_center_y    = T.x + T.w/2,               T.y + T.h + palm_offset + self:deck_hover_y_offset()
    local max_grab_pad,   step_deg        = cfg.fan_grab_pad or 0,     cfg.step_deg or 1.7
    local max_spread_deg, x_fit           = cfg.max_spread_deg or 50,  1

    local spread_deg = min(max(size - 1, 0)*step_deg, max_spread_deg)
    if abs(spread_deg - max_spread_deg) < 0.5 then step_deg = max_spread_deg/size end
    local start_deg = -0.5*spread_deg

    local estimated_width = 2*radius*sin(math.rad(spread_deg/2)) + 2*cw
    if estimated_width > T.w then x_fit = T.w/estimated_width end

    self:_align_cards_in_fan(T, cards, size, fan_center_x, fan_center_y, radius, start_deg, spread_deg, max_jitter_deg, max_grab_pad, x_fit)

    if cfg.enable_drag_sort and needs_drag_sort(cards) then enqueue_drag_sort(self, cfg) end
    set_card_ranks(cards)
    self.card_layout_dirty = N
end

end
