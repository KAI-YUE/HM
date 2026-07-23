local LG, LF = love.graphics, love.filesystem

local tsort = table.sort
local Y = true

return function(GMgr)
-----------------------------
--- init shaders
----------------------------
--- Helper: assemble shader source
local function assemble_shader_source(root_dir, relative_path, active_stack)
    active_stack = active_stack or {}
    if active_stack[relative_path] then error(("Cyclic shader include detected for '%s'"):format(relative_path)) end

    active_stack[relative_path] = Y
    local full_path = root_dir .. relative_path
    local source    = assert(LF.read(full_path), ("Failed to read shader source '%s'"):format(full_path))
    source          = source:gsub('#pragma%s+HM_INCLUDE%s+"([^"]+)"', function(include_path) return assemble_shader_source(root_dir, include_path, active_stack) end)
    active_stack[relative_path] = nil
    return source
end

--- Helper: collect shader dirs
local function collect_shader_dirs(root_dir, relative_dir, out)
    out, relative_dir = out or {}, relative_dir or ""
    local dir, items  = root_dir .. relative_dir, LF.getDirectoryItems(root_dir .. relative_dir)

    tsort(items)
    if relative_dir ~= "" then out[#out+1] = relative_dir end
    for _, item in ipairs(items) do
        local child = relative_dir == "" and item or (relative_dir .. "/" .. item)
        if LF.getInfo(root_dir .. child, "directory") then collect_shader_dirs(root_dir, child, out) end
    end
    return out
end

---____________________
--- main: init shaders
---____________________
function GMgr:init_shaders()
    self.t_shaders = {}
    local _root, shader_dirs = "resources/shaders/", collect_shader_dirs("resources/shaders/")

    for _, _dir in ipairs(shader_dirs) do
        local shader_files = LF.getDirectoryItems(_root .. _dir)
        for _, filename in ipairs(shader_files) do
            local extension = string.sub(filename, -3); if extension ~= ".fs" then goto continue end
            local shader_name   = string.sub(filename, 1, -4)
            local relative_path = _dir .. "/" .. filename
            self.t_shaders[shader_name] = LG.newShader(assemble_shader_source(_root, relative_path))
            ::continue::
        end
    end
end

end
