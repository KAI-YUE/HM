local M = {}

-----------------------------
--- hint hook
-----------------------------
function M.hint_hook(args)
    if args.hook_fn                 then return args.hook_fn end
    if args.options_tab_step        then return "opt_tab_step" end
    if args.hid_action == "delete"  then return function(gm) return gm.CTRL:activate_secondary_action("delete") end end
    if args.hid_action == "cancel"  then return "options2pause_menu" end
    if args.hid_action == "start"   then return "open_system_settings_confirm" end
    if args.hid_action == "done"    then return "open_system_settings_confirm" end
end

return M
