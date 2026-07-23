local min, max = math.min, math.max

local Y, N = true, false

return function (Chara)
----------------------------------------
--- bind expression shortcuts
----------------------------------------
--- Helper: init expression state
local function _init_expression_state(self)
    if self.expression_state then return self.expression_state end

    self.expression_state = { active = {}, values = {} }
    return self.expression_state
end

--- Helper: resolve expression def
local function _get_expression_def(self, name)
    local defs = self.expression_defs;   if not (defs and name) then return end
    return defs[name]
end

--- Helper: apply expression param
local function _apply_expression_param(self, expr_def, value)
    local model = self.model
    if not (model and model.setParamValuePost and expr_def and expr_def.id) then return end
    model:setParamValuePost(expr_def.id, value)
end

---_______________________________
--- main: bind expression
---_______________________________
function Chara:bind_expression_shortcuts()
    local defs = self.expression_defs or {}

    for name, _ in pairs(defs) do
        if self[name] then goto continue end 
        self[name] = function(obj, enabled, value) return obj:set_expression(name, enabled, value) end

        local clear_name = "clear_" .. name
        if self[clear_name] then goto continue end 
        self[clear_name] = function(obj) return obj:clear_expression(name) end
        ::continue::
    end
end

-------------------------------------------------------
--- has expression
-------------------------------------------------------
function Chara:has_expression(name) return _get_expression_def(self, name) ~= nil end

-------------------------------------------------------
--- set expression
-------------------------------------------------------
function Chara:set_expression(name, enabled, value)
    local expr_def = _get_expression_def(self, name);    if not expr_def then return end

    local st = _init_expression_state(self)
    if enabled == N then st.active[name], st.values[name] = nil, nil; return N end

    st.active[name] = Y
    st.values[name] = value ~= nil and value or expr_def.value or 1
    _apply_expression_param(self, expr_def, st.values[name])
    return Y
end

-------------------------------------------------------
--- clear expression
-------------------------------------------------------
function Chara:clear_expression(name)
    local expr_def = _get_expression_def(self, name);    if not expr_def then return end

    local st = _init_expression_state(self)
    st.active[name], st.values[name] = nil, nil
    _apply_expression_param(self, expr_def, expr_def.reset_value or 0)
    return Y
end

-------------------------------------------------------
---  clear all expressions
-------------------------------------------------------
function Chara:clear_expressions()
    local defs = self.expression_defs or {}
    for name, _ in pairs(defs) do self:clear_expression(name) end
end

-------------------------------------------------------
--- update active expressions
-------------------------------------------------------
function Chara:update_expressions()
    local defs = self.expression_defs
    if not defs then return end

    local st = _init_expression_state(self)
    for name, expr_def in pairs(defs) do
        if not st.active[name] then goto continue end 
        _apply_expression_param(self, expr_def, st.values[name] or expr_def.value or 1)
        ::continue::
    end
end

end
