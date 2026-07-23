local Atlas = require("HMEng.my_io.atlas")

local root_tex = "resources/textures/"
local Y, N = true, false

local asset_group_tabs = { "loaded", "owners", "managed" }

local groups = {
    title = {
        { key = "title_pack",      dir = root_tex .. "ui/",        asset = "title_pack", filter_min = "linear", filter_mag = "linear", image_settings = { mipmaps = Y, mipmap_filter = "linear" } },
        { key = "icon_pack",       dir = root_tex .. "ui/",        asset = "icon_pack",  filter_min = "linear", filter_mag = "linear", image_settings = { mipmaps = Y, mipmap_filter = "linear" } },
        { key = "title_map_dummy", dir = root_tex .. "map/dummy/", asset = "map",        filter_min = "linear", filter_mag = "linear", image_settings = { mipmaps = Y, mipmap_filter = "linear" } },
        { key = "title_map_blur",  dir = root_tex .. "map/dummy/", asset = "title_blur", filter_min = "linear", filter_mag = "linear", image_settings = { mipmaps = Y, mipmap_filter = "linear" } },
    },
}

return function(GMgr)
-----------------------------
--- Asset groups
----------------------------------
--- Helper: asset_group_state
local function asset_group_state(gm)
    gm.asset_groups = gm.asset_groups or { loaded = {}, owners = {}, managed = {} }
    local _groups = gm.asset_groups
    for _, tab in ipairs(asset_group_tabs) do _groups[tab] = _groups[tab] or {} end
    return gm.asset_groups
end

--- Helper: mark_group_owner
local function mark_group_owner(state, group_name, atlas_key)
    state.loaded[group_name]             = state.loaded[group_name] or {}
    state.owners[atlas_key]              = state.owners[atlas_key] or {}
    state.loaded[group_name][atlas_key]  = Y
    state.owners[atlas_key][group_name]  = Y
end

--- Helper: has_group_owner
local function has_group_owner(state, atlas_key)
    local owners = state.owners[atlas_key];     if not owners then return N end
    for _ in pairs(owners) do return Y end
    return N
end

--- Helper: load_group_atlas
local function load_group_atlas(gm, group_name, spec)
    local TA   = gm.T_atlas or {}
    gm.T_atlas = TA

    local state = asset_group_state(gm)
    if not TA[spec.key] then
        TA[spec.key] = Atlas(spec.dir, spec.asset, spec.filter_min, spec.filter_mag, spec.image_settings)
        state.managed[spec.key] = Y
    end
    mark_group_owner(state, group_name, spec.key)
    return TA[spec.key]
end

--- Helper: release_group_atlas
local function release_group_atlas(gm, group_name, atlas_key)
    local state, TA = asset_group_state(gm), gm.T_atlas or {}
    local loaded = state.loaded[group_name]
    if not (loaded and loaded[atlas_key]) then return end

    loaded[atlas_key] = nil
    if state.owners[atlas_key] then state.owners[atlas_key][group_name] = nil end
    if has_group_owner(state, atlas_key) or not state.managed[atlas_key] then return end

    local atlas = TA[atlas_key]
    if atlas and atlas.image and atlas.image.release then atlas.image:release() end
    TA[atlas_key], state.owners[atlas_key], state.managed[atlas_key] = nil, nil, nil
end

--- Helper: group_specs | ensure_asset_group
local function group_specs(group_name) return groups[group_name] or {} end
function GMgr:ensure_asset_group(group_name) for _, spec in ipairs(group_specs(group_name)) do load_group_atlas(self, group_name, spec) end; return Y end

-----------------------------
--- release_asset_groups
----------------------------------
function GMgr:release_asset_group(group_name)
    local state  = asset_group_state(self)
    local loaded = state.loaded[group_name];                if not loaded then return Y end

    local keys = {}
    for key in pairs(loaded) do keys[#keys + 1] = key end
    for _, key in ipairs(keys) do release_group_atlas(self, group_name, key) end
    state.loaded[group_name] = nil
    return Y
end

end
