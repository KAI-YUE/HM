local install_eye_update         = require("HMEng.chara.params_update.eyes")
local install_hair_update        = require("HMEng.chara.params_update.hair")
local install_mouth_update       = require("HMEng.chara.params_update.mouth")
local install_mouth_talk_update  = require("HMEng.chara.params_update.mouth_talk")

return function (Chara)
install_eye_update(Chara)
install_hair_update(Chara)
install_mouth_update(Chara)
install_mouth_talk_update(Chara)

-------------------------------------------------------
--- update
-------------------------------------------------------
function Chara:update(dt)
    if not self.auto_update or not self.model then return end
    local dt = (dt == 0 and 0) or ((self.gm.real_dt) or dt)
    self.model:update(dt)
    
    if self:eyes_closed() then self:close_eyes() else self:update_blink(dt) end
    
    self:update_eye_movement(dt)
    self:update_eyebrow_movement(dt)
    self:update_hair_movement(dt)
    self:update_mouth_audio_input(dt)
    self:update_mouth_movement(dt)
    self:update_expressions()
end

end
