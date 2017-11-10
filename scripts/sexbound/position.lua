--- Position Module.
-- @module Position
Sexbound.Position = {}

Sexbound.Position.__index = Sexbound.Position

function Sexbound.Position.new(...)
  local self = setmetatable({}, Sexbound.Position)
  self:init(...)
  return self
end

--- Initializes this module.
function Sexbound.Position:init(position)
  self.position = position
end

--- Returns data for the current position.
function Sexbound.Position:getData()
  return self.position
end
