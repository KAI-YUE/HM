local I18N = require("HMfns.utils.format.i18n_utils")

local i18n = I18N.i18n

local Y, N = true, false

local M = {}

local fade_time         = 0.22
local reveal_check_time = 0.04

---____________________________
--- main: description_text
---______________________________________
function M.description_text(self, fx_cfg)
    local desc_key   = fx_cfg.description_key or fx_cfg.key;  if not desc_key then return "" end

    local cfg        = self.config
    local i18n_type  = fx_cfg.i18n_type  or cfg.i18n_type  or "menu"
    local scope      = fx_cfg.i18n_scope or cfg.i18n_scope or "descriptions"
    local d          = i18n(self.gm, { type = i18n_type, key = scope .. "." .. desc_key })

    if type(d) == "table" then d = d.lines or d.text or d.description or d[1] end
    if type(d) == "table" then return table.concat(d, "\n") end
    return tostring(d or "")
end

-----------------------------
--- set hover description
----------------------------------
--- Helper: _cancel_description_fade
local function _cancel_description_fade(cfg)
    if not cfg then return end
    cfg.description_fade_token,   cfg.description_hover_lock   = (cfg.description_fade_token or 0) + 1, N
    cfg.description_fading,       cfg.description_fade_source  = N, nil
    cfg.hover_description_alpha = 1
end

--- Helper: _restore_description_lang
local function _restore_description_lang(cfg)
    if not (cfg and cfg.description_lang_active) then return end
    if cfg.description_lang_had_prev then cfg.lang = cfg.description_lang_prev else cfg.lang = nil end
    cfg.description_lang_active, cfg.description_lang_had_prev, cfg.description_lang_prev = nil, nil, nil
end

--- Helper: _apply_description_lang
local function _apply_description_lang(cfg, fx_cfg)
    local lang = fx_cfg and fx_cfg.description_lang;       if not lang then return end
    if not cfg.description_lang_active then
        cfg.description_lang_prev, cfg.description_lang_had_prev = cfg.lang, cfg.lang ~= nil
        cfg.description_lang_active = Y
    end
    cfg.lang = lang
end

--- Helper: _reset_text_caches
local function _reset_text_caches(cfg)
    cfg.text_parse_cache_key,  cfg.text_reveal_source      = nil, nil
    cfg.prev_raw_text,         cfg.prev_text_drawable_key  = nil, nil
end

---____________________________
--- main: set_hover_description
---______________________________________
function M.set_hover_description(self, fx, opts)
    local cfg, fx_cfg  = self.config, fx and fx.config or {}
    local desc_key     = fx_cfg.description_key or fx_cfg.key

    _cancel_description_fade(cfg)
    cfg.description_pinned = opts and opts.pinned == Y or N
    if cfg.description_hover_key == desc_key and not (opts and opts.refresh) then cfg.description_hover_source = fx; return end

    if cfg.description_hover_key ~= desc_key then _restore_description_lang(cfg) end
    cfg.description_hover_key,    cfg.description_hover_source = desc_key, fx

    _apply_description_lang(cfg, fx_cfg)
    cfg.hover_description_alpha,  cfg.text  = 1, M.description_text(self, fx_cfg)
    _reset_text_caches(cfg)
end

--- Helper: _tree_contains_node | _source_still_active | source_waits_for_reveal
local function _tree_contains_node(root, node)
    if not (root and node) then return N end
    if root == node then return Y end
    for _, child in ipairs(root.children or {}) do if _tree_contains_node(child, node) then return Y end end
    for _, child in ipairs(root.page_child_widgets or {}) do if _tree_contains_node(child, node) then return Y end end
    for _, child in ipairs(root.page_card_textfx or {}) do if _tree_contains_node(child, node) then return Y end end
    return N
end
local function _source_still_active(source, pinned)
    if pinned then return Y end
    if not (source and not source.REMOVED and source.states) then return N end
    local hover = source.states.hover;                               if hover and hover.is then return Y end
    local Ctrl  = source.Ctrl or (source.gm and source.gm.CTRL)
    local fct   = Ctrl and Ctrl.focused and Ctrl.focused.target
    return _tree_contains_node(fct, source)
