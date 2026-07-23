local Actor, C   = require("HMEng.actors.actor"), require("HMfns.animate.color.color_const")
local layout     = require("HMEng.entities.card.card_front.cfg_data.basic_layout")
local FaceSuits  = require("HMEng.entities.card.card_front.cfg_data.face_suit_keys")
local FrontCfg   = require("HMEng.entities.card.card_front.cfg_data.front_config")
local TabUtils   = require("HMfns.utils.table_utils")
local Rsuits     = require("HMGplay.cards.card_data.suits")
local Rranks     = require("HMGplay.cards.card_data.hand_ranks")
local LG         = love.graphics

local rand      = math.random
local contains  = TabUtils.contains
local Lpips     = layout.pips
local LSPpips   = layout.SPpips
local LEXpips   = layout.Expips
local LEEpips   = layout.EEpips
local LMpips    = layout.Mpips

local Tstd, Tex = { "H", "D", "S", "C" }, { "W", "F", "SM", "E", "R" }
local TE = {}

local cw = C.WHITE
local cb = C.CARD.BASE
local cs = C.CARD.SUIT
local Fdef = FrontCfg.default or {}

local Y, N = true, false

return function (CardFront)
-------------------------------
--- init_CardFront_attributes
-------------------------------
--- Helper: get rank color 
local function _get_rank_color(suit) return cs[suit] or cw end

--- Helper: init face 
function CardFront:_init_face_quads(TA)
    local s_code, r_code  = self.suit_code, self.rank_code
    local face_s_keys     = FaceSuits.get(self.suit, self.rank, s_code)
    local s32, s64, s128  = TA.suits32, TA.suits64, TA.suits128

    self.Qsuit = s32:get_quad(s_code)
    self.Qrank = TA.ranks:get_quad(r_code)

    self.fine_s_imgs = { [32] = s32.image,                     [64] = s64.image,                       [128] = s128.image } 
    self.fine_quads  = { [32] = s32:get_quad(face_s_keys[32]), [64]  = s64:get_quad(face_s_keys[64]),  [128] = s128:get_quad(face_s_keys[128]) }
end

--- Helper: init face frame
local function _init_face_frame(self, TA, card)
    local atlas, key = TA.cards, card.frame_key or FrontCfg.frame_key(Fdef);         if not (atlas and atlas.quads and atlas.quads[key]) then return end
    self.frame_img, self.frame_quad = atlas.image, atlas.quads[key]
    local sc = card.frame_scale or Fdef.frame_scale or 1
    self.frame_scale_x = card.frame_scale_x or Fdef.frame_scale_x or sc
    self.frame_scale_y = card.frame_scale_y or Fdef.frame_scale_y or sc
    self.frame_x, self.frame_y = card.frame_x or Fdef.frame_x or 0, card.frame_y or Fdef.frame_y or 0
    self.frame_color = card.frame_color or FrontCfg.frame_color(self.rank_color, Fdef)
end

---______________________________
--- init custom face 
---______________________________
function CardFront:_init_custom_face(gm, card)
    self.face_style = card.face_style or "pip"
    if self.face_style == "pip" then return end

    local params = self.params
    local res    = params.res or "128"

    local atlas_name, art_key  = card.face_art_atlas, card.face_art 
    
    local atlas  = gm.T_atlas[atlas_name..res]
    if not atlas or not art_key then return end

    self.face_img,     self.face_quad  = atlas.image, atlas:get_quad(art_key)
end

---______________________________
--- Main: init front attributes 
---______________________________
function CardFront:init_front_attributes(gm, x, y, w, h, card, params)
    Actor.init(self, gm, x, y, w, h)

    local TA, T, gFont, _s, _r, params = gm.T_atlas, self.T, gm.g_fonts, card.suit, tostring(card.rank), params or {}
    local _rl, s_shader                = card.rank_label and tostring(card.rank_label) or _r, params.suit_shader or Rsuits.shaders[_s]

	self.suit,        self.suit_code    = _s, Rsuits.code_names[_s]
    self.rank,        self.rank_label   = _r, _rl
    self.rank_code,   self.params       = _rl, params
	self.s_img,       self.r_img        = TA.suits32.image, TA.ranks.image
    self.fw,          self.fh           = T.w, T.h
    self.suit_shader, self.rank_color   = s_shader, _get_rank_color(self.suit)
    self.base_color                     = card.base_color or FrontCfg.random_base_color(Fdef) or cb

    self:_init_face_quads(TA)
    _init_face_frame(self, TA, card)
    self:_init_custom_face(gm, card)

    self.pips = LSPpips[_r]
    if _s == "M" and LMpips[_r] then self.pips = LMpips[_r]
    elseif contains(Tstd, _s) and (rand() < 0) then self.pips = Lpips[_r] 
    elseif contains(Tex, _s) then self.pips = LEXpips[_r] 
    elseif contains(TE, _s)  then self.pips = LEEpips[_r] end
    
    self.t_shaders, self._dirty = gm.t_shaders, Y
    self:_init_face_cache()
end

----------------------------------------------
--- quad_viewport & image_dims 
----------------------------------------------
function CardFront:quad_viewport() return { 0, 0, self.fw, self.fh } end
function CardFront:image_dims()    return { self.fw, self.fh } end

end
