--- Sexbound.Core.Pregnant Class Module.
-- @classmod Sexbound.Core.Pregnant
Sexbound.Core.Pregnant = {}
Sexbound.Core.Pregnant.__index = Sexbound.Core.Pregnant

--- Instantiates a new instance of Pregnant.
-- @param parent
function Sexbound.Core.Pregnant.new(parent)
  local self = setmetatable({}, Sexbound.Core.Pregnant)
  
  self.parent = parent
  
  return self
end

--- Update this instance.
-- @param dt
function Sexbound.Core.Pregnant:update(dt)

end