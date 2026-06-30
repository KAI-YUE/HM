local FileIO   = require("core.io.fileio")
local TabUtils = require("HMfns.utils.table_utils")
local LF       = love.filesystem

local deep_copy   = TabUtils.deep_copy
local unpickle    = FileIO.unpickle
local pickle_dump = FileIO.pickle_dump
local floor       = math.floor

local Y, N = true, false

local SAVE_SCHEMA_VERSION = 1
local DEFAULT_USER_NAME   = "player"
local DEFAULT_ICON        = { atlas_key = "icon_pack", quad_key = "question_mark" }
local CARD_ZONE_KEYS      = { "deck", "hand", "play", "discard" }

return function(GMgr)
-----------------------------
--- Save slot identity
----------------------------------
--- Helper: slot_count
local function slot_count(gm) local SD = gm.SET and gm.SET.save_data or {}; return SD.slot_count or 9 end

--- Helper: clamp_slot
local function clamp_slot(gm, slot_id)
    slot_id = tonumber(slot_id) or 1;   if slot_id < 1 then return 1 end
    local n = slot_count(gm);           if slot_id > n then return n end
    return floor(slot_id)
end

--- Helper: clean_user_name
local function clean_user_name(user_name)
    user_name  = tostring(user_name or DEFAULT_USER_NAME)
    user_name  = user_name:gsub("^%s+", ""):gsub("%s+$", "")
    user_name  = user_name:gsub("[^%w_%-.]", "_")
    if user_name == "" then return DEFAULT_USER_NAME end
    return user_name
end

--- Helper: save_root
local function save_root(gm)                           local SD = gm.SET and gm.SET.save_data or {}; return SD.root or "saves" end
--- Helper: slot_root
local function slot_root(gm)                           local SD = gm.SET and gm.SET.save_data or {}; return SD.slots_root or (save_root(gm) .. "/slots") end
--- Helper: slot_path
local function slot_path(gm, slot_id)                  return ("%s/slot_%02d.hm"):format(slot_root(gm), clamp_slot(gm, slot_id)) end
--- Helper: slot_meta_path
local function slot_meta_path(gm, slot_id)             return ("%s/slot_%02d_meta.hm"):format(slot_root(gm), clamp_slot(gm, slot_id)) end

--- Helper: summary cache
local function summary_cache(gm) gm.save_slot_summary_cache = gm.save_slot_summary_cache or {}; return gm.save_slot_summary_cache end
local function cache_slot_summary(gm, slot_id, meta) if meta then summary_cache(gm)[slot_id] = deep_copy(meta) end; return meta end
local function cached_slot_summary(gm, slot_id) local meta = summary_cache(gm)[slot_id]; return meta and deep_copy(meta) end
local function empty_slot_summary(gm, slot_id, user_name)
    return {
        slot_id   = slot_id,
        user_name = gm:save_user_name(user_name),
        empty     = Y,
        title     = ("DATA %d"):format(slot_id),
        icon      = deep_copy(DEFAULT_ICON),
    }
end

--- Helper: preserve_slot_progress_meta
local function preserve_slot_progress_meta(gm, slot_id, meta)
    local old_meta = unpickle(slot_meta_path(gm, slot_id))
    if not old_meta then return meta end
    meta.unlocked   = meta.unlocked   or old_meta.unlocked
    meta.discovered = meta.discovered or old_meta.discovered
    meta.alerted    = meta.alerted    or old_meta.alerted
    return meta
end

--- Helper: sync save slot data
local function sync_save_slot_data(gm, slot_id, save_data, meta)
    local root, slots = save_root(gm), slot_root(gm)
    if not LF.getInfo(root) then LF.createDirectory(root) end
    if not LF.getInfo(slots) then LF.createDirectory(slots) end
    meta = preserve_slot_progress_meta(gm, slot_id, meta)
    if save_data then save_data.meta = meta end
    pickle_dump(gm:save_slot_path(slot_id), save_data)
    pickle_dump(gm:save_slot_meta_path(slot_id), meta)
    cache_slot_summary(gm, clamp_slot(gm, slot_id), meta)
end

--- Helper: queue save slot data
local function queue_save_slot_data(gm, slot_id, user_name, save_data, meta)
    local mgr = gm.SaveMgr
    if not (mgr and mgr.channel) then sync_save_slot_data(gm, slot_id, save_data, meta); return N end
    meta = preserve_slot_progress_meta(gm, slot_id, meta)
    if save_data then save_data.meta = meta end
    cache_slot_summary(gm, clamp_slot(gm, slot_id), meta)
    mgr.channel:push({ type = "save_run", save_table = save_data, save_meta = meta,
        slot_id = slot_id, user_name = user_name, profile_num = gm.SET.profile, save_data = gm.SET.save_data })
    return Y
