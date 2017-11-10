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

function SexboundUI:show()
  local config = root.assetJson( "/interface/sexbound/default.config" )
  
  player.interact("ScriptPane", config, player.id())
end