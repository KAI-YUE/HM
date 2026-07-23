local Actor   = require("HMEng.actors.actor")
local GameObj = require("HMEng.actors.game_obj")
local DebugFlags = require("HMGmgr.data.global.flags.debug_flags")

local sin, pi = math.sin, math.pi
local rand    = math.random
local abs, min, max = math.abs, math.min, math.max

local Tdrags = { "pawn_drag_camera_target", "pawn_drag_camera_suspended", "pawn_drag_active", "pawn_drag_start_cursor", "pawn_drag_start_origin" }
local Y, N = true, false

local function _orig() return { x = 0, y = 0, r = 0 } end

return function (Pawn)
-------------------------------------------------------
--- begin toddle
-------------------------------------------------------
--- Helper: rand sign | rand span | rand about
local function _rand_sign()     return (rand() > 0.5 and 1 or -1) end
local function _rand_span(span) return (2*rand() - 1)*(span or 0) end
local function _rand_about(base, span, floor) return max(base + _rand_span(span), floor or 0) end

--- Helper: roll toddle offset
local function _roll_offset(td)
    local target = td.target_offset or {}
    target.x, target.y, target.r = _rand_span(td.noise_x), _rand_span(td.noise_y), _rand_span(td.noise_r)
    
    td.sway           = _rand_about(td.base_sway or td.sway or 0, td.noise_sway, 0.1)
    td.dur            = _rand_about(td.base_dur or td.dur or 0.4, td.noise_dur, td.min_dur or 0.35)
    td.target_offset  = target
    return target
end

---__________________________________
--- main: begin toddle
---__________________________________
function Pawn:begin_toddle()
    local td, T = self.toddle, self.T
    if DebugFlags.fps.disable_pawn_toddle then td.active, td.t = N, 0; td.offset.x, td.offset.y, td.offset.r = 0, 0, 0; return Y end
    td.active, td.t             = Y, 0
    td.offset, td.from_offset   = td.offset or _orig(), td.from_offset or _orig()

    td.anchor.x,      td.anchor.y,      td.anchor.r       = T.x - td.offset.x, T.y - td.offset.y, T.r - td.offset.r
    td.from_offset.x, td.from_offset.y, td.from_offset.r  = td.offset.x, td.offset.y, td.offset.r
    _roll_offset(td)
    Actor.jitter_rot(self, 0.05 * _rand_sign(), 0.20)
    return Y
end

-------------------------------------------------------
--- move by
-------------------------------------------------------
function Pawn:move_by(dr, dc)
    local cell = self.cell or {};          if not self.zone or cell.row == nil or cell.col == nil then return N end
    local row, col = cell.row + (dr or 0), cell.col + (dc or 0)
    return self:move_to_cell(row, col)
end

-------------------------------------------------------
--- move up, down, left, right
-------------------------------------------------------
function Pawn:move_up()    return self:move_by(-1, 0) end
function Pawn:move_down()  return self:move_by(1, 0) end
function Pawn:move_left()  return self:move_by(0, -1) end
function Pawn:move_right() return self:move_by(0, 1) end

-------------------------------------------------------
--- debug hover move
-------------------------------------------------------
--- Helper: debug next cell
local function _debug_next_cell(self)
    local cell, board = self.cell or {}, self.zone and self.zone.boardzone
    local choices = board and board.get_path_next_cells and board:get_path_next_cells(cell.row, cell.col)
    local fallback, prev = nil, self._debug_hover_prev_cell or {}
    for _, choice in ipairs(choices or {}) do
        if self:can_move_to_cell(choice.row, choice.col) then
            fallback = fallback or choice
            if choice.row ~= prev.row or choice.col ~= prev.col then return choice end
        end
    end
    return fallback
end

--- Helper: debug hover move
function Pawn:debug_hover_move(dt)
    local cfg, st, ctrl = DebugFlags.fps, self.states, self.gm and self.gm.CTRL
    local key = cfg.hover_pawn_move_key or "k"
    local key_down = ctrl and ((ctrl.held_keys and ctrl.held_keys[key]) or (ctrl.pressed_keys and ctrl.pressed_keys[key]))
    if cfg.hover_pawn_move and st.hover.is and key_down then self._debug_hover_steps = cfg.hover_pawn_move_steps or 100 end
    if not (cfg.hover_pawn_move and self._debug_hover_steps and self._debug_hover_steps > 0) then self._debug_hover_move_t = 0; return end
    if self.toddle and self.toddle.active then return end

    self._debug_hover_move_t = (self._debug_hover_move_t or 0) + dt
    if self._debug_hover_move_t < (cfg.hover_pawn_move_interval or 0.18) then return end
    self._debug_hover_move_t = 0

    local next_cell, cell = _debug_next_cell(self), self.cell or {}
    if next_cell then
        self._debug_hover_prev_cell = { row = cell.row, col = cell.col }
        if self:move_to_cell(next_cell.row, next_cell.col) then self._debug_hover_steps = self._debug_hover_steps - 1 end
    else self._debug_hover_steps = 0 end
