function createClass (className, classDefinition)
  -- Handles metatable creation (if needed)
  local metatable = classDefinition.prototype or {}
  metatable.__index = metatable

  -- Magic methods
  metatable.getClassName = (function (self)
    return self.__className
  end)

  -- The Class obj
  local class = {}

  -- Gets class constructor and a super constructor
  local construct = metatable.new or (function () end)
  class.new = (function (...)
    -- Creates instance
    local _ = {}
    setmetatable(_, metatable)

    -- Sets class name
    _.__className = className

    -- Calls constructor
    construct(_, table.unpack({...}))

    -- Returns instance
    return _
  end)

  -- Returns Class object
  return class
end

return createClass