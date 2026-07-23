local Actor = require("HMEng.actors.actor")

return function (Chara)
-------------------------------------------------------
--- move
-------------------------------------------------------
function Chara:move(dt) Actor.move(self, dt) end

end
