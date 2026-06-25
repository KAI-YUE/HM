local M = {}

-----------------------------
--- keyboard to controller
----------------------------
M.rows = {
    { key = "w",     button = "dpup",         label = "D-pad up" },
    { key = "s",     button = "dpdown",       label = "D-pad down" },
    { key = "a",     button = "dpleft",       label = "D-pad left" },
    { key = "d",     button = "dpright",      label = "D-pad right" },
    { key = "k",     button = "a",            label = "Cross / cancel" },
    { key = "l",     button = "b",            label = "Circle / confirm" },
    { key = "i",     button = "x",            label = "X" },
    { key = "j",     button = "y",            label = "Y" },
    { key = "q",     button = "leftshoulder",  label = "Left bumper" },
    { key = "e",     button = "rightshoulder", label = "Right bumper" },
    { key = "1",     button = "triggerleft",   label = "Left trigger" },
    { key = "3",     button = "triggerright",  label = "Right trigger" },
    { key = "8",     button = "camup",         label = "Analog wheel up" },
    { key = "2",     button = "camdown",       label = "Analog wheel down" },
    { key = "4",     button = "camleft",       label = "Analog wheel left" },
    { key = "6",     button = "camright",      label = "Analog wheel right" },
    { key = "kp8",   button = "camup",         label = "Analog wheel up" },
    { key = "kp2",   button = "camdown",       label = "Analog wheel down" },
    { key = "kp4",   button = "camleft",       label = "Analog wheel left" },
    { key = "kp6",   button = "camright",      label = "Analog wheel right" },
    { key = "up",    button = "camup",         label = "Analog wheel up" },
    { key = "down",  button = "camdown",       label = "Analog wheel down" },
    { key = "left",  button = "camleft",       label = "Analog wheel left" },
    { key = "right", button = "camright",      label = "Analog wheel right" },
    { key = "space", button = "start",         label = "Options / done" },
}

-----------------------------
--- map
----------------------------
M.map = {}
for _, row in ipairs(M.rows) do M.map[row.key] = row.button end

return M
