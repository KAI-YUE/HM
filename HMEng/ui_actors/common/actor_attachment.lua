local M = {}

----------------------------------
--- detach
----------------------------------
function M.detach(ui)
    local att = ui and ui._ui_actor_attachment;       if not att then return end
    
    local actor, slot = att.actor, att.slot
    if actor and actor.children and actor.children[slot] == ui then actor.children[slot] = att.previous end
    ui._ui_actor_attachment, ui.parent = nil, nil
end

-----------------------------------
--- attach 
-----------------------------------
function M.attach(ui, actor, args)
    args = args or {}
    local slot = args.slot or "use_button";           if not ui then return end
    local att  = ui._ui_actor_attachment
    
    if att and att.actor == actor and att.slot == slot then return end
    M.detach(ui)
    
    if not (actor and actor.children) then return end
    ui._ui_actor_attachment = { actor = actor, slot = slot, previous = actor.children[slot] }
    actor.children[slot], ui.parent = ui, actor
end

----------------------------------
--- hard_set_widget_tree
----------------------------------
function M.hard_set_widget_tree(widget, T)
    if not (widget and T) then return end
    widget:hard_set_T(T.x, T.y, T.w, T.h)
    for _, child in ipairs(widget.children or {}) do
        local cT, ro = child.T, child.role and child.role.offset or {}
        M.hard_set_widget_tree(child, { x = widget.T.x + (ro.x or 0), y = widget.T.y + (ro.y or 0), w = cT.w, h = cT.h })
    end
end

----------------------------------
--- hard_set_panel_tree
----------------------------------
function M.hard_set_panel_tree(panel, T)
    if not (panel and T) then return end
    panel:hard_set_T(T.x, T.y, T.w, T.h)
    M.hard_set_widget_tree(panel.widget, T)
end

return M
