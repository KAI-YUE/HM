local HMPanel = require("HMEng.ui_actors.hm_panel")
local Rewards = require("HMGplay.run_flow.game_run.battle.rewards")
local C       = require("HMfns.animate.color.color_const")

local Y, N = true, false

local M = {}

-----------------------------
--- helpers
----------------------------
--- Helper: remove panels
local function _remove_panels(panels) for _, panel in ipairs(panels or {}) do if panel and not panel.REMOVED then panel:remove() end end end

--- Helper: make panel
local function _panel(gm, battle, args)
    local panel = HMPanel(gm, {
        style      = "paint_rect",
        T          = args.T,
        text       = args.text,
        text_scale = args.text_scale or 0.30,
        text_color = args.text_color or C.UI.TEXT_LIGHT,
        fill_color = args.fill_color or C.BLACK,
        button     = args.button or N,
        can_hover  = args.button or N,
        can_click  = args.button or N,
        hook_fn    = args.hook_fn,
    })
    battle.conclusion_panels[#battle.conclusion_panels + 1] = panel
    return panel
end

--- Helper: reward line
local function _reward_line(reward)
    return tostring(reward.name or reward.id or "Reward") .. "  +" .. tostring(reward.score or 0)
end

--- Helper: all actioned
local function _all_actioned(rewards)
    for _, reward in ipairs(rewards or {}) do if not reward.action then return N end end
    return Y
end

-----------------------------
--- open
----------------------------
--- Helper: action button
local function _action_button(gm, battle, reward, action, label, x, y)
    local panel = _panel(gm, battle, {
        T = { x = x, y = y, w = 1.35, h = 0.42 }, text = label, text_scale = 0.22, fill_color = C.BLUE, button = Y,
        hook_fn = function()
            if Rewards.apply_action(battle, reward, action) then M.refresh(battle) end
            return Y
        end,
    })
    panel.reward_action_reward, panel.reward_action = reward, action
    return panel
end

--- Helper: build reward row
local function _build_reward_row(gm, battle, reward, x, y)
    _panel(gm, battle, { T = { x = x, y = y, w = 3.10, h = 0.42 }, text = _reward_line(reward), text_scale = 0.24, fill_color = { 0.08, 0.07, 0.06, 0.84 } })
    _action_button(gm, battle, reward, "eat",        "Eat",     x + 3.28, y, "eat")
    _action_button(gm, battle, reward, "print_card", "Card",    x + 4.78, y, "print")
    _action_button(gm, battle, reward, "send_gift",  "Gift",    x + 6.28, y, "gift")
    _action_button(gm, battle, reward, "discard",    "Discard", x + 7.78, y, "discard")
end

function M.open(battle)
    if not (battle and battle.active) or battle.conclusion_open then return end
    battle.conclusion_open, battle.busy, battle.turn = Y, N, "conclusion"
    battle.conclusion_panels = {}

    local gm = battle.gm
    local RT = gm._room and gm._room.T or { w = 24, h = 13.5 }
    local rewards = battle.claimed and battle.claimed.player or {}
    local h = math.max(2.25, 1.55 + #rewards*0.58)
    local x, y = 0.5*(RT.w - 10.85), 0.5*(RT.h - h)
    _panel(gm, battle, { T = { x = x, y = y, w = 10.85, h = h }, text = "Conclusion", text_scale = 0.34, fill_color = { 0.02, 0.02, 0.02, 0.88 } })
    if #rewards == 0 then _panel(gm, battle, { T = { x = x + 0.55, y = y + 0.72, w = 5.2, h = 0.48 }, text = "No player rewards claimed.", text_scale = 0.25, fill_color = { 0.08, 0.07, 0.06, 0.84 } }) end
    for idx, reward in ipairs(rewards) do _build_reward_row(gm, battle, reward, x + 0.55, y + 0.58 + idx*0.58) end
    battle.conclusion_done_button = _panel(gm, battle, {
        T = { x = x + 8.58, y = y + h - 0.62, w = 1.70, h = 0.45 }, text = "Done", text_scale = 0.24, fill_color = C.GREEN, button = Y,
        hook_fn = function() if _all_actioned(rewards) and battle.stop_battle then battle.stop_battle() end; return Y end,
    })
    M.refresh(battle)
end

-----------------------------
--- refresh
----------------------------
function M.refresh(battle)
    for _, panel in ipairs(battle.conclusion_panels or {}) do
        if panel.widget and panel.widget.config and panel.widget.config.text ~= "Conclusion" then
            for _, reward in ipairs(battle.claimed.player or {}) do
                if panel.widget.config.text == _reward_line(reward) and reward.action then panel.widget.config.text = _reward_line(reward) .. "  " .. tostring(reward.action) end
            end
            if panel.reward_action_reward then panel.widget.disable_button = panel.reward_action_reward.action ~= nil end
        end
    end
    local btn = battle.conclusion_done_button
    if btn and btn.widget then btn.widget.disable_button = not _all_actioned(battle.claimed and battle.claimed.player or {}) end
end

-----------------------------
--- close
----------------------------
function M.close(battle)
    if not battle then return end
    _remove_panels(battle.conclusion_panels)
    battle.conclusion_panels, battle.conclusion_open, battle.conclusion_done_button = nil, nil, nil
end

return M
