local CardTextFx      = require("HMEng.ui_actors.card_textfx")
local PaintSeeds      = require("HMEng.ui_actors.card_textfx.data.paint_seeds")
local TabUtils        = require("HMfns.utils.table_utils")
local I18N            = require("HMfns.utils.format.i18n_utils")
local TextDescription = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")

local copy, shuffle, random_pick = TabUtils.deep_copy, TabUtils.shuffle_in_place, TabUtils.random_pick
local i18n = I18N.i18n

local Y, N = true, false

local M = {}

-----------------------------
--- init_card_textfx
----------------------------------
--- Helper: room-referenced text box
local function _resolve_card_textfx_T(gm, args)
    local T         = args.T or args
    local r, scale  = T.r or args.r or 0, T.scale or args.scale or 1
    if args.room_ref == N then return { x = T.x or 0, y = T.y or 0, w = T.w or args.w, h = T.h or args.h, r = r, scale = scale } end

    local RT    = gm._room.T
    local w, h  = T.w or args.w, T.h or args.h
    if w and w > 0 and w <= 1 then w = RT.w * w end
    if h and h > 0 and h <= 1 then h = RT.h * h end

    local ax, ay  = args.anchor_x or 0.5,  args.anchor_y or 0.5
    local x,  y   = T.x or args.x or 0.5,  T.y or args.y or 0.5
    x, y          = RT.x + RT.w*x, RT.y + RT.h*y

    return { x = x - ax*(w or 0), y = y - ay*(h or 0), w = w, h = h, r = r, scale = scale }
end

--- Helper: card textfx
local function _card_textfx_configs(cfg) if not cfg then return {} elseif cfg[1] then return cfg end; return { cfg } end

