--- SexboundUI Module.
-- @module SexboundUI

SexboundUI = {}
SexboundUI.__index = SexboundUI

require "/scripts/sexbound/util.lua"

function SexboundUI.new(...)
  local self = setmetatable({}, SexboundUI)
  self:init(...)
  return self
end

function SexboundUI:init()

end

function SexboundUI:showUI(controllerId)
  local config = root.assetJson( "/interface/sexbound/default.config" )
  
  config.config.controllerId = controllerId 
  
  player.interact("ScriptPane", config)
end
