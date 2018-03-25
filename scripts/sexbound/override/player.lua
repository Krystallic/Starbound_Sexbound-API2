--- Sexbound.Player Module.
-- @module Sexbound.Player

require "/scripts/vec2.lua" -- Chucklefish's vector script

require "/scripts/sexbound/util.lua"

Sexbound.Player = {}
Sexbound.Player_mt = { __index = Sexbound.Player }

--- Hook (init)
Sexbound_Old_Init = init
function init()
  Sexbound_Old_Init()

  if not pcall(function()
    self.sb_player = Sexbound.Player:new()
  end) then
    sb.logInfo("There was an error in the Sexbound file that overrides player.")
  end
end

--- Hook (update)
Sexbound_Old_Update = update
function update(dt)
  Sexbound_Old_Update(dt)
  
  if not pcall(function()
    self.sb_player:update(dt)
  end) then
    sb.logInfo("There was an error in the Sexbound file that overrides player.")
  end
end

function Sexbound.Player:new()
  local self = setmetatable({
    _controllerId = nil,
    _hasSetupActor = false,
    _loungeId = nil,
    _mindControl = { damageSourceKind = "sexbound_mind_control" }
  }, Sexbound.Player_mt)

  self:initMessageHandlers()
  
  self:initStatusProperties()
  
  self:restorePreviousStorage()
  
  return self
end

function Sexbound.Player:update(dt)
  -- If the status property 'sexbound_mind_control' is set.
  if status.statusProperty("sexbound_mind_control") == true and not self._hasStoredActor then
    status.setStatusProperty("sexbound_mind_control", false)
    
    -- Control the player
  end

  -- If the status property 'sexbound_sex' is set.
  if status.statusProperty("sexbound_sex") == true and not self._hasStoredActor then
    if player.isLounging() then
      self._loungeId = player.loungingIn()
      
      self:setupActor()
    end
  end

  -- If the status property 'sexbound_sex' is cleared.
  if status.statusProperty("sexbound_sex") ~= true and self._hasStoredActor then
    self._hasStoredActor = false
  
    local msgId = self._controllerId or self._loungeId
  
    -- Request the SexboundAPI to remove this entity from the list of actors.
    Sexbound.Util.sendMessage( msgId, "sexbound-remove-actor", entity.id() )
  end
  
  -- Check for abortion
  if status.statusProperty("sexbound_abortion") == true then
    self:abortPregnancy()
  end
  
  if storage.pregnant and not isEmpty(storage.pregnant) then
    self:tryToGiveBirth(function(birthData)
      self:giveBirth(birthData)
    end)
  end
end

-- Getters / Setters

function Sexbound.Player:getControllerId()
  return self._controllerId
end

-- Attempts to abort all current pregnancies.
function Sexbound.Player:abortPregnancy()
  status.setStatusProperty("sexbound_abortion", false)
  
  if storage.pregnant == nil then return end
  
  storage.pregnant = nil
  
  -- Send radio message to inform player of abortion
  if entity.entityType() == "player" then
    world.sendEntityMessage(entity.id(), "queueRadioMessage", {
      messageId = "Pregnant:Abort",
      unique    = false,
      text      = "All vital scans indicate that you are no longer pregnant!"
    })
  end
end

function Sexbound.Player:initMessageHandlers()
  message.setHandler("sexbound-lounge", function(_, _, args)
    local anchor = 0

    self._loungeId = args.loungeId
    
    player.lounge(self._loungeId, anchor) -- Lounge the player in the object's first anchor
  end)
  
  message.setHandler("sexbound-show-ui", function(_, _, args)
    self._controllerId = args.controllerId
  
    -- Show the Sexbound UI.
    local config = root.assetJson( "/interface/sexbound/default.config" )
  
    config.config.controllerId = self._controllerId
    
    player.interact("ScriptPane", config)
  end)
  
  message.setHandler("sexbound-sync-storage", function(_,_,args)
    storage = util.mergeTable(storage, args or {})
  end)
 
  message.setHandler("sexbound-ui-dismiss", function(_,_,args)
    -- Do something when UI says player has dismissed it.
  end)
end

function Sexbound.Player:initStatusProperties()
  status.setStatusProperty("sexbound_mind_control", false)

  status.setStatusProperty("sexbound_sex", false)

  status.setStatusProperty("sexbound_abortion", false)
