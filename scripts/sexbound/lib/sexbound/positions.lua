--- Sexbound.Positions Class Module.
-- @classmod Sexbound.Positions
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Positions = {}
Sexbound.Positions_mt = {__index = Sexbound.Positions}

require "/scripts/sexbound/lib/sexbound/position.lua"

function Sexbound.Positions.new( parent )
  local self = setmetatable({
    _index = 1,
    _maxTempo = 1,
    _minTempo = 1,
    _logPrefix = "POSI",
    _parent = parent,
    _sustainedInterval = 10
  }, Sexbound.Positions_mt)
  
  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
  
  self._config = self:loadConfig( self._parent:getConfig() )
  
  self._positions = {
    idle = self:loadIdlePositions( self._parent:getConfig() ),
    sex  = self:loadSexPositions( self._parent:getConfig() )
  }
  
  self:initMessageHandler()
  
  return self
end

function Sexbound.Positions:initMessageHandler()
  message.setHandler("sexbound-switch-position", function(_,_,args)
    local stateMachine = self:getParent():getStateMachine()
  
    if stateMachine:isHavingSex() and not stateMachine:isClimaxing() and not stateMachine:isReseting() then
      self:switchPosition( args.positionId )
    end
  end)
end

--- Returns a reference to the Positions Configuration.
function Sexbound.Positions:getConfig()
  return self._config
end

function Sexbound.Positions:getLog()
  return self._log
end

function Sexbound.Positions:getLogPrefix()
  return self._logPrefix
end

function Sexbound.Positions:getIndex()
  return self._index
end

--- Returns a reference to the Current Position.
function Sexbound.Positions:getCurrentPosition()
  if self:getParent():getStateMachine():isHavingSex() then
    return self._positions.sex.positions[self._index]
  else
    return self._positions.idle.positions[self._index]
  end
end

function Sexbound.Positions:getParent()
  return self._parent
end

--- Returns a reference to the Positions.
function Sexbound.Positions:getPositions(name)
  if name then return self._positions[name] end
  
  return self._positions
end

function Sexbound.Positions:getMaxTempo()
  return self._maxTempo
end

function Sexbound.Positions:getMinTempo()
  return self._minTempo
end

function Sexbound.Positions:getSustainedInterval()
  return self._sustainedInterval
end

--- Returns loaded positions configuration as a table.
function Sexbound.Positions:loadConfig(sexboundConfig)
  local _configFileName  = sexboundConfig.position.configFile or "/positions/positions.config"

  local _positionsConfig = root.assetJson(_configFileName) or {}
  
  return _positionsConfig
end

--- Returns loaded Idle Positions as a table.
function Sexbound.Positions:loadIdlePositions(sexboundConfig)
  local _idlePositions = {
    count = 0,
    positions = {}
  }

  for _,v in ipairs(sexboundConfig.position.idle or {}) do
    local _configFileName = self._config[v].configFile or "/positions/idle.config"
  
    local _config = root.assetJson(_configFileName)
    
    if type(_config) == "table" then
      table.insert(_idlePositions.positions, Sexbound.Position.new(_config))
      
      _idlePositions.count = _idlePositions.count + 1
    end
  end
  
  return _idlePositions
end

--- Returns loaded Sex Positions as a table.
function Sexbound.Positions:loadSexPositions(sexboundConfig)
  local _sexPositions = {
    count = 0,
    positions = {}
  }

  for _,v in ipairs(sexboundConfig.position.sex or {}) do
    local _configFileName = self._config[v].configFile or "/positions/from_behind.config"
  
    local _config = root.assetJson(_configFileName)
  
    if type(_config) == "table" then
      table.insert(_sexPositions.positions, Sexbound.Position.new(_config))
      
      _sexPositions.count = _sexPositions.count + 1
    end
  end
  
  return _sexPositions
end

-- Updates and returns the next maxTempo.
function Sexbound.Positions:nextMaxTempo()
  self._maxTempo = util.randomInRange(self:getCurrentPosition():getConfig().maxTempo)
  
  return self:getMaxTempo()
end

-- Updates and returns the next minTempo.
function Sexbound.Positions:nextMinTempo()
  self._minTempo = util.randomInRange(self:getCurrentPosition():getConfig().minTempo)
  
  return self:getMinTempo()
end

function Sexbound.Positions:nextSustainedInterval()
  self._sustainedInterval = util.randomInRange(self:getCurrentPosition():getConfig().sustainedInterval)
  
  return self:getSustainedInterval()
end

function Sexbound.Positions:resetIndex()
  self._index = 1
end

function Sexbound.Positions:previousPosition()
  self._index = self._index - 1
  
  self:switchPosition(self._index)
end

function Sexbound.Positions:nextPosition()
  self._index = self._index + 1
  
  self:switchPosition(self._index)
end

function Sexbound.Positions:switchRandomSexPosition()
  local randomIndex = util.randomIntInRange({1, self._positions.sex.count})
  
  self:switchPosition(randomIndex)
end

--- Switches to the specified position.
-- @param index
function Sexbound.Positions:switchPosition(index)
  self._index = util.wrap(index, 1, self._positions.sex.count)
  
  self:getLog():info("Switch Position: " .. self:getCurrentPosition():getConfig().name)
  
  self:nextMinTempo()
  
  self:nextMaxTempo()
  
  self:nextSustainedInterval()
  
  -- Set new animation state to match the position.
  animator.setAnimationState("props", self._positions.sex.positions[self._index]:getConfig().animationState)
  animator.setAnimationState("actors", self._positions.sex.positions[self._index]:getConfig().animationState)
  
  -- Send undelayed broadcast
  Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:Positions:SwitchPosition", self:getCurrentPosition(), false)
end