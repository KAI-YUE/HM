local Actor, C  = require("HMEng.actors.actor"), require("HMfns.animate.color.color_const")
local layout    = require("HMEng.entities.card.card_front.build_face.basic_layout")
local TabUtils  = require("HMfns.utils.table_utils")
local Rsuits    = require("HMGplay.cards.card_data.suits")
local Rranks    = require("HMGplay.cards.card_data.hand_ranks")

local contains  = TabUtils.contains
local rand      = math.random
local Lpips     = layout.pips
local LSPpips   = layout.SPpips
local LEXpips   = layout.Expips
local LEEpips   = layout.EEpips
local LMpips    = layout.Mpips
local LG        = love.graphics

local Tstd, Tex = { "H", "D", "S", "C" }, { "W", "F", "SM", "E", "R" }
local TE = {}

local cw = C.WHITE

local Y, N = true, false

return function (CardFront)
-------------------------------
--- init_CardFront_attributes
-------------------------------
--- Helper: _norm_rgba
local function _norm_rgba(color)  if type(color) ~= "table" then return cw end; return { color[1]/255, color[2]/255, color[3]/255, color[4]/ 255 } end

--- Helper: get rank color 
local function _get_rank_color(rank_atlas, suit)
    local suits = rank_atlas and rank_atlas.data and rank_atlas.data.suits
    if type(suits) ~= "table" then return cw end

    local suit_index
    for i, abbrev in ipairs(Rsuits.abbrev or {}) do if abbrev == suit then suit_index = i; break end end
    if not suit_index then return cw end

    for _, suit_data in pairs(suits) do if suit_data.index == suit_index then return _norm_rgba(suit_data.color) end end
    return cw
end

--- Helper: get face suit keys 
local function _get_face_suit_keys(suit, rank, suit_code)
    if suit == "R" then return { [32] = "_14_mys", [64] = "_14_mys", [128] = "_14_mys" } end
    if suit ~= "M" then return { [32] = suit_code, [64] = suit_code, [128] = suit_code } end
    if rank == "1" or rank == "2" then return { [32] = "_11_moon_v1", [64] = "_11_moon_v1", [128] = "_11_moon_v1" } end
    if rank == "3" or rank == "4" then return { [32] = "_3_moon", [64] = "_3_moon", [128] = "_3_moon" } end
    if rank == "5" or rank == "10" or rank == "V" or rank == "X" then return { [32] = "_13_moon_v3", [64] = "_13_moon_v3", [128] = "_13_moon_v3" } end
    if rank == "6" or rank == "7" or rank == "8" or rank == "9"  then return { [32] = "_12_moon_v2", [64] = "_12_moon_v2", [128] = "_13_moon_v3" } end
    return { [32] = suit_code, [64] = suit_code, [128] = suit_code }
end

--- Helper: init face 
function CardFront:_init_face_quads(TA)
    local s_code, r_code  = self.suit_code, self.rank_code
    local face_s_keys     = _get_face_suit_keys(self.suit, self.rank, s_code)

    local s32, s64, s128  = TA.suits32, TA.suits64, TA.suits128

    self.Qsuit = s32:get_quad(s_code)
    self.Qrank = TA.ranks:get_quad(r_code)

    self.fine_s_imgs = { [32] = s32.image, [64] = s64.image, [128] = s128.image } 
    self.fine_quads  = { [32] = s32:get_quad(face_s_keys[32]), [64]  = s64:get_quad(face_s_keys[64]), [128] = s128:get_quad(face_s_keys[128]) }
end

--- Helper: init face frame
local function _init_face_frame(self, TA, card)
    local atlas, key = TA.cards, card.frame_key or "card_frame_1";         if not (atlas and atlas.quads and atlas.quads[key]) then return end
    self.frame_img, self.frame_quad = atlas.image, atlas.quads[key]
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
    self.suit_shader, self.rank_color   = s_shader, _get_rank_color(TA.ranks, self.suit)

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
