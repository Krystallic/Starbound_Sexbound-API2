--- Sexbound.API Module.
-- @module Sexbound.API
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound.lua"

Sexbound.API = {}

require "/scripts/sexbound/v2/api/actors.lua"
require "/scripts/sexbound/v2/api/nodes.lua"
require "/scripts/sexbound/v2/api/statemachine.lua"

Sexbound.API.init = function()
  self._sexbound = Sexbound.new()
end

Sexbound.API.getConfig = function()
  if self._sexbound then
    return self._sexbound:getConfig()
  end
end

Sexbound.API.getStateMachine = function()
  if self._sexbound then
    return self._sexbound:getStateMachine()
  end
end

Sexbound.API.handleDie = function()
  if self._sexbound then
    self._sexbound:respawnStoredActor()
  end
end

Sexbound.API.handleInteract = function(args)
  if self._sexbound then
    return self._sexbound:handleInteract(args)
  end
end

Sexbound.API.update = function(dt, callback)
  if self._sexbound then
    self._sexbound:update(dt, callback)
  end
end

Sexbound.API.uninit = function()
  if self._sexbound then
    self._sexbound:uninit()
  end
end