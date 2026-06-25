local LF = love.filesystem

local M = {}
----------------------------------------------------------------------------
-- fetch snd src: create all sounds from resources and play one each to load into mem
-----------------------------------------------------------------------------
function M.fetch_snd_src()
    local src, dirs = {}, { "resources/sounds" }

    for _, dir in ipairs(dirs) do 
        local sound_files = LF.getDirectoryItems(dir)
        for _, filename in ipairs(sound_files) do
            local extension = string.sub(filename, -4);      if extension ~= ".ogg" then goto continue end 
            local sound_code = string.sub(filename, 1, -5)
            src[sound_code] = {}
            ::continue::
        end
    end
    return src
end

return M