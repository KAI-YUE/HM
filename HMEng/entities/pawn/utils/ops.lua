local Actor = require("HMEng.actors.actor")

local Y, N = true, false
local Tbounce_arg = { "appear_dur", "squash_sy", "squash_sx", "pop_velocity", "launch_boost", "spring_k", "spring_damp", "target_sy", "width_gain", "settle_speed" }

return function (Pawn)
-------------------------------------------------------
--- forward occupied path-cell clicks
-------------------------------------------------------
function Pawn:click()
    local zone, cell = self.zone, self.cell or {}
    local board = zone and zone.boardzone
    if board and board.handle_path_cell_click and board:handle_path_cell_click(cell) then return Y end
    return Pawn.super.click(self)
end

-------------------------------------------------------
--- collides with
-------------------------------------------------------
function Pawn:hit_test(point)
    local zone, gm = self.zone, self.gm
    local cam      = gm.camera
    local is_field = zone and zone.config and zone.config.type == "field"
    if not cam or not cam.active or not is_field then return Actor.hit_test(self, point) end

    local args = self.args
    args.pawn_camera_point = args.pawn_camera_point or {}
    local cp = cam:screen_to_world_point(point, args.pawn_camera_point)
    return Actor.hit_test(self, cp)
end

-------------------------------------------------------
--- occupies cell
-------------------------------------------------------
function Pawn:occupies_cell(r_idx, c_idx) local cell = self.cell or {}; return (cell.row == r_idx) and (cell.col == c_idx) end

-------------------------------------------------------
--- bounce me
-------------------------------------------------------
function Pawn:bounce_me(args)
    local bn = self.bounce;         if not bn then return N end

    args = args or {}
    self.states.visible  = Y
    bn.active, bn.phase  = Y,"appear"
    bn.t,      bn.alpha  = 0, args.alpha_from or 0
    bn.sy,     bn.sx     = args.sy_from or 0.02, args.sx_from or 1.0
    bn.vy = 0

    for _, key in ipairs(Tbounce_arg) do if args[key] ~= nil then bn[key] = args[key] end end
    self.draw_alpha, self.draw_scale_x, self.draw_scale_y = bn.alpha, bn.sx, bn.sy
    return Y
end


end
