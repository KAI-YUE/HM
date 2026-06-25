local TabUtils    = require("HMfns.utils.table_utils")
local Layout      = require("HMEng.ui_actors.card_textfx.in_factory.layout")
local HookRunner  = require("HMEng.ui_actors.common.hooks")

local random_pick  = TabUtils.random_pick

local Y, N = true, false

return function (CardTextFx)

---____________________________
--- main: click
---______________________________________
function CardTextFx:click()
    local cfg = self.config;        if not cfg.button then return end
    local gm  = self.gm;            local now = gm._T.real_s

    if self.last_clicked and now <= self.last_clicked + 0.1 then return end
    if cfg.textfx_reveal_lock == Y then return end
    if not self.states.visible or self.under_overlay or self.disable_button then return end

    if cfg.one_press then self.disable_button = Y end
    self.last_clicked = now
    HookRunner.run_hook(self, gm)
end

-----------------------------
--- hover | stop_hover
----------------------------------
function CardTextFx:hover() end
function CardTextFx:stop_hover() end

---____________________________
--- main: hit_test
---______________________________________
function CardTextFx:hit_test(point, text, opts)
    if self.config.textfx_reveal_lock == Y then return N end
    local cache     = self:build(tostring(text or self.config.text or ""));      if not cache then return N end
    local local_p   = Layout.actor_point_to_local(self, point);                  if not local_p then return N end
    local text_box  = Layout.text_visual_box(self, cache, opts)
    local bg        = Layout.text_bg_cfg(self)
    local box       = (bg and bg.hit_test == "bg" and Layout.text_bg_box(self, cache, text_box)) or text_box

    return Layout.point_in_rotated_box(local_p, box, box.r or cache.r or 0)
end

end
