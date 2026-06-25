local TabUtils = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

-----------------------------
--- textfx cfg helpers
-----------------------------
--- Helper: textfx T
local function _textfx_T(self, src, pressed_dx, pressed_dy)
    local cfg, VT   = self.config, self.VT
    local fxcfg     = src or cfg.textfx or {}
    local T,  rcfg  = fxcfg.T or fxcfg, self.rcfg
    local tz        = rcfg.tile_size
    local dx, dy    = (pressed_dx or 0) / tz, (pressed_dy or 0) / tz

    return {
        x     = VT.x + (T.x or 0) + dx,
        y     = VT.y + (T.y or 0) + dy,
        w     = T.w or VT.w,
        h     = T.h or VT.h,
        r     = (VT.r or 0) + (T.r or fxcfg.r or 0),
        scale = (VT.scale or 1) * (T.scale or fxcfg.scale or 1),
    }
end

--- Helper: textfx configs
local function _textfx_configs(cfg)
    local out = {}
    if cfg.textfx then out[#out + 1] = cfg.textfx end
    for _, textfx in ipairs(cfg.extra_textfx or {}) do out[#out + 1] = textfx end
    return out
end

--- Helper: init textfx args
local function _init_textfx_args(self, gm, src)
    local cfg, args = self.config, copy(src)
    args.T, args.no_register = _textfx_T(self, src), Y
    args.text = tostring(args.text or "")
    args.button, args.can_hover, args.can_click, args.can_collide = N, N, N, N
    args.lang = args.lang or cfg.lang or gm.selected_lang
    if args.textfx_static == nil then args.textfx_static = args.static end
    if args.textfx_static == nil then args.textfx_static = cfg.textfx_static end
    if args.letter_flip   == nil then args.letter_flip   = cfg.letter_flip   end
    return args
end

---____________________________
--- main: init
---____________________________
function M.init(self, gm)
    local CardTextFx = require("HMEng.ui_actors.card_textfx")
    local textfxs = {}
    for _, textfx in ipairs(_textfx_configs(self.config)) do
        textfxs[#textfxs + 1] = CardTextFx(gm, _init_textfx_args(self, gm, textfx))
    end
    self.paint_rect_textfxs = textfxs
    self.paint_rect_textfx  = textfxs[1]
end

--- Helper: sync textfx
local function _sync_textfx(self, fx, src, pressed_dx, pressed_dy)
    local cfg = self.config
    if not (fx and src) then return end

    local T, ft = _textfx_T(self, src, pressed_dx, pressed_dy), fx.T
    ft.x, ft.y, ft.w, ft.h, ft.r, ft.scale = T.x, T.y, T.w, T.h, T.r, T.scale
    fx.VT.x, fx.VT.y, fx.VT.w, fx.VT.h, fx.VT.r, fx.VT.scale = T.x, T.y, T.w, T.h, T.r, T.scale
    fx.fx_mask, fx.fx_mask_dir = self.fx_mask, self.fx_mask_dir
    fx.draw_alpha = self.draw_alpha
    fx.config.text = tostring(src.text or "")
    fx.config.lang = fx.config.lang or cfg.lang or self.gm.selected_lang
end

---____________________________
--- main: draw
---____________________________
function M.draw(self, pressed_dx, pressed_dy)
    local textfxs, cfgs = self.paint_rect_textfxs or {}, _textfx_configs(self.config)
    for i, fx in ipairs(textfxs) do
        _sync_textfx(self, fx, cfgs[i], pressed_dx, pressed_dy)
        fx:draw_cache(fx.config.text)
    end
end

return M
