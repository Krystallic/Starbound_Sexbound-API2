--- Sexbound.Position Class Module.
-- @classmod Sexbound.Position
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Position = {}
Sexbound.Position_mt = {__index = Sexbound.Position}

--- Returns a reference to a new instance of this class.
function Sexbound.Position.new( positionConfig )
  local self = setmetatable({}, Sexbound.Position_mt)
  
  self._config = positionConfig
  
  self._maxTempo = util.randomInRange(self._config.maxTempo)
  self._minTempo = util.randomInRange(self._config.minTempo)
  self._sustainedInterval = util.randomInRange(self._config.sustainedInterval)
  
  return self
end

--- Returns a reference to this instance's running configuration.
function Sexbound.Position:getConfig()
  return self._config
end

--- Returns the friendly name of this instance.
function Sexbound.Position:getFriendlyName()
  return self:getConfig().friendlyName
end

--- Returns the name of this instance.
function Sexbound.Position:getName()
  return self:getConfig().name
end