local HookRunner = require("HMEng.ui_actors.common.hooks")

local Y, N = true, false

return function(Controller)
--------------------------------------------------
--- Helper: secondary action target
--------------------------------------------------
function Controller:_secondary_action_target()
    local hovered = self.hovering and self.hovering.target
    local focused = self.focused and self.focused.target
    local hcfg    = hovered and not hovered.REMOVED and hovered.config
    local fcfg    = focused and not focused.REMOVED and focused.config

    if self.HID and self.HID.controller then
        if fcfg and fcfg.secondary_action then return focused end
        if hcfg and hcfg.secondary_action then return hovered end
        if fcfg then return focused end
        if hcfg then return hovered end
        return
    end

    if hcfg and hcfg.secondary_action then return hovered end
    if hovered and not hovered.REMOVED then return hovered end
end

--------------------------------------------------
--- Main: activate secondary action
--------------------------------------------------
function Controller:activate_secondary_action(action)
    if self.UI and self.UI.modal_backdrop then return N end

    local target = self:_secondary_action_target()
    local cfg    = target and target.config
    if not (cfg and cfg.secondary_action == action and cfg.secondary_hook_fn) then return N end

    local old_hook = cfg.hook_fn
    cfg.hook_fn = cfg.secondary_hook_fn
    local result = HookRunner.run_hook(target, target.gm or self.gm or G)
    cfg.hook_fn = old_hook
    return result ~= N
end

end
