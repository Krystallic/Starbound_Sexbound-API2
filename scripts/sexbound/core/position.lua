--- Sexbound.Core.Position Class Module.
-- @classmod Sexbound.Core.Position
Sexbound.Core.Position = {}

Sexbound.Core.Position.__index = Sexbound.Core.Position

function Sexbound.Core.Position.new(...)
  local self = setmetatable({}, Sexbound.Core.Position)
  self:init(...)
  return self
end

--- Initializes this module.
function Sexbound.Core.Position:init(position)
  self.position = position
  
  self.data = {}
  self.data.maxTempo = util.randomInRange(position.maxTempo)
  self.data.minTempo = util.randomInRange(position.minTempo)
  self.data.sustainedInterval = util.randomInRange(position.sustainedInterval)
end

--- Returns data for the current position.
function Sexbound.Core.Position:getData()
  return self.position
end

-- Returns the maxTempo.
function Sexbound.Core.Position:maxTempo()
  return self.data.maxTempo
end

-- Returns the next maxTempo.
function Sexbound.Core.Position:nextMaxTempo()
  self.data.maxTempo = util.randomInRange(self.position.maxTempo)
  return self:maxTempo()
end

-- Returns the minTempo.
function Sexbound.Core.Position:minTempo()
  return self.data.minTempo
end

-- Returns the next minTempo.
function Sexbound.Core.Position:nextMinTempo()
  self.data.minTempo = util.randomInRange(self.position.minTempo)
  return self:minTempo()
end

-- Returns the sustainedInterval.
function Sexbound.Core.Position:sustainedInterval()
  return self.data.sustainedInterval
end

-- Returns the nextSustainedInterval
function Sexbound.Core.Position:nextSustainedInterval()
  self.data.sustainedInterval = util.randomInRange(self.position.sustainedInterval)
  return self:sustainedInterval()
end