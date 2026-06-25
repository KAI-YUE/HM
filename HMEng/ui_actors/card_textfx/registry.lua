local Actor      = require("HMEng.actors.actor")
local DataFonts  = require("HMEng.ui_actors.card_textfx.data.fonts")

local push    = table.insert
local Tst  = { "hover", "click", "collide", "drag", "release_on" }

local Y, N = true, false

return function (CardTextFx)
-----------------------------
--- init_card_textfx_attributes
----------------------------------
--- Helper: orig | cleanup
local function _orig()            return { x = 0, y = 0 } end
local function cleanup(tab, obj)  if not tab then return end; for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end

--- Helper: init text config
local function init_text_config(self, config, T, ax, ay)
    self.config      = config
    self.data_fonts  = config.data_fonts or DataFonts

    config.text,          config.lang           = tostring(config.text) or "", config.lang or "all"
    config.text_padding,  config.text_align     = config.text_padding or _orig(), config.text_align or { x = "center", y = "middle" }
    config.textfx_auto_w, config.textfx_auto_h  = (T.w == nil), (T.h == nil)
    config.text_scale,    config.textfx_anchor  = config.text_scale or 1, { x = (T.x or 0) + ax*(T.w or 0), y = (T.y or 0) + ay*(T.h or 0), ax = ax, ay = ay }
end

--- Helper: init states
local function init_states(self, config)
    local st = self.states
    for _, k in ipairs(Tst) do st[k].can = N end

    if config.button then st.collide.can, st.click.can = Y, Y; if config.can_hover ~= N then st.hover.can = Y end end
    if config.can_collide ~= nil then st.collide.can  = config.can_collide end
    if config.can_click   ~= nil then st.click.can    = config.can_click   end
    if config.can_hover   ~= nil then st.hover.can    = config.can_hover   end
end

---____________________________
--- main: init_card_textfx_attributes
---______________________________________
function CardTextFx:init_card_textfx_attributes(gm, config)
    config = config or {}
    local T       = config.T or { x = config.x or 0, y = config.y or 0, w = config.w, h = config.h, r = config.r, scale = config.scale }
    local ax, ay  = config.anchor_x or 0.5, config.anchor_y or 0.5
    init_text_config(self, config, T, ax, ay)

    Actor.init(self, gm, { T = { x = T.x, y = T.y, w = T.w, h = T.h, r = T.r, scale = T.scale } })
    init_states(self, config)

    self:set_role({ wh_bond = "Weak", scale_bond = "Weak" })
    if config.no_register then cleanup(self.t_actors, self); cleanup(self.RACTOR, self); return end
    if getmetatable(self) == CardTextFx then push(self.RACTOR, self) end
end

---____________________________
--- main: remove
---______________________________________
function CardTextFx:remove()
    local cfg = self.config
    if cfg then cfg.card_textfx_cache = nil end
    Actor.remove(self)
end

end
