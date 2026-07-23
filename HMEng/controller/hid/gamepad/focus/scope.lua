local Card = require("HMEng.entities.card")
local Pawn = require("HMEng.entities.pawn")

local Y, N = true, false

local M = {}

--- Helper: wake zone layout
function M.wake_zone_layout(node)
    local zone = node and node.zone
    if node and node.is and node:is(Pawn) and zone and zone.config and zone.config.type == "field" then return end
    if node and node.is and node:is(Pawn) and zone and zone.mark_pawn_layout_dirty then zone:mark_pawn_layout_dirty(); return end
    if zone and zone.mark_card_layout_dirty then zone:mark_card_layout_dirty() end
end

--- Helper: page state
function M.on_title_page(self) local gm = self.gm; return gm and gm.stages and gm.g_stage == gm.stages.title_page end
function M.on_pause_page(self) local gm, OM = self.gm, self.UI and self.UI.overlay_menu; return gm and gm.SET and gm.SET.pause and OM end
function M.ingame_scope_active(self)
    local gm = self.gm;                              if not (gm and gm.hand) then return N end
    if gm.SET and gm.SET.pause then return N end
    if M.on_title_page(self) then return N end
    return Y
end

--- Helper: node scope
function M.active_scope(self) return (self.navigate_field or self.gamepad_focus_scope == "field") and "field" or "hand" end
function M.node_scope(self, node)
    local gm, zone = self.gm, node and node.zone;       if not gm then return end
    if zone == gm.hand then return "hand" end
    if zone == gm.field or zone == gm.gridzone then return "field" end
    if node and node.is and node:is(Card) then return "field" end
end

--- Helper: first in-game hand focus
function M.first_ingame_hand_focus(self)
    local gm = self.gm;                              if not (gm and gm.hand and gm.hand.cards) then return end
    if self.navigate_field then return end
    if gm.SET and gm.SET.pause then return end
    if M.on_title_page(self) then return end
    self.gamepad_focus_scope = self.gamepad_focus_scope or "hand"
    if self.gamepad_focus_scope ~= "hand" then return end
    return gm.hand.cards[1]
end

--- Helper: field scope
local function _ingame_field_scope(self)
    local gm = self.gm;                              if not (self.navigate_field or self.gamepad_focus_scope == "field") or not (gm and gm.gridzone) then return end
    if gm.SET and gm.SET.pause then return end
    if M.on_title_page(self) then return end
    return gm
end

function M.field_scope_allows_node(self, node)
    if not _ingame_field_scope(self) then return Y end
    local scope = M.node_scope(self, node)
    return not scope or scope == "field"
end

--- Helper: hand scope
function M.hand_scope_blocks_node(self, node)
    if not M.ingame_scope_active(self) or M.active_scope(self) == "field" then return N end
    return M.node_scope(self, node) == "field"
end

--- Helper: cursor layer
function M.cursor_layer_allows_node(self, node)
    local layer = self.cursor_context and self.cursor_context.layer or 1
    if layer <= 1 then return Y end
    return node and (node.interaction_layer or 1) == layer
end

--- Helper: focus scope
function M.focus_scope_allows_node(self, node)
    if not M.cursor_layer_allows_node(self, node) then return N end
    if not M.ingame_scope_active(self) then return Y end
    local scope = M.node_scope(self, node);               if not scope then return Y end
    return scope == M.active_scope(self)
end

--- Helper: hand card focus hover
function M.apply_hand_card_focus_hover(self, node)
    local gm, zone = self.gm, node and node.zone
    if self.navigate_field then return end
    if not (gm and zone and zone == gm.hand and node.is and node:is(Card)) then return end
    local hst = node.states and node.states.hover;       if not hst then return end
    if not hst.is and node.hover then node:hover() end
    hst.can, hst.is = Y, Y
    M.wake_zone_layout(node)
end

function M.install(Controller)
    function Controller:field_scope_allows_node(node) return M.field_scope_allows_node(self, node) end
    function Controller:focus_scope_allows_node(node) return M.focus_scope_allows_node(self, node) end
end

return M
