local Atlas = require("HMEng.my_io.atlas")

local root_tex = "resources/textures/"
local Y = true

return function(GMgr)
-----------------------------
--- shared atlas settings
----------------------------
--- Helper: atlas smooth settings
local function atlas_smooth() return { mipmaps = Y, mipmap_filter = "linear" } end

---____________________
--- main: shared atlas settings
---____________________
function GMgr:shared_atlas_settings()
    local smooth = atlas_smooth()
    self.T_atlas = {
        ranks    = Atlas(root_tex.."card/ranks/",        "ranks",       "linear",  "linear",  smooth),
        cards    = Atlas(root_tex.."card/cards/",        "cards",       "linear",  "linear",  smooth),

        suits32  = Atlas(root_tex.."card/suits/32/",     "suits",       "linear",  "linear",  smooth),
        suits64  = Atlas(root_tex.."card/suits/64/",     "suits",       "linear",  "linear",  smooth),
        suits128 = Atlas(root_tex.."card/suits/128/",    "suits",       "linear",  "linear",  smooth),

        machi128 = Atlas(root_tex.."machi/128/",         "machi",       "linear",  "linear",  smooth),
        meshi128 = Atlas(root_tex.."meshi/128/",         "meshi",       "linear",  "linear",  smooth),

        grass     = Atlas(root_tex.."map/grass/",        "grass_tiles", "nearest", "nearest"),
        grass_dec = Atlas(root_tex.."map/grass/",        "grass_dec",   "linear",  "linear",  smooth),

        hud_pack            = Atlas(root_tex.."ui/",     "hud_pack",            "linear", "linear", smooth),
        icon_pack           = Atlas(root_tex.."ui/",     "icon_pack",           "linear", "linear", smooth),
        inter_btn_pack      = Atlas(root_tex.."ui/",     "inter_btn_pack",      "linear", "linear", smooth),
        card_pawn_icon_pack = Atlas(root_tex.."ui/",     "card_pawn_icon_pack", "linear", "linear", smooth),
        ui_pack             = Atlas(root_tex.."ui/",     "ui_pack",             "linear", "linear", smooth),
        console_pack        = Atlas(root_tex.."btns_pads/", "console_pack",     "linear", "linear", smooth),

        pawns = Atlas(root_tex.."pawns/", "pawns"),
    }
end

end
