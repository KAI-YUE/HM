local AnimUtils = require("HMfns.animate.transitions.anim_utils")
local Settings  = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.settings")

local ENTER, EXIT = Settings.ENTER, Settings.EXIT

local M = {}

-----------------------------
--- timing helpers
-----------------------------
function M.mini_at(delay)                      return ENTER.start_delay + delay end
function M.ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, ENTER.queue) end
function M.after(gm, delay, fn)                return AnimUtils.after(gm, delay, fn, ENTER.queue) end
function M.ease_exit(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, EXIT.queue) end

--- Helper: dilated_spring
function M.dilated_spring(spring, dilation)
    if (dilation or 1) == 1 then return spring end
    
    local dilated = {}
    for i, step in ipairs(spring or {}) do dilated[i] = { t = (step.t or 0)*dilation, x = step.x, y = step.y, ease = step.ease } end
    return dilated
end

return M
