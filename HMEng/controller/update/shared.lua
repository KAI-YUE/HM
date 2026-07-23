local M = {}

local Y, N = true, false

M.Y = Y
M.N = N
M.ta = "after"
M.tU = "session_s"
M.input_update_groups = {
    { values = "pressed_keys",      fn = "key_press_update" },
    { values = "held_keys",         fn = "key_hold_update" },
    { values = "released_keys",     fn = "key_release_update" },
    { values = "pressed_buttons",   fn = "button_press_update" },
    { values = "held_buttons",      fn = "button_hold_update" },
    { values = "released_buttons",  fn = "button_release_update" },
}

-----------------------------------------------------------
--- Helper: enqueue_after
-----------------------------------------------------------
function M.enqueue_after(event_mgr, delay, func, args)
    args = args or {}
    
    args.trigger,   args.delay  = M.ta, delay
    args.blockable, args.func   = (args.blockable == nil) and N or args.blockable, func
    event_mgr:enqueue_event(args)
    return Y
end

return M
