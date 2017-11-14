--- Pregnant Module.
-- @module Sexbound.Pregnant
Sexbound.Pregnant = {}
Sexbound.Pregnant.__index = Sexbound.Pregnant

function Sexbound.Pregnant.new(...)
  local self = setmetatable({}, Sexbound.Pregnant)
  self:init(...)
  return self
end

--- Initialize this instance.
-- @param parent
function Sexbound.Pregnant:init(parent)
  self.parent = parent
end

--- Update this instance.
-- @param dt
function Sexbound.Pregnant:update(dt)

end