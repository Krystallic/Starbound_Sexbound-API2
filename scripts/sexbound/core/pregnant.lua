--- Sexbound.Core.Pregnant Class Module.
-- @classmod Sexbound.Core.Pregnant
Sexbound.Core.Pregnant = {}
Sexbound.Core.Pregnant.__index = Sexbound.Core.Pregnant

function Sexbound.Core.Pregnant.new(...)
  local self = setmetatable({}, Sexbound.Core.Pregnant)
  self:init(...)
  return self
end

--- Initialize this instance.
-- @param parent
function Sexbound.Core.Pregnant:init(parent)
  self.parent = parent
end

--- Update this instance.
-- @param dt
function Sexbound.Core.Pregnant:update(dt)

end