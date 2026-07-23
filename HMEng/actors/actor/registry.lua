local TabUtils = require("HMfns.utils.table_utils")
local GameObj  = require("HMEng.actors.game_obj")

local rM,   bS    = "Major", "Strong"
local Y,    N     = true, false
local push, _copy = table.insert, TabUtils.deep_copy

return function(Actor)
-----------------------------
--- Move registry
----------------------------
--- Helper: registry contains | cleanup
local function contains(tab, obj) for _, v in ipairs(tab or {}) do if v == obj then return Y end end; return N end
local function cleanup(tab, obj) for i, v in ipairs(tab or {}) do if v == obj then table.remove(tab, i); break end end end

--- Helper: actor uses static move
local function uses_static_move(self) return self.static_move or (self.config and self.config.static_move) end

--- Helper: push unique
local function push_unique(tab, obj) if tab and not contains(tab, obj) then push(tab, obj) end end

--- refresh_move_registry
function Actor:refresh_move_registry()
    local gm = self.gm;                                      if not gm then return end
    if uses_static_move(self) then
        cleanup(gm.t_move_actors, self);                     push_unique(gm.t_static_actors, self)
    else
        cleanup(gm.t_static_actors, self);                   push_unique(gm.t_move_actors, self)
    end
end

--- wake_move
function Actor:wake_move()
    if self.REMOVED or not uses_static_move(self) then return end
    local gm = self.gm;                                      if not gm then return end
    if gm.mark_actor_move_pending then return gm:mark_actor_move_pending(self) end
    local tab = gm.t_pending_move_actors;                    if not tab or self.move_pending then return end
    self.move_pending = Y;                                   push(tab, self)
end

----------------------------------------------------------------
--- Init role 
--------------------------------------------------------------- 
--- Helper: parse args 
local function _parse_args(x, y, w, h)
    local args = { T = { x = x or 0, y = y or 0, w = w or 0, h = h or 0 } }   -- default table: recommended
    if type(x) == "table" then args = x.T and x or { T = { x = x.x or 0, y = x.y or 0, w = x.w or 0, h = x.h or 0 } } end
    return args
end

-- Helper: origin point & initial role
local function _orig() return { x = 0, y = 0 } end
local function _vel()  return { x = 0, y = 0, w = 0, h = 0, r = 0, scale = 0, mag = 0 } end
local function _motion_defaults()
    return {
        xy    = { smooth_time = 0.060, max_speed = 70, snap = 0.010 },
        r     = { smooth_time = 0.030, max_speed = 70, snap = 0.001 },
        scale = { smooth_time = 0.030, max_speed = 70, snap = 0.001 },
        wh    = { smooth_time = 0.030, max_speed = 70, snap = 0.001, pinch_in_dur = 0.5, pinch_out_dur = 0.14 },
    }
end

function Actor:init_role() return { role_type = rM, offset = _orig(), major = nil, draw_major = self, xy_bond = bS, wh_bond = bS, r_bond = bS, scale_bond = bS } end

--_____________________________________________
--- Main, Actor:init_params 
--_____________________________________________
function Actor:init_actor_attributes(gm, x, y, w, h)
    local args, pinch = _parse_args(x, y, w, h), {}
	GameObj.init(self, gm, args)
    self:init_registry(gm)                                           

    self.VT,        self.velocity  = _copy(self.T),   _vel()
    self.role,      self.jitter    = self:init_role(), nil
    self.alignment, self.pinch     = { type = "a", offset = _orig(), prev_type = "", prev_offset = _orig() }, { x = N, y = N, min_w = 1, min_h = 2 }

    self.Mid,             self.shadow_height     = self, 0.2
    self.motion,          self.prev_role_offset  = self.motion or _motion_defaults(), _orig()
    self.last_moved,      self.last_aligned      = -1, -1                        -- Keep track of the last time this Actor was moved via :move(dt). 
    self.static_rotation, self.offset            = N, _orig()
    self.shadow_parallax, self.layered_parallax  = { x = 0, y = -1.5 }, _orig()  -- parallax params 
    self:calculate_parallax()                  
end

---------------------------------------------------
-- init_registry: Init the game manager related Registry
----------------------------------------------------
function Actor:init_registry(gm)
    self.cache  = gm.g_cache               
    self._room,     self._T      = gm._room,    gm._T                     -- Room, _T reference
    self.FRS,       self.SET     = gm.FRS,      gm.SET

    local t_actors, RACTOR       = gm.t_actors, gm.R.ACTOR
    self.t_actors,  self.RACTOR  = t_actors,    RACTOR 
    push(t_actors, self)
    self:refresh_move_registry()
    if getmetatable(self) == Actor then push(RACTOR, self) end
end

-------------------------------------------------------
-- Remove: Cleanup Everything 
-------------------------------------------------------
function Actor:remove()
    local gm = self.gm
    cleanup(self.t_actors, self); cleanup(self.RACTOR, self)
    if gm then cleanup(gm.t_move_actors, self); cleanup(gm.t_static_actors, self); cleanup(gm.t_pending_move_actors, self) end
    self.move_pending = N
    GameObj.remove(self)
end

end
