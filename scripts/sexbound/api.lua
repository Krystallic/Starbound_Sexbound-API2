--- Sexbound.API Module.
-- @module Sexbound.API
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/core.lua"

--- Private: Initialize Message Handlers
local function Sexbound_API_InitMessageHandlers()
  message.setHandler("main-climax", function(_,_,args)
    if Sexbound.API.Status.isHavingSex() then
      -- Invoke specified actor to begin climaxing.
      self.sexboundData.actors[args.actorId]:getClimax():beginClimax()
    end
  end)

  message.setHandler("main-remove-actor", function(_,_,args)
    Sexbound.API.Actors.removeActor(args)
  end)

  message.setHandler("main-setup-actor", function(_,_,args)
    Sexbound.API.Actors.addActor(args, false)
  end)
  
  message.setHandler("main-store-actor", function(_,_,args)
    Sexbound.API.Actors.addActor(args, true)
  end)
  
  message.setHandler("main-switch-position", function(_,_,args)
    Sexbound.API.Positions.switchPosition( args.positionId )
  end)
  
  message.setHandler("main-switch-role", function(_,_,args)
    Sexbound.API.Actors.switchRole()
  end)
  
  message.setHandler("main-sync-ui", function(_,_,args)
    local data = {}
    data.actors = {}
    
    for _,actor in ipairs(self.sexboundData.actors) do
      table.insert(data.actors, {
        climax = {
          currentPoints = actor:getClimax():currentPoints(),
          maxPoints = actor:getClimax():maxPoints()
        }
      })
    end
    
    return data
  end)
end

--- Private: Initialize Sound Effects
local function Sexbound_API_InitSoundEffect()
  self.sexboundData.animatorSound = {}

  -- Initialize climax.
  if (animator.hasSound("climax")) then
    self.sexboundData.animatorSound.climax = {
      "/sfx/sexbound/cum/squish.ogg"
    }
    
    animator.setSoundPool("climax", self.sexboundData.animatorSound.climax)
  end

  -- Initialize female moans.
  if (animator.hasSound("moanfemale")) then
    self.sexboundData.animatorSound.moanfemale = {
      "/sfx/sexbound/moans/femalemoan1.ogg",
      "/sfx/sexbound/moans/femalemoan2.ogg",
      "/sfx/sexbound/moans/femalemoan3.ogg",
      "/sfx/sexbound/moans/femalemoan4.ogg",
      "/sfx/sexbound/moans/femalemoan5.ogg"
    }
  
    animator.setSoundPool("moanfemale", self.sexboundData.animatorSound.moanfemale)
  end
  
  -- Initialize male moans.
  if (animator.hasSound("moanmale")) then
    self.sexboundData.animatorSound.moanmale = {
      "/sfx/sexbound/moans/malemoan1.ogg",
      "/sfx/sexbound/moans/malemoan2.ogg",
      "/sfx/sexbound/moans/malemoan3.ogg"
    }
    
    animator.setSoundPool("moanmale", self.sexboundData.animatorSound.moanmale)
  end
  
  -- Initialize female orgasms.
  if (animator.hasSound("orgasmfemale")) then
    self.sexboundData.animatorSound.orgasmfemale = {
      "/sfx/sexbound/orgasms/femaleorgasm1.ogg"
    }
    
    animator.setSoundPool("orgasmfemale", self.sexboundData.animatorSound.orgasmfemale)
  end
end

--- Initializes this module.
-- @usage function init() Sexbound.API.init() end
function Sexbound.API.init()
  self.sexboundData = {}

  -- Load configuration from mod
  self.sexboundData.config = util.mergeTable(root.assetJson("/sexbound.config"), config.getParameter("sexboundConfig", {}))

  -- Sets this object to be interactive when interactive is true
  object.setInteractive(config.getParameter("interactive", false))
  
  -- Initialize empty table for actors
  self.sexboundData.actors = {}
  self.sexboundData.actorCount = 0
  
  -- Initialize the animation rate
  self.sexboundData.animationRate = 1
  
  -- Initialize empty table for nodes
  self.sexboundData.nodes = {}
  self.sexboundData.nodeCount = 0
  
  -- Initialize animator sounds
  Sexbound_API_InitSoundEffect()
  
  -- Initialize positions
  Sexbound.API.Positions.initPositions()
  
  -- Initialize statuses
  self.sexboundData.status = {
    havingSex = false,
    climaxing = false,
    reseting  = false
  }
  
  -- Create new log utility.
  self.log = Sexbound.Core.Log.new({
    moduleName = "Main"
  })

  -- Create new state machine.
  self.stateMachine = Sexbound.Core.StateMachine.new()
  
  -- Initialize message handlers.
  Sexbound_API_InitMessageHandlers()
