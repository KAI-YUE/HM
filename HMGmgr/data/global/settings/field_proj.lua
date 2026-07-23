local CardDimensions = require("HMGmgr.data.global.card_dimensions")

return function (self)
-----------------------------
--- Projection / field cfg
----------------------------------
    local n_rows, n_cols = 10, 18

    local default_proj = {
        bottom_offset    = 0.9,            --- baseline lift from the bottom edge.
        anchor_w         = CardDimensions.w, --- projected field width at the anchor row.
        anchor_top_q     = 0.98,           --- bottom anchor's depth along the vertical projection.
        h_compress       = 1.0,            --- vertical projection compression.
        vanish_center_u  = 0.5,            --- horizontal vanishing center, 0 left to 1 right.
        aspect_compress  = 0.9,            --- card width compression after projection.
    }

    self.Fdata = { proj = { default = default_proj } }
    self.Fcfg  = { n_rows = n_rows,  n_cols = n_cols,  shx = -0.8,  scale_x = 1., scale_y = 1., proj_key = "default",  proj = default_proj }
end
