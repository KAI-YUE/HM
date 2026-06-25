local apply_sections = {
    require("HMGmgr.data.global.settings.base"),
    require("HMGmgr.data.global.settings.render"),
    require("HMGmgr.data.global.settings.field"),
    require("HMGmgr.data.global.settings.map"),
}

return function (GMgr)
-----------------------------
--- settings and configs
----------------------------------
--- Helper: init_setting_and_cfg
function GMgr:init_setting_and_cfg()
    for _, apply_section in ipairs(apply_sections) do apply_section(self) end
end

end
