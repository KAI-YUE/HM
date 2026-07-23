local SkyDecorator  = require("HMEng.actors.sky_decorator")
local ModelDefs     = require("HMEng.actors.sky_decorator.data.model_defs")
local IntroTimeline = require("HMfns.animate.start.intro_timeline")

local LM = love.math

local abs, min, max = math.abs, math.min, math.max

local Y, N = true, false

local M = {}

-----------------------------
--- place_sky_decorators
----------------------------------
--- Helper: random range
local function _rand_range(lo, hi)
    if hi <= lo then return lo end
    return lo + (hi - lo)*LM.random()
end

--- Helper: enqueue after
local function _enqueue_after(EM, delay, func) EM:enqueue_event({ queue = "shader_fx", trigger = "after", blockable = N, delay = delay, func = func }) end

--- Helper: sky bounds
local function _sky_bounds(gm)
    local cam = gm.camera
    if cam and cam.active and cam.get_view_size then
        local vw, vh = cam:get_view_size()
        return { x = cam.x or 0, y = cam.y or 0, w = vw or 16, h = vh or 9 }
    end

    local bgT, roomT = gm.bg and gm.bg.T, gm._room and gm._room.T
    local T = bgT or roomT or { x = 0, y = 0, w = 16, h = 9 }
    return { x = T.x or 0, y = T.y or 0, w = T.w or 16, h = T.h or 9 }
end

--- Helper: field-pawn sky anchor
local function _field_pawn_sky_anchor(gm, bounds)
    local field, pawn = gm.field, gm.field_pawn
    local fT, pT = field and field.T, pawn and pawn.T
    if not fT then return { x = bounds.x + 0.5*bounds.w, y = bounds.y + 0.24*bounds.h } end

    local field_center = { x = fT.x + 0.5*fT.w, y = fT.y + 0.5*fT.h }
    local pawn_center = field_center
    if pT then pawn_center = { x = pT.x + 0.5*pT.w, y = pT.y + 0.5*pT.h } end

    return { x = 0.5*(field_center.x + pawn_center.x), y = 0.5*(field_center.y + pawn_center.y) }
end

--- Helper: clamp
local function _clamp(v, lo, hi) return max(lo, min(hi, v)) end

