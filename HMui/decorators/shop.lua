--- Shop-related UI callbacks
--- Handles buy/redeem/open interactions, button state, and purchase logic.

local shop = {}

-------------------------------------------------------
-- Button state checks
-------------------------------------------------------
--- Checks if a non-voucher card can be bought.
function shop.can_buy(gm, e)
    local ecfg, game, C  = e.config, gm.GAME, gm.C
    local item           = ecfg.ref_table
    local cost           = item.cost
    local too_expensive  = (cost > game.dollars - game.bankrupt_at)

	if (too_expensive and cost > 0) then
		ecfg.color  = C.UI.BACKGROUND_INACTIVE
		ecfg.button = nil
	else
		ecfg.color  = C.ORANGE
		ecfg.button = "buy_from_shop"
	end

    local parent = e.config.ref_parent
    if not parent or not parent.children.buy_and_use then return end
	
    local offset   = e.UIPanel.alignment.offset
    local visible  = parent.children.buy_and_use.states.visible
    
    -- Adjust UI position if "buy_and_use" button exists
    if visible then offset.y = -0.6
    else            offset.y = 0 end
end

--- Checks if a non-voucher card can be bought & used immediately.
function shop.can_buy_and_use(gm, e)
    local ecfg, game, C  = e.config, gm.GAME, gm.C
    local item           = ecfg.ref_table
    local cost, states   = item.cost, e.UIPanel.states

	local too_expensive = (cost > game.dollars - game.bankrupt_at)
	local cannot_use = not item:can_use_consumable()

	if (too_expensive and cost > 0) or cannot_use then
		states.visible  = false
		ecfg.color      = C.UI.BACKGROUND_INACTIVE
		ecfg.button     = nil
	else
		if item.highlighted then states.visible = true end
		ecfg.color  = C.SECONDARY_SET.Voucher
		ecfg.button = "buy_from_shop"
	end
end

--- Checks if a voucher card can be redeemed.
function shop.can_redeem(gm, e)
    local ecfg, game, C  = e.config, gm.GAME, gm.C
    local item           = ecfg.ref_table
    local cost           = item.cost

    local too_expensive = (cost > game.dollars - game.bankrupt_at) 
	if (too_expensive and cost > 0) then
		ecfg.color  = C.UI.BACKGROUND_INACTIVE
		ecfg.button = nil
	else
		ecfg.color  = C.GREEN
		ecfg.button = "use_card"
	end
end

--- Checks if a booster pack can be opened.
function shop.can_open(gm, e)
    local ecfg, game, C  = e.config, gm.GAME, gm.C
    local item           = ecfg.ref_table
    local cost           = item.cost

    local too_expensive = (cost > game.dollars - game.bankrupt_at)
	if (too_expensive and cost > 0) then
		ecfg.color  = C.UI.BACKGROUND_INACTIVE
		ecfg.button = nil
	else
		ecfg.color  = C.GREEN
		ecfg.button = "use_card"
	end
end

return shop
