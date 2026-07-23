local Cfg = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.hint_btn_cfg.hint_btn_type1_cfg")

local M = {}

function M.default(v, fallback)  if v ~= nil then return v end; return fallback end
function M.with(t, opts)         if type(opts) == "table" then for k, v in pairs(opts) do t[k] = v end end; return t end
function M.hint_r(args)          return args.r or (args.T and args.T.r) end
function M.hint_T(args)          local T = args.T or {}; return { x = args.x or T.x, y = args.y or T.y, w = args.w or T.w, h = args.h or T.h, r = args.r or T.r, scale = args.scale or T.scale } end
function M.cfg()                 return Cfg end

return M
