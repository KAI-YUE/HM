local Y, N = true, false

local M = {}

--- Helper: _txn (transaction) | mark_changed | reset_changed
local function _txn(gm)       gm.opt_system_txn = gm.opt_system_txn or {}; local txn = gm.opt_system_txn; txn.original, txn.touched, txn.targets = txn.original or {}, txn.touched or {}, txn.targets or {}; return txn end
function M.mark_changed(gm)   gm.opt_system_settings_changed = Y end
function M.reset_changed(gm)  gm.opt_system_settings_changed, gm.opt_system_pending, gm.opt_system_txn = nil, nil, nil end

--- Helper: current_value
local function current_value(settings, txn, key)
    local target = txn.targets and txn.targets[key]
    if target then
        local owner = settings[target.owner_key]
        return owner and owner[target.key]
    end
    return settings[key]
end

--- Helper: has_changes
function M.has_changes(gm)
    if not (gm and gm.opt_system_settings_changed) then return N end
    local txn, settings = gm.opt_system_txn, gm.SET or {}
    if not (txn and txn.touched) then return Y end
    for key in pairs(txn.touched) do if current_value(settings, txn, key) ~= txn.original[key] then return Y end end
    return N
end

--- Helper: set_preview
function M.set_preview(gm, key, value, on_preview)
    if not (gm.SET and key) then return end
    local txn = _txn(gm)
    if not txn.touched[key] then txn.original[key], txn.touched[key] = gm.SET[key], Y end
    gm.SET[key] = value
    gm.opt_system_pending = gm.opt_system_pending or {}
    gm.opt_system_pending[key] = value
    if on_preview then on_preview(gm, key, value) end
    M.mark_changed(gm)
end

--- Helper: set_preview_in
function M.set_preview_in(gm, owner_key, key, value, on_preview)
    if not (gm.SET and owner_key and key) then return end
    gm.SET[owner_key] = gm.SET[owner_key] or {}
    local owner, txn, txn_key = gm.SET[owner_key], _txn(gm), owner_key .. "." .. key
    if not txn.touched[txn_key] then txn.original[txn_key], txn.touched[txn_key], txn.targets[txn_key] = owner[key], Y, { owner_key = owner_key, key = key } end
    owner[key] = value
    gm.opt_system_pending = gm.opt_system_pending or {}
    gm.opt_system_pending[owner_key] = gm.opt_system_pending[owner_key] or {}
    gm.opt_system_pending[owner_key][key] = value
    if on_preview then on_preview(gm, key, value) end
    M.mark_changed(gm)
end

--- Helper: apply_preview
function M.apply_preview(gm) gm.opt_system_settings_changed, gm.opt_system_pending, gm.opt_system_txn = nil, nil, nil end

--- Helper: cancel_preview
function M.cancel_preview(gm, opts)
    local txn, settings = gm.opt_system_txn, gm.SET
    if not txn or not txn.touched or not settings then return M.reset_changed(gm) end
    for key in pairs(txn.touched) do
        local target = txn.targets and txn.targets[key]
        if target then
            settings[target.owner_key] = settings[target.owner_key] or {}
            settings[target.owner_key][target.key] = txn.original[key]
            if opts and opts.on_restore then opts.on_restore(gm, target.key, settings[target.owner_key][target.key], target.owner_key) end
        else
            settings[key] = txn.original[key]
            if opts and opts.on_restore then opts.on_restore(gm, key, settings[key]) end
        end
    end
    M.reset_changed(gm)
end

--- Helper: wrap_on_change
function M.wrap_on_change(fn)
    return function(gm, widget, value)
        local out
        if fn then out = fn(gm, widget, value) end
        M.mark_changed(gm)
        return out
    end
end

return M