end

--- Returns a table consisting of identifying information about the player character.
-- @param portraitData
function Sexbound.Player:buildIdentityFromPortrait(portraitData)
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

  -- Store player's name
  identity.name    = world.entityName( player.id() )
  
  -- Store player's gender
  identity.gender  = player.gender()
  
  -- Store player's species
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
      identity.facialMaskDirectives = self:filterReplace(v.image)
    end
    
    -- Attempt to find facial hair
    if identity.facialHairGroup ~= nil and identity.facialHairGroup ~= "" and string.find(v.image, "/" .. identity.facialHairGroup) ~= nil then
      identity.facialHairFolder, identity.facialHairType  = string.match(v.image, '^.*/(' .. identity.facialHairGroup .. '.*)/(.*)%.png:.-$')
      identity.facialHairDirectives = self:filterReplace(v.image)
    end
    
    -- Attempt to find body identity
    if (string.find(v.image, "body.png") ~= nil) then
      identity.bodyDirectives = string.match(v.image, '%?replace.*')
    end
  
    -- Attempt to find emote identity
    if (string.find(v.image, "emote.png") ~= nil) then
      identity.emoteDirectives = self:filterReplace(v.image)
    end
    
    -- Attempt to find hair identity
    if (string.find(v.image, "/hair") ~= nil) then
      identity.hairFolder, identity.hairType = string.match(v.image, '^.*/(hair.*)/(.*)%.png:.-$')
      
      identity.hairDirectives = self:filterReplace(v.image)
    end
  end)

  return identity
end

--- Returns a filtered string. Used to filter desired data out of directive strings.
-- @param image
function Sexbound.Player:filterReplace(image)
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

--- Spawns a new NPC as sexbound_familymember type.
function Sexbound.Player:giveBirth(birthData)
  -- Make sure the gender has been set to a random gender ('male' or 'female').
  birthData.birthGender = birthData.birthGender or util.randomChoice({"male", "female"})
  
  -- Make sure that the mother's name is set to the correct player's name.
  birthData.motherName = birthData.motherName or world.entityName( player.id() )
  
  -- Set the mother's player id
  birthData.playerId = player.id()
  
  local parameters = {}
  
  parameters.identity = {}
  parameters.identity.gender = birthData.birthGender
  parameters.statusControllerSettings = {
    statusProperties = {
      sexbound_birthday = birthData
    }
  }
  parameters.uniqueId = sb.makeUuid()

  world.spawnNpc(entity.position(), player.species(), "sexbound_familymember", -1, nil, parameters) -- level 1
end

--- Attempt to restore this entity's previous storage parameters.
function Sexbound.Player:restorePreviousStorage()
  if (type(status.statusProperty("sexbound_previous_storage")) == "table") then
    storage = util.mergeTable(storage, status.statusProperty("sexbound_previous_storage", {}))
    
    status.setStatusProperty("sexbound_previous_storage", "default")
  end  

  -- storage = util.mergeTable(storage, config.getParameter("sexbound.previousStorage") or {})
end

function Sexbound.Player:setupActor()
  local msgId = self._loungeId

  if not msgId then return end
  
  self._hasStoredActor = true
  
  local actorData = {
    -- Store id
    id = player.id(),
    
    -- Store the Player / NPC's name
    name = world.entityName( player.id() ),
    
    -- Store the Player's current storage table
    storage = storage,
    
    -- Store entity type as 'player'
    entityType = "player"
  }
  
  -- Get 'full' player portrait.
  local portraitData = world.entityPortrait( player.id(), "full" )
  
  actorData.identity = self:buildIdentityFromPortrait( portraitData )

  Sexbound.Util.sendMessage( msgId, "sexbound-setup-actor", actorData )
end

function Sexbound.Player:splashDamage()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self._mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

--- Attempt to invoke entity to give birth.
function Sexbound.Player:tryToGiveBirth(callback)
  local worldTime = world.day() + world.timeOfDay()
  
  for i,v in ipairs(storage.pregnant) do
    local birthTime = v.birthDate + v.birthTime
    
    if worldTime >= birthTime then
      local birthData = util.mergeTable({}, v)
      
      table.remove(storage.pregnant, i)
    
      if type(callback) == "function" then
        callback( birthData )
      end
    end
  end
end