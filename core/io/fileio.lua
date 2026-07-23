local class  = require("core.class")
local LF     = love.filesystem

local sgmatch  = string.gmatch
local push     = table.insert

local FileIO = {}

------------------------------------------------------
--- list folders 
------------------------------------------------------
function FileIO.list_folders(directory)
    local pfile         = assert(io.popen(("find '%s' -mindepth 1 -maxdepth 1 -type d -printf '%%f\\0'"):format(directory), "r"))
    local list, folders = pfile:read("*a"), {}      
    
    pfile:close()
    for s in sgmatch(list, "[^%z]+") do if not s:match("%.") then push(folders, s) end end
    
    return folders
end

---------------------------------------------------------------------
-- Pickle_pack
---------------------------------------------------------------------
function FileIO.pickle_pack(data, recursive)
    local ret = (recursive and "" or "return ") .. "{"

    for i, v in pairs(data) do
        local key_type, val_type = type(i), type(v);                            assert(key_type ~= "table", "Keys cannot be tables")
        if key_type == "string" then i = "[" .. string.format("%q", i) .. "]"
        else                         i = "[" .. tostring(i) .. "]" end          -- Format key

        if     val_type == "table"    then if v.is and v:is(class) then v = [["MANUAL_REPLACE"]] else v = FileIO.pickle_pack(v, true) end
        elseif val_type == "string"   then v = string.format("%q", v)
        elseif val_type == "boolean"  then v = v and "true" or "false" end
        ret = ret .. i .. "=" .. tostring(v) .. ","
    end
    return ret .. "}"
end

---------------------------------------------------------------------
-- Pickle_load
---------------------------------------------------------------------
function FileIO.pickle_load(path)
    local info = LF.getInfo(path);                                        if not info then return "" end

    local file_string = LF.read(path)
    if not file_string or file_string == "" then return end
    if file_string:sub(1, 6) == "return"    then return file_string end   -- Already Lua code?

    local ok, result = pcall(love.data.decompress, "string", "deflate", file_string) -- Try to decompress
    if ok then return result end
end

---------------------------------------------------------------------
-- Unpickle
---------------------------------------------------------------------
function FileIO.unpickle(str)
    local chunk         = FileIO.pickle_load(str);  if not chunk or chunk == "" then return end
    local fn, load_err  = loadstring(chunk);        if not fn then return nil, load_err end
    local ok, data      = pcall(fn);                if ok then return data end
    return nil, data
end

---------------------------------------------------------------------
-- Pickle dump
---------------------------------------------------------------------
function FileIO.pickle_dump(path, data)
    local save_string  = type(data) == "table" and FileIO.pickle_pack(data) or tostring(data)
    local compressed   = love.data.compress("string", "deflate", save_string, 1)
    LF.write(path, compressed)
end

return FileIO
