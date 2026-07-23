local ops = {
    "dialogue",
    "click",
    "hover",
    "drag",
    "scroll",
    "hit",
}

return function(HMWidget)
    for _, name in ipairs(ops) do require("HMEng.ui_actors.hm_widget.ops." .. name)(HMWidget) end
end
