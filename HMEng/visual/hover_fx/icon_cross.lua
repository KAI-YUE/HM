local Common    = require("HMEng.visual.hover_fx.common")
local Parallax  = require("HMEng.actors.actor.parallax")
local Presets   = require("HMEng.visual.hover_fx.presets")
local TabUtils  = require("HMfns.utils.table_utils")

local exp, max, min, sin = math.exp, math.max, math.min, math.sin
local _copy = TabUtils.deep_copy

local M = {}

--------------------------------------------
--- draw 
--------------------------------------------
--- Helper: _lerp | _merge | _preset | _resolve_cfg
local function _lerp(a, b, t)      return (a or 0) + ((b or a or 0) - (a or 0))*t end
local function _merge(base, over)  local out = _copy(base); for k, v in pairs(over or {}) do out[k] = v end; return out end
local function _preset(name)       return Presets[name] or Presets.fork_knife end
local function _resolve_cfg(cfg)   if type(cfg) ~= "table" then return _copy(Presets.fork_knife) end; if cfg.preset then return _merge(_preset(cfg.preset), cfg) end; return cfg end

--- Helper: _position
local function _position(cfg, box)
    local pos   = cfg.position or {}
    local h     = (pos.h or cfg.h or 0.72)*box.h
    local x, y  = box.x + (pos.x or 0.5)*box.w, box.y + (pos.y or -(cfg.y or 0.54))*box.h
    return x, y, h
end

--- Helper: _sprite_cfg
local function _sprite_cfg(cfg, i)
    if cfg.sprites and cfg.sprites[i] then return cfg.sprites[i] end
    local key = cfg.keys and cfg.keys[i] or (i == 1 and "fork" or "knife")
    local dir = i == 1 and -1 or 1
    return { key = key, start = { x = dir*0.09, y = 0, r = dir*0.62 }, finish = { x = dir*0.15, y = 0, r = dir*0.80 } }
end

--- Helper: _draw_sprite
local function _draw_sprite(atlas, sprite, box, cx, cy, h, pulse, wobble, color, ofs)
    local from, to  = sprite.start or {}, sprite.finish or sprite.to or {}
    local x,    y   = cx + _lerp(from.x, to.x, pulse)*box.w + ((ofs and ofs.x) or 0), cy + _lerp(from.y, to.y, pulse)*box.h + ((ofs and ofs.y) or 0)
    local sx,   sy  = sprite.scale_x or (sprite.flip_x and -1) or 1,                  sprite.scale_y or (sprite.flip_y and -1) or 1
    local r         = _lerp(from.r, to.r, pulse) + (sprite.wobble_dir or 1)*wobble
    
    Common.draw_icon(atlas, sprite.key, x, y, h*(sprite.h or 1), r, color, { scale_x = sx, scale_y = sy })
end

--- Helper: _parallax_shadow
local function _parallax_shadow(gm, ctx, cfg)
    local shadow = cfg.shadow;                         if shadow == false then return end
    shadow = type(shadow) == "table" and shadow or {}
    
    ctx = ctx or {}
    local sp, rcfg = ctx.shadow_parallax or {}, ctx.rcfg or {}
    local spx      = sp.x or 0
    if ctx.T and ctx._room then spx = Parallax.shadow_x(gm, ctx._room.T, ctx.T) end
    local tz, dist = rcfg.tile_size or 1, shadow.dist or cfg.widget_dist or 1.55
    return { x = -spx*dist/tz, y = -((sp.y or 0.1)*dist/tz) }, shadow.color or cfg.shadow_color or { 0, 0, 0, 0.30 }
end

--- Helper: _draw_sprites
local function _draw_sprites(atlas, cfg, box, cx, cy, h, pulse, wobble, color, ofs)
    _draw_sprite(atlas, _sprite_cfg(cfg, 1), box, cx, cy, h, pulse,  wobble, color, ofs)
    _draw_sprite(atlas, _sprite_cfg(cfg, 2), box, cx, cy, h, pulse, -wobble, color, ofs)
end

---________________________
--- main: draw
---_______________________
function M.draw(gm, ctx, box, cfg, start_at, alpha)
    cfg = _resolve_cfg(cfg);                          if not (box and cfg) then return end
    local atlas = Common.atlas(gm, cfg);              if not atlas then return end

    local now,   move_time  = gm._T.real_s or 0,       cfg.move_time or 0.18
    local t                 = now - (start_at or now) 
    local pulse, settle     = min(t / move_time, 1),    exp(-max(t - move_time, 0) * (cfg.settle_speed or 12))
    local bob,   fade       = sin(t*12) * (cfg.bob or 0.05)*box.h*settle, min(t / (cfg.alpha_time or move_time), 1)
    local cx,   cy,   h     = _position(cfg, box)
    cy = cy + bob
    
    local draw_alpha  = Common.draw_alpha(ctx, alpha)*fade
    local color       = Common.color_alpha(cfg.color, draw_alpha)
    local wobble      = (cfg.wobble_rot or 0.08)*settle*sin(t*18)
    local shadow_ofs, shadow_color = _parallax_shadow(gm, ctx, cfg)

    if shadow_ofs then _draw_sprites(atlas, cfg, box, cx, cy, h, pulse, wobble, Common.color_alpha(shadow_color, draw_alpha), shadow_ofs) end
    _draw_sprites(atlas, cfg, box, cx, cy, h, pulse, wobble, color)
end

------------------------------
--- instance
------------------------------
function M.instance(name, args) return _merge(_preset(name), args) end

return M
