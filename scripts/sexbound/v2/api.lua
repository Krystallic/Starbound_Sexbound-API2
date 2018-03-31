--- Sexbound.API Module.
-- @module Sexbound.API
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound.lua"

Sexbound.API = {}

require "/scripts/sexbound/v2/api/actors.lua"
require "/scripts/sexbound/v2/api/nodes.lua"
require "/scripts/sexbound/v2/api/statemachine.lua"

--- Initializes a new instance of Sexbound.
-- @usage function init() Sexbound.API.init() end
Sexbound.API.init = function()
  self._sexbound = Sexbound:new()
end

--- Returns the running configuration for the current instance.
-- @usage local currentVersion = Sexbound.API.getConfig().currentVersion
Sexbound.API.getConfig = function()
  if self._sexbound then
    return self._sexbound:getConfig()
  end
end

--- Returns the state machine for the current instance.
-- @usage local stateMachine = Sexbound.API.getStateMachine()
Sexbound.API.getStateMachine = function()
  if self._sexbound then
    return self._sexbound:getStateMachine()
  end
end

--- Handles the specified arguments from an interact request.
-- @param args The arguments table from this object's onInteraction hook.
-- @usage function onInteraction(args) return Sexbound.API.handleInteract(args) end
Sexbound.API.handleInteract = function(args)
  if self._sexbound then
    return self._sexbound:handleInteract(args)
  end
end

--- Commands this object to respawn the stored actor.
-- @usage function die() Sexbound.API.respawnStoredActor() end
Sexbound.API.respawnStoredActor = function()
  if self._sexbound then
    self._sexbound:respawnStoredActor()
  end
end

--- Uninitializes the underlying systems for this instance.
-- @usage function uninit() Sexbound.API.uninit() end
Sexbound.API.uninit = function()
  if self._sexbound then
    self._sexbound:uninit()
  end
end

--- Updates the underlying systems for this instance.
-- @param dt The dt argument from this object's update hook.
-- @usage function update(dt) Sexbound.API.update(dt) end
Sexbound.API.update = function(dt)
  if self._sexbound then
    self._sexbound:update(dt)
  end
end
