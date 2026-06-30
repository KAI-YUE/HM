local Actor        = require("HMEng.actors.actor")
local TextFX       = require("HMEng.ui_actors.card_textfx")
local ShaderUtils   = require("HMEng.visual.shader_utils")
local TabUtils     = require("HMfns.utils.table_utils")
local Icon          = require("HMui.icons.stake")
local I18N, C      = require("HMfns.utils.format.i18n_utils"), require("HMfns.animate.color.color_const")
local Render       = require("HMfns.systems.render")

local enqueue_drawable     = Render.enqueue_drawable
local contains, i18n       = TabUtils.contains, I18N.i18n
local push, max, min       = table.insert, math.max, math.min
local rand, abs, cos, sin  = math.random,  math.abs, math.cos, math.sin

local Teb, Tsize   = { "Edition" }, { "Half" }
local Tsp          = { "Stone" }
local Tsp_set      = { "Mcard" }
local T_LUD        = { "Locked", "Undiscovered", "Default" }
local T_ch         = { "focused_ui", "front", "back", "soul_parts", "template", "floating_sprite", "shadow", "use_button", "buy_button", "buy_and_use_button", "debuff", "price", "particles", "h_popup", "mesh_card" }

local cw = C.WHITE
local crd, cgy, ctd, ctl = C.RED, C.SPGRAY, C.UI.TEXT_DARK, C.UI.TEXT_LIGHT
local Y, N = true, false

local LG = love.graphics

--- common Helpers: shader visible & fx mask active 
local function _shader_visible(st) return (not st.shader_visible) or st.shader_visible.is end

return function (Card)
--------------------------------------------------
--- Draw 
--------------------------------------------------
--- Helper: init_ss 
function Card:_init_ss() return ShaderUtils.init_ss(self) end

--- Helper: draw shadow 
function Card:_draw_shadow()
    local gm,  VT,   ch  = self.gm, self.VT ,  self.children
    local SET, zone, st  = gm.SET,  self.zone, self.states

    local is_dragging, is_hovering = st.drag.is, st.hover.is
    local is_dealing = st.dealing.is and not (is_dragging or is_hovering)
    if zone and zone.is_hand and zone:is_hand() and not (is_dragging or is_hovering or is_dealing) then return end

    for k, v in pairs(ch) do v.VT.scale = VT.scale end

    local invalid_s  = gm:is_shadow_off();    if invalid_s then return end

    local is_play_highlighted  = self.highlighted and (zone == gm.play)
    local sh = self.shadow_heights or {}

    self.shadow_height = sh.idle or 0.01
    if is_dealing then self.shadow_height = sh.dealing or sh.hover or (1.2*self.shadow_height) end
    if is_play_highlighted or is_dragging then self.shadow_height = sh.active or (1.5*self.shadow_height) end
    if is_hovering then self.shadow_height = sh.hover or (1.2*self.shadow_height) end

    local shadow = (self.sprite_facing == "front" and ch.template) or ch.back
    shadow.tilt_shadow = self.tilt_shadow
    shadow:draw_shader(self.template_shader, self.shadow_height, nil, is_dealing)
end

--- Helper: render seal ed
function Card:_render_seal_ed(gm, ed, ab, aname, _antim, basic, front, set, template, ctemplate, _ss)
    local _seal, gss, _sticker  = self.seal, gm.shared_seals, self.sticker
    local S, _sr, gstickers     = gm.t_shaders, self.sticker_run, gm.shared_sticker 
    local _has_ed, SET          = ed or self.sticker, gm.SET
    local sticker_run           = _sticker or ((_sr and _sr ~= "NONE") and SET.run_stake_stickers)
    local _sp, _VB              =  self.debuff or self.greyed or (aname == "The Soul"), (set == "Booster")
    
    local s_code = "rainbow_edge"
    if ed and ed.foil then ctemplate:draw_shader("foil", nil, _ss);  if basic then front:draw_shader("foil", nil, _ss) end  end 
    if ed and ed.glow then ctemplate:draw_shader("glow", nil, _ss);  if basic then front:draw_shader("glow", nil, _ss) end  end 
    
    if ed and ed.test then
        ctemplate:draw_shader(s_code, nil, _ss)  
        if basic then front:draw_shader(s_code, nil, _ss) end
    end
end

