local TITLE_FOCUS_IDS = { "new_game", "continue", "options", "quit", "press_any", "back" }
local PAUSE_FOCUS_IDS = { "continue", "load", "save", "options", "return_title" }

local Y, N = true, false

local M = { TITLE_FOCUS_IDS = TITLE_FOCUS_IDS, PAUSE_FOCUS_IDS = PAUSE_FOCUS_IDS }

--- Helper: active icon button
local function _active_icon_btn(node)
    local cfg = node and node.config
    local st = node and node.states
    return cfg and cfg.type == "icon_btn" and cfg.button and cfg.can_hover ~= N and not node.REMOVED and not node.disable_button and (not st or st.visible ~= N)
end

--- Helper: first active node
function M.first_active_node(self, node, prefer_icon)
    if node and ((prefer_icon and _active_icon_btn(node)) or ((not prefer_icon) and self:is_focusable(node))) then return node end
    for _, child in ipairs((node and node.children) or {}) do local found = M.first_active_node(self, child, prefer_icon); if found then return found end end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do local found = M.first_active_node(self, child, prefer_icon); if found then return found end end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do local found = M.first_active_node(self, child, prefer_icon); if found then return found end end
end

--- Helper: find node by id
function M.find_node_by_id(node, id)
    local cfg = node and node.config
    if cfg and (cfg.id == id or cfg.key == id) then return node end
    for _, child in ipairs((node and node.children) or {}) do local found = M.find_node_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do local found = M.find_node_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do local found = M.find_node_by_id(child, id); if found then return found end end
end

function M.find_panel_node_by_id(panel, id) if panel then return M.find_node_by_id(panel.widget, id) or M.find_node_by_id(panel.attached_panel, id) end end
function M.title_panel(self) local gm, UI = self.gm, self.UI or {}; return (gm and gm.title_page_UI) or UI.title_page_panel end
function M.first_panel_focus_target(self, panel) if panel then return M.first_active_node(self, panel.widget, Y) or M.first_active_node(self, panel.attached_panel, Y) or M.first_active_node(self, panel.widget, N) or M.first_active_node(self, panel.attached_panel, N) end end

--- Helper: auto snap focus target
function M.auto_snap_focus_target(self)
    local gm, UI, panel = self.gm, self.UI or {}, M.title_panel(self)
    local node = M.first_panel_focus_target(self, UI.overlay_menu); if node then return node end
    if gm and gm.SET and gm.SET.pause and UI.overlay_menu then return end
    for _, id in ipairs(TITLE_FOCUS_IDS) do
        node = M.find_panel_node_by_id(panel, id)
        if node and self:is_focusable(node) then return node end
    end
    node = M.first_panel_focus_target(self, panel) or M.first_panel_focus_target(self, gm and gm.debug_tools)
    if node then return node end
    for _, actor in pairs(self.t_actors or {}) do if self:focus_scope_allows_node(actor) and self:is_focusable(actor) then return actor end end
end

--- Helper: ordered focus
function M.ordered_focus_index(ids, node)
    local cfg = node and node.config;        if not cfg then return end
    local current = cfg.id or cfg.key;       if not current then return end
    for i, id in ipairs(ids) do if id == current then return i end end
end

function M.ordered_focus_step(self, panel, ids, fct, step)
    local idx = M.ordered_focus_index(ids, fct);       if not idx then return end
    for offset = 1, #ids do
        local node = M.find_panel_node_by_id(panel, ids[((idx - 1 + step*offset) % #ids) + 1])
        if node and self:is_focusable(node) then return node end
    end
end

--- Helper: title focus node by step
function M.title_focus_step(self, fct, step)
    local cfg = fct and fct.config;        if not cfg then return end
    local current = cfg.id or cfg.key;     if not current then return end
    local panel, idx = M.title_panel(self), nil
    for i, id in ipairs(TITLE_FOCUS_IDS) do if id == current then idx = i; break end end
    if not idx then return end
    for i = idx + step, step > 0 and #TITLE_FOCUS_IDS or 1, step do
        local node = M.find_panel_node_by_id(panel, TITLE_FOCUS_IDS[i])
        if node and self:is_focusable(node) then return node end
    end
end

return M
