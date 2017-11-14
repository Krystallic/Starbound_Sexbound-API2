--- Climax Module.
-- @module Sexbound.Climax
Sexbound.Climax = {}
Sexbound.Climax.__index = Sexbound.Climax

function Sexbound.Climax.new(...)
  local self = setmetatable({}, Sexbound.Climax)
  self:init(...)
  return self
end

--- Initialize this instance.
-- @param parent
function Sexbound.Climax:init(parent)
  self.parent = parent
  
  self.climax = {
    config = util.mergeTable({}, Sexbound.Main.getParameter("climax")),
    isClimaxing = false
  }
  
  self.timer = {
    shoot = 0
  }
  
  self.timeout = {}
  
  self.timeout.shoot = self:refreshTimeout("shoot")
end

function Sexbound.Climax:getMaxPoints()
  return self.climax.config.maxPoints
end

function Sexbound.Climax:getPoints()
  return self.climax.config.currentPoints
end

--- Updates this instance.
-- @param dt
function Sexbound.Climax:update(dt)
  if Sexbound.Main.isHavingSex() then
    if not self.climax.isClimaxing and not Sexbound.Main.isReseting() then
      local multiplier = Sexbound.Main.currentPosition():getData().climaxMultiplier[self.parent:actorNumber()] or 1
    
      local increase = util.randomInRange(self.climax.config.defaultIncrease)
    
      self.climax.config.currentPoints = util.clamp(self.climax.config.currentPoints + increase * multiplier * dt, self.climax.config.minPoints, self.climax.config.maxPoints)
    end
    
    if self.climax.isClimaxing and not Sexbound.Main.isHavingSex() then
      Sexbound.Main.setStatus("climaxing" , false)
      
      self.climax.config.currentPoints = 0
    end
    
    if self.climax.isClimaxing then
      self.timer.shoot = self.timer.shoot + dt
    
      if self.timer.shoot >= self.timeout.shoot then
        -- Play "cum sound" by default
        animator.playSound("climax")
      
        -- Burst cum particles
        animator.burstParticleEmitter( self.particleEffect )
        
        -- Reset shoot timer
        self.timer.shoot = 0
        
        -- Refresh next shoot timeout
        self:refreshTimeout("shoot")
      end
    
      local decrease = self.climax.config.defaultDecrease
  
      self.climax.config.currentPoints = util.clamp(self.climax.config.currentPoints - decrease * dt, self.climax.config.minPoints, self.climax.config.maxPoints)
      
      if self.climax.config.currentPoints == 0 then
        self.climax.isClimaxing = false
      
        Sexbound.Main.setStatus("climaxing" , false)
      end
    end
  end
end

function Sexbound.Climax:beginClimax()
  self.climax.isClimaxing = true
  
  self.timer.shoot = self:refreshTimeout("shoot")
  
  self.particleEffect = Sexbound.Main.currentPosition():getData().climaxParticles[ self.parent:actorNumber() ][ self.parent:gender() ]
  
  Sexbound.Main.setStatus("climaxing" , true)
end

function Sexbound.Climax:defaultTimeout()
  return self.climax.config.defaultTimeout
end

function Sexbound.Climax:refreshTimeout(name)
  self.timeout[name] = util.randomInRange(self:defaultTimeout()[name])
  return self.timeout[name]
end