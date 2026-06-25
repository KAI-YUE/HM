local SND = require("HMfns.utils.sound_utils")
local TabUtils = require("HMfns.utils.table_utils")

local destroy_tree = TabUtils.destroy_tree
local play_clip    = SND.play_clip
local Y, N = true, false

return function (GMgr)
-----------------------------
--- Update game over 
----------------------------------
function GMgr:update_game_over(dt)
    if self.state_comp then return end

    local EM, Fs, SET = self.E_MANAGER, self.Fs, self.SET

    Fs.delete_state_dict(self)
    play_clip(self, "negative", 0.5, 0.7)
    play_clip(self, "whoosh2", 0.9, 0.7)

    SET.pause = Y
    -- Fs.open_menu(self, { definition = create_UIPanel_game_over(), config = { no_esc = true } })
    self._room.jiggle = self._room.jiggle + 3
    self.state_comp = Y
end

-----------------------------
--- Delete run 
----------------------------------
--- Helper: post delete run 
function GMgr:_post_delete_run()
    self.VIEWING_DECK = nil;                   self.E_MANAGER:clear_queue()
    local Ctrl = self.CTRL;                    Ctrl:mod_cursor_context_layer(-1000)
    Ctrl.focus_cursor_stack = {};              Ctrl.focus_cursor_stack_level = 1
    
    self.camera = nil
    if self.GAME then self.GAME.won = N end;   self.g_state = -1
    return Y
end

local TNT = { "buttons", "deck_preview", "shop", "title_page_UI", "title_wallpaper", "title_page_cloud_fx", "splash_f", "bg", "splash_logo", "over_UI", "collection_alert", "HUD", "PROFILE_BUTTON" }

-----------------------------
--- delete_run
----------------------------------
function GMgr:delete_run()
    if not self._room then
        if self.remove_scope then self:remove_scope("run") end
        if self.release_asset_group then self:release_asset_group("title") end
        return self:_post_delete_run()
    end
    if self.stage_objs and self.stage_objs[self.g_stage] then destroy_tree(self.stage_objs[self.g_stage]) end

    for _, k in ipairs(TNT) do if self[k] then if self[k].remove then self[k]:remove() end; self[k] = nil end end
    if self.HUD_tags then for k, v in pairs(self.HUD_tags) do v:remove() end; self.HUD_tags = nil end

    local UI = self.UI

    if UI.overlay_menu then UI.overlay_menu:remove(); UI.overlay_menu = nil end
    
    if self.remove_scope then self:remove_scope("run") end
    if self.release_asset_group then self:release_asset_group("title") end
    return self:_post_delete_run()
end

end
