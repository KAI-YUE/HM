local Atlas   = require("HMEng.my_io.atlas")
local FileIO  = require("core.io.fileio")
local LG, LF  = love.graphics, love.filesystem

local tsort   = table.sort

local Tuda      = { "unlocked", "discovered", "alerted" }
local root_tex  = "resources/textures/"

local Y, N      = true, false

return function (GMgr)
---------------------------------
--- init shaders 
----------------------------------
--- Helper: assemble_shader_source
local function assemble_shader_source(root_dir, relative_path, active_stack)
    active_stack = active_stack or {}
    if active_stack[relative_path] then error(("Cyclic shader include detected for '%s'"):format(relative_path)) end

    active_stack[relative_path] = Y

    local full_path  = root_dir .. relative_path
    local source     = assert(LF.read(full_path), ("Failed to read shader source '%s'"):format(full_path))
    source           = source:gsub('#pragma%s+HM_INCLUDE%s+"([^"]+)"', function(include_path) return assemble_shader_source(root_dir, include_path, active_stack) end)

    active_stack[relative_path] = nil
    return source
end

--- Helper: collect_shader_dirs
local function collect_shader_dirs(root_dir, relative_dir, out)
    out          = out or {}
    relative_dir = relative_dir or ""
    local dir    = root_dir .. relative_dir
    local items  = LF.getDirectoryItems(dir)

    tsort(items)
    if relative_dir ~= "" then out[#out+1] = relative_dir end

    for _, item in ipairs(items) do
        local child = relative_dir == "" and item or (relative_dir .. "/" .. item)
        if LF.getInfo(root_dir .. child, "directory") then collect_shader_dirs(root_dir, child, out) end
    end
    return out
end

---_________________________________________
--- main: init_shaders 
---_________________________________________
function GMgr:init_shaders()
    self.t_shaders = {}                          -- Load all shaders from resources
    local _root        = "resources/shaders/"
    local shader_dirs  = collect_shader_dirs(_root)

    for _, _dir in ipairs(shader_dirs) do
        local dir           = _root .. _dir
        local shader_files  = LF.getDirectoryItems(dir)
        
        for _, filename in ipairs(shader_files) do
            local extension = string.sub(filename, -3);         if extension ~= ".fs" then goto continue end
            
            local shader_name    = string.sub(filename, 1, -4)
            local relative_path  = _dir .. "/" .. filename
            local shader_source  = assemble_shader_source(_root, relative_path)

            -- print(G.debugger.time_stamp(), shader_name)
            self.t_shaders[shader_name] = LG.newShader(shader_source)
            ::continue::
        end
    end
end

-----------------------------
--- Shared atlas settings
----------------------------------
function GMgr:shared_atlas_settings()
    local atlas_smooth = { mipmaps = Y, mipmap_filter = "linear" }
    self.T_atlas = {
        -- general card related
        ranks    = Atlas(root_tex.."card/ranks/",        "ranks", "linear", "linear", atlas_smooth),
        cards    = Atlas(root_tex.."card/cards/",        "cards", "linear", "linear", atlas_smooth),

        suits32  = Atlas(root_tex.."card/suits/32/",     "suits", "linear", "linear", atlas_smooth),
        suits64  = Atlas(root_tex.."card/suits/64/",     "suits", "linear", "linear", atlas_smooth),
        suits128 = Atlas(root_tex.."card/suits/128/",    "suits", "linear", "linear", atlas_smooth),
        
        -- machi card
        machi128  = Atlas(root_tex.."machi/128/",        "machi", "linear", "linear", atlas_smooth),

        -- meshi card
        meshi128   = Atlas(root_tex.."meshi/128/",       "meshi", "linear", "linear", atlas_smooth),

        -- map
        grass     = Atlas(root_tex.."map/grass/",        "grass_tiles", "nearest", "nearest" ),
        grass_dec = Atlas(root_tex.."map/grass/",        "grass_dec", "linear", "linear", atlas_smooth),

        -- ui experiments
        icon_pack = Atlas(root_tex.."ui/", "icon_pack",  "linear", "linear", atlas_smooth),
        ui_pack   = Atlas(root_tex.."ui/", "ui_pack",    "linear", "linear", atlas_smooth),

        -- pawns 
        pawns    = Atlas(root_tex.."pawns/", "pawns")
    }
end

-----------------------------
--- Initialize the window
----------------------------------
function GMgr:init_window(reset)
    local rcfg  = self.rcfg;                         
    rcfg.r_pad_h, rcfg.r_pad_w = 0.7, 1
    
    local tz, ts      = rcfg.tile_size, rcfg.tile_scale
    local norm, SET   = tz*ts,          self.SET 
    local w,  h       = rcfg.tile_w + 2*rcfg.r_pad_w, rcfg.tile_h + 2*rcfg.r_pad_h

    self.win_trans    = { x = 0, y = 0, w = w, h = h }
    self.window_prev  = { orig_scale = ts, w = w*norm, h = h*norm, orig_ratio = w/h }
    SET.queued_c      = SET.queued_c or {}
    SET.queued_c.screenmode = SET.s_win.screenmode
    
    self.Fs.apply_window_settings(self, nil, Y)
end

-----------------------------
--- init item prototypes
----------------------------------
--- Helper: seal 
local function _seal(order) return { order = order, discovered = N, set = "Seal"  }  end

--- Helper: save to profile 
function GMgr:_save2profile()
    self:save_progress()
    local SET  = self.SET;           local Spro = SET.profile

    self.Fs.convert_save_to_meta(self)
    local shared = self.shared_save_path and FileIO.unpickle(self:shared_save_path())
    local meta = shared and shared.meta and shared.meta[Spro] or FileIO.unpickle(Spro.."/meta.hm") or {}
    for i, k in ipairs(Tuda) do meta[k] = meta[k] or {} end 

    tsort(self.P_locked,         function (a, b) return not a.order or not b.order or a.order < b.order end)
    tsort(self.P_CPools["Deck"], function (a, b) return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0)) end)
end

---______________________________________
--- main: init_item_prototypes
---______________________________________
function GMgr:init_item_prototypes()
    self:shared_atlas_settings()
    self.tag_undiscovered = {name = "Not Discovered", order = 1, config = {type = ""}, pos = { x=3,y=4 } }

    self.b_undiscovered = {name = "Undiscovered", debuff_text = "Defeat this blind to discover", pos = {x=0,y=30}}

    self.CMod = {
        c_base = { max = 500, freq = 1, line = "base", name = "Default Base", pos = { x = 1,y = 0 }, set = "Default", label = "Base Card", effect = "Base", cost_mult = 1.0, config = {} },

        -- --Backs
        b_red  = {name = "Red Deck",         stake = 1, unlocked = true,order = 1, pos =   {x=0,y=0}, set = "Deck", config = {discards = 1}, discovered = true},

        -- --editions
        e_base =       {order = 1,  unlocked = true, discovered = N, name = "Base", pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {}},
        e_foil =       {order = 2,  unlocked = true, discovered = N, name = "Foil", pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 50}},
        e_holo =       {order = 3,  unlocked = true, discovered = N, name = "Holographic", pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 10}},
        e_polychrome = {order = 4,  unlocked = true, discovered = N, name = "Polychrome", pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 1.5}},
        e_negative =   {order = 5,  unlocked = true, discovered = N, name = "Negative", pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 1}},
    }

    self.P_CPools = { Default = {}, Edition = {}, Deck = {} }
    self.P_locked = {}

    self:_save2profile()
end

end
