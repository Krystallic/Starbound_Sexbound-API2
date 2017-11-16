--- Sexbound.API.UI Submodule.
-- @submodule Sexbound.API
Sexbound = Sexbound or {API = {}}
Sexbound.API.UI = {}

--- Pops up the Sexbound UI.
-- @param controllerId
function Sexbound.API.UI.showUI(controllerId)
  local config = root.assetJson( "/interface/sexbound/default.config" )
  
  config.config.controllerId = controllerId 
  
  player.interact("ScriptPane", config)
end
