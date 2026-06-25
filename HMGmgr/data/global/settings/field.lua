local Y, N = true, false

return function (self)
-----------------------------
--- Projection / field cfg
----------------------------------
    local _cw, _ch, n_rows, n_cols = 2.1, 3.0, 10, 18

    local default_proj = {
        bottom_offset   = 0.9,     --- baseline lift from the bottom edge.
        anchor_w        = _cw,     --- projected field width at the anchor row.
        anchor_top_q    = 0.9,     --- top anchor depth along the vertical projection.
        h_compress      = 1.0,     --- vertical projection compression.
        vanish_center_u = 0.5,     --- horizontal vanishing center, 0 left to 1 right.
        aspect_compress = 0.72,    --- card width compression after projection.
    }

    local focus_projection = {
        enabled    = Y,            --- blend edge cells toward a center-view quad map while camera is pawn-focused.
        zoom_start = 1.05,         --- below this zoom, use the whole-field projection.
        zoom_end   = 1.60,         --- by this zoom, use max_weight of the focus projection.
        max_weight = 0.92,         --- keep some whole-field shape so the board still reads as one object.
        smoothing  = 0,            --- 0 snaps quad reassignment after pawn landing.
        track_zoom_settle = N,     --- if true, projection follows camera.zoom during zoom easing.
        camera_anchor = Y,         --- camera/POV anchor changes only when the destination leaves the safe rect.
        safe_margin_u = 0.22,      --- inner viewport margin before refocusing.
        safe_margin_v = 0.22,
        snap       = 0.002,        --- settle threshold for smoothed quad corners.
    }

    self.Fdata = { proj = { default = default_proj } }
    self.Fcfg  = { n_rows = n_rows,  n_cols = n_cols,  shx = -0.8,  scale_x = 1., scale_y = 1., proj_key = "default",  proj = default_proj, focus_projection = focus_projection }
end
