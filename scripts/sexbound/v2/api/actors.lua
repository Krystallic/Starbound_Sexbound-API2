--- Sexbound.API.Actors Module.
-- @module Sexbound.API.Actors
-- @author Loxodon
-- @license GNU General Public License v3.0

Sexbound.API.Actors = {}

Sexbound.API.Actors.addActor = function( actorConfig, store )
  if self._sexbound then
    self._sexbound:addActor( actorConfig, store )
  end
end