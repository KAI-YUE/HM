local Metrics = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.metrics")

local M = {}

--- Helper: _init_sprite_overlays
local function _init_sprite_overlays(self, gm, cfg)
    local overlays  = cfg.sprite_overlays;         if not overlays then return end

    overlays = overlays[1] and overlays or { overlays }
    self.sprite_overlays = {}
    for _, overlay in ipairs(overlays) do
        local atlas     = gm.T_atlas[overlay.atlas_key or cfg.atlas_key]
        local quad_key  = overlay.quad_key;       if not atlas or not quad_key then goto continue end
        local item      = overlay

        item.atlas,  item.quad     = atlas,       atlas:get_quad(quad_key)
        item.img,    item.metrics  = atlas.image, Metrics.quad_metrics(item.quad)
        self.sprite_overlays[#self.sprite_overlays + 1] = item
        ::continue::
    end
end

---____________________________
--- main: init
---______________________________________
function M.init(self, gm)
    local cfg = self.config;                                if not cfg.quad_key then return end

    self.draw_alpha = self.draw_alpha or 1
    self._single_sprite_hover_offset = { x = 0, y = 0 }

    local atlas = gm.T_atlas[cfg.atlas_key];                if not atlas then return end

    self.sprite_atlas, self.sprite_img  = atlas, atlas.image
    self.sprite_quad                    = atlas:get_quad(cfg.quad_key)
    self.sprite_metrics                 = Metrics.quad_metrics(self.sprite_quad)
    _init_sprite_overlays(self, gm, cfg)

    if not cfg.sprite_mask_key then return end
    self.sprite_mask_quad     = atlas:get_quad(cfg.sprite_mask_key)
    self.sprite_mask_metrics  = Metrics.quad_metrics(self.sprite_mask_quad)
end

return M