end
local function _source_waits_for_reveal(source)  return source and source.config and source.config.finish_reveal_b4_fade; end

--- Helper: _wait_for_reveal_before_clear
local function _wait_for_reveal_before_clear(self, token, force)
    local cfg, gm = self.config, self.gm
    if not (cfg and gm and gm.E_MANAGER) then return N end
    if not (cfg.text_reveal == Y and not cfg.text_reveal_done and _source_waits_for_reveal(cfg.description_hover_source)) then return N end
    cfg.description_hover_lock = Y

    gm.E_MANAGER:enqueue_event({ trigger = "after", delay = reveal_check_time, blockable = N, blocking = N,
        func = function()
            if not (self.config == cfg) or cfg.description_fade_token ~= token then   return Y end
            if cfg.text_reveal_done then M.clear_hover_description(self, nil, force); return Y end
            return _wait_for_reveal_before_clear(self, token, force)
        end })
    return Y
end

-----------------------------
--- clear_hover_description
----------------------------------
--- Helper: _apply_pending_text_config
local function _apply_pending_text_config(cfg)
    local pending = cfg and cfg.description_after_fade_text_config;     if not pending then return end
    for key, value in pairs(pending) do cfg[key] = value end
    cfg.description_after_fade_text_config = nil
end

--- Helper: _finish_description_fade
local function _finish_description_fade(self, token)
    local cfg = self.config;       if not cfg or cfg.description_fade_token ~= token then return Y end

    cfg.description_hover_key,    cfg.description_hover_source = nil, nil
    cfg.description_pinned                                      = nil
    cfg.description_hover_lock,   cfg.description_fading       = N, N
    cfg.description_fade_source,  cfg.hover_description_alpha  = nil, nil
    cfg.text = ""

    _restore_description_lang(cfg)
    _apply_pending_text_config(cfg)
    _reset_text_caches(cfg)
    return Y
end

--- Helper: _clear_description_now
local function _clear_description_now(cfg)
    if not cfg then return Y end
    cfg.description_hover_key,    cfg.description_fade_token   = nil, (cfg.description_fade_token or 0) + 1
    cfg.description_hover_source, cfg.description_hover_lock   = nil, N
    cfg.description_pinned                                     = nil
    cfg.description_fading,       cfg.description_fade_source  = N,   nil
    cfg.hover_description_alpha,  cfg.text                     = nil, ""

    _restore_description_lang(cfg)
    _apply_pending_text_config(cfg)
    _reset_text_caches(cfg)
    return Y
end

---____________________________
--- main: clear_hover_description
---______________________________________
function M.clear_hover_description(self, immediate, force)
    local cfg = self.config
    if not cfg.description_hover_key and (cfg.text or "") == "" then return end
    if immediate then return _clear_description_now(cfg) end
    if not force and _source_still_active(cfg.description_hover_source, cfg.description_pinned) then return end
    if cfg.description_fading then return end

    cfg.description_fade_token = (cfg.description_fade_token or 0) + 1
    local token = cfg.description_fade_token
    if _wait_for_reveal_before_clear(self, token, force) then return end
    cfg.description_hover_lock,   cfg.description_fading       = Y, Y
    cfg.description_fade_source,  cfg.hover_description_alpha  = cfg.description_hover_source, cfg.hover_description_alpha or 1

    local gm = self.gm
    local EM = gm.E_MANAGER

    local delay = cfg.description_fade_time or fade_time
    EM:enqueue_event({ trigger = "ease", ease = cfg.description_fade_ease or "lerp", blockable = N,
        ref_table = cfg, ref_value = "hover_description_alpha", ease_to = 0, delay = delay,
        func = function(v) return cfg.description_fade_token == token and v or (cfg.hover_description_alpha or 1) end,
    })
    EM:enqueue_event({ trigger = "after", blockable = N, blocking = N, delay = delay,
        func = function() return _finish_description_fade(self, token) end,
    })
end

return M