--- Helper: copy table
local function _copy_table(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do out[k] = _copy_table(v) end
    return out
end

--- Helper: sky cfg
local function _sky_cfg(cfg)
    cfg = cfg or {}
    local model_key = cfg.model_key or "bird1"
    local def = ModelDefs[model_key] or ModelDefs.bird1 or {}
    local out = _copy_table(def.spawn or {})
    for k, v in pairs(cfg) do out[k] = v end
    out.model_key = model_key
    return out
end

--- Helper: cell scaled
local function _cell_scaled(cfg, key, cell_key, cell_size, fallback)
    if cfg[key] ~= nil then return cfg[key] end
    if cfg[cell_key] ~= nil then return cfg[cell_key]*cell_size end
    return fallback
end

--- Helper: choose end x from horizontal speed
local function _choose_end_x(start_x, x_min, x_max, duration, cfg, cell_w)
    local h_min = _cell_scaled(cfg, "horizontal_speed_min", "horizontal_speed_min_cells", cell_w, 0.08*cell_w)
    local h_max = _cell_scaled(cfg, "horizontal_speed_max", "horizontal_speed_max_cells", cell_w, 0.55*cell_w)
    h_min = cfg.x_speed_min or h_min
    h_max = cfg.x_speed_max or h_max
    if h_max < h_min then h_min, h_max = h_max, h_min end

    local max_dx = h_max*duration
    local lo = max(x_min, start_x - max_dx)
    local hi = min(x_max, start_x + max_dx)
    if hi <= lo then return _clamp(start_x, x_min, x_max), 0 end

    local end_x = _rand_range(lo, hi)
    local dx = end_x - start_x
    local min_dx = h_min*duration
    if abs(dx) < min_dx then
        local dir = LM.random() < 0.5 and -1 or 1
        local candidate = start_x + dir*_rand_range(min_dx, max_dx)
        end_x = _clamp(candidate, lo, hi)
        dx = end_x - start_x
    end

    return end_x, dx / max(duration, 0.001)
end

--- Helper: active sky decorators
local function _active_sky_decorators(gm)
    local n = 0
    for _, v in ipairs(gm.sky_decorators or {}) do if not v.REMOVED then n = n + 1 end end
    return n
end

--- Helper: build bird flyover params
local function _bird_flyover_params(gm, cfg)
    local b = _sky_bounds(gm)
    local anchor = _field_pawn_sky_anchor(gm, b)
    local field = gm.field
    local cell_w, cell_h = (field and field.cell_w) or max(b.w/10, 1), (field and field.cell_h) or max(b.h/6, 1)

    local bird_w = (cfg.size_w or 1.25)*cell_w
    local bird_h = (cfg.size_h or 0.70)*cell_h
    local x_span = (cfg.x_span or 0.62)*b.w
    local x_center = _clamp(anchor.x, b.x + 0.20*b.w, b.x + 0.80*b.w)
    local x_min = max(b.x + (cfg.x_min or 0.12)*b.w, x_center - 0.5*x_span)
    local x_max = min(b.x + (cfg.x_max or 0.88)*b.w, x_center + 0.5*x_span)
    local start_x = _rand_range(x_min, x_max)
    local start_y = cfg.debug_visible_start and (b.y + b.h - 0.35*bird_h) or (b.y + b.h + (cfg.bottom_pad or 0.25)*bird_h)
    local end_y   = b.y - (cfg.top_pad or 0.85)*bird_h
    local v_min = _cell_scaled(cfg, "vertical_speed_min", "vertical_speed_min_cells", cell_h, 1.15*cell_h)
    local v_max = _cell_scaled(cfg, "vertical_speed_max", "vertical_speed_max_cells", cell_h, 1.65*cell_h)
    v_min, v_max = cfg.y_speed_min or v_min, cfg.y_speed_max or v_max
    local vertical_speed = _rand_range(v_min, v_max)
    local duration = cfg.duration or (abs(end_y - start_y) / max(vertical_speed, 0.001))
    local end_x, horizontal_speed = _choose_end_x(start_x, x_min, x_max, duration, cfg, cell_w)
    local base_r  = _clamp(horizontal_speed / max(vertical_speed, 0.001), -0.30, 0.30)

    return {
        model_key = cfg.model_key or "bird1",
        draw_alpha = cfg.draw_alpha or 0.92,
        flyover = {
            start = { x = start_x, y = start_y, scale = 1, r = cfg.r or base_r },
            finish = { x = end_x, y = end_y, scale = _rand_range(cfg.end_scale_min or 0.86, cfg.end_scale_max or 1.08), r = cfg.r or base_r },
            duration = duration,
            vertical_speed = vertical_speed,
            horizontal_speed = horizontal_speed,
            arc_y = cfg.arc_y or 0,
            wave_y = _rand_range(_cell_scaled(cfg, "wave_y_min", "wave_y_min_cells", cell_h, 0.04*cell_h), _cell_scaled(cfg, "wave_y", "wave_y_max_cells", cell_h, 0.14*cell_h)),
            wave_freq = _rand_range(cfg.wave_freq_min or 1.4, cfg.wave_freq_max or 2.6),
            phase = _rand_range(0, 2*math.pi),
            tilt = cfg.tilt or 0.04,
            ease = cfg.ease or "smooth",
            flip_x = cfg.flip_x or 1,
        },
    }, bird_w, bird_h
end

--- Helper: spawn bird
local function _spawn_bird(gm, cfg)
    cfg = _sky_cfg(cfg)
    if _active_sky_decorators(gm) >= (cfg.max_active or 1) then return end

    local params, w, h = _bird_flyover_params(gm, cfg)
    local start = params.flyover.start
    local bird = SkyDecorator(gm, start.x, start.y, w, h, params)
    return bird
end

--- Helper: schedule next bird
local function _schedule_next_bird(gm, cfg)
    cfg = _sky_cfg(cfg)
    local EM = gm.E_MANAGER;                if not EM then return end
    local delay = _rand_range(cfg.wait_min or 8.0, cfg.wait_max or 18.0)
    _enqueue_after(EM, delay, function()
        if gm._sky_decorator_stopped then return Y end
        _spawn_bird(gm, cfg)
        _schedule_next_bird(gm, cfg)
        return Y
    end)
end

function M.place_sky_decorators(gm, opts)
    -- opts = opts or {}
    -- if opts.silent_start then return end

    -- local cfg = _sky_cfg(opts.sky_decor or opts.sky_decorators or IntroTimeline.sky_decor)
    -- if cfg.enabled == N then return end

    -- gm._sky_decorator_stopped = nil
    -- if cfg.spawn_immediate ~= N then _spawn_bird(gm, cfg) end
    -- _schedule_next_bird(gm, cfg)
end

-----------------------------
--- debug_spawn_bird
----------------------------------
function M.debug_spawn_bird(gm, cfg)
    if not gm then return end
    cfg = cfg or {}
    cfg.max_active = cfg.max_active or math.huge
    cfg.debug_visible_start = cfg.debug_visible_start ~= N
    return _spawn_bird(gm, cfg)
end

return M
