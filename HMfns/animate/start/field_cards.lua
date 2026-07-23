local C, CUtils      = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local SoundUtils     = require("HMfns.utils.sound_utils")
local IntroTimeline  = require("HMfns.animate.start.intro_timeline")

local randomize_alpha = CUtils.randomize_alpha
local play_clip       = SoundUtils.play_clip
local rand            = math.random

local CFX  = C.FX_MASK
local Y, N = true, false

local M = {}

--------------------------------------------------
--- animate_field_cards_rise
--------------------------------------------------
--- Helpers: enqueue_event & cell_key 
local function _ease(EM, delay, ease, ref_table, ref_value, ease_to) EM:enqueue_event({ trigger = "ease", delay = delay, ease = ease, blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to }) end
local function _after(EM, delay, func)                               EM:enqueue_event({ trigger = "after", delay = delay, blockable = N, func = func }) end

--- Helper: row delay compensation
local function _row_delay_comp(entry, n_rows, row_step)
    local row = entry and entry.row or 1;     if n_rows <= 1 or row_step <= 0 then return 0 end
    return (n_rows - row) * row_step
end

--- Helper: path reveal order
local function _path_reveal_order(gridzone, path)
    local cells, ordered, used = path and path.cells or {}, {}, {}
    local n_cells = #cells
    local function _append_from_idx(idx)
        if idx < 1 or idx > n_cells or used[idx] then return end
        local cell = cells[idx]
        local row  = gridzone.cells and gridzone.cells[cell.row]
        local card = row and row[cell.col];                     if not card then return end
        used[idx] = Y
        ordered[#ordered + 1] = { card = card, row = cell.row, col = cell.col }
    end

    _append_from_idx(1)
    for offset = 1, n_cells - 1 do
        _append_from_idx(1 + offset)
        _append_from_idx(n_cells - offset + 1)
    end
    return ordered
end

--- Helper: collect reveal order
local function _collect_reveal_order(gridzone, paths)
    local per_path, ordered, max_count = {}, {}, 0
    for i, path in ipairs(paths or {}) do
        per_path[i] = _path_reveal_order(gridzone, path)
        max_count = math.max(max_count, #per_path[i])
    end
    for card_idx = 1, max_count do
        for _, entries in ipairs(per_path) do if entries[card_idx] then ordered[#ordered + 1] = entries[card_idx] end end
    end
    return ordered
end

--- Helper: set reveal pose 
local function _set_reveal_pose(card, cell_h)
    local reveal = card.field_reveal or {}

    reveal.x, reveal.y      = 0.1*cell_h, 0.2*cell_h
    reveal.r, reveal.scale  = 0.2*(rand()-0.5), 0.9 + 0.1*rand()
    
    card.field_reveal, card.fx_mask = reveal, 1
    card.fx_mask_colors             = card.fx_mask_colors or { CFX.SOFT_LIGHT, CFX.SOFT_DARK }
    for i = 1,2 do randomize_alpha(card.fx_mask_colors[i], 0.2) end 
end

--- Helper: show card
local function _show_card(card)
    local st = card and card.states;      if st then st.visible = Y end
    if card and (card.fx_mask or 0) >= 0.999 then card.fx_mask = 0.98 end
end

--- Helper: schedule suit shader reveal
local function _schedule_suit_shader_start(EM, cards, delay)
    if not delay or delay <= 0 then return end

    for _, entry in ipairs(cards) do
        local st = entry.card and entry.card.states and entry.card.states.suit_shader_visible
        if st then st.is = N end
    end

    _after(EM, delay, function()
        for _, entry in ipairs(cards) do
            local card = entry.card
            local st = card and card.states and card.states.suit_shader_visible
            if st and not (card.removed or card.REMOVED) then st.is = Y end
        end
        return Y
    end)
end

---______________________________________________
--- animate_field_cards_rise
---______________________________________________
function M.animate_field_cards_rise(gm)
    local field,     EM             = gm.field, gm.E_MANAGER
    local gridzone                  = field and field.gridzone;                                 if not field or not gridzone or not EM then return end
    local reveal_order              = _collect_reveal_order(gridzone, field.paths or { field.path }); if #reveal_order == 0 then return end
    local timeline,  cell_h         = IntroTimeline.field,  gridzone.cell_h or gm.card_h or 1
    local n_rows                    = gridzone.n_rows or 1
    local ease_type, fade_type      = "cubic",              "lerp"

    _schedule_suit_shader_start(EM, reveal_order, timeline.suit_shader_start)
    
    local pawns = gm.party_pawns or { gm.field_pawn }
    _after(EM, timeline.pawn_reveal, function() for _, pawn in ipairs(pawns) do if pawn then pawn:bounce_me() end; end; return Y; end)

    for idx = 1, #reveal_order do
        local entry     = reveal_order[idx]
        local card      = entry.card
        local start     = timeline.cards_start
        local settle    = timeline.settle_start
        local reveal_t  = ((idx == 1) and timeline.reveal_t/1.5) or timeline.reveal_t
        local delay     = start

        if idx > 1 then delay = delay + settle + (idx - 2)*timeline.cards_step + reveal_t/1.5 end
        if idx > 1 then delay = delay - _row_delay_comp(entry, n_rows, timeline.row_delay_comp or 0) end

        _set_reveal_pose(card, cell_h)
        _after(EM, delay-1, function() _ease(EM, 1.2*reveal_t, fade_type, card, "fx_mask", 0); return Y; end)
        _after(EM, delay,   function()
            if card.removed or not card.field_reveal then return Y end
            -- play_clip(gm, "cardFan2", 0.95 + 0.15*rand(), 0.28)

            local reveal = card.field_reveal
            _show_card(card)
            _ease(EM, reveal_t,  ease_type,    reveal, "y",     0)
            _ease(EM, reveal_t,  ease_type,    reveal, "x",     0)
            _ease(EM, reveal_t,  ease_type,    reveal, "scale", 1.0)
            _ease(EM, reveal_t,  ease_type,    reveal, "r",    0)
            return Y
        end)
    end
end

return M
