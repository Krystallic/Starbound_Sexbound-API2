--- Sexbound.NPC Module.
-- @module Sexbound.NPC

require "/scripts/vec2.lua"

require "/scripts/sexbound/lib/sexbound/util.lua"

Sexbound.NPC = {}
Sexbound.NPC.__index = Sexbound.NPC

--- Hook (init)
Sexbound_Old_Init = init
function init()
  Sexbound_Old_Init()

  self.sb_npc = Sexbound.NPC.new()
end

--- Hook (update)
Sexbound_Old_Update = update
function update(dt)
  Sexbound_Old_Update(dt)
  
  self.sb_npc:update(dt)
end

function Sexbound.NPC.new()
  local self = setmetatable({
    _hasSetupActor = false,
    _mindControl = {damageSourceKind = "sexbound_mind_control"}
  }, Sexbound.NPC)

  self:restorePreviousStorage()
  
  return self
end

function Sexbound.NPC:update(dt)
  -- If the status property 'sexbound_mind_control' is set.
  if status.statusProperty("sexbound_mind_control") == true and not self._hasStoredActor then
    status.setStatusProperty("sexbound_mind_control", false)
  
    self:transformIntoObject(function()
      -- If Successful then.. Do nothing for now.
    end)
  end
  
  -- Legacy support for older versions of Aphrodite's Bow.
  if status.statusProperty("lust") == true and not self._hasStoredActor then
    status.setStatusProperty("lust", false)
  
    self:transformIntoObject(function()
      -- If Successful then.. Do nothing for now.
    end)
  end
  
  -- If the status property 'sexbound_sex' is set.
  if status.statusProperty("sexbound_sex") == true and not self._hasStoredActor then
    if npc.isLounging() then
      self._loungeId = npc.loungingIn()
    
      self:setupActor(false)
    end
  end
  
  -- If the status property 'sexbound_sex' is cleared.
  if status.statusProperty("sexbound_sex") ~= true then
    if self._hasStoredActor and not self._isTransformed then
      Sexbound.Util.sendMessage( self._loungeId, "main-remove-actor", entity.id() )
      
      self._hasStoredActor = false
    end
  end
  
    -- If the status property 'sexbound_birthday' is not 'default'
  if status.statusProperty("sexbound_birthday") and status.statusProperty("sexbound_birthday") ~= "default" then
    self:announceBirth()
  end

  if storage.pregnant and not isEmpty(storage.pregnant) then
    Sexbound.NPC:tryToGiveBirth(function(index)
      Sexbound.NPC:giveBirth(index)
    end)
  end
end

function Sexbound.NPC:announceBirth()
  local birthData  = status.statusProperty("sexbound_birthday")
  
  local motherName = birthData.motherName  or "UNKNOWN"
  local myName     = npc.humanoidIdentity().name or "UNKNOWN"
  local myGender   = npc.humanoidIdentity().gender
  
  local text = "^green;" .. motherName .. "^reset; has just given birth to a "
  
  local altText = "You have just given birth to a "
  
  if myGender == "male" then
    text = text .. "^blue;boy^reset; named ^green;" .. myName .. "^reset;!"
    
    altText = altText .. "^blue;boy^reset; named ^green;" .. myName .. "^reset;!"
  end
  
  if myGender == "female" then
    text = text .. "^pink;girl^reset; named ^green;" .. myName .. "^reset;!"
    
    altText = altText .. "^pink;girl^reset; named ^green;" .. myName .. "^reset;!"
  end
  
  if birthData.playerId then
    world.sendEntityMessage(birthData.playerId, "queueRadioMessage", {
      messageId = "Sexbound_Event:Birth",
      unique = false,
      text = altText
    })
  end
  
  for _,playerId in ipairs(world.players()) do
    if playerId ~= birthData.playerId then
      world.sendEntityMessage(playerId, "queueRadioMessage", {
        messageId = "Sexbound_Event:Birth",
        unique = false,
        text = text
      })
    end
  end
  
  -- Clear status property
  status.setStatusProperty("sexbound_birthday", "default")
end

--- Spawns a new NPC.
function Sexbound.NPC:giveBirth(birthData)
  -- Make sure the gender has been set to a random gender ('male' or 'female').
  birthData.birthGender = birthData.birthGender or util.randomChoice({"male", "female"})
  
  -- Make sure that the mother's name is set to the correct player's name.
  birthData.motherName  = birthData.motherName  or npc.humanoidIdentity().name
  
  local parameters = {}
  
  parameters.identity = {}
  parameters.identity.gender = birthData.birthGender
  parameters.statusControllerSettings = {
    statusProperties = {
      sexbound_birthday = birthData
    }
  }
  
  parameters.uniqueId = sb.makeUuid()
  
  world.spawnNpc(entity.position(), npc.species(), npc.npcType(), mcontroller.facingDirection(), nil, parameters) -- level 1
