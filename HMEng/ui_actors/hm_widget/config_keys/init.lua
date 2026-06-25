local M = {}

local groups = {
    require("HMEng.ui_actors.hm_widget.config_keys.base"),
    require("HMEng.ui_actors.hm_widget.config_keys.button"),
    require("HMEng.ui_actors.hm_widget.config_keys.tooltip"),
    require("HMEng.ui_actors.hm_widget.config_keys.text"),
}

for _, group in ipairs(groups) do
    for _, key in ipairs(group) do M[#M + 1] = key end
end

return M
