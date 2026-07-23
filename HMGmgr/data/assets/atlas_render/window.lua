local Y = true

return function(GMgr)
-----------------------------
--- initialize the window
----------------------------
function GMgr:init_window(reset)
    local rcfg = self.rcfg
    rcfg.r_pad_h, rcfg.r_pad_w = 0.7, 1

    local tz, ts    = rcfg.tile_size, rcfg.tile_scale
    local norm, SET = tz*ts,          self.SET
    local w, h      = rcfg.tile_w + 2*rcfg.r_pad_w, rcfg.tile_h + 2*rcfg.r_pad_h

    self.win_trans   = { x = 0, y = 0, w = w, h = h }
    self.window_prev = { orig_scale = ts, w = w*norm, h = h*norm, orig_ratio = w/h }
    SET.queued_c = SET.queued_c or {}
    SET.queued_c.screenmode = SET.s_win.screenmode

    self.Fs.apply_window_settings(self, nil, Y)
end

end
