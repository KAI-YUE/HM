local M = {}

---------------------------------------------
--- Init screen pos
--------------------------------------------
function M.init_screen_pos(gm)
    local STG, STGS  = gm.g_stage,      gm.stages
    local W,   H     = gm.rcfg.tile_w,  gm.rcfg.tile_h

	if STG == STGS.run_game or STG == STGS.run_tut then
        local hand, play, deck, discard = gm.hand, gm.play, gm.deck, gm.discard
        local hT, pT, dT, disT  = hand.T, play.T, deck.T, discard.T
		
        hT.x, hT.y       = W - hT.w + 0,    H - 0.48*pT.h
		pT.x, pT.y       = W - pT.w - 3,    H - pT.h
		dT.x, dT.y, dT.r = W - dT.w - 0.5,  H - 0.8*dT.h, -0.2
        disT.x, disT.y   = W - dT.w - 0.5,  H - 2*dT.h - 0.1
      
        play:hard_set_VT()       
		deck:hard_set_VT();         discard:hard_set_VT()
        return
	elseif STG == STGS.title_page then
	end
end

return M
