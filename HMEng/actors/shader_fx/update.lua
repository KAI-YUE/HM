local cos, sin = math.cos, math.sin
local max, min = math.max, math.min

local rand = math.random

local Y, N = true, false

return function (ShaderFX)
-----------------------------------------------------------
--- update
-----------------------------------------------------------
function ShaderFX:update(dt) end

-----------------------------------------------------------
--- stop event motion
-----------------------------------------------------------
function ShaderFX:stop_event_motion()
    local motion   = self.event_motion or {}
    motion.enabled = N
    motion.token   = (motion.token or 0) + 1
    self.event_motion = motion
end

-----------------------------------------------------------
--- start event motion 
-----------------------------------------------------------
--- Helper: rand range | current center 
local function _rand_range(lo, hi)   if hi <= lo then return lo end; return lo + (hi - lo)*rand() end
local function _current_center(self) local ro = self.role.offset; return { x = ro.x, y = ro.y } end

--- Helper: pick random target 
local function _pick_random_target(self)
    local motion = self.event_motion or {}
    local start  = _current_center(self)
    local angle  = _rand_range(0, 2*math.pi)
    local dist   = _rand_range(motion.min_dist or 1.0, motion.max_dist or 2.0)

    local target = { angle = angle, x = start.x + dist*cos(angle), y = start.y + dist*sin(angle) }
    return start, target
end

--- Helper: token still valid
local function _motion_valid(self, token)
    if self.REMOVED then return N end
    local motion = self.event_motion
    return motion and motion.enabled and motion.token == token
end

--- Helper: enqueue ease
local function _enqueue_ease(EM, ref_table, ref_value, ease_to, delay, ease)
    EM:enqueue_event({ queue  = "shader_fx",  trigger   = "ease",     ease    = ease,     blockable = N, 
        ref_table = ref_table,                ref_value = ref_value,  ease_to = ease_to,  delay     = delay })
end

--- Helper: enqueue after
local function _enqueue_after(EM, delay, func) EM:enqueue_event({ queue = "shader_fx", trigger = "after", blockable = N, delay = delay, func = func }) end

--- Helper: queue next motion leg 
function ShaderFX:_queue_next_motion_leg()
    local gm, motion = self.gm, self.event_motion
    local EM, role   = gm.E_MANAGER, self.role
    local ro         = role.offset;                if not motion or not motion.enabled or not EM or not ro then return end

    if self.draw_alpha == nil then self.draw_alpha = 1 end

    local _, target = _pick_random_target(self)
    local duration  = _rand_range(motion.min_dur or 2.5, motion.max_dur or 5.0)
    
    local token     = (motion.token or 0) + 1
    motion.token, motion.last_angle = token, target.angle
    local fade_dur, fade_in_dur     = motion.fade_dur or 0, motion.fade_in_dur or 0

    _enqueue_ease(EM, ro, "x", target.x, duration, "cubic")
    _enqueue_ease(EM, ro, "y", target.y, duration, "cubic")

    _enqueue_after(EM, duration, function()
        if not _motion_valid(self, token) then return Y end
        if fade_dur <= 0 then self.draw_alpha = 0; self:_queue_next_motion_leg(); return Y; end

        _enqueue_ease(EM, self, "draw_alpha", 0, fade_dur)
        _enqueue_after(EM, fade_dur, function()
            if not _motion_valid(self, token) then return Y end
            self.draw_alpha = 0
            if fade_in_dur > 0 then _enqueue_ease(EM, self, "draw_alpha", 1, fade_in_dur)
            else self.draw_alpha = 1 end
            self:_queue_next_motion_leg()
            return Y
        end)
        return Y
    end)
end

---______________________________
--- main: start event motion 
---______________________________
function ShaderFX:start_event_motion(args)
    args = args or {}
    self.event_motion = {
        enabled  = Y,      token = 0,       last_angle  = nil,
        min_dist = args.min_dist or 0.8,    max_dist    = args.max_dist or args.radius or 2.4,
        min_dur  = args.min_dur  or 3.2,    max_dur     = args.max_dur or 5.8,
        fade_dur = args.fade_dur or 0.30,   fade_in_dur = args.fade_in_dur,
    }
    self:_queue_next_motion_leg()
    return self
end

end