end

-------------------------------------------------------
--- update toddle transform
-------------------------------------------------------
function Pawn:update_toddle(dt)
    local td = self.toddle;             if not td or not td.active then return end

    td.t = td.t + dt
    local p,    T,      anchor  = td.t/td.dur,    self.T,           td.anchor
    local from, target, offset  = td.from_offset, td.target_offset, td.offset
    local mix = min(max(p, 0), 1)
    offset.x  = from.x + (target.x - from.x)*mix
    offset.y  = from.y + (target.y - from.y)*mix
    offset.r  = from.r + (target.r - from.r)*mix
    if p >= 1 then
        td.active = N; T.x, T.y, T.r = anchor.x + offset.x, anchor.y + offset.y, anchor.r + offset.r
        return
    end

    local wave     = sin(2 * pi * p)
    local envelope = 1 - p
    T.x = anchor.x + offset.x
    T.y = anchor.y + offset.y - td.bob*wave*envelope
    T.r = anchor.r + offset.r + td.sway*wave*envelope
end

-------------------------------------------------------
--- move
-------------------------------------------------------
function Pawn:move(dt)
    self:update_toddle(dt)
    self:debug_hover_move(dt)
    Actor.move(self, dt)
end

-------------------------------------------------------
--- drag
-------------------------------------------------------
--- Helper: suspend camera follow during field drag
local function _suspend_camera_follow(self)
    local gm, zone, args  = self.gm, self.zone, self.args
    local cam             = gm and gm.camera
    local is_field = zone and zone.config and zone.config.type == "field"
    if not cam or not cam.active or not is_field or args.pawn_drag_camera_suspended then return end

    args.pawn_drag_camera_target    = cam.target
    args.pawn_drag_camera_offset    = args.pawn_drag_camera_offset or {}
    args.pawn_drag_camera_offset.x  = cam.target_offset.x or 0
    args.pawn_drag_camera_offset.y  = cam.target_offset.y or 0
    args.pawn_drag_camera_suspended = Y
    cam:set_target(nil)
end

--- Helper: initialize field drag state
local function _begin_field_drag(self, Ctrl)
    local args, T = self.args, self.T
    local cpos = Ctrl.cursor_position

    args.pawn_drag_start_cursor = args.pawn_drag_start_cursor or {}
    args.pawn_drag_start_origin = args.pawn_drag_start_origin or {}

    local scur, sori = args.pawn_drag_start_cursor, args.pawn_drag_start_origin

    scur.x, scur.y         = cpos.x, cpos.y
    sori.x, sori.y         = T.x, T.y
    args.pawn_drag_active  = Y
end

---___________________________________
--- main: drag
---___________________________________
function Pawn:drag(Ctrl, offset)
    local zone = self.zone
    local is_field = zone and zone.config and zone.config.type == "field"
    if not is_field then return Actor.drag(self, Ctrl, offset) end

    _suspend_camera_follow(self)

    local args, cam, T = self.args, self.gm.camera, self.T
    if not args.pawn_drag_active then _begin_field_drag(self, Ctrl) end

    local cpos     = Ctrl.cursor_position
    local start_c  = args.pawn_drag_start_cursor or {}
    local start_o  = args.pawn_drag_start_origin or {}
    local zoom     = (cam and cam.active and cam.zoom) or 1
    local norm     = self.rcfg.tile_size * self.rcfg.tile_scale * zoom

    T.x = start_o.x + (cpos.x - start_c.x)/norm
    T.y = start_o.y + (cpos.y - start_c.y)/norm

    self.new_align = Y
    GameObj.drag(Ctrl, self)
end

-------------------------------------------------------
--- stop drag
-------------------------------------------------------
function Pawn:stop_drag()
    local args, gm = self.args, self.gm
    local cam = gm and gm.camera
    if cam and args.pawn_drag_camera_suspended then
        local off = args.pawn_drag_camera_offset or {}
        cam:set_target(args.pawn_drag_camera_target, off.x, off.y)
    end

    for _, key in ipairs(Tdrags) do args[key] = nil end
    GameObj.stop_drag(self)
end

end
