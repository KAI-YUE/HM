local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")

local push = table.insert

local Tst   = { "collide", "hover", "click" }
local Y, N  = true, false

return function (Chara)
-------------------------------------------------------
--- init chara attributes
-------------------------------------------------------
function Chara:init_chara_attributes(gm, x, y, w, h, params)
    AnimDecorator.init(self, gm, x, y, w, h, params)

    local p          = self.params
    local def        = p.definition or p.def or {}
    self.definition  = def

    self.model_params    = def.params or {}
    self.expression_defs = def.expressions or {}
    self.hair_cfg        = def.hair or {}
    self.hair_params     = def.hair and def.hair.params 
    if self.bind_expression_shortcuts then self:bind_expression_shortcuts() end

    local st = self.states
    for _, v in ipairs(Tst) do st[v].can = Y end
    st.drag.can   = N
    st.eye_close  = { is = (p.eyes_closed == Y) }

    local gR = gm.R
    if getmetatable(self) == Chara then push(gR.CHARA, self) end
    self.RCHARA = gR.CHARA
end

-------------------------------------------------------
--- remove
-------------------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end

function Chara:remove()
    cleanup(self.RCHARA, self)
    AnimDecorator.remove(self)
end

end