end

--- Adds new node and tracks it as being this object.
function Sexbound.API.becomeNode()
  table.insert(self.sexboundData.nodes, Sexbound.Core.Node.new({0, 0}, false))
  
  self.sexboundData.nodeCount = self.sexboundData.nodeCount + 1
end

--- Handles a player interaction request.
-- @param args interact arguments
-- @usage function onInteraction(args) Sexbound.API.handleInteract(args) end
function Sexbound.API.handleInteract(args)
  -- Lounge-in next available node.
  for _,node in ipairs(self.sexboundData.nodes) do
    if not node:occupied() then
      node:lounge(args.sourceId)
      return
    end
  end
end

--- Handles this entities uninit.
function Sexbound.API.handleUninit()
  -- Uninit any and all nodes.
  Sexbound.API.Nodes.uninitNodes()
end

--- Updates this module.
-- @param dt delta time
-- @usage function update(dt) Sexbound.API.update(dt) end
function Sexbound.API.update(dt)
  -- Update each Node instance.
  for _,node in ipairs(self.sexboundData.nodes) do
    node:update(dt)
  end
  
  -- Update each Actor instance.
  for _,actor in ipairs(self.sexboundData.actors) do
    actor:update(dt)
  end

  if Sexbound.API.Status.isHavingSex() then
    Sexbound.API.updateAnimationRate(dt)
  end
  
  -- Update the state machine
  self.stateMachine:update(dt)
end

--- Returns a reference to the entire configuration.
-- @usage local config = Sexbound.API.getConfig()
-- @return table of data
function Sexbound.API.getConfig()
  return self.sexboundData.config
end

--- Returns a reference to a specific parameter in the configuation.
-- @param param string value
-- @usage local name = Sexbound.API.getParameter("position.idle.name")
function Sexbound.API.getParameter(param)
  local config = self.sexboundData.config or root.assetJson("/sexbound.config")
  
  for _,p in ipairs(util.split(param, ".")) do
    if config[p] ~= nil then
      config = config[p]
    else return nil end
  end
  
  return config
end

--- Attempts to spawn a stored actor.
function Sexbound.API.respawnNPC()
  self.log:info("Restoring actor.")
  self.log:info(storage.actor)

  if storage.actor then
    -- Don't respawn NPC if it is a companion.
    --if storage.npc.storage.ownerUuid then 
      --world.sendEntityMessage(storage.npc.storage.ownerUuid, "transform-into-npc", {uniqueId = storage.npc.uniqueId})
    --return end
    
    local position = vec2.add(object.position(), {0, 3})
    
    -- Copy reference to pregnant storage into NPC storage
    if storage.pregnant and storage.pregnant.isPregnant then
      storage.npc.storage.pregnant = storage.pregnant
    end
    
    -- Message the actor's respawner that it is turning back into an NPC.
    if storage.actor.storage.respawner then
      world.sendEntityMessage(storage.actor.storage.respawner, "transform-into-npc", {uniqueId = storage.actor.uniqueId})
    end
    
    -- Initialize parameters to send to spawned NPC.
    local parameters = {
      scriptConfig = {
        sexbound = {
          previousStorage = storage.actor.storage
        }
      }
    }
    
    -- Restore actor's unique ID.
    if (storage.actor.uniqueId and not world.findUniqueEntity(storage.actor.uniqueId):result()) then
      parameters.scriptConfig.uniqueId = storage.actor.uniqueId
    end
    
    world.spawnNpc(position, storage.actor.identity.species, storage.actor.type, storage.actor.level, storage.actor.seed, parameters)
  end
end

--- Adjusts the animation rate of the animator.
-- @param dt
function Sexbound.API.updateAnimationRate(dt)
  if Sexbound.API.Status.isClimaxing() or Sexbound.API.Status.isReseting() then
    self.sexboundData.animationRate = 1
    return
  end

  local position = Sexbound.API.Positions.currentPosition()

  self.sexboundData.animationRate = self.sexboundData.animationRate + (position:maxTempo() / (position:sustainedInterval() / dt))

  self.sexboundData.animationRate = util.clamp(self.sexboundData.animationRate, position:minTempo(), position:maxTempo())

  -- Set the animator's animation rate
  animator.setAnimationRate(self.sexboundData.animationRate)
  
  if (self.sexboundData.animationRate >= position:maxTempo()) then
    self.sexboundData.animationRate = position:minTempo()
    
    position:nextMaxTempo()
      
    position:nextSustainedInterval()
  end
end