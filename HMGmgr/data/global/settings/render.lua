local CardDimensions = require("HMGmgr.data.global.card_dimensions")

return function (self)
-----------------------------
--- Render cfg
----------------------------------
    local _cw, _ch, _c_depth = CardDimensions.w, CardDimensions.h, CardDimensions.depth

    self.rcfg  = { tile_size = 20,      tile_scale = 3.65,    tile_w = 20,       tile_h  = 11.5,      d_buff  = 2,      s_canvas = 1,         card_w = _cw,      card_h  = _ch,        highlight_h = 0.55,        coll_buffer = 0.05 }
    self.Ccfg  = { discard_W = _cw,     discard_H  = _ch,     deck_W = 1.1*_cw, deck_H  = 0.95*_ch,   hand_W  = 6*_cw,  hand_H   = 0.95*_ch,  play_W = 5.3*_cw,  play_H  = 0.95*_ch }
    self.card_w, self.card_h, self.card_d = _cw, _ch, _c_depth

    --- Card view
    self.card_view = { font = "HachiMaruPop", fsize = 10 }

    self.parallax = { scale_min = 0.88, scale_max = 0.91, pivot_scale = nil, pivot_x = nil }
end
