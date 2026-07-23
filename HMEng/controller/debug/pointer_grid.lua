local LG = love.graphics

local ceil = math.ceil
local Y = true

local M = {}

--------------------------------------------------
--- Helpers: coords
--------------------------------------------------
local function _norm(gm) local rcfg = gm and gm.rcfg or {}; return (rcfg.tile_size or 1) * (rcfg.tile_scale or 1) end
local function _canvas_scale(gm) local c = gm and gm.g_canvas; return c and LG.getWidth()/c:getWidth() or 1 end
local function _room_T(gm) return gm and gm._room and gm._room.T end
local function _fmt_coord(x, y) return ("(%.2f, %.2f)"):format(x or 0, y or 0) end

local function _window_to_room(gm, x, y)
    local RT = _room_T(gm);                         if not RT then return end
    local n, s = _norm(gm), _canvas_scale(gm)
    local p = { x = (x or 0)/(n*s), y = (y or 0)/(n*s) }
    local cam = gm.camera
    if cam and cam.active then p = cam:screen_to_world_point(p, {}) end
    return p.x - (RT.x or 0), p.y - (RT.y or 0)
end

local function _room_to_window(gm, x, y, out)
    local RT = _room_T(gm);                         if not RT then return end
    out = out or {}
    out.x, out.y = (RT.x or 0) + (x or 0), (RT.y or 0) + (y or 0)
    local cam = gm.camera
    if cam and cam.active then out = cam:world_to_screen_point(out, out) end
    local n, s = _norm(gm), _canvas_scale(gm)
    out.x, out.y = out.x*n*s, out.y*n*s
    return out
end

--------------------------------------------------
--- Helpers: grid draw
--------------------------------------------------
local function _draw_label(text, x, y)
    LG.setColor(0, 0, 0, 0.72); LG.print(text, x + 2, y + 2, 0, 0.72, 0.72)
    LG.setColor(1, 1, 1, 0.95); LG.print(text, x, y, 0, 0.72, 0.72)
end

local function _draw_grid_lines(gm, RT, step)
    local p1, p2 = {}, {}
    LG.setColor(0.1, 0.95, 1, 0.28); LG.setLineWidth(1)
    for x = 0, RT.w, step do
        _room_to_window(gm, x, 0, p1); _room_to_window(gm, x, RT.h, p2)
        LG.line(p1.x, p1.y, p2.x, p2.y)
    end
    for y = 0, RT.h, step do
        _room_to_window(gm, 0, y, p1); _room_to_window(gm, RT.w, y, p2)
        LG.line(p1.x, p1.y, p2.x, p2.y)
    end
end

local function _draw_grid_labels(gm, RT, step)
    local p = {}
    for y = 0, ceil(RT.h/step) - 1 do
        for x = 0, ceil(RT.w/step) - 1 do
            local gx, gy = x*step, y*step
            _room_to_window(gm, gx, gy, p)
            if p.x > -60 and p.y > -20 and p.x < LG.getWidth() + 10 and p.y < LG.getHeight() + 10 then _draw_label(("%d,%d"):format(gx, gy), p.x + 3, p.y + 3) end
        end
    end
end

--------------------------------------------------
--- Main: key handling
--------------------------------------------------
function M.handle(ctrl, key)
    if key == "=" then ctrl.debug_pointer_mode = not ctrl.debug_pointer_mode; return Y end
    if key == "-" then ctrl.debug_grid_mode = not ctrl.debug_grid_mode; return Y end
end

--------------------------------------------------
--- Main: pointer click probe
--------------------------------------------------
function M.capture_click(ctrl, x, y)
    if not (ctrl and ctrl.debug_pointer_mode) then return end
    local gm = ctrl.gm or G
    local rx, ry = _window_to_room(gm, x, y);       if not rx then return end
    ctrl.debug_pointer_last = { x = rx, y = ry, button = 1, time = gm and gm._T and gm._T.real_s or 0 }
    print("[debug pointer] room " .. _fmt_coord(rx, ry))
    return Y
end

--------------------------------------------------
--- Main: overlay text
--------------------------------------------------
function M.overlay_text(ctrl)
    if not (ctrl and ctrl.debug_pointer_mode) then return end
    local p = ctrl.debug_pointer_last
    return "Pointer: " .. (p and _fmt_coord(p.x, p.y) or "click to sample")
end

--------------------------------------------------
--- Main: grid overlay
--------------------------------------------------
function M.draw_grid(gm)
    local ctrl = gm and gm.CTRL;                    if not (ctrl and ctrl.debug_grid_mode) then return end
    local RT = _room_T(gm);                         if not RT then return end
    local step = ctrl.debug_grid_step or 1
    LG.push()
    _draw_grid_lines(gm, RT, step)
    _draw_grid_labels(gm, RT, step)
    LG.pop()
    return Y
end

return M
