local Assembly = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.assembly")
local Cfg      = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.hint_btn_cfg.hint_btn_type1_cfg")

local N = false

local M = {}

--- Helpers: default | with | composite role
local function _default(value, fallback)  if value == nil then return fallback end; return value end
local function _with(base, args)          for k, v in pairs(args or {}) do base[k] = v end; return base end
local function _composite_role()          return { xy_bond = "Strong", r_bond = "Weak", wh_bond = "Weak", scale_bond = "Weak" } end

function M.build(args) return Assembly.build(args) end

-----------------------------
--- composite
-----------------------------
function M.composite(args)
    args = args or {}
    local shape = args.shape or "square"
    local out = _with({
        label = "",                         button_w = 0.8,
        page_draw_layer = N,
        hint_btn_quad_key = shape .. "_shape_btn",
        hint_mask_quad_key = shape .. "_shape_btn_mask",
        role = _composite_role(),
    }, args)
    out.page_draw_layer, out.shape = _default(args.page_draw_layer, N), nil
    return Assembly.build(out)
end

M.type1_cfg = Cfg

return M
