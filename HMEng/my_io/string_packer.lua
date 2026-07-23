local class = require("core.class")
-- Serialization + compression utilities
---------------------------------------------------------------------
-- STR_PACK: Serialize a Lua table into a string (Lua code)
---------------------------------------------------------------------
function STR_PACK(data, recursive)
    local ret = (recursive and "" or "return ") .. "{"

    for i, v in pairs(data) do
        local key_type, val_type = type(i), type(v);    assert(key_type ~= "table", "Keys cannot be tables")
        if key_type == "string" then i = "[" .. string.format("%q", i) .. "]"
        else i = "[" .. tostring(i) .. "]" end -- Format key

        if val_type == "table" then if v.is and v:is(class) then v = [["MANUAL_REPLACE"]] else v = STR_PACK(v, true) end
        elseif val_type == "string"  then v = string.format("%q", v)
        elseif val_type == "boolean" then v = v and "true" or "false" end
        ret = ret .. i .. "=" .. tostring(v) .. ","
    end
    return ret .. "}"
end

---------------------------------------------------------------------
-- STR_UNPACK Deserialize & evaluate a packed string back into a table
---------------------------------------------------------------------
function STR_UNPACK(str) if not str then return else return assert(loadstring(str))() end end

---------------------------------------------------------------------
-- get_compressed: Read and decompress a file (if needed)
---------------------------------------------------------------------
function get_compressed(path)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    local file_string = love.filesystem.read(path)
    if not file_string or file_string == "" then return end
    if file_string:sub(1, 6) == "return" then return file_string end -- Already Lua code?

    local ok, result = pcall(love.data.decompress, "string", "deflate", file_string) -- Try to decompress
    if ok then return result end
end

---------------------------------------------------------------------
-- Compress and save: data to file. If table → serialize first
---------------------------------------------------------------------
function compress_and_save(path, data)
    local save_string = type(data) == "table" and STR_PACK(data) or tostring(data)
    local compressed = love.data.compress("string", "deflate", save_string, 1)
    love.filesystem.write(path, compressed)
end
