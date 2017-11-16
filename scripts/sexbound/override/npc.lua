--- Sexbound_NPC Module.
-- @module Sexbound_NPC

require "/scripts/vec2.lua"

require "/scripts/sexbound.lua"
require "/scripts/sexbound/override/common.lua"

Sexbound_NPC = {}

--- Hook - init
function init()
  -- Initializes the NPC
  Sexbound_Common.init()
  
  -- Initialize message handlers.
  Sexbound_NPC.initMessageHandlers()
  
  -- Restore the NPCs previous storage
  storage = util.mergeTable(storage, config.getParameter("sexbound.previousStorage", {}))
end

--- Hook - Update
-- @param dt
function update(dt)
  -- Updates the NPC
  Sexbound_Common.update(dt)
  
  -- Update status effects.
  Sexbound_NPC.updateStatuses()
end

--- Initializes message handlers.
Sexbound_NPC.initMessageHandlers = function()
  message.setHandler("sexbound-unload", function(_,_,args)
    Sexbound_NPC.unload()
  end)
end

Sexbound_NPC.hasOwnerUuid = function()
  if storage and storage.ownerUuid then return true end
  return false
end

Sexbound_NPC.hasRespawner = function()
  if storage.respawner then return true end
  return false
end

--- Creates and sends actor data to the Sexbound API.
-- @param store is a boolean
Sexbound_NPC.setupActor = function(store)
  self.sexbound.hasStoredActor = true
  
  local actorData = {
    -- Store id.
    id = entity.id(),
    
    uniqueId = entity.uniqueId(),
    
    level = npc.level(),
    
    entityType = "npc",
    
    identity = npc.humanoidIdentity(),
    
    -- Store the Player / NPC's name.
    name = world.entityName( entity.id() ),    
    
    type = npc.npcType(),
    
    seed = npc.seed(),
    
    -- Store the Player / NPC's storage.
    storage = storage
  }
  
  if store then
    Sexbound.API.Util.sendMessage( self.sexbound.loungeId, "main-store-actor", actorData )
  else
    Sexbound.API.Util.sendMessage( self.sexbound.loungeId, "node-setup-actor", actorData )
  end
end

--- Attempts to transform the NPC into a Sexbound node by placing a 'sexbound_main_node' object at the feet of the NPC.
-- @param[opt] callback
Sexbound_NPC.transformIntoObject = function(callback)
  -- Attempt to override default mind control status options.
  self.sexbound.mindControl = util.mergeTable(self.sexbound.mindControl, status.statusProperty("sexbound_mind_control_override", {}))
  
  -- Legacy support for older versions of Aphrodite's Bow.
  self.sexbound.mindControl = util.mergeTable(self.sexbound.mindControl, status.statusProperty("lustConfigOverride", {}))
  
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
    self.sexbound.isTransformed = true
  
    -- Generate new uniqueId.
    self.sexbound.loungeId = randomUUID
  
    -- Check for respawner (tenant)
    if Sexbound_NPC.hasRespawner() or Sexbound_NPC.hasOwnerUuid() then
      if Sexbound_NPC.hasRespawner() and Sexbound.API.Util.findEntityWithUid(storage.respawner) then
        Sexbound_NPC.setupActor(true)
        
        world.sendEntityMessage(storage.respawner, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
      
      -- Check for crew member
      --if Sexbound_NPC.hasOwnerUuid() and Sexbound.API.Util.findEntityWithUid(storage.ownerUuid) then
        --Sexbound_Common.splashDamage()
        --world.sendEntityMessage(storage.ownerUuid, "transform-into-object", {uniqueId = entity.uniqueId()})
      --end
    else
      Sexbound_NPC.setupActor(true)
      
      Sexbound_NPC.unload()
    end
  end
  
  if not result then Sexbound_Common.splashDamage() end
end

--- Unloads this NPC.
Sexbound_NPC.unload = function()
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
    damageSourceKind = self.sexbound.mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
  
  --self.forceDie = true
end

--- Updates status effects.
Sexbound_NPC.updateStatuses = function()
  -- If the status property 'sexbound_mind_control' is set.
  if status.statusProperty("sexbound_mind_control") == true and not self.sexbound.hasStoredActor then
    status.setStatusProperty("sexbound_mind_control", false)
  
    Sexbound_NPC.transformIntoObject(function()
      -- If Successful then..
      
    end)
  end
  
  -- Legacy support for older versions of Aphrodite's Bow.
  if status.statusProperty("lust") == true and not self.sexbound.hasStoredActor then
    status.setStatusProperty("lust", false)
  
    Sexbound_NPC.transformIntoObject(function()
      -- If Successful then..
      
    end)
  end
  
  -- If the status property 'sexbound_sex' is set.
  if status.statusProperty("sexbound_sex") == true and not self.sexbound.hasStoredActor then
    if npc.isLounging() then
      self.sexbound.loungeId = npc.loungingIn()
    
      Sexbound_NPC.setupActor(false)
    end
  end
  
  -- If the status property 'sexbound_sex' is cleared.
  if  not self.sexbound.isTransformed and status.statusProperty("sexbound_sex") ~= true and self.sexbound.hasStoredActor then
    Sexbound_Common.removeActor()
  end
end
