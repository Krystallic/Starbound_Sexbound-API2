--- Sexbound.Core.Climax Class Module.
-- @classmod Sexbound.Core.Climax
Sexbound.Core.Climax = {}
Sexbound.Core.Climax.__index = Sexbound.Core.Climax

--- Instantiates a new instance of Climax.
-- @param parent
function Sexbound.Core.Climax.new(parent)
  local self = setmetatable({}, Sexbound.Core.Climax)
  
  self.parent = parent
  
  self.climax = {
    config = util.mergeTable({}, Sexbound.API.getParameter("climax")),
    isClimaxing = false
  }
  
  self.climax.cooldown = self:refreshCooldown()
  
  self.timer = {
    shoot = self.climax.cooldown
  }

  return self
end

--- Updates this instance.
-- @param dt
function Sexbound.Core.Climax:update(dt)
  if Sexbound.API.Status.isHavingSex() then
    if not self.climax.isClimaxing and not Sexbound.API.Status.isReseting() then
      local multiplier = Sexbound.API.Positions.currentPosition():getData().climaxMultiplier[self.parent:actorNumber()] or 1
    
      local increase = util.randomInRange(self.climax.config.defaultIncrease)
    
      self.climax.config.currentPoints = util.clamp(self.climax.config.currentPoints + increase * multiplier * dt, self.climax.config.minPoints, self.climax.config.maxPoints)
    end
    
    if self.climax.isClimaxing and not Sexbound.API.Status.isHavingSex() then
      Sexbound.API.Status.setStatus("climaxing" , false)
      
      self.climax.config.currentPoints = 0
    end
    
    if self.climax.isClimaxing then
      self.timer.shoot = self.timer.shoot + dt
    
      if self.timer.shoot >= self.climax.cooldown then
        -- Play "cum sound" by default
        animator.playSound("climax")
      
        -- Burst cum particles
        animator.burstParticleEmitter( self.particleEffect )
        
        -- Reset shoot timer
        self.timer.shoot = 0
        
        -- Refresh next shoot timeout
        self:refreshCooldown()
      end
    
      local decrease = self.climax.config.defaultDecrease
  
      self.climax.config.currentPoints = util.clamp(self.climax.config.currentPoints - decrease * dt, self.climax.config.minPoints, self.climax.config.maxPoints)
      
      if self.climax.config.currentPoints == 0 then
        self.climax.isClimaxing = false
      
        Sexbound.API.Status.setStatus("climaxing" , false)
      end
    end
  end
end

--- Returns a reference to this instance's config.
function Sexbound.Core.Climax:config()
  return self.climax.config
end

--- Returns the climaxing status for this instance.
function Sexbound.Core.Climax:isClimaxing()
  return self.climax.isClimaxing
end

--- Returns the max possible climax points.
function Sexbound.Core.Climax:maxPoints()
  return self.climax.config.maxPoints
end

--- Return the current climax points.
function Sexbound.Core.Climax:currentPoints()
  return self.climax.config.currentPoints
end

--- Causes the actor to begin climaxing.
function Sexbound.Core.Climax:beginClimax()
  self.climax.isClimaxing = true
  
  self.climax.cooldown = self:refreshCooldown()
  
  self.particleEffect = Sexbound.API.Positions.currentPosition():getData().climaxParticles[ self.parent:actorNumber() ][ self.parent:gender() ]
  
  for _,actor in ipairs(Sexbound.API.Actors.getActors()) do
    actor:getPregnant():tryBecomePregnant()
  end
  
  Sexbound.API.Status.setStatus("climaxing" , true)
end

-- Refreshes the cooldown time for this module.
function Sexbound.Core.Climax:refreshCooldown()
  self.climax.cooldown = util.randomInRange(self:config().cooldown)
  
  return self.climax.cooldown
end
