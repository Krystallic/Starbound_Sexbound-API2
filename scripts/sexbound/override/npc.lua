--- Sexbound.NPC Module.
-- @module Sexbound.NPC

require "/scripts/sexbound/override/common.lua"

Sexbound.NPC = {}
Sexbound.NPC_mt = { __index = Sexbound.NPC }

SexboundErrorCounter = 0

--- Hook (init)
Sexbound_Old_Init = init
function init()
  Sexbound_Old_Init()

  if not pcall(function()
    self.sb_npc = Sexbound.NPC:new()
  end) then
    sb.logInfo("There was an error in the Sexbound file that overrides NPC.")
  end
end

--- Hook (update)
Sexbound_Old_Update = update
function update(dt)
  Sexbound_Old_Update(dt)
  
  if SexboundErrorCounter < 5 then
    if not pcall(function()
      self.sb_npc:update(dt)
    end) then
      SexboundErrorCounter = SexboundErrorCounter + 1
      
      sb.logInfo("There was an error in the Sexbound file that overrides NPC.")
    end
  end
end

function Sexbound.NPC:new()
  local self = setmetatable({
    _common = Sexbound.Common:new(),
    _controllerId  = nil,
    _hasSetupActor = false,
    _mindControl   = {damageSourceKind = "sexbound_mind_control"}
  }, Sexbound.NPC_mt)

  self:initMessageHandlers()
  
  self:initStatusProperties()
  
  self:restorePreviousStorage()
  
  return self
end


function Sexbound.NPC:getCommon()
  return self._common
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
      
      self._hasStoredActor = true
      
      self:setupActor(false)
    end
  end
  
  -- If the status property 'sexbound_sex' is cleared.
  if status.statusProperty("sexbound_sex") ~= true and self._hasStoredActor then
    self._hasStoredActor = false
  
    local msgId = self._loungeId
  
    Sexbound.Util.sendMessage( msgId, "sexbound-remove-actor", entity.id() )
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
  local common = self:getCommon()
  
  local notifications = common:getNotifications() or {}

  local plugins  = notifications.plugins or {}
  local pregnant = plugins.pregnant or {}

  local message = pregnant.birthMessage1 or ""
  
  local birthData = status.statusProperty("sexbound_birthday")
  
  local babyName = npc.humanoidIdentity().name or "UNKNOWN"
  babyName = "^green;" .. babyName .. "^reset;"
  
  local babyGender = npc.humanoidIdentity().gender
  
  if babyGender == "male" then
    babyGender = "^blue;boy^reset;"
  end
  
  if babyGender == "female" then
    babyGender = "^pink;girl^reset;"
  end
  
  message = util.replaceTag(message, "babyname", babyName)
  
  message = util.replaceTag(message, "babygender", babyGender)
  
  if birthData.playerId then
    world.sendEntityMessage(birthData.playerId, "queueRadioMessage", {
      messageId = "Sexbound_Event:Birth",
      unique    = false,
      text      = message
    })
  end
  
  local motherName = birthData.motherName or "UNKNOWN"
  motherName = "^green;" .. motherName .. "^reset;"
  
  message = pregnant.birthMessage2 or ""
  
  message = util.replaceTag(message, "name", motherName)
  
  message = util.replaceTag(message, "babyname", babyName)
  
  message = util.replaceTag(message, "babygender", babyGender)
  
  for _,playerId in ipairs(world.players()) do
    if playerId ~= birthData.playerId then
      world.sendEntityMessage(playerId, "queueRadioMessage", {
        messageId = "Sexbound_Event:Birth",
        unique    = false,
        text      = message
      })
    end
  end
  
  -- Clear status property
  status.setStatusProperty("sexbound_birthday", "default")
end

--- Spawns a new NPC.
function Sexbound.NPC:giveBirth(birthData)
  -- Make sure that the mother's name is set to the correct player's name.
  birthData.motherName  = birthData.motherName  or npc.humanoidIdentity().name
  
  local parameters = {}
  
  parameters.statusControllerSettings = {
    statusProperties = {
      sexbound_birthday = birthData
    }
  }
  
  local level = 1
  
  parameters.uniqueId = sb.makeUuid()

  world.spawnNpc(entity.position(), npc.species(), npc.npcType(), level, nil, parameters) -- level 1
end

function Sexbound.NPC:initStatusProperties()
  status.setStatusProperty("sexbound_mind_control", false)

  status.setStatusProperty("sexbound_sex", false)

  status.setStatusProperty("sexbound_abortion", false)
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
  local actorData = {
    -- Store id.
    id = entity.id(),
    
    uniqueId = entity.uniqueId(),
    
    level = npc.level(),
    
    entityType = "npc",
    
    identity = npc.humanoidIdentity(),
    
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
