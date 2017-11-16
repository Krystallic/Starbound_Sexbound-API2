--- Sexbound.API.Positions Submodule.
-- @submodule Sexbound.API

Sexbound.API.Positions = {}

--- Initializes the defined positions.
function Sexbound.API.Positions.initPositions()
  self.sexboundData.positions = {}
  
  -- Initialize idle positions.
  self.sexboundData.positions.idle = {}
  self.sexboundData.positions.idle.positionCount = 0
  self.sexboundData.positions.idle.positionIndex = 1
  
  for _,v in ipairs(Sexbound.API.getParameter("position.idle")) do
    table.insert(self.sexboundData.positions.idle, Sexbound.Core.Position.new(v))
    
    self.sexboundData.positions.idle.positionCount = self.sexboundData.positions.idle.positionCount + 1
  end
  
  -- Initialize sex positions.
  self.sexboundData.positions.sex = {}
  self.sexboundData.positions.sex.positionCount = 0
  self.sexboundData.positions.sex.positionIndex = 1
  
  for _,v in ipairs(Sexbound.API.getParameter("position.sex")) do
    table.insert(self.sexboundData.positions.sex, Sexbound.Core.Position.new(v))
    
    self.sexboundData.positions.sex.positionCount = self.sexboundData.positions.sex.positionCount + 1
  end
end

--- Returns a reference to the current position.
function Sexbound.API.Positions.currentPosition()
  if Sexbound.API.Status.isHavingSex() then
    return self.sexboundData.positions.sex[self.sexboundData.positions.sex.positionIndex]
  else
    return self.sexboundData.positions.idle[self.sexboundData.positions.idle.positionIndex]
  end
end

--- Changes to the next position and returns it.
function Sexbound.API.Positions.nextPosition()
  if Sexbound.API.Status.isHavingSex() then
    self.sexboundData.positions.sex.positionIndex = self.sexboundData.positions.sex.positionIndex + 1
    return Sexbound.API.Positions.switchPosition(self.sexboundData.positions.sex.positionIndex)
  else
    self.sexboundData.positions.idle.positionIndex = self.sexboundData.positions.idle.positionIndex + 1
    return Sexbound.API.Positions.switchPosition(self.sexboundData.positions.idle.positionIndex)
  end
end

--- Changes to the previous position and returns it.
function Sexbound.API.Positions.previousPosition()
  if Sexbound.API.Status.isHavingSex() then
    self.sexboundData.positions.sex.positionIndex = self.sexboundData.positions.sex.positionIndex - 1
    return Sexbound.API.Positions.switchPosition(self.sexboundData.positions.sex.positionIndex)
  else
    self.sexboundData.positions.idle.positionIndex = self.sexboundData.positions.idle.positionIndex - 1
    return Sexbound.API.Positions.switchPosition(self.sexboundData.positions.idle.positionIndex)
  end
end

--- Switches to the specified position.
-- @param index
function Sexbound.API.Positions.switchPosition( index )
  if Sexbound.API.Status.isHavingSex() and not Sexbound.API.Status.isClimaxing() and not Sexbound.API.Status.isReseting() then
    self.sexboundData.positions.sex.positionIndex = util.wrap(index, 1, self.sexboundData.positions.sex.positionCount)
    
    -- Set new animation state to match the position.
    animator.setAnimationState("main", self.sexboundData.positions.sex[self.sexboundData.positions.sex.positionIndex]:getData().animationState)
    
    -- Reset all actors.
    Sexbound.API.Actors.resetActors()
    
    return self.sexboundData.positions.sex[self.sexboundData.positions.sex.positionIndex]:getData()
  end
  
  if not Sexbound.API.Status.isHavingSex() and not Sexbound.API.Status.isClimaxing() and not Sexbound.API.Status.isReseting() then
    return self.sexboundData.positions.idle[self.sexboundData.positions.idle.positionIndex]:getData()
  end
end
