require "/scripts/vec2.lua"

require "/scripts/sexbound/util.lua"
require "/scripts/sexbound/sexboundui.lua"
require "/scripts/sexbound/override/common.lua"

Sexbound_NPC = {}

function init()
  Sexbound_Common.init()
end

function update(dt)
  Sexbound_Common.update(dt)
  
  Sexbound_NPC.updateStatuses()
end

Sexbound_NPC.updateStatuses = function()
  -- If the status property 'sexbound_mind_control' is set.
  if status.statusProperty("sexbound_mind_control") == true and not self.sexbound.hasStoredActor then
    status.setStatusProperty("sexbound_mind_control", false)
  
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

Sexbound_NPC.setupActor = function(store)
  self.sexbound.hasStoredActor = true
  
  local actorData = {
    -- Store id.
    id = entity.id(),
    
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
    Sexbound_Util.sendMessage( self.sexbound.loungeId, "node-store-actor", actorData )
  else
    Sexbound_Util.sendMessage( self.sexbound.loungeId, "node-setup-actor", actorData )
  end
end

Sexbound_NPC.transformIntoObject = function(callback)
  -- Attempt to override default mind control status options.
  self.sexbound.mindControl = util.mergeTable(self.sexbound.mindControl, status.statusProperty("sexbound_mind_control_override", {}))
  
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
      if Sexbound_NPC.hasRespawner() and Sexbound_NPC.findEntityWithUid(storage.respawner) then
        Sexbound_NPC.setupActor(true)
        
        world.sendEntityMessage(storage.respawner, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
      
      -- Check for crew member
      --if Sexbound_NPC.hasOwnerUuid() and Sexbound_NPC.findEntityWithUid(storage.ownerUuid) then
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

Sexbound_NPC.findEntityWithUid = function(uniqueId)
  if world.findUniqueEntity(uniqueId):result() then return true end
  return false
end

Sexbound_NPC.hasOwnerUuid = function()
  if storage and storage.ownerUuid then return true end
  return false
end

Sexbound_NPC.hasRespawner = function()
  if storage and storage.respawner then return true end
  return false
end

Sexbound_NPC.unload = function()
  npc.setDropPools({}) -- prevent loot drop
  
  npc.setDeathParticleBurst(nil) -- prevent death particle effect
  
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