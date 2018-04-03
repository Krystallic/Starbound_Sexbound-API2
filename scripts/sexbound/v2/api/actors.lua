--- Sexbound.API.Actors Module.
-- @module Sexbound.API.Actors
-- @author Loxodon
-- @license GNU General Public License v3.0

Sexbound.API.Actors = {}

--- Adds a new actor to the current instance.
-- @param actorConfig A table representing the actor.
-- @param store A boolean indicating wether or not to store the actor.
-- @usage Sexbound.API.Actors.addActor(actorConfig, false)
Sexbound.API.Actors.addActor = function( actorConfig, store )
  if self._sexbound then
    self._sexbound:addActor( actorConfig, store )
  end
end

Sexbound.API.Actors.getActors = function()
  if self._sexbound then
    return self._sexbound:getActors()
  end
end

Sexbound.API.Actors.getActorCount = function()
  if self._sexbound then
    return self._sexbound:getActorCount()
  end
end

Sexbound.API.Actors.uninitActors = function()
  if self._sexbound then
    return self._sexbound:uninitActors()
  end
end