local Y, N = true, false

local M = {}

--- Helper: clear child focus hover
function M.clear_child_focus_hover(node)
    local st = node and node.states
    if st and st.focus then st.focus.is = N end
    if st and st.hover then st.hover.is = N end
    for _, child in ipairs((node and node.children) or {}) do M.clear_child_focus_hover(child) end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do M.clear_child_focus_hover(child) end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do M.clear_child_focus_hover(child) end
end

--- Helper: field nav blocks hand node
function M.field_nav_blocks_hand_node(self, node)
    local gm = self.gm
    return self.navigate_field and gm and gm.hand and node and node.zone == gm.hand
end

--- Helper: gamepad scope allows node
function M.gamepad_scope_allows_node(self, node)
    if not (self.HID and self.HID.controller and self.focus_scope_allows_node) then return Y end
    return self:focus_scope_allows_node(node)
end

--- Helper: tree contains node
function M.tree_contains_node(root, node)
    if not (root and node) then return N end
    if root == node then return Y end
    for _, child in ipairs(root.children or {}) do if M.tree_contains_node(child, node) then return Y end end
    for _, child in ipairs(root.page_child_widgets or {}) do if M.tree_contains_node(child, node) then return Y end end
    for _, child in ipairs(root.page_card_textfx or {}) do if M.tree_contains_node(child, node) then return Y end end
    return N
end

--- Helper: cursor owner allows node
local function _cursor_owner_allows_node(owner, node)
    if not owner then return N end
    if M.tree_contains_node(owner.widget, node) or M.tree_contains_node(owner.attached_panel, node) then return Y end
    local allows = owner.cursor_context_allows_node
    return allows and allows(node) or N
end

--- Helper: modal cursor allows node
function M.modal_cursor_allows_node(self, node)
    local gm, OM, DT = self.gm, self.UI and self.UI.overlay_menu, self.gm and self.gm.debug_tools
    local modal = self.UI and self.UI.modal_backdrop and self.UI.modal_backdrop.owner
    if DT and not DT.REMOVED and _cursor_owner_allows_node(DT, node) then return Y end
    if modal and not modal.REMOVED then return _cursor_owner_allows_node(modal, node) end
    if not (gm and gm.SET and gm.SET.pause and OM) then return Y end
    return _cursor_owner_allows_node(OM, node)
end

--- Helper: clear hover node
function M.clear_hover_node(node)
    if not node then return end
    if node.stop_hover then node:stop_hover(); return end
    if node.states and node.states.hover then node.states.hover.is = N end
end

return M
