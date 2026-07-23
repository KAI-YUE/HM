local C = require("HMfns.animate.color.color_const")

local ck, cw = C.BLACK, C.WHITE

local M = {}

--- Helper: _is_color | _resolved_color
local function _is_color(color)            return type(color) == "table" end
local function _resolved_color(self, key)  local color = self:resolve_visual_color(key); if _is_color(color) then return color end end

---____________________________
--- main: with_draw_alpha
---______________________________________
function M.with_draw_alpha(self, color, fallback)
    if not _is_color(color) then color = fallback or cw end

    local a = (color[4] or 1) * (self.draw_alpha or 1)
    return { color[1], color[2], color[3], a }
end

---____________________________
--- main: face_color
---______________________________________
function M.face_color(self, shadow)
    local cfg = self.config;            if shadow then return cfg.shadow_color or ck end

    if cfg.sprite_color ~= nil then
        local sprite_color = _resolved_color(self, "sprite_color")
        if sprite_color then return sprite_color end
    end

    return _resolved_color(self, "tint") or cw
end

---____________________________
--- main: mask_color
---______________________________________
function M.mask_color(self, shadow)
    if shadow then return self.config.shadow_color or ck end
    return _resolved_color(self, "fill_color") or cw
end

---____________________________
--- main: overlay_color
---______________________________________
function M.overlay_color(self, overlay, shadow)
    local cfg = self.config;  if shadow then return overlay.shadow_color or cfg.shadow_color or ck end
    return overlay.sprite_color or overlay.tint or cfg.sprite_color or cfg.tint or cw
end

---____________________________
--- main: with_overlay_alpha
---______________________________________
function M.with_overlay_alpha(self, color, shadow)
    if not _is_color(color) then color = cw end

    local parent_color = M.face_color(self, shadow)
    local parent_alpha = 1
    if _is_color(parent_color) then parent_alpha = parent_color[4] or 1 end
    local a = (color[4] or 1) * parent_alpha * (self.draw_alpha or 1)
    return { color[1], color[2], color[3], a }
end

return M
