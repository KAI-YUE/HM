local Colors = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup.confirm_colors")

local Y, N = true, false

local M = {}

---____________________________
--- main: set_backdrop
---______________________________________
function M.set_backdrop(gm, popup) if not gm.UI then return end; gm.UI.modal_backdrop = { owner = popup, dirty = Y, shader = "mc", blur_radius = 5., dim_color = Colors.backdrop_dim } end

---____________________________
--- main: reveal_next_frame
---______________________________________
function M.reveal_next_frame(gm, popup, args)
    local EM = gm.E_MANAGER
    popup.states.visible = N
    EM:enqueue_event({ queue = args.queue, trigger = "after", delay = (EM.queue_dt or (1/60)), blockable = N, blocking = N,
        func = function() if popup.REMOVED or not gm.UI or gm.UI[args.ui_key] ~= popup then return Y end; popup.states.visible = Y; return Y end })
end

return M
