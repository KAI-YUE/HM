local M = {}

--- Helper: push focusable
function M.push_focusable(self, node, list)
    if not self:focus_scope_allows_node(node) then return end
    if not self:is_focusable(node) then return end
    node.states.focus.can = true
    for _, v in ipairs(list) do if v == node then return end end
    table.insert(list, node)
end

--- Helper: collect focusable nodes
function M.collect_focusables(self, node, list)
    M.push_focusable(self, node, list)
    local fargs = node and node.config and node.config.focus_args
    if fargs and fargs.type and fargs.type:match("_row$") then return end
    for _, child in ipairs((node and node.children) or {}) do M.collect_focusables(self, child, list) end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do M.collect_focusables(self, child, list) end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do M.collect_focusables(self, child, list) end
end

--- Helper: build focusable candidates
function M.build_focusable_candidates(self, dir, fct, args, Scope, Targets)
    args = args or self.args
    fct  = fct  or self.focused.target
    local afcs = args.focusables
    if not dir and fct then if self:focus_scope_allows_node(fct) then fct.states.focus.can = true; table.insert(afcs, fct) end; return
    elseif not dir then
        for _, v in ipairs(self.nodes_at_cursor) do
            local vfc = v.states.focus;     vfc.can, vfc.is = false, false
            if not self:focus_scope_allows_node(v) then goto continue end
            if #afcs ~= 0 or not self:is_focusable(v) then goto continue end
            vfc.can = true;                 table.insert(afcs, v)
            ::continue::
        end
        return
    end
    if Scope.on_pause_page(self) then
        local OM = self.UI.overlay_menu
        M.collect_focusables(self, OM.widget, afcs)
        M.collect_focusables(self, OM.attached_panel, afcs)
        return
    end
    if Scope.on_title_page(self) then
        local panel = Targets.title_panel(self)
        M.collect_focusables(self, panel and panel.widget, afcs)
        M.collect_focusables(self, panel and panel.attached_panel, afcs)
    end
    if self.UI and self.UI.overlay_menu then
        M.collect_focusables(self, self.UI.overlay_menu.widget, afcs)
        M.collect_focusables(self, self.UI.overlay_menu.attached_panel, afcs)
    end
    local gm, field_allowed = self.gm, self.gamepad_focus_scope == "field"
    for _, v in pairs(self.t_actors or {}) do
        local vfc = v.states.focus
        vfc.can, vfc.is = false, false
        if field_allowed and not self:focus_scope_allows_node(v) then goto continue end
        if gm and gm.gridzone and v.zone == gm.gridzone and not field_allowed then goto continue end
        M.push_focusable(self, v, afcs)
        ::continue::
    end
end

return M
