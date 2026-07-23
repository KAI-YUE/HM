local Y = true

return function (GMgr)
-----------------------------
--- register scope obj
----------------------------------
function GMgr:register_scope_obj(obj, scope)
    if not obj then return end

    local SR = self.ScopeR
    if not SR then SR = { run = {}, menu = {}, transient = {}, system = {} }; self.ScopeR = SR end

    scope     = scope or self.registry_scope or "run"
    SR[scope] = SR[scope] or {}
    SR[scope][obj] = Y

    obj.registry_scope = scope
end

-----------------------------
--- unregister_scope_obj
----------------------------------
function GMgr:unregister_scope_obj(obj)
    local SR, scope = self.ScopeR, obj and obj.registry_scope
    if not SR or not scope or not SR[scope] then return end

    SR[scope][obj] = nil
    obj.registry_scope = nil
end

-----------------------------
--- remove scope
----------------------------------
function GMgr:remove_scope(scope)
    local SR = self.ScopeR
    local reg = SR and SR[scope]
    if not reg then return end

    local targets = {}
    for obj in pairs(reg) do targets[#targets + 1] = obj end
    for _, obj in ipairs(targets) do if obj and not obj.REMOVED then obj:remove() end end

    SR[scope] = {}
end

end
