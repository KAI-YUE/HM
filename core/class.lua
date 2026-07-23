-- core/class.lua
local class = {}

-- class = Object

class.__index = class

-- Object creation and initialization
function class:init() end  -- Default init, override if needed

-- Inheritance: Create a new class that inherits from the base class
function class:extend()
    local newClass = {}
    for k, v in pairs(self) do if k:find("__") == 1 then newClass[k] = v end end
    newClass.__index = newClass
    newClass.super = self
    setmetatable(newClass, self) -- Inherit from the base class
    return newClass
end


-- Class type check: Class:is(BaseClass)
function class:is(T)
    local mt = getmetatable(self)
    while mt do
        if mt == T then return true end
        mt = getmetatable(mt)
    end
    return false
end

-- Constructor: Call to create a new instance of the class
function class:__call(...)
    local obj = setmetatable({}, self)
    obj:init(...)
    return obj
end

return class