end

--- Helper: save_user_name
function GMgr:save_user_name(user_name) local SET = self.SET or {}; return clean_user_name(user_name or SET.user_name or SET.username or DEFAULT_USER_NAME) end
--- Helper: save_slot_path
function GMgr:save_slot_path(slot_id) return slot_path(self, slot_id) end
--- Helper: save_slot_meta_path
function GMgr:save_slot_meta_path(slot_id) return slot_meta_path(self, slot_id) end

-----------------------------
--- build save slot data
----------------------------------
--- Helper: build save slot meta
function GMgr:build_save_slot_meta(slot_id, user_name)
    slot_id   = clamp_slot(self, slot_id)
    user_name = self:save_user_name(user_name)

    return {
        schema_version = SAVE_SCHEMA_VERSION,
        slot_id        = slot_id,
        user_name      = user_name,
        saved_at       = os.time(),
        playtime_s     = floor((self._T.session_s) or 0),
        icon           = deep_copy(DEFAULT_ICON),
        title          = ("DATA %d"):format(slot_id),
    }
end

--- Helper: copy_transform | copy_cell
local function copy_transform(T)  if not T then return end; return { x = T.x, y = T.y, r = T.r, w = T.w, h = T.h, scale = T.scale } end
local function copy_cell(cell)    if not cell then return end; return { row = cell.row, col = cell.col } end

--- Helper: is field pawn | capture_pawn_list
local function is_field_pawn(gm, pawn)
    local zone = pawn and pawn.zone
    return zone and (zone == gm.gridzone or (zone.config and zone.config.type == "field"))
end

local function capture_pawn_list(gm, list, kind)
    local out = {}
    for _, pawn in ipairs(list or {}) do
        if not is_field_pawn(gm, pawn) then goto continue end
        out[#out + 1] = {
            kind       = pawn.kind or kind,
            T          = copy_transform(pawn.T),
            cell       = copy_cell(pawn.cell),
            zone_type  = pawn.zone and pawn.zone.config and pawn.zone.config.type,
            static     = pawn.static,
            visible    = pawn.states and pawn.states.visible,
            sprite_key = pawn.params and pawn.params.sprite_name,
            atlas_key  = pawn.params and pawn.params.atlas_key,
        }
        ::continue::
    end
    return out
end

