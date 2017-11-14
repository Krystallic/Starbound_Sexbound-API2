--- Main Module.
-- @module Sexbound.Main

Sexbound = {}
Sexbound.Main = {}

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/Sexbound/util.lua"
require "/scripts/Sexbound/log.lua"

require "/scripts/Sexbound/actor.lua"
require "/scripts/Sexbound/node.lua"
require "/scripts/Sexbound/position.lua"
require "/scripts/Sexbound/state.lua"

--- Initializes this module
function Sexbound.Main.init()
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
  
  -- Initialize moan sound effects
  Sexbound.Main.initSoundEffects()
  
  -- Initialize positions
  Sexbound.Main.initPositions()
  
  -- Initialize statuses
  self.sexboundData.status = {
    havingSex = false,
    climaxing = false,
    reseting  = false
  }
  
  -- Create new log utility.
  self.log = Sexbound.Log.new({
    moduleName = "Main"
  })

  -- Setup test actor
  --Sexbound.Main.addActor(Sexbound.Main.getParameter("testNPC"), false)
  
  -- Create new state machine.
  self.stateMachine = Sexbound.StateMachine.new()
  
  -- Initialize message handlers.
  Sexbound.Main.initMessageHandlers()
end

--- Updates this module.
-- @param dt
function Sexbound.Main.update(dt)
  Sexbound.Main.updateActors(dt)

  if Sexbound.Main.isHavingSex() then
    Sexbound.Main.adjustTempo(dt)
  end
  
  -- Update the state machine
  self.stateMachine:update(dt)
end

--- Returns a reference to stored Sexbound configuration.
function Sexbound.Main.getConfig()
  return self.sexboundData.config
end

--- Returns the value for the specified parameter.
-- @param parameter string value with periods to separate parameters.
function Sexbound.Main.getParameter(parameter)
  local config = self.sexboundData.config or root.assetJson("/sexbound.config")
  
  local parameters = util.split(parameter, ".")
  
  for _,p in ipairs(parameters) do
    if config[p] ~= nil then
      config = config[p]
    else return nil end
  end
  
  return config
end

--- Handles a player interaction request.
-- @param args
function Sexbound.Main.handleInteract(args)
  -- Lounge-in next available node.
  for _,node in ipairs(self.sexboundData.nodes) do
    if not node:occupied() then
      node:lounge(args.sourceId)
      return
    end
  end
end

--- Handles this entities uninit.
function Sexbound.Main.handleUninit()
  -- Uninit any and all nodes.
  Sexbound.Main.uninitNodes()
end

--- Initializes the message handlers.
function Sexbound.Main.initMessageHandlers()
  message.setHandler("main-climax", function(_,_,args)
    if Sexbound.Main.isHavingSex() then
      -- Invoke specified actor to begin climaxing.
      self.sexboundData.actors[args.actorId]:getClimax():beginClimax()
    end
  end)

  message.setHandler("main-remove-actor", function(_,_,args)
    Sexbound.Main.removeActor(args)
  end)

  message.setHandler("main-setup-actor", function(_,_,args)
    Sexbound.Main.addActor(args, false)
  end)
  
  message.setHandler("main-store-actor", function(_,_,args)
    Sexbound.Main.addActor(args, true)
  end)
  
  message.setHandler("main-switch-position", function(_,_,args)
    Sexbound.Main.switchPosition( args.positionId )
  end)
  
  message.setHandler("main-switch-role", function(_,_,args)
    Sexbound.Main.switchRole()
  end)
  
  message.setHandler("main-sync-ui", function(_,_,args)
    local data = {}
    data.actors = {}
    
    for i,actor in ipairs(self.sexboundData.actors) do
      data.actors[i] = {}
      data.actors[i].climaxPoints = actor:climaxPoints()
      data.actors[i].maxClimaxPoints = actor:maxClimaxPoints()
    end
    
    return data
  end)
end

-- Initializes the moan sound effects.
function Sexbound.Main.initSoundEffects()
  self.sexboundData.animatorSound = {}

  if (animator.hasSound("climax")) then
    self.sexboundData.animatorSound.climax = {
      "/sfx/sexbound/cum/squish.ogg"
    }
    
    animator.setSoundPool("climax", self.sexboundData.animatorSound.climax)
  end

  if (animator.hasSound("femalemoan")) then
    self.sexboundData.animatorSound.femaleMoans = {
      "/sfx/sexbound/moans/femalemoan1.ogg",
      "/sfx/sexbound/moans/femalemoan2.ogg",
      "/sfx/sexbound/moans/femalemoan3.ogg",
      "/sfx/sexbound/moans/femalemoan4.ogg",
      "/sfx/sexbound/moans/femalemoan5.ogg"
    }
  
    animator.setSoundPool("femalemoan", self.sexboundData.animatorSound.femaleMoans)
  end
  
  if (animator.hasSound("malemoan")) then
    self.sexboundData.animatorSound.maleMoans = {
      "/sfx/sexbound/moans/malemoan1.ogg",
      "/sfx/sexbound/moans/malemoan2.ogg",
      "/sfx/sexbound/moans/malemoan3.ogg"
    }
    
    animator.setSoundPool("malemoan", self.sexboundData.animatorSound.maleMoans)
  end
