return function(Actor)
    local install_list = { "hard_set", "clamp", "xy", "scale", "wh", "r", "jitter", "major", "dispatch", "drag" }
    for _, pkg in ipairs(install_list) do require("HMEng.actors.actor.move." .. pkg)(Actor) end
end
