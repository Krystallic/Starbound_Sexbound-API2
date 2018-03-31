--- Sexbound.API.StateMachine Module.
-- @module Sexbound.API.StateMachine
-- @author Loxodon
-- @license GNU General Public License v3.0

Sexbound.API.StateMachine = {}

--- Returns the status the specified State Machine state for this instance.
-- @param name A string that represents a state name.
-- @usage local isIdling = Sexbound.API.StateMachine.getStatus("idle")
Sexbound.API.StateMachine.getStatus = function(name)
  if self._sexbound then
    if name then return self._sexbound:getStateMachine():getStatus(name) end
    
    return self._sexbound:getStateMachine():getStatus()
  end
end