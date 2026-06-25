local Y, N = true, false
local TunnelColors = require("HMui.menu.transitions.data.page_tunnel_colors")
local PageAnimator = require("HMui.menu.transitions.page.animator")
local PageTransition = require("HMui.menu.transitions.page.transition")

local M = {}

-------------------------------------------------
--- Return to title
-------------------------------------------------
function M.return_title(gm, source)
    gm.SET.pause = Y
    PageTransition.start(gm, {
        tunnel_tone_light  = TunnelColors.pause_return_title.tunnel_tone_light,
        tunnel_tone_mid    = TunnelColors.pause_return_title.tunnel_tone_mid,
        tunnel_tone_accent = TunnelColors.pause_return_title.tunnel_tone_accent,
        on_covered = function(_gm)
            local EM = _gm.E_MANAGER
            EM:clear_queue()
            _gm:delete_run()
            _gm:title_page("title")
            PageAnimator.ready(_gm)
            return Y
        end,
        on_revealed = function()
            return Y
        end
    })
    return Y
end

return M
