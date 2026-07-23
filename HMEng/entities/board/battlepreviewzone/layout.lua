local max, min = math.max, math.min
local ceil     = math.ceil
local N        = false

return function (BattlePreviewZone)
--------------------------------------------------
--- adaptive layout helpers
--------------------------------------------------
local function preview_bounds(self)
    local cfg, T = self.config, self.T
    local pad_x = cfg.preview_pad_x or 0.65
    local pad_top = cfg.preview_pad_top or 0.55
    local pad_bottom = cfg.preview_pad_bottom or 0.65
    local pad_right = cfg.preview_pad_right or pad_x
    return {
        x = T.x + pad_x, y = T.y + pad_top,
        w = max(0, T.w - pad_x - pad_right),
        h = max(0, T.h - pad_top - pad_bottom),
    }
end

local function layout_candidate(self, count, cols, bounds)
    local cfg = self.config
    local rows = ceil(count/cols)
    local overlap_x = min(0.85, max(0, cfg.preview_overlap_x or 0.32))
    local overlap_y = min(0.85, max(0, cfg.preview_overlap_y or 0.20))
    local stride_x = 1 - overlap_x
    local stride_y = 1 - overlap_y
    local base_w = self.card_w*(1 + max(0, cols - 1)*stride_x)
    local base_h = self.card_h*(1 + max(0, rows - 1)*stride_y)
    local scale = min(bounds.w/max(base_w, 1e-6), bounds.h/max(base_h, 1e-6), cfg.preview_max_scale or 1)
    return { cols = cols, rows = rows, scale = scale, stride_x = stride_x, stride_y = stride_y }
end

local function better_layout(candidate, best)
    if not best or candidate.scale > best.scale + 1e-6 then return candidate end
    if candidate.scale < best.scale - 1e-6 then return best end
    if candidate.rows < best.rows then return candidate end
    return best
end

local function solve_layout(self, count)
    local bounds = preview_bounds(self)
    local best
    for cols = 1, max(1, count) do best = better_layout(layout_candidate(self, count, cols, bounds), best) end

    best = best or layout_candidate(self, 1, 1, bounds)
    best.bounds = bounds
    best.card_w, best.card_h = self.card_w*best.scale, self.card_h*best.scale
    best.content_w = best.card_w*(1 + max(0, best.cols - 1)*best.stride_x)
    best.content_h = best.card_h*(1 + max(0, best.rows - 1)*best.stride_y)
    best.x = bounds.x + 0.5*(bounds.w - best.content_w)
    best.y = bounds.y + 0.5*(bounds.h - best.content_h)
    return best
end

local function card_quad(layout)
    local w, h = layout.card_w, layout.card_h
    return { { x = 0, y = 0 }, { x = w, y = 0 }, { x = w, y = h }, { x = 0, y = h } }
end

--------------------------------------------------
--- main: align cards
--------------------------------------------------
function BattlePreviewZone:align_cards()
    local cards = self.cards
    if not cards or #cards == 0 then self.layout, self.card_layout_dirty = nil, N; return end

    local layout = solve_layout(self, #cards)
    self.layout = layout
    for idx, card in ipairs(cards) do
        local row = math.floor((idx - 1)/layout.cols)
        local col = (idx - 1)%layout.cols
        local cT = card.T
        cT.x = layout.x + col*layout.card_w*layout.stride_x
        cT.y = layout.y + row*layout.card_h*layout.stride_y
        cT.w, cT.h, cT.r, cT.scale = layout.card_w, layout.card_h, 0, 1
        card.rank = idx
        card:hard_set_T(cT.x, cT.y, cT.w, cT.h)
        card:assign_field_quad(card_quad(layout))
    end
    self.card_layout_dirty = N
end
end
