return function (CardTextFx)

-----------------------------
--- sync runtime child alignment
-----------------------------
function CardTextFx:sync_runtime_child_alignment()
    local align = self.config.runtime_child_align;       if not align then return end
    local offset, anchor, T = align.offset or {}, align.anchor or {}, self.T
    local cache, VT = self.config.card_textfx_cache or {}, self.VT
    local ax, ay = anchor.x == nil and 1 or anchor.x, anchor.y == nil and 1 or anchor.y
    for _, child in ipairs(self.children or {}) do
        local cT, ro = child.T, child.role and child.role.offset;       if not (cT and ro) then goto continue end
        local x = align.x == "right" and T.w - cT.w*ax or 0
        local y = align.y == "bottom" and T.h - cT.h*ay or 0
        x, y = x + (offset.x or 0), y + (offset.y or 0)
        if ro.x ~= x or ro.y ~= y then ro.x, ro.y = x, y; if child.move_with_major then child:move_with_major(0) end end
        if align.r == "dominant" then local r = (VT.r or 0) + (cache.r or 0) + (self.draw_rotate or 0); cT.r, child.VT.r = r, r end
        ::continue::
    end
end

---____________________________
--- main: update
---______________________________________
function CardTextFx:update(dt)
    local cfg = self.config;        if not cfg then return end
    local text, cache = tostring(cfg.text or ""), cfg.card_textfx_cache
    if not (cache and cache.text == text and cache.text_scale == cfg.text_scale and cache.config_scale == cfg.scale) then self:build(text) end
    self:sync_runtime_child_alignment()
    for _, child in ipairs(self.children or {}) do if child.update then child:update(dt) end end
end

end
