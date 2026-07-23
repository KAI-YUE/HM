local Prep     = require("HMGplay.run_flow.prep")
local GameRun  = require("HMGplay.run_flow.game_run")
local TabUtils = require("HMfns.utils.table_utils")
local RunTransition = require("HMui.menu.transitions.run")

local copy = TabUtils.deep_copy
local Y = true

local M = {}

-----------------------------
--- init_run
----------------------------------
--- Helper: stage for run
local function stage_for_run(gm, args)
    args = args or {}
    if args.stage then return args.stage end
    return gm.stages.run_game
end

--- Helper: apply saved run state
local function apply_saved_run_state(gm, savetext)
    if type(savetext) ~= "table" then return end
    if type(savetext.GAME) == "table" then
        local selected_back = gm.GAME and gm.GAME.selected_back
        gm.GAME = copy(savetext.GAME)
        if type(gm.GAME.selected_back) ~= "table" then gm.GAME.selected_back = selected_back end
    end
    if savetext.g_state then gm.g_state = savetext.g_state end
    gm.saved_game = savetext
end

--- Helper: cardzone snapshot | world snapshot
local function cardzone_snapshot(args) return args and args.savetext and args.savetext.cardzones end
local function world_snapshot(args) return args and args.save_data and args.save_data.world end

--- Helper: apply saved world state
local function apply_saved_world_state(gm, save_data)
    local field = save_data and save_data.world and save_data.world.field
    if not field then return end
    if field.Fcfg then gm.Fcfg = copy(field.Fcfg) end
    if field.Mcfg then gm.Mcfg = copy(field.Mcfg) end
end

function M.init_run(gm, args)
    args = args or {}
    local saved   = args.savetext
    local loading = type(saved) == "table"
    local opts    = { stage = stage_for_run(gm, args), silent_start = args.silent_start or loading, cardzones = cardzone_snapshot(args), world = world_snapshot(args),
        seed                   = args.seed, stake = args.stake, challenge = args.challenge,
        field_spawn_batch_size = args.field_spawn_batch_size, field_spawn_batch_delay = args.field_spawn_batch_delay,
        sky_decor              = args.sky_decor or args.sky_decorators, on_prepared = args.on_prepared,
        party_count            = args.party_count }

    Prep.prepare_for_gm(gm, opts)
    GameRun.prepare(gm, opts)
    apply_saved_run_state(gm, saved)
    apply_saved_world_state(gm, args.save_data)

    Prep.init_gridzone(gm, opts)
    Prep.prep_camera(gm, opts)
    Prep.prep_chara(gm)
    Prep.init_cardzones(gm, opts)
    GameRun.start(gm, opts)
    Prep.render_bg(gm)
    Prep.place_shader_fx(gm, opts)
    Prep.place_sky_decorators(gm, opts)

    if not opts.field_spawn_batch_size and opts.on_prepared then opts.on_prepared(gm) end
    return Y
end

-----------------------------
--- transition_to_run
----------------------------------
function M.transition_to_run(gm, e, args)
    local game, SET, rb = gm.GAME, gm.SET, "restart_button"

    SET.pause = Y
    if e and e.config and e.config.id == rb then game.viewed_back = nil end
    return RunTransition.start(gm, { run_args = args })
end

-----------------------------
--- new_run_args
----------------------------------
function M.new_run_args(gm, run_opts)
    run_opts = run_opts or {}
    local setup, SG = gm.SET.current_setup, gm.saved_game
    local P, _c, _n = gm.g_profile, "Continue", "New Run"

    if setup ~= _c and setup ~= _n then return end
    if setup == _c and SG then return { savetext = SG,
        field_spawn_batch_size = run_opts.field_spawn_batch_size, field_spawn_batch_delay = run_opts.field_spawn_batch_delay, on_prepared = run_opts.on_prepared,
        party_count            = run_opts.party_count, silent_start = run_opts.silent_start } end

    local _seed      = gm.run_setup_seed and gm.setup_seed or gm.forced_seed
    local _challenge = gm.challenge_tab
    local _stake     = gm.forced_stake or P[gm.SET.profile].mem.stake or 1
    return { stake = _stake, seed = _seed, challenge = _challenge,
        field_spawn_batch_size = run_opts.field_spawn_batch_size, field_spawn_batch_delay = run_opts.field_spawn_batch_delay, on_prepared = run_opts.on_prepared,
        party_count            = run_opts.party_count, silent_start = run_opts.silent_start }
end

-----------------------------
--- begin_new_run
----------------------------------
function M.begin_new_run(gm, e, run_opts)
    run_opts = run_opts or {}
    local OM, Fs = gm.UI.overlay_menu, gm.Fs; if OM then Fs.exit_overlay_menu(gm) end
    local args = M.new_run_args(gm, run_opts); if not args then return end
    return M.transition_to_run(gm, e, args)
end

-----------------------------
--- quit
----------------------------------
function M.quit() love.event.quit() end

return M
