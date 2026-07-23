local class = require("core.class")

local max, min  = math.max, math.min
local sin, cos  = math.sin, math.cos
local sqrt      = math.sqrt
local LG = love.graphics

local Projector = class:extend()
-------------------------------------------------
--- init 
-------------------------------------------------
function Projector:init(x, y, w, h, args)
    local args = args or {};          self.room = args.room

    local RT, _s   = self.room.T, 1.2
    self.x, self.y = (RT and RT.x) or x or 0, (RT and RT.y) or y or 0
    self.w, self.h = (RT and RT.w) or w or 1, (RT and RT.h) or h or 1

    self.rcfg,    self.grid       = args.rcfg, nil;                     local rcfg = self.rcfg
    self.card_w,  self.card_h     = _s*(args.card_w or rcfg.card_w),     _s*(args.card_h or rcfg.card_h)
    self.x_offset, self.y_offset  = args.x_offset or (-0.6*rcfg.card_w), args.y_offset or (-1.6*rcfg.card_h)

    self.mode = args.mode or "dual_anchor"
end

-----------------------------------------
--- build_row_bands
-----------------------------------------
--- Helper: as_quad
local function as_quad(quad_pts)
    if not quad_pts then return end
    if quad_pts[1] and quad_pts[1].x then return quad_pts end
    if #quad_pts >= 8 then return { { x = quad_pts[1], y = quad_pts[2] }, { x = quad_pts[3], y = quad_pts[4] }, { x = quad_pts[5], y = quad_pts[6] }, { x = quad_pts[7], y = quad_pts[8] }, } end
end

--- Helper: row centerline
local function centerline_x_for_col(c_idx, n_cols) return c_idx - 0.5*(n_cols + 1) end

--- Helper: row band
local function make_row_band(cx_bottom, y_bottom, bottom_w, cx_top, y_top, top_w, n_cols)
    local bot_half, top_half = 0.5*n_cols*bottom_w, 0.5*n_cols*top_w
    return {
        left          = { x = cx_top - top_half,    y = y_top },
        right         = { x = cx_top + top_half,    y = y_top },
        bottom_left   = { x = cx_bottom - bot_half, y = y_bottom },
        bottom_right  = { x = cx_bottom + bot_half, y = y_bottom },
        center_bottom = { x = cx_bottom, y = y_bottom },
        center_top    = { x = cx_top,    y = y_top },
        bottom_w      = bottom_w,
        top_w         = top_w,
        h             = y_bottom - y_top,
    }
end

--- Helper: anchor quad
local function make_anchor_quad(cx, y_bottom, bottom_w, top_w, h, top_shift_x)
    local shift = top_shift_x or 0
    local y_top, cx_top = y_bottom - h, cx + shift
    return {
        { x = cx_top - 0.5 * top_w,    y = y_top },
        { x = cx_top + 0.5 * top_w,    y = y_top },
        { x = cx + 0.5 * bottom_w,     y = y_bottom },
        { x = cx - 0.5 * bottom_w,     y = y_bottom },
    }
end

