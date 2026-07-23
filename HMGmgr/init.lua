local class = require("core.class")
local GMgr   = class:extend()

local TabUtils   = require("HMfns.utils.table_utils")
local MathUtils  = require("HMfns.utils.math.math_utils")
local random_pick, wipe = TabUtils.random_pick, TabUtils.wipe
local t_in, r_in        = MathUtils.vec_translate_inplace, MathUtils.vec_rotate_inplace

local function install(mod) mod(GMgr) end

local install_list = { "registry" }
for _, pkg in ipairs(install_list) do install(require("HMGmgr." .. pkg)) end

local asset_list = { "atlas_render.init", "asset_groups" }
for _, pkg in ipairs(asset_list) do install(require("HMGmgr.data.assets." .. pkg)) end

local data_list = { "mgr", "globals" }
for _, pkg in ipairs(data_list) do install(require("HMGmgr.data." .. pkg)) end

local lang_list = { "lang" }
for _, pkg in ipairs(lang_list) do install(require("HMGmgr.data.fonts_lang." .. pkg)) end

local io_list = { "save_load", "save_story", "save_slots" }
for _, pkg in ipairs(io_list) do install(require("HMGmgr.io." .. pkg)) end

local inter_list = { "debug" }
for _, pkg in ipairs(inter_list) do install(require("HMGmgr.interactions." .. pkg)) end

local game_ui_list = { "menu", "render", "debug_render" }
for _, pkg in ipairs(game_ui_list) do install(require("HMGmgr.ui_render." .. pkg)) end

local prep_list = { "start", "s_newrun" }
for _, pkg in ipairs(prep_list) do install(require("HMGmgr.prep." .. pkg)) end

local update_list = { "update_me", "u_gameover", "update_rounds" }
for _, pkg in ipairs(update_list) do install(require("HMGmgr.update." .. pkg)) end

-----------------------------
--- init
----------------------------------
function GMgr:init() self:init_gm_attributes() end
-- function GMgr:update_menu(dt) end
function GMgr:state_col(_state) return (_state*15251252.2/5.132)%1,  (_state*1422.5641311/5.42)%1,  (_state*1522.1523122/5.132)%1, 1 end

return GMgr
