local M = {}

-----------------------------
--- opt_value
----------------------------------
--- Helper: opt_value
function M.opt_value(v, fallback)
    if v ~= nil then return v end
    return fallback
end

-----------------------------
--- load_snapshot_mask_domain
----------------------------------
--- Helper: load_snapshot_mask_domain
function M.load_snapshot_mask_domain(gm, snap, w, h)
    if snap.fx_mask_ref ~= "room" then return { 0, 0, w, h }, { w, h }, { 0, 0, w, h } end

    local RT, rcfg = gm._room and gm._room.T, gm.rcfg or {}
    if not RT then return { 0, 0, w, h }, { w, h }, { 0, 0, w, h } end

    local tz, norm = rcfg.tile_size or 1, (rcfg.tile_size or 1) * (rcfg.tile_scale or 1)
    local mw, mh   = RT.w * tz, 0.67 * RT.h * tz
    return { 0, 0, mw, mh }, { mw, mh }, { RT.x * norm, RT.y * norm, RT.w * norm, 0.67 * RT.h * norm }
end

return M
