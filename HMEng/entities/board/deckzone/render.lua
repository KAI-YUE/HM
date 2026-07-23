local TabUtils = require("HMfns.utils.table_utils")
local Composite = require("HMEng.visual.composite_layer")
local Render   = require("HMfns.systems.render")
local LG       = love.graphics

local contains          = TabUtils.contains
local enqueue_drawable  = Render.enqueue_drawable
local max, min, ceil    = math.max, math.min, math.ceil

local Y, N = true, false

return function (DeckZone)

local _default_hover_shadow_alpha = 0.95
--------------------------------------------------
--- draw
--------------------------------------------------
--- Helper: thin draw 
function DeckZone:_thin_draw(i, cfg, _sc)
    local st = _sc[i].states
    if st.focus.is or st.drag.is      then return N end
    if i == 1 or i == #_sc            then return Y end
    if (i%(cfg.thin_draw or 2) == 0)  then return Y end -- special position 
    return N 
end

--- Helper: thin shadow
function DeckZone:_thin_shadow(i, cfg, _sc)
    local st = _sc[i].states
    if st.focus.is or st.drag.is  then return N end
    if i == 1 or i == #_sc        then return Y end
    return i%(cfg.thin_shadow or 10) == 0
end

--- Helper: _hover_shadow_amount
local function _hover_shadow_amount(self)
    local h = max(0, min(1, self.hover_t or 0));    if h <= 0.01 then return 0, 0 end
    return h, h*(self.config.hover_shadow_alpha or _default_hover_shadow_alpha)
end

--- Helper: _ensure_shadow_mask
local function _ensure_shadow_mask(self, target)
    if not target then return end

    local w, h  = target:getDimensions()
    return Composite.ensure_canvas(self, "hover_shadow_mask", w, h)
end

--- Helper: _add_shadow_card
local function _add_shadow_card(cards, card)
    if not card then return end
    for _, v in ipairs(cards) do if v == card then return end end
    cards[#cards + 1] = card
end

--- Helper: hover_shadow_cards
local function _hover_shadow_cards(_sc)
    local cards, count = {}, #_sc
    _add_shadow_card(cards, _sc[1])
    _add_shadow_card(cards, _sc[ceil(count/2)])
    _add_shadow_card(cards, _sc[count])
    return cards
end

--- Helper: draw_card_hover_shadow 
local function _draw_card_hover_shadow(card, shadow_h, alpha)
    local mesh_card = card.children and card.children.mesh_card
    if not (mesh_card and mesh_card:is_ready()) then return end

    local old_alpha = card.draw_alpha
    card.draw_alpha = (old_alpha or 1)*alpha
    mesh_card:draw_shadow(card.template_shader, shadow_h)
    card.draw_alpha = old_alpha
end

--- Helper: render_shadow_mask 
local function _render_shadow_mask(self, _sc, mask, shadow_h)
    Composite.render_to_canvas(mask, { blend = "lighten", alpha_mode = "premultiplied" }, function()
        for _, card in ipairs(_hover_shadow_cards(_sc)) do _draw_card_hover_shadow(card, shadow_h, 1) end
    end)
end

--- Helper: draw_shadow_mask 
local function _draw_shadow_mask(mask, alpha, color)
    Composite.draw_canvas(mask, { origin = Y, color = color or { 0, 0, 0, 1 }, alpha = alpha, blend = "alpha", alpha_mode = "alphamultiply" })
end

--- Helper: draw_hover_shadow
function DeckZone:_draw_hover_shadow(_sc)
    if self.gm:is_shadow_off() then return end
    local h, alpha = _hover_shadow_amount(self)
    if alpha <= 0 or not _sc[1] then return end

    local shadow_h = (self.config.hover_shadow_height or 0.20)*h
    local mask = _ensure_shadow_mask(self, LG.getCanvas())
    if not mask then return end

    _render_shadow_mask(self, _sc, mask, shadow_h)
    _draw_shadow_mask(mask, alpha, self.config.hover_shadow_color)
end

---__________________________________
--- main: draw 
---__________________________________
function DeckZone:draw()
    local gm, st = self.gm, self.states;        if not st.visible then return end

    local Tzone = { gm.deck, gm.hand, gm.play, gm.discard }
    if gm.VIEWING_DECK and contains(Tzone, self) and gm.deck_preview_preserve_source ~= self then return end

    local cfg, _sc = self.config, self.cards
    self:bound_me()
    enqueue_drawable(self.t_drawable, self)

    self:_draw_hover_shadow(_sc)
    for i = #_sc, 1, -1 do 
        if self:_thin_shadow(i, cfg, _sc) then _sc[i]:draw_shadow_only() end
        if self:_thin_draw(i, cfg, _sc)   then _sc[i]:draw_without_shadow() end end
end

end
