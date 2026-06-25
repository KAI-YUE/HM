local GameObj         = require("HMEng.actors.game_obj")
local HookRunner      = require("HMEng.ui_actors.common.hooks")
local TextDescription = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")

return function(HMWidget)

-----------------------------
--- hover
----------------------------------
--- Helper: _run_hover_hook
local function _run_hover_hook(self)
    local cfg = self.config;            if not (cfg and cfg.hover_hook_fn) then return end

    local old_hook = cfg.hook_fn
    cfg.hook_fn    = cfg.hover_hook_fn
    HookRunner.run_hook(self, self.gm)
    cfg.hook_fn    = old_hook
end

--- Helper: _hover_jitter
local function _hover_jitter(self)
    local cfg    = self.config or {}
    local jitter = cfg.hover_jitter;      if not jitter then return end
    if jitter == true then return self:jitter_me(0.16, 0.08) end
    self:jitter_me(jitter.amount or 0.16, jitter.rot or jitter.r or 0.08)
end

--- Helper: _description_widget
local function _description_widget(self)
    local OM     = self.gm.UI.overlay_menu
    local widget = OM and OM.widget
    if widget and widget.config and widget.config.renderer == "stroked_page" then return widget end
end

--- Helper: _set_hover_description
local function _set_hover_description(self)
    local cfg     = self.config;                       if not (cfg and (cfg.description_key or cfg.key)) then return end
    local widget  = _description_widget(self);      if not widget then return end
    TextDescription.set_hover_description(widget, self)
end

--- Helper: _clear_hover_description
local function _clear_hover_description(self)
    local cfg = self.config
    if not (cfg and (cfg.description_key or cfg.key)) then return end
    local widget = _description_widget(self);      if not widget then return end
    if widget.config and widget.config.description_hover_key == (cfg.description_key or cfg.key) then TextDescription.clear_hover_description(widget) end
end

---____________________________
--- main: hover
---______________________________________
function HMWidget:hover()
    local now   = self._T.real_s
    local safe  = self.config.hover_safe_time or 0.1

    if self.last_hovered and now <= self.last_hovered + safe then return end
    self.last_hovered = now
    _hover_jitter(self)
    _set_hover_description(self)
    _run_hover_hook(self)
    GameObj.hover(self)
end

function HMWidget:stop_hover() _clear_hover_description(self); GameObj.stop_hover(self) end

end
