require "/scripts/vec2.lua"

require "/scripts/sexbound/api/util.lua"
require "/scripts/sexbound/api/ui.lua"
require "/scripts/sexbound/override/common.lua"

Sexbound_Player = {}

--- Hook - init
function init()
  Sexbound_Common.init()
  
  Sexbound_Player.initMessageHandlers()
  
  --Sexbound.API.Util.deepdump(_ENV)
end

--- Hook - update
function update(dt)
  Sexbound_Common.update(dt)
  
  Sexbound_Player.updateStatuses()
end

Sexbound_Player.initMessageHandlers = function()
  message.setHandler("sexbound-lounge", function(_, _, args)
    local anchor = 0
    
    -- Lounge the player in the object's first anchor.
    player.lounge(args.loungeId, anchor)
    
    self.sexbound.controllerId = args.controllerId
    
    -- Show the Sexbound UI.
    Sexbound.API.UI.showUI(args.controllerId)
  end)
end

--- Returns a table consisting of identifying information about the player character.
-- @param portraitData
Sexbound_Player.buildIdentityFromPortrait = function(portraitData)
  local identity = {
    bodyDirectives = "",
    emoteDirectives = "",
    facialHairDirectives = "",
    facialHairFolder = "",
    facialHairGroup = "",
    facialHairType = "",
    facialMaskDirectives = "",
    facialMaskFolder = "",
    facialMaskGroup = "",
    facialMaskType = "",
    hairFolder = "hair",
    hairGroup = "hair",
    hairType = "1",
    hairDirectives = ""
  }

  identity.gender = player.gender()
  identity.species = player.species()
  
  local genderId = 1
  
  if gender == "male" then
    genderId = 1
  end
  
  if gender == "female" then
    genderId = 2
  end
  
  local speciesConfig = nil
  
  -- Attempt to read configuration from species config file.
  if not pcall(function()
    speciesConfig = root.assetJson("/species/" .. identity.species .. ".species")
    identity.facialHairGroup = speciesConfig.genders[ genderId ].facialHairGroup or ""
    identity.facialMaskGroup = speciesConfig.genders[ genderId ].facialMaskGroup or ""
  end) then
    sb.logInfo("Could not find species config file.")
  end
  
  util.each(portraitData, function(k, v)
    -- Attempt to find facial mask
    if identity.facialMaskGroup ~= nil and identity.facialMaskGroup ~= "" and string.find(v.image, "/" .. identity.facialMaskGroup) ~= nil then
      identity.facialMaskFolder, identity.facialMaskType  = string.match(v.image, '^.*/(' .. identity.facialMaskGroup .. '.*)/(.*)%.png:.-$')
      identity.facialMaskDirectives = Sexbound_Player.filterReplace(v.image)
    end
    
    -- Attempt to find facial hair
    if identity.facialHairGroup ~= nil and identity.facialHairGroup ~= "" and string.find(v.image, "/" .. identity.facialHairGroup) ~= nil then
      identity.facialHairFolder, identity.facialHairType  = string.match(v.image, '^.*/(' .. identity.facialHairGroup .. '.*)/(.*)%.png:.-$')
      identity.facialHairDirectives = Sexbound_Player.filterReplace(v.image)
    end
    
    -- Attempt to find body identity
    if (string.find(v.image, "body.png") ~= nil) then
      identity.bodyDirectives = string.match(v.image, '%?replace.*')
    end
  
    -- Attempt to find emote identity
    if (string.find(v.image, "emote.png") ~= nil) then
      identity.emoteDirectives = Sexbound_Player.filterReplace(v.image)
    end
    
    -- Attempt to find hair identity
    if (string.find(v.image, "/hair") ~= nil) then
      identity.hairFolder, identity.hairType = string.match(v.image, '^.*/(hair.*)/(.*)%.png:.-$')
      
      identity.hairDirectives = Sexbound_Player.filterReplace(v.image)
    end
  end)

  return identity
end

--- Returns a filtered string. Used to filter desired data out of directive strings.
-- @param image
Sexbound_Player.filterReplace = function(image)
  if (string.find(image, "?addmask")) then
    if (string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')) then
      return string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')
    else
      return string.match(image, '^.*(%?replace.*)%?addmask.-$')
    end
  else
    if (string.match(image, '^.*(%?replace.*%?replace.*)')) then
      return string.match(image, '^.*(%?replace.*%?replace.*)')
    else
      return string.match(image, '^.*(%?replace.*)')
    end
  end
  
  return ""
end

Sexbound_Player.updateStatuses = function()
  -- If the status property 'sexbound_mind_control' is set.
  if status.statusProperty("sexbound_mind_control") == true and not self.sexbound.hasStoredActor then
    status.setStatusProperty("sexbound_mind_control", false)
    
    -- Control the player
  end
  
  -- If the status property 'sexbound_sex' is set.
  if status.statusProperty("sexbound_sex") == true and not self.sexbound.hasStoredActor then
    if player.isLounging() then
      self.sexbound.loungeId = player.loungingIn()
    
      Sexbound_Player.setupActor()
    end
  end
  
  -- If the status property 'sexbound_sex' is cleared.
  if status.statusProperty("sexbound_sex") ~= true and self.sexbound.hasStoredActor then
    self.sexbound.hasStoredActor = false
  
    -- Request the SexboundAPI to remove this entity from the list of actors.
    Sexbound.API.Util.sendMessage( self.sexbound.controllerId, "main-remove-actor", entity.id() )
  end
end

Sexbound_Player.setupActor = function()
  self.sexbound.hasStoredActor = true
  
  local actorData = {
    -- Store id.
    id = player.id(),
    
    -- Store the Player / NPC's name.
    name = world.entityName( player.id() ),
    
    -- Store the Player / NPC's storage.
    storage = storage,
    
    entityType = "player"
  }
  
  -- Get 'full' player portrait.
  local portraitData = world.entityPortrait( player.id(), "full" )
  
  actorData.identity = Sexbound_Player.buildIdentityFromPortrait( portraitData )
  
  Sexbound.API.Util.sendMessage( self.sexbound.controllerId, "main-setup-actor", actorData )
end