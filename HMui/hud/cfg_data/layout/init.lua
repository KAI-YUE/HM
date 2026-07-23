local M = {}

-----------------------------
--- helpers
----------------------------
--- Helper: merge
local function _merge(src) for k, v in pairs(src or {}) do M[k] = v end end

-----------------------------
--- layout blocks
----------------------------
_merge(require("HMui.hud.cfg_data.layout.base"))
_merge(require("HMui.hud.cfg_data.layout.layout_profile"))
_merge(require("HMui.hud.cfg_data.layout.status"))

return M
