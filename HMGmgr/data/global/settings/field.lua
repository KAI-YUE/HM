return function (self)
-----------------------------
--- Projection / field cfg
----------------------------------
    local _cw, _ch, n_rows, n_cols = 2.1, 3.0, 10, 18

    local default_proj = {
        bottom_offset   = 0.9,     --- baseline lift from the bottom edge.
        anchor_w        = 1.2*_cw, --- projected field width at the anchor row.
        anchor_top_q    = 0.9,     --- top anchor depth along the vertical projection.
        h_compress      = 1.0,     --- vertical projection compression.
        vanish_center_u = 0.5,     --- horizontal vanishing center, 0 left to 1 right.
        aspect_compress = 0.72,    --- card width compression after projection.
    }

    self.Fdata = { proj = { default = default_proj } }
    self.Fcfg  = { n_rows = n_rows,  n_cols = n_cols,  shx = -0.8,  scale_x = 1., scale_y = 1., proj_key = "default",  proj = default_proj, }
end
