local T_elems   = { "x", "y", "w", "h", "r", "scale" }
local T_default = { 0, 0, 1, 1, 0, 1 }
local Tst       = { "collide", "focus", "hover", "click", "drag", "release_on" }
local Tmisc     = { "plane" }
local push      = table.insert
local Y, N      = true, false

return function (GameObj)
------------------------------------------------
--- GameObj: init_params
-----------------------------------------------
-- Helper: robusify_tab | orig | initialize trans
local function robusify_tab(T) return T or {} end
local function _orig() return { x = 0, y = 0 } end
local function _init_T(args) local T, aT = {}, args.T; for i, k in ipairs(T_elems) do T[k] = aT[k] or aT[i] or T_default[i] end; return T end


-- Helper: default states
local function default_collide_states() return { can = N, is = N } end
local function default_click_states()   return { can = Y, is = N } end
local function _init_states() local s = { visible = Y }; for i, k in ipairs(Tst) do s[k] = ((i == 1) and default_collide_states()) or default_click_states() end; return s end

--_________________________________________________
-- Main: initialize the params
--_________________________________________________
function GameObj:init_gameobj_attributes(gm, args)
    args, R, self.args   = robusify_tab(args),   gm._room, self.args or {}
    args.T,  self.RETS   = robusify_tab(args.T), {}
    self.T,  self.config = _init_T(args), robusify_tab(self.config)
    self.gm = self.gm or gm
    
    local T = self.T
    self.created_on_pause, self.center     = gm and gm.SET.pause, { x = T.x + T.w/2, y = T.y + T.y/2}
    self.interaction_layer                 = (gm and gm.CTRL and gm.CTRL.cursor_context and gm.CTRL.cursor_context.layer) or 1
    self.click_offset,  self.hover_offset  = _orig(),_orig()                      
    self.ID,  self.FR,  self.states        = gm.ID, { f_dr = -1, f_m = -1 }, _init_states()
    self.container, self.children,  gm.ID  = args.container or R, robusify_tab(self.children), gm.ID + 1

    for i, v in ipairs(Tmisc) do self.v = nil end   -- init misc params 

    local R, stage    = gm.R,   gm.g_stage          -- Register game object
    local ROBJ, POPUP = R.GOBJ, R.POPUP 
    if getmetatable(self) == GameObj then push(ROBJ, self) end                 
    gm:register_scope_obj(self, args.scope)
    if gm.mark_render_buckets_dirty then gm:mark_render_buckets_dirty() end

    self.ROBJ, self.POPUP      = ROBJ, POPUP        -- Store tas/params from gm
    self.Ctrl, self.t_drawable = gm.CTRL, gm.t_drawable
    self.rcfg, self.cbuffer    = gm.rcfg, gm.rcfg.coll_buffer
    self.debug = gm.debug
end

--------------------------------------------------------
--- Remove 
--------------------------------------------------------
--- Helper: cleanup the obj from the given table 
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end

--- Main: remove the object from registries 
function GameObj:remove()
    local targets, ctl = { "clicked", "focused", "dragging", "hovering", "released_on", "scrolled", "cursor_down", "cursor_up", "cursor_hover" }, self.Ctrl
    local registries   = { "ROBJ", "POPUP" }
    for i, reg in ipairs(registries) do cleanup(self[reg], self) end
	
	if self.children then for _, child in pairs(self.children) do child:remove() end end -- Recursively remove children
	for _, key in ipairs(targets) do if ctl[key].target == self then ctl[key].target = nil end end
    if self.gm.unregister_scope_obj then self.gm:unregister_scope_obj(self) end
    if self.gm.mark_render_buckets_dirty then self.gm:mark_render_buckets_dirty() end
	self.REMOVED = Y
end

end
