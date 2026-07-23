local M = {}

-----------------------------
--- keyboard to controller
----------------------------
M.rows = {
    { key = "w",     button = "dpup",         label = "D-pad up" },
    { key = "s",     button = "dpdown",       label = "D-pad down" },
    { key = "a",     button = "dpleft",       label = "D-pad left" },
    { key = "d",     button = "dpright",      label = "D-pad right" },
    { key = "l",     button = "a",            label = "Cross / A" },
    { key = "k",     button = "b",            label = "Circle / B" },
    { key = "i",     button = "y",            label = "Triangle / Y" },
    { key = "j",     button = "x",            label = "Square / X" },
    { key = "q",     button = "leftshoulder",  label = "Left bumper" },
    { key = "e",     button = "rightshoulder", label = "Right bumper" },
    { key = "1",     button = "triggerleft",   label = "Left trigger" },
    { key = "3",     button = "triggerright",  label = "Right trigger" },
    { key = "8",     button = "camup",         label = "Right stick up" },
    { key = "2",     button = "camdown",       label = "Right stick down" },
    { key = "4",     button = "camleft",       label = "Right stick left" },
    { key = "6",     button = "camright",      label = "Right stick right" },
    { key = "kp8",   button = "camup",         label = "Right stick up" },
    { key = "kp2",   button = "camdown",       label = "Right stick down" },
    { key = "kp4",   button = "camleft",       label = "Right stick left" },
    { key = "kp6",   button = "camright",      label = "Right stick right" },
    { key = "up",    button = "camup",         label = "Right stick up" },
    { key = "down",  button = "camdown",       label = "Right stick down" },
    { key = "left",  button = "camleft",       label = "Right stick left" },
    { key = "right", button = "camright",      label = "Right stick right" },
    { key = "space", button = "start",         label = "Options / done" },
}

-----------------------------
--- map
----------------------------
M.map = {}
for _, row in ipairs(M.rows) do M.map[row.key] = row.button end

return M