--- Helper: capture_zone_summary
local function capture_zone_summary(zone)
    if not zone then return end
    local cards = {}
    for i, card in ipairs(zone.cards or {}) do cards[i] = card.playing_card or card.sort_id or i end
    return { type = zone.config and zone.config.type, count = #cards, cards = cards }
end

--- Helper: capture_card_zones
local function capture_card_zones(gm)
    local out = {}
    for _, key in ipairs(CARD_ZONE_KEYS) do
        local zone = gm[key]
        if zone and not zone.REMOVED then out[key] = capture_zone_summary(zone) end
    end
    return out
end

--- Helper: capture revealed field cells
local function capture_revealed_field_cells(gm)
    local out, field, gridzone = {}, gm.field, gm.gridzone
    for _, cell in pairs(field and field.revealed_field_cells or {}) do
        local row = gridzone and gridzone.cells and gridzone.cells[cell.row]
        local card = row and row[cell.col]
        out[#out + 1] = {
            row = cell.row,
            col = cell.col,
            card = deep_copy(card and card.config and card.config.card or card and card.base),
        }
    end
    table.sort(out, function(a, b) return a.row == b.row and a.col < b.col or a.row < b.row end)
    return out
end

function GMgr:build_save_slot_data(slot_id, run_snapshot, user_name)
    local R = self.R;               if not R then  return end
    local meta = self:build_save_slot_meta(slot_id, user_name)

    return {
        schema_version = SAVE_SCHEMA_VERSION,
        meta           = meta,
        story          = deep_copy(self:story_state_ref()),
        world          = {
            field = {
                Fcfg = deep_copy(self.Fcfg or {}),
                Mcfg = deep_copy(self.Mcfg or {}),
                revealed_cells = capture_revealed_field_cells(self),
            },
            pawns = {
                pawns     = capture_pawn_list(self, R.PAWN, "pawn"),
                terrain   = capture_pawn_list(self, R.TERRAINPAWN, "terrain_pawn"),
            },
        },
        cards          = {
            zones = capture_card_zones(self),
        },
        run            = run_snapshot,
    }, meta
end

--- Helper: build run snapshot
local function build_run_snapshot(gm)
    local args, Fs = gm.args, gm.Fs
    return (Fs and Fs.build_state_dict and Fs.build_state_dict(gm)) or args.save_run
end

--- Helper: prepared save slot data
function GMgr:clear_prepared_save_slot_data()
    local args = self.args; if not args then return end
    if args.save_slot_run_prepared then args.save_run = nil end
    args.save_slot_id, args.save_slot_user_name = nil, nil
    args.save_slot_data, args.save_slot_meta = nil, nil
    args.save_slot_run_prepared = nil
end

function GMgr:prepare_save_slot_data(slot_id, user_name)
    slot_id   = clamp_slot(self, slot_id)
    user_name = self:save_user_name(user_name)

    local args = self.args
    if args.save_slot_data and args.save_slot_meta and args.save_slot_id == slot_id and args.save_slot_user_name == user_name then return args.save_slot_data, args.save_slot_meta, args.save_run end

    local run_snapshot = build_run_snapshot(self)
    local save_data, meta = self:build_save_slot_data(slot_id, run_snapshot, user_name)
    if not save_data then return end

    args.save_run = run_snapshot
    args.save_slot_run_prepared = Y
    args.save_slot_id, args.save_slot_user_name = slot_id, user_name
    args.save_slot_data, args.save_slot_meta = save_data, meta
    return save_data, meta, run_snapshot
end

-----------------------------
--- save_slot
----------------------------------
function GMgr:save_slot(slot_id, user_name)
    slot_id   = clamp_slot(self, slot_id)
    user_name = self:save_user_name(user_name)
    self.SET.slot_idx = slot_id

    local save_data, meta = self:prepare_save_slot_data(slot_id, user_name)
    if not save_data then return end

    self:clear_prepared_save_slot_data()

    local queued = queue_save_slot_data(self, slot_id, user_name, save_data, meta)

    return save_data, meta, queued
end

-----------------------------
--- save_slot_sync
----------------------------------
function GMgr:save_slot_sync(slot_id, user_name)
    slot_id   = clamp_slot(self, slot_id)
    user_name = self:save_user_name(user_name)
    self.SET.slot_idx = slot_id

    local save_data, meta = self:prepare_save_slot_data(slot_id, user_name)
    if not save_data then return end

    self:clear_prepared_save_slot_data()

    sync_save_slot_data(self, slot_id, save_data, meta)
    return save_data, meta
end

-----------------------------
--- queue_save_slot
----------------------------------
function GMgr:queue_save_slot(slot_id, user_name) return self:save_slot(slot_id, user_name) end

-----------------------------
--- delete_save_slot
----------------------------------
function GMgr:delete_save_slot(slot_id, user_name)
    slot_id   = clamp_slot(self, slot_id)
    user_name = self:save_user_name(user_name)

    LF.remove(self:save_slot_path(slot_id))
    LF.remove(self:save_slot_meta_path(slot_id))
    summary_cache(self)[slot_id] = nil

    local empty = empty_slot_summary(self, slot_id, user_name)
    cache_slot_summary(self, slot_id, empty)
    return empty
end

-----------------------------
--- load_save_slot
----------------------------------
function GMgr:load_save_slot(slot_id, user_name)
    local data = unpickle(self:save_slot_path(slot_id))
    if data and data.story then self.story_state = data.story end
    return data
end

-----------------------------
--- load_save_slot_run
----------------------------------
function GMgr:load_save_slot_run(slot_id, user_name)
    local data = self:load_save_slot(slot_id, user_name)
    if not data then return end
    return data.run or data
end

-----------------------------
--- save_slot_summary
----------------------------------
function GMgr:save_slot_summary(slot_id, user_name)
    slot_id = clamp_slot(self, slot_id)
    local cached = cached_slot_summary(self, slot_id); if cached then return cached end

    local meta = unpickle(self:save_slot_meta_path(slot_id))
    if meta then return cache_slot_summary(self, slot_id, meta) end

    local data = unpickle(self:save_slot_path(slot_id))
    return data and data.meta and cache_slot_summary(self, slot_id, data.meta)
end

-----------------------------
--- list_save_slot_summaries
----------------------------------
function GMgr:list_save_slot_summaries(user_name)
    local out = {}
    for i = 1, slot_count(self) do
        out[i] = self:save_slot_summary(i, user_name) or empty_slot_summary(self, i, user_name)
    end
    return out
end

end
