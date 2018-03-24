--- Sexbound.Actor.Climax Class Module.
-- @classmod Sexbound.Actor.Climax
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound/actor/plugin.lua"

Sexbound.Actor.Climax = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Climax_mt = { __index = Sexbound.Actor.Climax }

--- Instantiates a new instance of Climax.
-- @param parent
-- @param config
function Sexbound.Actor.Climax:new( parent, config )
  local self = setmetatable({
    _logPrefix    = "CLIM",
    _config       = config,
    _isClimaxing  = false,
    _soundEffects = {}
  }, Sexbound.Actor.Climax_mt)
  
  self:init(parent, self._logPrefix, function()
    self._cooldown = self:refreshCooldown()
    
    self._timer = {
      shoot = self._cooldown
    }
    
    -- Initialize climax sound effect.
    if (animator.hasSound("climax")) then
      self._soundEffects.climax = self._config.sounds
      
      animator.setSoundPool("climax", self._soundEffects.climax)
    end
  end)

  return self
end

function Sexbound.Actor.Climax:onMessage(message)
  if message:getType() == "Sexbound:Climax:BeginClimax" then
    if self:getRoot():getStateMachine():isHavingSex() then
      self:beginClimax()
    end
  end
end

function Sexbound.Actor.Climax:onEnterClimaxState()
  self._timer.shoot = 0
end

function Sexbound.Actor.Climax:onExitClimaxState()
  self:endClimax()
end

function Sexbound.Actor.Climax:onUpdateClimaxState(dt)
  if not self._isClimaxing then return end

  self._timer.shoot = self._timer.shoot + dt

  if self._timer.shoot >= self._cooldown then
    -- Play "cum sound" by default
    animator.playSound("climax")
  
    -- Burst cum particles
    animator.burstParticleEmitter( self._particleEffect )
    
    -- Reset shoot timer
    self._timer.shoot = 0
    
    -- Refresh next shoot timeout
    self:refreshCooldown()
  end

  local decrease = self:getConfig().defaultDecrease

  self._config.currentPoints = util.clamp(self:getConfig().currentPoints - decrease * dt, self:getConfig().minPoints, self:getConfig().maxPoints)
  
  if self:getConfig().currentPoints == 0 then
    self:endClimax()
  end
end

function Sexbound.Actor.Climax:onUpdateSexState(dt)
  local positionConfig = self:getRoot():getPositions():getCurrentPosition():getConfig()

  local multiplier = positionConfig.climaxMultiplier[self:getParent():getActorNumber()] or 1

  local increase = util.randomInRange(self:getConfig().defaultIncrease)

  self._config.currentPoints = util.clamp(self:getConfig().currentPoints + increase * multiplier * dt, self:getConfig().minPoints, self:getConfig().maxPoints)
end

--- Return the current climax points.
function Sexbound.Actor.Climax:getCurrentPoints()
  return self._config.currentPoints
end

--- Returns the max possible climax points.
function Sexbound.Actor.Climax:getMaxPoints()
  return self._config.maxPoints
end

function Sexbound.Actor.Climax:getSoundEffects(name)
  if name then return self._soundEffects[name] end
  
  return self._soundEffects
end

--- Begins the climax.
function Sexbound.Actor.Climax:beginClimax()
  if self._isClimaxing then return end
  
  self:getLog():info("Actor is beginning climax: " .. self:getParent():getName())
  
  self:getParent():addStatus("climaxing")
  
  self._isClimaxing = true

  self._cooldown = self:refreshCooldown()
  
  local position = self:getRoot():getPositions():getCurrentPosition()
  local positionConfig = position:getConfig()
  
  self._particleEffect = positionConfig.climaxParticles[ self:getParent():getActorNumber() ][ self:getParent():getGender() ]
  
  self:getRoot():getStateMachine():setStatus("climaxing", true)
  
  Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:Pregnant:BecomePregnant", self:getParent())
end

--- Ends the climax.
function Sexbound.Actor.Climax:endClimax()
  self._isClimaxing = false

  self:getParent():removeStatus("climaxing")
  
  self:getRoot():getStateMachine():setStatus("climaxing", false)
end

-- Refreshes the cooldown time for this module.
function Sexbound.Actor.Climax:refreshCooldown()
  self._cooldown = util.randomInRange(self:getConfig().cooldown)
  
  return self._cooldown
end
