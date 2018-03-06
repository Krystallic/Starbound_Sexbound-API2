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

--- Private: Initialize Positions.
local function Sexbound_API_InitPositions()
  local configFileName = Sexbound.API.getParameter("position.configFile", "/positions/positions.config")

  local positionsConfig = root.assetJson(configFileName)

  self.sexboundData.positions = {}
  
  -- Initialize idle positions.
  self.sexboundData.positions.idle = {}
  self.sexboundData.positions.idle.positionCount = 0
  self.sexboundData.positions.idle.positionIndex = 1
  
  for _,v in ipairs(Sexbound.API.getParameter("position.idle")) do
    local pConfigFileName = positionsConfig[v].configFile or "/positions/idle.position"
  
    local pConfig = root.assetJson(pConfigFileName)
    
    if type(pConfig) == "table" then
      table.insert(self.sexboundData.positions.idle, Sexbound.Core.Position.new(pConfig))
      
      self.sexboundData.positions.idle.positionCount = self.sexboundData.positions.idle.positionCount + 1
    end
  end
  
  -- Initialize sex positions.
  self.sexboundData.positions.sex = {}
  self.sexboundData.positions.sex.positionCount = 0
  self.sexboundData.positions.sex.positionIndex = 1
  
  for _,v in ipairs(Sexbound.API.getParameter("position.sex")) do
    local pConfigFileName = positionsConfig[v].configFile or "/positions/from_behind.position"
  
    local pConfig = root.assetJson(pConfigFileName)
  
    if type(pConfig) == "table" then
      table.insert(self.sexboundData.positions.sex, Sexbound.Core.Position.new(pConfig))
      
      self.sexboundData.positions.sex.positionCount = self.sexboundData.positions.sex.positionCount + 1
    end
  end
end

--- Private: Initialize Sound Effects
local function Sexbound_API_InitSoundEffect()
  self.sexboundData.animatorSound = {}

  -- Initialize climax.
  if (animator.hasSound("climax")) then
    self.sexboundData.animatorSound.climax = Sexbound.API.getParameter("climax.sounds")
    
    animator.setSoundPool("climax", self.sexboundData.animatorSound.climax)
  end

  -- Initialize female moans.
  if (animator.hasSound("moanfemale")) then
    self.sexboundData.animatorSound.moanfemale = Sexbound.API.getParameter("moan.sounds.female")
  
    animator.setSoundPool("moanfemale", self.sexboundData.animatorSound.moanfemale)
  end
  
  -- Initialize male moans.
  if (animator.hasSound("moanmale")) then
    self.sexboundData.animatorSound.moanmale = Sexbound.API.getParameter("moan.sounds.male")
    
    animator.setSoundPool("moanmale", self.sexboundData.animatorSound.moanmale)
  end
end

--- Private: Updates the animator's animation rate.
local function Sexbound_API_UpdateAnimationRate(dt)
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

--- Initializes this module.
-- @usage function init() Sexbound.API.init() end
function Sexbound.API.init()
  self.sexboundData = {}

  -- Load configuration from mod
  self.sexboundData.config = util.mergeTable(root.assetJson("/scripts/sexbound/default.config"), config.getParameter("sexboundConfig", {}))

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
  Sexbound_API_InitPositions()
  
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

--- Updates this module.
-- @param dt delta time
-- @param[opt] callback
-- @usage function update(dt) Sexbound.API.update(dt) end
function Sexbound.API.update(dt, callback)
  if not self.sexboundData then return end

  -- Update each Node instance.
  for _,node in ipairs(self.sexboundData.nodes) do
    node:update(dt)
  end
  
  -- Update each Actor instance.
  for _,actor in ipairs(self.sexboundData.actors) do
    actor:update(dt)
  end

  if Sexbound.API.Status.isHavingSex() then
    Sexbound_API_UpdateAnimationRate(dt)
  end
  
  -- Update the state machine
  self.stateMachine:update(dt)
  
  if type(callback) == "function" then
    callback(self.sexboundData)
  end
end

--- Adds new node and tracks it as being this object.
function Sexbound.API.becomeNode()
  table.insert(self.sexboundData.nodes, Sexbound.Core.Node.new({0, 0}, false))
  
  self.sexboundData.nodeCount = self.sexboundData.nodeCount + 1
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

function Sexbound.API.respawnStoredActor()
  -- Respawn stored actor.
  if storage.actor then
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
      statusControllerSettings = {
        statusProperties = {
          sexbound_previous_storage = storage.actor.storage
        }
      }
    }
    
    -- Restore actor's unique ID.
    if (storage.actor.uniqueId and not world.findUniqueEntity(storage.actor.uniqueId):result()) then
      parameters.scriptConfig = {
        uniqueId = storage.actor.uniqueId
      }
    end
    
    world.spawnNpc(position, storage.actor.identity.species, storage.actor.type, storage.actor.level, storage.actor.seed, parameters)
  end
end

--- Handles this entities uninit.
function Sexbound.API.uninit()
  -- Uninit any and all nodes.
  Sexbound.API.Nodes.uninit()
end
