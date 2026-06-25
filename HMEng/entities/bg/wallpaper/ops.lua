return function (Wallpaper)
--------------------------------------------------
--- sync atlas
--------------------------------------------------
function Wallpaper:sync_atlas()
    local gm, cfg  = self.gm, self.config
    
    local atlas      = gm.T_atlas[cfg.atlas_key]
    self.atlas       = atlas
    self.image       = atlas.image
    self.quad        = atlas:get_quad(cfg.quad_key)
    self.image_dims  = { self.image:getDimensions() } 
end

--------------------------------------------------
--- sync to screen
--------------------------------------------------
function Wallpaper:sync_to_screen()
    local T = Wallpaper.screen_T(self.gm)
    if self.T.x == T.x and self.T.y == T.y and self.T.w == T.w and self.T.h == T.h then return end
    self:hard_set_T(T.x, T.y, T.w, T.h)
end

end
