--- Sexbound.API.Actors Submodule.
-- @submodule Sexbound.API
Sexbound.API.Actors = {}

--- Stores the specified actor.
-- @param actor
-- @param storeActor
function Sexbound.API.Actors.addActor(actor, storeActor)
  self.log:info("Storing new actor.")
  
  table.insert(self.sexboundData.actors, Sexbound.Core.Actor.new( actor, storeActor ))

  self.sexboundData.actorCount = self.sexboundData.actorCount + 1
  
  if self.sexboundData.actorCount > 1 then self.sexboundData.status.havingSex = true end
  
  -- Automatically shift actor roles based on gender
  if self.sexboundData.actorCount == 2 then
    if self.sexboundData.actors[1]:gender() == "female" and self.sexboundData.actors[2]:gender() == "male" then
      Sexbound.API.Actors.switchRole()
    end
  end
  
  Sexbound.API.Actors.resetAll()
end

--- Returns a reference to all actors.
function Sexbound.API.Actors.getActors()
  return self.sexboundData.actors
end

--- Returns the count of actors.
function Sexbound.API.Actors.getCount()
  return self.sexboundData.actorCount
end

--- Removes the specified actor.
-- @param actorId
function Sexbound.API.Actors.removeActor(actorId)
  self.log:info("Removing actor.")

  Sexbound.API.Actors.resetAllGlobalAnimatorTags()
  
  for i,actor in ipairs(self.sexboundData.actors) do
    if actor:id() == actorId then
      actor:uninit()
      
      table.remove(self.sexboundData.actors, i)
      
      self.sexboundData.actorCount = self.sexboundData.actorCount - 1
    end
  end
  
  Sexbound.API.Actors.resetAll()
  
  if self.sexboundData.actorCount <= 1 then self.sexboundData.status.havingSex = false end
end

--- Resets all actors.
function Sexbound.API.Actors.resetAll()
  for i,actor in ipairs(self.sexboundData.actors) do
    actor:reset(i, Sexbound.API.Positions.currentPosition():getData())
  end
end

--- Resets all global animator tags for all actors.
function Sexbound.API.Actors.resetAllGlobalAnimatorTags()
  for i,actor in ipairs(self.sexboundData.actors) do
    actor:resetGlobalAnimatorTags(i)
  end
end

--- Shifts the actors in actor data list to the right.
function Sexbound.API.Actors.switchRole()
  if Sexbound.API.Status.isHavingSex() and not Sexbound.API.Status.isClimaxing() and not Sexbound.API.Status.isReseting() then
    table.insert(self.sexboundData.actors, 1, table.remove(self.sexboundData.actors, #self.sexboundData.actors))
    
    Sexbound.API.Actors.resetAll()
  end
end