end

--- Adjusts the animation rate of the animator.
-- @param dt
function Sexbound.Main.adjustTempo(dt)
  if Sexbound.Main.isClimaxing() or Sexbound.Main.isReseting() then
    self.sexboundData.animationRate = 1
    return
  end

  local position = Sexbound.Main.currentPosition()

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

--- Attempts to spawn a stored actor.
function Sexbound.Main.respawnNPC()
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


--[ ACTOR FUNCTIONS ]---------------------------------------------------------[ ACTOR FUNCTIONS ]--#

--- Stores the specified actor.
-- @param actor
-- @param storeActor
function Sexbound.Main.addActor(actor, storeActor)
  self.log:info("Storing new actor.")
  
  table.insert(self.sexboundData.actors, Sexbound.Actor.new( actor, storeActor ))
  
  self.sexboundData.actorCount = self.sexboundData.actorCount + 1

  Sexbound.Main.resetActors()
  
  if self.sexboundData.actorCount > 1 then self.sexboundData.status.havingSex = true end
end

--- Returns all actors.
function Sexbound.Main.getActors()
  return self.sexboundData.actors
end

function Sexbound.Main.getActorCount()
  return self.sexboundData.actorCount
end

--- Removes the specified actor.
-- @param actorId
function Sexbound.Main.removeActor(actorId)
  self.log:info("Removing actor.")

  Sexbound.Main.resetAllGlobalAnimatorTags()
  
  for i,actor in ipairs(self.sexboundData.actors) do
    if actor:id() == actorId then
      actor:uninit()
      
      table.remove(self.sexboundData.actors, i)
      
      self.sexboundData.actorCount = self.sexboundData.actorCount - 1
    end
  end
  
  Sexbound.Main.resetActors()
  
  if self.sexboundData.actorCount <= 1 then self.sexboundData.status.havingSex = false end
end

--- Resets all actors.
function Sexbound.Main.resetActors()
  for i,actor in ipairs(self.sexboundData.actors) do
    actor:reset(i, Sexbound.Main.currentPosition():getData())
  end
end

--- Resets all global animator tags for all actors.
function Sexbound.Main.resetAllGlobalAnimatorTags()
  for i,actor in ipairs(self.sexboundData.actors) do
    actor:resetGlobalAnimatorTags(i)
  end
end