end

function Sexbound.NPC:hasOwnerUuid()
  if storage and storage.ownerUuid then return true end
  return false
end

function Sexbound.NPC:hasRespawner()
  if storage.respawner then return true end
  return false
end

function Sexbound.NPC:initMessageHandlers()
  message.setHandler("sexbound-unload", function(_,_,args)
    self.sb_npc:unload()
  end)
  
  message.setHandler("sexbound-sync-storage", function(_,_,args)
    storage = util.mergeTable(storage, args or {})
  end)
 
  message.setHandler("sexbound-ui-dismiss", function(_,_,args)
    -- Do something when UI says player has dismissed it.
  end)
end


--- Attempt to restore this entity's previous storage parameters.
function Sexbound.NPC:restorePreviousStorage()
  if (type(status.statusProperty("sexbound_previous_storage")) == "table") then
    storage = util.mergeTable(storage, status.statusProperty("sexbound_previous_storage", {}))
    
    status.setStatusProperty("sexbound_previous_storage", "default")
  end  

  -- storage = util.mergeTable(storage, config.getParameter("sexbound.previousStorage") or {})
end

--- Creates and sends actor data to the Sexbound API.
-- @param store is a boolean
function Sexbound.NPC:setupActor(store)
  self._hasStoredActor = true
  
  local actorData = {
    -- Store id.
    id = entity.id(),
    
    uniqueId = entity.uniqueId(),
    
    level = npc.level(),
    
    entityType = "npc",
    
    identity = npc.humanoidIdentity(),
    
    -- Store the Player / NPC's name.
    name = npc.humanoidIdentity().name,    
    
    type = npc.npcType(),
    
    seed = npc.seed(),
    
    -- Store the Player / NPC's storage.
    storage = storage
  }
  
  if store then
    Sexbound.Util.sendMessage( self._loungeId, "sexbound-store-actor", actorData )
  else
    Sexbound.Util.sendMessage( self._loungeId, "sexbound-setup-actor", actorData )
  end
end

function Sexbound.NPC:splashDamage()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self._mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

--- Attempts to transform the NPC into a Sexbound node by placing a 'sexbound_main_node' object at the feet of the NPC.
-- @param[opt] callback
function Sexbound.NPC:transformIntoObject(callback)
  -- Attempt to override default mind control status options.
  self._mindControl = util.mergeTable(self._mindControl, status.statusProperty("sexbound_mind_control_override", {}))
  
  -- Legacy support for older versions of Aphrodite's Bow.
  self._mindControl = util.mergeTable(self._mindControl, status.statusProperty("lustConfigOverride", {}))
  
  -- Create an object that resembles the npc at the position
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 2
  
  local randomUUID = sb.makeUuid()
  
  local params = {
    mindControl = {
      timeout = world.day() + world.timeOfDay() + 0.2
    },
    uniqueId = randomUUID
  }
  
  -- Try to place object in the world.
  local result = world.placeObject("sexbound_main_node", position, mcontroller.facingDirection(), params)
  
  if result then
    self._isTransformed = true
  
    -- Generate new uniqueId.
    self._loungeId = randomUUID
  
    -- Check for respawner (tenant)
    if self:hasRespawner() or self:hasOwnerUuid() then
      if self:hasRespawner() and Sexbound.Util.findEntityWithUid(storage.respawner) then
        self:setupActor(true)
        
        world.sendEntityMessage(storage.respawner, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
      
      -- Check for crew member
      --if Sexbound_NPC.hasOwnerUuid() and Sexbound.API.Util.findEntityWithUid(storage.ownerUuid) then
        --Sexbound_Common.splashDamage()
        --world.sendEntityMessage(storage.ownerUuid, "transform-into-object", {uniqueId = entity.uniqueId()})
      --end
    else
      self:setupActor(true)
      
      self:unload()
    end
  end
  
  if not result then self:splashDamage() end
end

--- Attempt to invoke entity to give birth.
function Sexbound.NPC:tryToGiveBirth(callback)
  local worldTime = world.day() + world.timeOfDay()
  
  for i,v in ipairs(storage.pregnant) do
    local birthTime = v.birthDate + v.birthTime
    
    if worldTime >= birthTime then
      local birthData = util.mergeTable({}, v)
      
      table.remove(storage.pregnant, i)
    
      if type(callback) == "function" then
        callback(birthData)
      end
    end
  end
end

function Sexbound.NPC:unload()
  -- Prevent loot drop.
  npc.setDropPools({})
  
  -- Prevent death particle effect.
  npc.setDeathParticleBurst(nil) 
  
  -- Remove persistence from NPC?
  npc.setPersistent(false)

  -- Kill the NPC
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = status.resourceMax("health"),
    damageSourceKind = self._mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
  
  --self.forceDie = true
end