--+++++++++++++++++++++++ Important sub-Helper +++++++++++++++++++++++
--- Helper: render front 
function Card:_render_sfront(template, ctemplate, front, now)
    local discovered            = (template.discovered or self.bypass_discovery_template)
    local gm, ab, ch            = self.gm, self.ability, self.children
    local ed, aname, args, set  = self.edition, ab.name, self.args, ab.set
    local effect, _ss, basic    = ab.effect, args.send2fs, front and not contains(Tsp, ab.effect)

    if self.greyed then return self:_render_seal_ed(gm, ed, ab, aname, _antim, basic, front, set, template, ctemplate, _ss) end 
    if self:_fx_mask_active() then return self:_render_masked_front(gm, ed, basic, front, ctemplate, _ss) end

    local base_color = front and front.base_color
    if     base_color              then ctemplate:draw(base_color);              if basic then front:draw_self() end
    elseif _shader_visible(self.states) then ctemplate:draw_shader(self.template_shader, nil, _ss); if basic then front:draw_suit_shader(_ss) end
    else                                ctemplate:draw();                        if basic then front:draw_self() end end

    self:_render_seal_ed(gm, ed, ab, aname, _antim, basic, front, set, template, ctemplate, _ss)
end

--- Helper: render back
function Card:_get_back_overlay()
    local overlay, zone = cw, self.zone
    if not zone or zone.config.type ~= "deck"then return overlay end
        
    local base_gray, _cards    = 0.8, zone.cards                                         
    self.back_overlay, _r      = self.back_overlay or {}, self.rank 
    local bo, _o               = self.back_overlay, ((#_cards - _r)%20)/#_cards; 
    bo[1], bo[2], bo[3], bo[4] = base_gray + _o, base_gray + _o, base_gray + _o, 1;  
    overlay = bo

    return overlay
end

--- Helper: render back
function Card:_render_back(gm, ch)
    local chb, overlay = ch.back, self:_get_back_overlay()
    if _shader_visible(self.states) then chb:draw(overlay) -- chb:draw_shader("generic") 
    else chb:draw() end
end

--- Helper: render btn 
function Card:_render_btn(btn, bub, ch)
    if not btn then if ch.use_button and self.highlighted then ch.use_button:draw() end; return end

    if self.highlighted then btn.states.visible = Y; btn:draw(); if bub then bub:draw() end
    else btn.states.visible = N end
    if ch.use_button and self.highlighted then ch.use_button:draw() end
end

--- Helper: draw children 
function Card:_draw_children(gm)
    local ch, ab,  cfg, args       = self.children,         self.ability, self.config, self.args
    local cons,    template, set   = ab.consumable,         cfg.template, ab.set
    local sfacing, _T          = self.sprite_facing,    gm._T
    local now,     ctemplate, btn  = _T.real_s,          ch.template, ch.buy_button
    local bub,     front           = ch.buy_and_use_button, ch.front
    local zone = self.zone

    if ch.particles then ch.particles:draw() end  -- Any particles
    if ch.price     then ch.price:draw() end      -- Draw any tags/buttons

    self:_render_btn(btn, bub, ch)

    if     sfacing == "front" then self:_render_sfront(template, ctemplate, front, now)
    elseif sfacing == "back"  then self:_render_back(gm, ch) end

    for k, v in pairs(ch) do if not contains(T_ch, k) then v:draw() end end
    if zone and zone.is_hand and zone:is_hand() then if ch.focused_ui then ch.focused_ui:draw() end end
end

-- Helper: init tilt_var
function Card:_init_tilt_var(st, _tf)
    if not self.tilt_var then self.tilt_var = { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 } end

    local gm = self.gm;         local _T = gm._T;         local now = _T.real_s
    local Ctrl, TV     = gm.CTRL, self.tilt_var;              local cpos = Ctrl.cursor_position
    local ho           = self.hover_offset

    if st.hover.is then self:_update_tilt(TV, cpos, ho, _tf) end
    self:_update_idle_tilt(TV, now, _tf)
end

--- Helper: draw shadow only
function Card:draw_shadow_only()
    local st = self.states;                  if not st.visible or st.hide_shadow.is then return end
    self:_init_ss()
    self:_draw_shadow()
end

--- Helper: draw without shadow 
function Card:draw_without_shadow()
    local gm, st = self.gm, self.states;     if not st.visible then return end
    self:_init_ss()
    local zone, ch, _tf = self.zone, self.children, 0.2
    if not (zone and zone.is_hand and zone:is_hand()) then if ch.focused_ui then ch.focused_ui:draw() end end
    
    self:_init_tilt_var(st, _tf)
    self:_draw_children(gm)
    enqueue_drawable(gm.t_drawable, self)
    self:bound_me()
end

--____________________________________________
--- Main: draw  
--_____________________________________________
function Card:draw()
    local st = self.states;                  if not st.visible then return end
    self:draw_shadow_only()
    self:draw_without_shadow()
end

----------------------------------------------
--- Remove UI
----------------------------------------------
function Card:remove_UI()
    self.ability_UIPanel_table, self.no_ui = nil, Y
    local cfg = self.config
    cfg.h_popup, cfg.h_popup_config = nil, nil
end

end
