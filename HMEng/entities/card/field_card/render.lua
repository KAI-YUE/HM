return function (FieldCard)
local contains = require("HMfns.utils.table_utils").contains
local DebugFlags = require("HMGmgr.data.global.flags.debug_flags")

local T_ch = { "focused_ui", "front", "back", "soul_parts", "template", "floating_sprite", "shadow", "use_button", "buy_button", "buy_and_use_button", "debuff", "price", "particles", "h_popup", "mesh_card" }

-------------------------------------------
--- FieldCard
-------------------------------------------
--- Helper: debug skip render
local function _debug_skip_field_card_render(self) local cfg = self.zone and self.zone.config; return DebugFlags.fps.skip_field_card_render and cfg and cfg.type == "field" end

--- Main: draw
function FieldCard:draw() if _debug_skip_field_card_render(self) then return end; return FieldCard.super.draw(self) end

--- Helper: _draw_shadow
function FieldCard:_draw_shadow()
    local gm,  VT,   ch  = self.gm, self.VT,   self.children
    local SET, zone, st  = gm.SET,  self.zone, self.states

    local is_dragging, is_hovering = st.drag.is, st.hover.is
    if zone and zone.is_hand and zone:is_hand() and not (is_dragging or is_hovering) then return end
    if gm:is_shadow_off() then return end

    for _, v in pairs(ch) do v.VT.scale = VT.scale end

    local is_play_highlighted = self.highlighted and (zone == gm.play)
    local board, cell = zone and zone.boardzone, self.cell or {}
    local preview = board and board.move_preview
    local endpoint_key = cell.row and cell.col and (tostring(cell.row) .. ":" .. tostring(cell.col))
    local is_move_endpoint = preview and preview.endpoints and preview.endpoints[endpoint_key] ~= nil
    local sh = self.field_shadow_heights or self.shadow_heights or {}
    self.shadow_height = sh.idle or 0.01
    
    if is_move_endpoint then self.shadow_height = sh.hover or (1.2*self.shadow_height) end
    if is_play_highlighted or is_dragging then self.shadow_height = sh.active or (1.5*self.shadow_height) end
    if is_hovering then self.shadow_height = sh.hover or (1.2*self.shadow_height) end

    local mesh_card = ch.mesh_card
    if mesh_card and mesh_card:is_ready() then return mesh_card:draw_shadow(self.template_shader, self.shadow_height) end

    local shadow = (self.sprite_facing == "front" and ch.template) or ch.back
    shadow.tilt_shadow = self.tilt_shadow
    shadow:draw_shader(self.template_shader, self.shadow_height)
end

--- Helper: draw children
function FieldCard:_draw_children(gm)
    local ch,       cfg,        args  = self.children,     self.config,   self.args
    local sfacing,  _T,     btn   = self.sprite_facing, gm._T,        ch.buy_button
    local now,      ctemplate,  bub   = _T.real_s,       ch.template,  ch.buy_and_use_button
    local front,    mesh_card,  zone  = ch.front,           ch.mesh_card, self.zone

    if ch.particles then ch.particles:draw() end
    if ch.price     then ch.price:draw() end

    self:_render_btn(btn, bub, ch)

    local mesh_ready = (not (zone and zone.is_hand and zone:is_hand())) and mesh_card and mesh_card:is_ready()
    if not mesh_ready then return end
    
    local overlay = (sfacing == "back") and self:_get_back_overlay() 
    mesh_card:draw(overlay)
end

end
