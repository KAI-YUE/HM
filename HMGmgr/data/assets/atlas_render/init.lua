local install_list = { "shader_loader", "shared_atlas", "window", "item_prototypes" }

return function(GMgr)
    for _, pkg in ipairs(install_list) do require("HMGmgr.data.assets.atlas_render." .. pkg)(GMgr) end
end