--- Helper: shuffled paint seeds for this stroked page
local function _paint_seed_entries(k)
    local seeds  = shuffle(copy(PaintSeeds))
    local out    = {}

    if not seeds or #seeds <= 0 then return out end
    for i = 1, k do out[i] = copy(seeds[((i - 1) % #seeds) + 1]) end
    return out
end

--- Helper: _resolve_sampling_seed
local function _resolve_sampling_seed(args)
    if args.sampling_seed ~= nil then return args.sampling_seed end
    return args.sampling_seed_list and random_pick(args.sampling_seed_list)
end

--- Helper: build one card textfx actor
local function _new_card_textfx(self, gm, item, alpha, paint_seed_entry)
    local args = copy(item)
    if args.text_i18n_key then
        local scope = args.text_i18n_scope or "items"
        args.text = i18n(gm, { type = args.text_i18n_type or "menu", key = scope .. "." .. args.text_i18n_key })
    end
    args.sampling_seed            = _resolve_sampling_seed(args)
    args.T,    args.no_register   = _resolve_card_textfx_T(gm, args), Y
    args.lang, args.textfx_alpha  = args.lang or self.config.lang or gm.selected_lang, alpha or args.textfx_alpha or 1
    args.paint_seed_entry         = args.paint_seed_entry or paint_seed_entry
    return CardTextFx(gm, args)
end

---____________________________
--- main: init_card_textfx
---______________________________________
function M.init_card_textfx(self, gm)
    local cfg = self.config.card_textfx;        if not cfg then return end
    self.page_card_textfx = {}

    local items  = _card_textfx_configs(cfg)
    local seeds  = _paint_seed_entries(#items)
    for i, item in ipairs(items) do self.page_card_textfx[#self.page_card_textfx + 1] = _new_card_textfx(self, gm, item, nil, seeds[i]) end
end

---____________________________
--- main: replace_card_textfx
---______________________________________
function M.replace_card_textfx(self, gm, cfg, alpha)
    self.config.card_textfx = cfg
    self.page_card_textfx   = {}

    local items = _card_textfx_configs(cfg)
    local seeds = _paint_seed_entries(#items)

    for i, item in ipairs(items) do self.page_card_textfx[#self.page_card_textfx + 1] = _new_card_textfx(self, gm, item, alpha, seeds[i]) end
    return self.page_card_textfx
end

-----------------------------
--- draw_card_textfx
----------------------------------
--- Helper: enqueue textfx hint reveal
local function _enqueue_textfx_hint_reveal(self, cfg)
    local EM = self.gm.E_MANAGER
    cfg.text_hint_fx_mask = 1
    cfg.text_hint_token = (cfg.text_hint_token or 0) + 1

    local token = cfg.text_hint_token
    local delay = (1 / (cfg.text_hint_speed or 4.8)) or 1

    EM:enqueue_event({ trigger = "ease", ease = cfg.text_hint_ease or "lerp", blockable = N,
        ref_table = cfg, ref_value = "text_hint_fx_mask", ease_to = 0, delay = delay,
        func = function(v) return cfg.text_hint_token == token and v or (cfg.text_hint_fx_mask or 1) end,
    })
end

--- Helper: _clear_textfx_hover
local function _clear_textfx_hover(cfg)
    if cfg.text_hint_hover then cfg.text_hint_token = (cfg.text_hint_token or 0) + 1 end
    cfg.text_hint_hover,   cfg.opt_tab_hovered, cfg.tab_hover_started_at = N, N, nil
    cfg.text_hint_fx_mask, cfg.hover_dwell_start                         = 0, nil
end

--- Helper: _set_textfx_hover
local function _set_textfx_hover(self, cfg)
    cfg.opt_tab_hovered      = Y
    cfg.tab_hover_started_at = cfg.tab_hover_started_at or self._T.real_s

    if cfg.options_tab_visual_state == "selected"     then cfg.textfx_hover_event = Y end
    if cfg.textfx_hover_event == N                    then return end
    if cfg.text_hint ~= N and not cfg.text_hint_hover then cfg.text_hint_hover = Y; _enqueue_textfx_hint_reveal(self, cfg) end
    if cfg.text_hint == N                             then cfg.text_hint_hover = Y end
end

--- Helper: _apply_tab_hover_state
local function _apply_tab_hover_state(cfg, hovering)
    if not cfg or cfg.options_tab_visual_state ~= "idle" then return end
    if cfg.options_tab_switch_fade                       then return end

    local state = hovering and "hover" or "idle";        if cfg.options_tab_color_state == state then return end

    cfg.options_tab_color_state  = state
    cfg.card_text_color          = hovering and (cfg.options_tab_text_color or cfg.card_text_color) or (cfg.options_tab_idle_text_color or cfg.card_text_color)
    cfg.card_textfx_cache        = nil
    if type(cfg.text_bg) == "table" then
        cfg.text_bg.color = hovering and (cfg.options_tab_bleed_color or cfg.text_bg.color) or (cfg.options_tab_idle_bleed_color or cfg.text_bg.color)
        cfg.text_bg.paint_alpha = nil
    end
end

--- Helper: _hover_dwell
local function _hover_dwell(self, cfg)
    local dwell        = cfg.hover_dwell_desc or self.config.hover_dwell_desc or 0.4
    local speed        = math.floor((tonumber(self.gm.SET.text_speed) or 3) + 0.5)
    local speed_dwell  = cfg.hover_dwell_by_text_speed
    if speed_dwell then return speed_dwell[speed] or speed_dwell.default or dwell end
    return dwell - 0.1*(speed - 3)
end

--- Helper: textfx hint mask when hovered
local function _textfx_hint_fx_mask(self, fx)
    if not fx then return end
    local cfg  = fx.config or {}
    local st   = fx.states
    local cT   = self.Ctrl.p_cursor.T
    if self.config.description_hover_lock == Y      then return _clear_textfx_hover(cfg) end
    if not (st and st.hover and st.hover.can) then return _clear_textfx_hover(cfg) end
    if cfg.textfx_reveal_lock == Y            then return _clear_textfx_hover(cfg) end
    if fx.disable_button                      then return _clear_textfx_hover(cfg) end
    if not cT                                 then return _clear_textfx_hover(cfg) end
    if not fx:hit_test(cT)                    then return _clear_textfx_hover(cfg) end

    local now = self.gm._T.real_s
    cfg.hover_dwell_start = cfg.hover_dwell_start or now
    _set_textfx_hover(self, cfg)

    local dwell = _hover_dwell(self, cfg)
    if now - cfg.hover_dwell_start >= dwell then
        TextDescription.set_hover_description(self, fx)
        return cfg.text_hint_fx_mask or 0, Y
    end

    TextDescription.clear_hover_description(self)
    return cfg.text_hint_fx_mask or 0, N
end

---____________________________
--- main: draw_card_textfx
---______________________________________
function M.draw_card_textfx(self, opts)
    opts = opts or {}
    local list = self.page_card_textfx;         if not list then return end
    local desc_hovered = N

    for _, fx in ipairs(list) do
        local fx_mask, desc_active
        if not opts.shadow_only then fx_mask, desc_active = _textfx_hint_fx_mask(self, fx) end
        _apply_tab_hover_state(fx.config, fx.config and fx.config.opt_tab_hovered)
        if desc_active then desc_hovered = Y end
        fx:draw({ text_hint_fx_mask = fx_mask, shadow_only = opts.shadow_only, skip_shadow = opts.skip_shadow })
    end
    if not opts.shadow_only and not desc_hovered then TextDescription.clear_hover_description(self) end
end

return M