--- Helper: row specs
function Projector:build_row_bands(n_rows, n_cols, field_rect, args)
    args = args or {}

    local fr = field_rect or { x = self.x, y = self.y, w = self.w, h = self.h }
    local RT = self.room.T or fr
    local base_aspect = self.card_w / max(self.card_h, 1e-6)
    local function resolve_dim(v, vu, scale, fallback) if v ~= nil  then return v end; if vu ~= nil then return vu * scale end; return fallback end

    local room_mid_x     = RT.x + 0.5*RT.w
    local bottom_y       = RT.y + RT.h + resolve_dim(args.room_bottom_offset, args.bottom_offset, RT.h, 0)
    local anchor_bw      = resolve_dim(args.anchor_w, args.anchor_w_u, fr.w,  (fr.w/max(n_cols, 1)))
    local anchor_tw      = resolve_dim(args.anchor_top_w,    args.anchor_top_w_u,    fr.w,  (anchor_bw*(args.anchor_top_q or 0.84)))
    local anchor_h       = resolve_dim(args.anchor_height,   args.anchor_height_u,   fr.h, ((anchor_bw/max(base_aspect, 1e-6)) * (args.h_compress or 1.0)))
    local depth_h_ratio  = args.aspect_compress or 0.82
    local vanish_x       = RT.x + (args.vanish_center_u or 0.5) * RT.w
    local width_drop     = max(anchor_bw - anchor_tw, 1e-6)
    local vanish_dy      = anchor_h * anchor_bw / width_drop
    local row_bands      = {}

    local function width_at_y(y) return max(anchor_bw *((y - (bottom_y - vanish_dy))/max(vanish_dy, 1e-6)), 1e-4) end
    local function center_at_y(y)
        local t = (bottom_y - y) / max(vanish_dy, 1e-6)
        return room_mid_x + (vanish_x - room_mid_x) * t
    end

    local anchor_top_y                     = bottom_y - anchor_h
    local anchor_quad                      = make_anchor_quad(room_mid_x, bottom_y, anchor_bw, anchor_tw, anchor_h, center_at_y(anchor_top_y) - room_mid_x)
    local cur_bottom_cx, cur_bottom_y      = room_mid_x, bottom_y
    local cur_bottom_w,  cur_top_w, cur_h  = anchor_bw, anchor_tw, anchor_h
    local cur_top_cx                       = center_at_y(anchor_top_y)

    row_bands[n_rows] = make_row_band(cur_bottom_cx, cur_bottom_y, cur_bottom_w, cur_top_cx, cur_bottom_y - cur_h, cur_top_w, n_cols)

    for r = n_rows - 1, 1, -1 do
        cur_bottom_cx = cur_top_cx
        cur_bottom_y  = cur_bottom_y - cur_h
        cur_bottom_w  = width_at_y(cur_bottom_y)
        cur_h         = (cur_bottom_w / max(base_aspect, 1e-6))*depth_h_ratio
        cur_top_w     = width_at_y(cur_bottom_y - cur_h)
        cur_top_cx    = center_at_y(cur_bottom_y - cur_h)

        row_bands[r] = make_row_band(cur_bottom_cx, cur_bottom_y, cur_bottom_w, cur_top_cx, cur_bottom_y - cur_h, cur_top_w, n_cols)
    end

    return row_bands, anchor_quad
end

-----------------------------------------
--- Helper: construct cells from row bands
-----------------------------------------
function Projector:construct_cells(n_rows, n_cols, row_bands, args)
    local cells = {}
    for r = 1, n_rows do
        local band = row_bands[r]
        cells[r] = {}
        for c = 1, n_cols do
            local dx = centerline_x_for_col(c, n_cols)
            local tl = { x = band.center_top.x + dx*band.top_w - 0.5*band.top_w,          y = band.center_top.y }
            local tr = { x = band.center_top.x + dx*band.top_w + 0.5*band.top_w,          y = band.center_top.y }
            local br = { x = band.center_bottom.x + dx*band.bottom_w + 0.5*band.bottom_w, y = band.center_bottom.y }
            local bl = { x = band.center_bottom.x + dx*band.bottom_w - 0.5*band.bottom_w, y = band.center_bottom.y }
            cells[r][c] = { tl, tr, br, bl }
        end
    end

    local x_offsets, y_offsets = (args.x_offset or self.x_offset or 0), (args.y_offset or self.y_offset or 0)
    if x_offsets == 0 and y_offsets == 0 then return cells end

    for r = 1, n_rows do
        for c = 1, n_cols do
            local quad = cells[r][c]
            for i = 1, 4 do quad[i].x, quad[i].y = quad[i].x + x_offsets, quad[i].y + y_offsets end
        end
    end
    return cells
end

--------------------------------------------------------
--- build_grid
--------------------------------------------------------
function Projector:build_grid(n_rows, n_cols, field_rect, args)
    args = args or {}
    if n_rows <= 0 or n_cols <= 0 then self.grid = nil; return end

    local fr = field_rect or { x = self.x, y = self.y, w = self.w, h = self.h }

    local row_bands, anchor_quad = self:build_row_bands(n_rows, n_cols, fr, args)
    local cells = self:construct_cells(n_rows, n_cols, row_bands, args)

    self.grid = { n_rows = n_rows, n_cols = n_cols,   field_rect = fr,
        row_edges = row_bands,     cells = cells,    anchor_quad = anchor_quad,
    }
    return self.grid
end

------------------------------------------------
--- get cell quad 
------------------------------------------------
function Projector:get_cell_quad(r_idx, c_idx)
    local grid = self.grid;                     if not grid or not grid.cells[r_idx] then return end
    local quad = grid.cells[r_idx][c_idx];      if not quad then return end
    return { { x = quad[1].x, y = quad[1].y }, { x = quad[2].x, y = quad[2].y }, { x = quad[3].x, y = quad[3].y }, { x = quad[4].x, y = quad[4].y }, }
end

