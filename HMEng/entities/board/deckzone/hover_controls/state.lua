local Card = require("HMEng.entities.card")

local max, min = math.max, math.min
local Y, N = true, false

return function (DeckZone)
--------------------------------------------------
--- hover control state helpers
--------------------------------------------------
local function clicked_non_deck_card(self)
    local Ctrl   = self.Ctrl
    local c      = Ctrl.clicked
    local target = c and c.target;      if not target or (target == self.last_hover_control_click_target) then return N end

    self.last_hover_control_click_target = target
    return target.is and target:is(Card) and target.zone ~= self
end

local function cursor_far_from_deck(self)
    local Ctrl = self.Ctrl
    local p, T = Ctrl.p_cursor and Ctrl.p_cursor.T, self.T
    if not p then p = Ctrl and Ctrl.cursor_hover and Ctrl.cursor_hover.T end
    if not (p and T) then return N end

    local cfg = self.config
    local controls_w = (cfg.hover_control_x_offset or 0.28) + (cfg.hover_control_w or cfg.hover_control_button_w or 1.8)
    local margin = cfg.hover_control_far_dist or max(self.card_w or 0, self.card_h or 0, T.w or 0, T.h or 0, controls_w + 0.4)
    return p.x < T.x - margin or p.x > T.x + T.w + margin or p.y < T.y - margin or p.y > T.y + T.h + margin
end

--------------------------------------------------
--- explicit cancel suppression helpers
--------------------------------------------------
local function cursor_in_hover_hit_area(self)
    local Ctrl = self.Ctrl
    local p = Ctrl.p_cursor and Ctrl.p_cursor.T
    if not p then p = Ctrl.cursor_hover and Ctrl.cursor_hover.T end
    if not p then return Y end

    local T, panel = self.T, self.hover_controls
    local pT = panel and panel.T
    local pad = self.config.hover_control_hit_padding or self.cbuffer or 0
    local x1, y1 = T.x, T.y
    local x2, y2 = T.x + T.w, T.y + T.h
    if pT then
        x1, y1 = min(x1, pT.x), min(y1, pT.y)
        x2, y2 = max(x2, pT.x + pT.w), max(y2, pT.y + pT.h)
    end
    return p.x >= x1 - pad and p.x <= x2 + pad and p.y >= y1 - pad and p.y <= y2 + pad
end

local function update_explicit_cancel_suppression(self)
    if not self.hover_controls_suppressed then return end
    if not cursor_in_hover_hit_area(self) then self.hover_controls_suppressed = N end
end

--------------------------------------------------
--- _update_hover_control_latch
--------------------------------------------------
function DeckZone:_update_hover_control_latch()
    local st = self.states
    update_explicit_cancel_suppression(self)
    local should_open = st and st.hover and st.hover.is and not self.hover_controls_suppressed
    if should_open and not self.hover_controls_open then
        self.hover_controls_open, self.deck_hover_extended = Y, Y
        self.last_hover_control_click_target = self.gm.CTRL.clicked and self.gm.CTRL.clicked.target
    end
    if not self.hover_controls_open then return end
    if cursor_far_from_deck(self)   then self.deck_hover_extended = N; self:close_hover_controls(); return end
    if clicked_non_deck_card(self)  then self:close_hover_controls() end
end

--------------------------------------------------
--- main: update_hover_controls
--------------------------------------------------
function DeckZone:update_hover_controls()
    if self.gm.VIEWING_DECK then self.hover_controls_open, self.deck_hover_extended = N, N; self:_set_panel_visible(self.hover_controls, N); return end
    self:_update_hover_control_latch()

    local panel = self.hover_controls
    local visible = not self.hover_controls_suppressed and (self.hover_controls_open or self:_hover_controls_visible(panel))
    panel = visible and self:_ensure_hover_controls() or panel;         if not panel then return end

    self:_position_hover_controls(panel)
    self:_set_panel_visible(panel, visible)
end

--------------------------------------------------
--- cancel_hover_controls
--------------------------------------------------
function DeckZone:cancel_hover_controls(explicit)
    if explicit then self.hover_controls_suppressed = Y end
    self.deck_hover_extended = N
    self:close_deck_view()
    self:close_hover_controls()
end

--------------------------------------------------
--- remove_hover_controls
--------------------------------------------------
function DeckZone:remove_hover_controls()
    if self.hover_controls then self.hover_controls:remove(); self.hover_controls = nil end
end

end
