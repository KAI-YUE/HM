local HookRunner      = require("HMEng.ui_actors.common.hooks")
local TextDescription = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")

local min, max = math.min, math.max

local Y, N = true, false

return function (AnimDecorator)
-----------------------------
--- set anim param
----------------------------------
local function _clamp(v, lo, hi) return max(lo, min(hi, v or 0)) end
function AnimDecorator:set_anim_param(id, value, lo, hi)
    local model = self.model;       if not (model and model.setParamValuePost and id) then return end
    local v     = value;            if lo or hi then v = _clamp(v, lo or 0, hi or 1) end
    model:setParamValuePost(id, v)
    return v
end

---____________________________
--- main: set_anim_params
---______________________________________
function AnimDecorator:set_anim_params(values)
    if not values then return end
    for id, value in pairs(values) do self:set_anim_param(id, value) end
    return values
end

---____________________________
--- main: set_anim_motion
---______________________________________
function AnimDecorator:set_anim_motion(motion_name, motion_group)
    if not self.model or not motion_name then return end
    self.model:setMotion(motion_name, motion_group or self.motion_group)
    return Y
end

-----------------------------
--- set param | set motion | set motion by idx
----------------------------------
function AnimDecorator:set_param(id, value, lo, hi)           return self:set_anim_param(id, value, lo, hi) end
function AnimDecorator:set_motion(motion_name, motion_group)  return self:set_anim_motion(motion_name, motion_group) end
function AnimDecorator:set_motion_by_idx(idx, motion_group)   return self:set_anim_motion_by_idx(idx, motion_group) end

---____________________________
--- main: set_anim_motion_by_idx
---______________________________________
function AnimDecorator:set_anim_motion_by_idx(idx, motion_group)
    local motion_name = self.model_motion and self.model_motion[idx]
    if not motion_name then return end
    return self:set_anim_motion(motion_name, motion_group)
end

-----------------------------
--- hover
----------------------------------
--- Helper: _hover_jitter
local function _hover_jitter(self)
    local cfg = self.config or {}
    local jitter = cfg.hover_jitter;      if not jitter then return end
    if jitter == Y then return self:jitter_me(0.16, 0.08) end
    self:jitter_me(jitter.amount or 0.16, jitter.rot or jitter.r or 0.08)
end

--- Helper: _run_config_hook
local function _run_config_hook(self, hook)
    local gm = self.gm
    if type(hook) == "function" then return hook(gm, self) end
    if type(hook) == "string" and gm.Fs[hook] then return gm.Fs[hook](gm, self) end
end

--- Helper: _description_widget
local function _description_widget(self)
    local UI     = self.gm and self.gm.UI
    local OM     = UI and (UI.overlay_menu or (UI.title_page_options and UI.title_page_panel))
    local widget = OM and OM.widget
    if widget and widget.config and widget.config.renderer == "stroked_page" then return widget end
end

--- Helper: _set_hover_description
local function _set_hover_description(self)
    local cfg = self.config;                                if not (cfg and (cfg.description_key or cfg.key)) then return end
    local widget = _description_widget(self);               if not widget then return end
    TextDescription.set_hover_description(widget, self)
end

---____________________________
--- main: hover
---______________________________________
function AnimDecorator:hover()
    _hover_jitter(self)
    local cfg = self.config
    _set_hover_description(self)
    if cfg and cfg.hover_hook_fn then return _run_config_hook(self, cfg.hover_hook_fn) end
end

-----------------------------
--- stop hover
----------------------------------
--- Helper: _clear_hover_description
local function _clear_hover_description(self)
    local cfg = self.config;                       if not (cfg and (cfg.description_key or cfg.key)) then return end
    local widget = _description_widget(self);      if not widget then return end
    if widget.config and widget.config.description_hover_key == (cfg.description_key or cfg.key) then TextDescription.clear_hover_description(widget) end
end

function AnimDecorator:stop_hover() _clear_hover_description(self) end

---____________________________
--- main: click
---______________________________________
function AnimDecorator:click() local cfg = self.config; if cfg and cfg.hook_fn then return HookRunner.run_hook(self, self.gm) end end

end
