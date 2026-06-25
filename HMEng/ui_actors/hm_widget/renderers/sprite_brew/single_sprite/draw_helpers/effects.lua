local max, min  = math.max, math.min
local sin, exp  = math.sin,  math.exp

local M = {}

--- Helper: _hover_like_active
local function _hover_like_active(self)
    local st = self.states;    if not st then return end
    return (st.hover and st.hover.is) or (st.focus and st.focus.is)
end

---____________________________
--- main: hover_elapsed
---______________________________________
function M.hover_elapsed(self)
    if not _hover_like_active(self) then return 0 end

    local now = self._T.real_s
    self.shader_hover_started_at = self.shader_hover_started_at or self.last_hovered or now
    return max(now - self.shader_hover_started_at, 0.0001)
end

---____________________________
--- main: clear_hover_start_when_safe
---______________________________________
function M.clear_hover_start_when_safe(self)
    if _hover_like_active(self) then return end

    local cfg           = self.config
    local last_hovered  = self.last_hovered
    local safe          = cfg.hover_safe_time or 0.1
    if not last_hovered or self._T.real_s > last_hovered + safe then self.shader_hover_started_at = nil; end
end

---____________________________
--- main: hover_transform
---______________________________________
function M.hover_transform(self)
    local ofs = self._single_sprite_hover_offset
    if not _hover_like_active(self) then ofs.x, ofs.y = 0, 0; return 1, ofs, 0 end

    local cfg,    elapsed  = self.config,         M.hover_elapsed(self)
    local zoom,   shake    = cfg.hover_zoom or 1, cfg.hover_shake
    local rotate, damp     = 0, 1

    if cfg.hover_rotate then local rotate_time = cfg.hover_rotate_time or 0.35; rotate = cfg.hover_rotate * min(elapsed / rotate_time, 1); end
    if not shake        then ofs.x, ofs.y = 0, 0; return zoom, ofs, rotate; end

    local speed, sr  = shake.speed or 32, shake.r or 0
    local sx,    sy  = shake.x or 0,      shake.y or 0
    if shake.settle then damp = exp(-elapsed * (shake.settle or 8)) end

    ofs.x = sx*damp*sin(elapsed*speed)
    ofs.y = sy*damp*sin(elapsed*speed*1.37 + self.ID)

    local shake_rotate = sr*damp*sin(elapsed*speed*0.83 + self.ID*0.7)
    return zoom, ofs, rotate + shake_rotate
end

return M
