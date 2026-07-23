return function (BattlePreviewZone)
--------------------------------------------------
--- draw
--------------------------------------------------
function BattlePreviewZone:draw()
    if not self.states.visible then return end

    self:bound_me()
    for _, card in ipairs(self.cards) do
        if card.states.visible then card:draw() end
    end
end
end
