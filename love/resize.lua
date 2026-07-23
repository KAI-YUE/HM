local LG = love.graphics

local M = {}

--------------------------------------
--- resize
--------------------------------------
function M.resize(w, h)
	if w/h < 1 then h = w end 
    local WP, R, rcfg = G.window_prev, G._room, G.rcfg
    local is_wide = (w/h) < WP.orig_ratio

    local ts, tz = WP.orig_scale * (is_wide and (w/WP.w) or (h/WP.h)), rcfg.tile_size
    rcfg.tile_scale = ts

    if R then
        local RT, RR = R.T, G._room_r.T
        RT.w, RT.h = rcfg.tile_w, rcfg.tile_h
        RR.w, RR.h = rcfg.tile_w, rcfg.tile_h

        local inv = 1/(tz*ts)
        local padW, padH = rcfg.r_pad_w, rcfg.r_pad_h

        if is_wide then RT.x, RT.y = padW, (h*inv - (RT.h + padH))*0.5 + padH*0.5
        else RT.y, RT.x = padH, (w*inv - (RT.w + padW))*0.5 + padW*0.5 end

        G.ROOM_ORIG = { x = RT.x, y = RT.y, r = RT.r }
        if G.buttons then G.buttons:recalculate() end
        if G.HUD     then G.HUD:recalculate()     end
    end

    G.win_trans = { x = 0, y = 0, w = rcfg.tile_w + 2*rcfg.r_pad_w, h = rcfg.tile_h + 2*rcfg.r_pad_h, real_window_w = w, real_window_h = h }
    local s_canvas = rcfg.s_canvas

    G.g_canvas = LG.newCanvas(w*s_canvas, h*s_canvas, { type = "2d", readable = Y })
    G.g_canvas:setFilter("linear", "linear")
end

return M