--- Shifts the actors in actor data list to the right.
-- @param skipReset True := Skip reseting all actors.
function Sexbound.Main.switchRole()
  if Sexbound.Main.isHavingSex() and not Sexbound.Main.isClimaxing() and not Sexbound.Main.isReseting() then
    table.insert(self.sexboundData.actors, 1, table.remove(self.sexboundData.actors, #self.sexboundData.actors))
    
    Sexbound.Main.resetActors()
  end
end

--- Invokes the update method for all actors.
-- @param dt
function Sexbound.Main.updateActors(dt)
  for _,actor in ipairs(self.sexboundData.actors) do
    actor:update(dt)
  end
end

--[ NODE FUNCTIONS ]-----------------------------------------------------------[ NODE FUNCTIONS ]--#

--- Adds new node and tracks it as being this object.
function Sexbound.Main.becomeNode()
  table.insert(self.sexboundData.nodes, Sexbound.Node.new({0, 0}, false))
  
  self.sexboundData.nodeCount = self.sexboundData.nodeCount + 1
end

--- Creates a new node.
-- @param tilePosition
function Sexbound.Main.createNode(tilePosition)
  table.insert(self.sexboundData.nodes, Sexbound.Node.new( tilePosition, true ))
  
  self.sexboundData.nodeCount = self.sexboundData.nodeCount + 1
end

--- Uninitializes all nodes.
function Sexbound.Main.uninitNodes()
  while self.sexboundData.nodeCount > 0 do
    self.sexboundData.nodes[1]:uninit()
  
    table.remove(self.sexboundData.nodes, 1)
  
    self.sexboundData.nodeCount = self.sexboundData.nodeCount - 1
  end
end


--[ POSITION FUNCTIONS ]---------------------------------------------------[ POSITION FUNCTIONS ]--#

--- Initializes the defined positions.
function Sexbound.Main.initPositions()
  self.sexboundData.positions = {}
  
  -- Initialize idle positions.
  self.sexboundData.positions.idle = {}
  self.sexboundData.positions.idle.positionCount = 0
  self.sexboundData.positions.idle.positionIndex = 1
  
  for _,v in ipairs(Sexbound.Main.getParameter("position.idle")) do
    table.insert(self.sexboundData.positions.idle, Sexbound.Position.new(v))
    
    self.sexboundData.positions.idle.positionCount = self.sexboundData.positions.idle.positionCount + 1
  end
  
  -- Initialize sex positions.
  self.sexboundData.positions.sex = {}
  self.sexboundData.positions.sex.positionCount = 0
  self.sexboundData.positions.sex.positionIndex = 1
  
  for _,v in ipairs(Sexbound.Main.getParameter("position.sex")) do
    table.insert(self.sexboundData.positions.sex, Sexbound.Position.new(v))
    
    self.sexboundData.positions.sex.positionCount = self.sexboundData.positions.sex.positionCount + 1
  end
end

--- Returns a reference to the current position.
function Sexbound.Main.currentPosition()
  if Sexbound.Main.isHavingSex() then
    return self.sexboundData.positions.sex[self.sexboundData.positions.sex.positionIndex]
  else
    return self.sexboundData.positions.idle[self.sexboundData.positions.idle.positionIndex]
  end
end

--- Changes to the next position and returns it.
function Sexbound.Main.nextPosition()
  if Sexbound.Main.isHavingSex() then
    self.sexboundData.positions.sex.positionIndex = self.sexboundData.positions.sex.positionIndex + 1
    return Sexbound.Main.switchPosition(self.sexboundData.positions.sex.positionIndex)
  else
    self.sexboundData.positions.idle.positionIndex = self.sexboundData.positions.idle.positionIndex + 1
    return Sexbound.Main.switchPosition(self.sexboundData.positions.idle.positionIndex)
  end
end

--- Changes to the previous position and returns it.
function Sexbound.Main.previousPosition()
  if Sexbound.Main.isHavingSex() then
    self.sexboundData.positions.sex.positionIndex = self.sexboundData.positions.sex.positionIndex - 1
    return Sexbound.Main.switchPosition(self.sexboundData.positions.sex.positionIndex)
  else
    self.sexboundData.positions.idle.positionIndex = self.sexboundData.positions.idle.positionIndex - 1
    return Sexbound.Main.switchPosition(self.sexboundData.positions.idle.positionIndex)
  end
end

--- Switches to the specified position.
-- @param index
function Sexbound.Main.switchPosition( index )
  if Sexbound.Main.isHavingSex() and not Sexbound.Main.isClimaxing() and not Sexbound.Main.isReseting() then
    self.sexboundData.positions.sex.positionIndex = util.wrap(index, 1, self.sexboundData.positions.sex.positionCount)
    
    -- Set new animation state to match the position.
    animator.setAnimationState("main", self.sexboundData.positions.sex[self.sexboundData.positions.sex.positionIndex]:getData().animationState)
    
    -- Reset all actors.
    Sexbound.Main.resetActors()
    
    return self.sexboundData.positions.sex[self.sexboundData.positions.sex.positionIndex]:getData()
  end
  
  if not Sexbound.Main.isHavingSex() and not Sexbound.Main.isClimaxing() and not Sexbound.Main.isReseting() then
    return self.sexboundData.positions.idle[self.sexboundData.positions.idle.positionIndex]:getData()
  end
end


--[ STATUS FUNCTIONS ]-------------------------------------------------------[ STATUS FUNCTIONS ]--#

--- Returns the value for the specified status.
-- @param statusName
function Sexbound.Main.getStatus(statusName)
  return self.sexboundData.status[statusName]
end

--- Returns whether or not this object is having sex.
function Sexbound.Main.isHavingSex()
  return Sexbound.Main.getStatus("havingSex")
end

--- Returns whether or not this object is climaxing.
function Sexbound.Main.isClimaxing()
  return Sexbound.Main.getStatus("climaxing")
end

--- Returns whether or not this object is reseting.
function Sexbound.Main.isReseting()
  return Sexbound.Main.getStatus("reseting")
end

--- Sets the specified status name as the specified boolean value.
function Sexbound.Main.setStatus(statusName, value)
  self.sexboundData.status[statusName] = value 
end
