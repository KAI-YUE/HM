local I18N      = require("HMfns.utils.format.i18n_utils")
local PanelArgs = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup.confirm_panel_args")
local Modal     = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup.confirm_modal")

local i18n = I18N.i18n

local M = {}

--- Helper: child_by_suffix
local function child_by_suffix(node, suffix)
    for _, child in ipairs((node and node.children) or {}) do
        local id = child.config and child.config.id
        if id and id:match(suffix .. "$") then return child end
        local found = child_by_suffix(child, suffix);       if found then return found end
    end
end

--- Helper: popup_text
local function popup_text(gm, key, fallback, opts)
    opts = opts or {}
    local text = i18n(gm, { type = opts.i18n_type or "menu", key = (opts.i18n_prefix or "items.") .. key, scope = opts.i18n_scope })
    return text or fallback
end

---____________________________
--- main: panel_args
---______________________________________
function M.panel_args(RT, args) return PanelArgs.make(RT, args) end

---____________________________
--- main: remove_popup
---______________________________________
function M.remove_popup(gm, args)
    local gUI = gm.UI;                         if not gUI then return end
    local popup = gUI[args.ui_key]
    if gm.clear_modal_backdrop then gm:clear_modal_backdrop(popup)
    elseif gUI.modal_backdrop and gUI.modal_backdrop.owner == popup then gUI.modal_backdrop = nil end
    if popup then popup:remove(); gUI[args.ui_key] = nil end
    if args.slot_key then gUI[args.slot_key] = nil end
end

---____________________________
--- main: cancel_active_popup
---______________________________________
function M.cancel_active_popup(gm)
    local popup = gm and gm.UI and gm.UI.modal_backdrop and gm.UI.modal_backdrop.owner;      if not popup or popup.REMOVED then return end
    local no = child_by_suffix(popup.widget, "_no");                                        if not (no and no.click) then return end
    no:click()
    return true
end

---____________________________
--- main: show_popup
---______________________________________
function M.show_popup(gm, args)
    local Panel = require("HMEng.ui_actors.hm_panel")
    local RT    = gm._room.T or { x = 0, y = 0, w = 10, h = 8 }
    local gUI   = gm.UI

    if gUI and gUI[args.ui_key] and (not args.slot_key or gUI[args.slot_key] == args.slot_idx) then return end
    M.remove_popup(gm, args)

    args.prompt  = popup_text(gm, args.prompt_key, args.prompt_fallback, { i18n_type = args.prompt_i18n_type, i18n_prefix = args.prompt_i18n_prefix, i18n_scope = args.prompt_i18n_scope })
    args.yes     = popup_text(gm, args.yes_key or "yes", args.yes_fallback or "Yes", { i18n_type = args.button_i18n_type, i18n_prefix = args.button_i18n_prefix, i18n_scope = args.button_i18n_scope })
    args.no      = popup_text(gm, args.no_key  or "no",  args.no_fallback  or "No", { i18n_type = args.button_i18n_type, i18n_prefix = args.button_i18n_prefix, i18n_scope = args.button_i18n_scope })

    local popup = Panel(gm, PanelArgs.make(RT, args))
    gUI = gm.UI
    gUI[args.ui_key] = popup
    
    if args.slot_key then gUI[args.slot_key] = args.slot_idx end
    Modal.set_backdrop(gm, popup)
    Modal.reveal_next_frame(gm, popup, args)
end

return M