------------------------------------------------
--- get local cell quad
------------------------------------------------
function Projector:get_local_cell_quad(r_idx, c_idx, T)
    local quad = self:get_cell_quad(r_idx, c_idx)
    if not quad then return end

    local ox, oy = (T and T.x) or 0, (T and T.y) or 0
    for i = 1, 4 do quad[i].x, quad[i].y = quad[i].x - ox, quad[i].y - oy end
    return quad
end

------------------------------------------------
--- point in quad
------------------------------------------------
function Projector:point_in_quad(p, quad, margin)
    local sign = nil
    margin = margin or 0.2

    for i = 1, 4 do
        local a, b     = quad[i], quad[i % 4 + 1]
        local ex, ey   = b.x - a.x, b.y - a.y
        local edge_len = math.sqrt(ex*ex + ey*ey)
        local cross    = ex*(p.y - a.y) - ey*(p.x - a.x)
        local tol      = margin*edge_len

        if math.abs(cross) < tol then goto continue end 
        local cur = cross > 0
        if     sign == nil then sign = cur
        elseif sign ~= cur then return N end
        ::continue::
    end
    return true
end

------------------------------------------------
--- to mesh local
------------------------------------------------
function Projector:to_mesh_local(actor, point)
    local args = actor.args
    local p = args.collides_with_point_point or {}
    local t = args.collides_with_point_translation or {}
    local r = args.collides_with_point_rotation or {}
    args.collides_with_point_point, args.collides_with_point_translation, args.collides_with_point_rotation = p, t, r

    p.x, p.y = point.x, point.y
    if actor.container ~= actor then actor:_to_container(p) end

    local mesh_card  = actor.children and actor.children.mesh_card
    local VT, T      = (mesh_card and mesh_card.VT) or actor.VT, actor.T
    local lp         = actor.layered_parallax or (actor.parent and actor.parent.layered_parallax) or { x = 0, y = 0 }
    local cx, cy     = VT.x + 0.5 * VT.w + lp.x, VT.y + 0.5 * VT.h + lp.y
    local dx, dy     = p.x - cx, p.y - cy
    local s          = VT.scale or 1
    local c, sn      = cos(-(VT.r or 0)), sin(-(VT.r or 0))

    t.x, t.y = (dx*c - dy*sn)/s, (dx*sn + dy*c)/s
    p.x, p.y = t.x + 0.5 * VT.w, t.y + 0.5 * VT.h
    return p
end

---------------------------------------------
--- new card mesh 
---------------------------------------------
function Projector:new_card_mesh(image)
    if not image then return end
    local vertices = { { 0, 0, 0, 0 }, { 0, 0, 1, 0 }, { 0, 0, 0, 1 }, { 0, 0, 1, 1 } }

    local mesh = LG.newMesh({ { "VertexPosition", "float", 2 }, { "VertexTexCoord", "float", 2 } }, vertices, "fan", "dynamic")
    mesh:setTexture(image)
    return mesh
end

---------------------------------------------
--- update_card_mesh
---------------------------------------------
function Projector:update_card_mesh(mesh, quad_pts)
    if not mesh then return end
    local q = as_quad(quad_pts);                   if not q then return end

    mesh:setVertex(1, { q[1].x, q[1].y, 0, 0 });   mesh:setVertex(2, { q[2].x, q[2].y, 1, 0 })
    mesh:setVertex(3, { q[4].x, q[4].y, 0, 1 });   mesh:setVertex(4, { q[3].x, q[3].y, 1, 1 })
end

---------------------------------------------
--- make_card_mesh
---------------------------------------------
function Projector:make_card_mesh(image, quad_pts)
    local mesh = self:new_card_mesh(image);        if not mesh then return end
    if quad_pts then self:update_card_mesh(mesh, quad_pts) end
    return mesh
end

---------------------------------------------
--- apply_to_mesh
---------------------------------------------
function Projector:apply_to_mesh(mesh, quad, uv_rect)
    if not mesh or not quad or #quad < 4 then return end
    local uv = uv_rect or { u1 = 0, v1 = 0, u2 = 1, v2 = 1 }

    mesh:setVertex(1, { quad[1].x, quad[1].y, uv.u1, uv.v1, 1, 1, 1, 1 });  mesh:setVertex(2, { quad[2].x, quad[2].y, uv.u2, uv.v1, 1, 1, 1, 1 })
    mesh:setVertex(3, { quad[3].x, quad[3].y, uv.u2, uv.v2, 1, 1, 1, 1 });  mesh:setVertex(4, { quad[4].x, quad[4].y, uv.u1, uv.v2, 1, 1, 1, 1 })
end

return Projector
