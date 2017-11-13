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
    auto = false,
    defaultIncrease = {0, 2.5},
    defaultDecrease = 10,
    currentPoints = 0,
    minPoints = 0,
    maxPoints = 100,
    threshold = 100
  }
  
  self.isClimaxing = false
end

function Sexbound.Climax:getMaxPoints()
  return self.climax.maxPoints
end

function Sexbound.Climax:getPoints()
  return self.climax.currentPoints
end

--- Updates this instance.
-- @param dt
function Sexbound.Climax:update(dt)
  if Sexbound.Main.isHavingSex() then
    if not self.isClimaxing and not Sexbound.Main.isReseting() then
      local multiplier = Sexbound.Main.currentPosition():getData().pleasureMultiplier[self.parent:actorNumber()] or 1
    
      local increase = util.randomInRange(self.climax.defaultIncrease)
    
      self.climax.currentPoints = util.clamp(self.climax.currentPoints + increase * multiplier * dt, self.climax.minPoints, self.climax.maxPoints)
    end
    
    if self.isClimaxing then
      local decrease = self.climax.defaultDecrease
  
      self.climax.currentPoints = util.clamp(self.climax.currentPoints - decrease * dt, self.climax.minPoints, self.climax.maxPoints)
      
      if self.climax.currentPoints == 0 then
        self.isClimaxing = false
      
        Sexbound.Main.setStatus("climaxing" , false)
      end
    end
  end
end

function Sexbound.Climax:beginClimax()
  self.isClimaxing = true
  
  Sexbound.Main.setStatus("climaxing" , true)
end