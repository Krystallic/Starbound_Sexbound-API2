--- Sexbound.Position Module.
-- @module Sexbound.Position
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
  
  self.data = {}
  self.data.maxTempo = util.randomInRange(position.maxTempo)
  self.data.minTempo = util.randomInRange(position.minTempo)
  self.data.sustainedInterval = util.randomInRange(position.sustainedInterval)
end

--- Returns data for the current position.
function Sexbound.Position:getData()
  return self.position
end

-- Returns the maxTempo.
function Sexbound.Position:maxTempo()
  return self.data.maxTempo
end

-- Returns the next maxTempo.
function Sexbound.Position:nextMaxTempo()
  self.data.maxTempo = util.randomInRange(self.position.maxTempo)
  return self:maxTempo()
end

-- Returns the minTempo.
function Sexbound.Position:minTempo()
  return self.data.minTempo
end

-- Returns the next minTempo.
function Sexbound.Position:nextMinTempo()
  self.data.minTempo = util.randomInRange(self.position.minTempo)
  return self:minTempo()
end

-- Returns the sustainedInterval.
function Sexbound.Position:sustainedInterval()
  return self.data.sustainedInterval
end

-- Returns the nextSustainedInterval
function Sexbound.Position:nextSustainedInterval()
  self.data.sustainedInterval = util.randomInRange(self.position.sustainedInterval)
  return self:sustainedInterval()
end