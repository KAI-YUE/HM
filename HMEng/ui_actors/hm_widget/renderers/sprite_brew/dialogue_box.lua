local Render       = require("HMfns.systems.render")
local TabUtils     = require("HMfns.utils.table_utils")
local SingleSprite = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite")
local LG           = love.graphics

local _pick, push      = TabUtils.random_pick, table.insert
local push_draw_trans  = Render.push_actor_draw_transform
local max, rand        = math.max, math.random

local M = {}

local config_keys = { "decorators", "decorator_color", "decorator_cycle",
    "decorator_cycle_jitter", "decorator_hold", "decorator_pause", "decorator_pause_jitter" }

M.config_keys = {}
for _, key in ipairs(SingleSprite.config_keys) do push(M.config_keys, key) end
for _, key in ipairs(config_keys) do push(M.config_keys, key) end

M.layout_sprite = SingleSprite.layout_sprite
M.hit_test      = SingleSprite.hit_test

-----------------------------
--- init
----------------------------------
--- Helper: sprite metrics | choice key  | delay | duration
local function _sprite_metrics(quad)   local _, _, w, h = quad:getViewport(); return { w = w, h = h } end
local function _choice_key(dec)        return dec.quad_keys and _pick(dec.quad_keys) or dec.quad_key end
local function _delay(dec)             return (dec.delay or 0) + (dec.delay_jitter or 0)*rand() end
local function _duration(base, jitter) return max(0, (base or 0) + (jitter or 0)*rand()) end

--- Helper: set decorator quad
local function _set_decorator_quad(sprite, atlas, key)
    if not key then return end; local quad = atlas:get_quad(key)
    sprite.quad, sprite.metrics, sprite.quad_key = quad, _sprite_metrics(quad), key
end

--- Helper: reset decorator cycle
local function _reset_decorator_cycle(sprite, atlas)
    local dec = sprite.config
    if dec.quad_keys then _set_decorator_quad(sprite, atlas, _choice_key(dec)) end
    sprite.delay = _delay(dec)
end

--- Helper: _schedule_decorator_cycle
local function _schedule_decorator_cycle(self, now)
    local cfg, atlas, max_delay = self.config, self.sprite_atlas, 0
    for _, sprite in ipairs(self.decorator_sprites or {}) do
        _reset_decorator_cycle(sprite, atlas)
        max_delay = max(max_delay, sprite.delay or 0)
    end

    local active = max(_duration(cfg.decorator_cycle, cfg.decorator_cycle_jitter), max_delay + (cfg.decorator_hold or 0.15))
    local pause  = _duration(cfg.decorator_pause, cfg.decorator_pause_jitter)
    self.decorator_started_at = now
    self.decorator_active_until = now + active
    self.decorator_next_cycle_at = active > 0 and (now + active + pause)
end

---____________________________
--- main: init
---______________________________________
function M.init(self, gm)
    SingleSprite.init(self, gm)

    local cfg, atlas = self.config, self.sprite_atlas;  if not atlas or not cfg.decorators then return end
    local _T         = self._T

    self.decorator_sprites    = {}
    self.decorator_started_at = _T.real_s
    local dec_sprites         = self.decorator_sprites

    for _, dec in ipairs(cfg.decorators) do
        local key = _choice_key(dec)
        if not key then goto continue end

        local sprite = { config = dec }
        _set_decorator_quad(sprite, atlas, key)
        sprite.delay = _delay(dec)
        dec_sprites[#dec_sprites + 1] = sprite
        ::continue::
    end
    _schedule_decorator_cycle(self, _T.real_s)
end

-----------------------------
--- draw
----------------------------------
--- Helper: draw decorators
local function _draw_decorators(self)
    local sprites  = self.decorator_sprites
    local img, SM  = self.sprite_img, self.sprite_metrics
    if not sprites or not img or not SM then return end

    local cfg,  _T  = self.config, self._T
    local now, tz   = _T.real_s, self.rcfg.tile_size
    if self.decorator_next_cycle_at and now >= self.decorator_next_cycle_at then _schedule_decorator_cycle(self, now) end
    if self.decorator_active_until  and now >= self.decorator_active_until then return end

    local x, y, sx, sy  = M.layout_sprite(self, SM)
    local dw,  dh, _t0  = SM.w*sx, SM.h*sy, self.decorator_started_at or 0
    local cycle_t       = now - _t0

    local pressed, p_dist = self:button_press_distance()
    local sp = self.shadow_parallax or { x = 0, y = 0 }
    local dx, dy = pressed and -sp.x*p_dist or 0, pressed and -sp.y*p_dist or 0

    push_draw_trans(self, pressed and 0.985 or 1)
    LG.scale(1/tz)
    for _, sprite in ipairs(sprites) do
        local dec = sprite.config
        local m = sprite.metrics

        if cycle_t < (sprite.delay or dec.delay or 0) then goto continue end
        if not sprite.quad or not m then goto continue end
        local pos, anchor  = dec.pos or { x = 0, y = 0 }, dec.anchor or { x = 0.5, y = 0.5 }
        local scale        = dec.scale or 1
        local dsx, dsy     = sx * scale, sy * scale
        local px,  py      = x + (pos.x or 0)*dw + dx, y + (pos.y or 0)*dh + dy

        LG.setColor(dec.color or cfg.decorator_color or cfg.sprite_color or cfg.tint)
        LG.draw(img, sprite.quad, px, py, dec.r or 0, dsx, dsy)
        ::continue::
    end
    LG.pop()
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self)
    SingleSprite.draw(self, { no_button_press = true })
    _draw_decorators(self)
end

return M
