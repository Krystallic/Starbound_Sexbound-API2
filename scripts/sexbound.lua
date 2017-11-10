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
  
  -- Initialize empty table for nodes
  self.sexboundData.nodes = {}
  self.sexboundData.nodeCount = 0
  
  -- Initialize empty table for positions
  self.sexboundData.positions = {}
  self.sexboundData.positionCount = 0
  self.sexboundData.positionIndex = 1
  
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

  -- Update the state machine
  self.stateMachine:update(dt)
end

--- Returns a reference to stored Sexbound configuration.
function Sexbound.Main.getConfig()
  return self.sexboundData.config
end

--- Returns the value for the specified parameter.
-- @param paramater string value with periods to separate parameters.
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
  message.setHandler("main-remove-actor", function(_, _, args)
    Sexbound.Main.removeActor(args)
  end)

  message.setHandler("main-setup-actor", function(_, _, args)
    Sexbound.Main.addActor(args, false)
  end)
  
  message.setHandler("main-store-actor", function(_, _, args)
    Sexbound.Main.addActor(args, true)
  end)
  
  message.setHandler("main-switch-position", function(_, _, args)
    Sexbound.Main.switchPosition( args.positionId )
  end)
  
  message.setHandler("main-switch-role", function(_,_,args)
    Sexbound.Main.switchRole()
  end)
  
  message.setHandler("main-sync-ui", function(_, _, args)
  
  end)
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
    
    local parameters = {
      statusControllerSettings = {
        statusProperties = {
          sexboundPrevStorage = storage.actor.storage
        }
      }
    }
    
    if (storage.actor.uniqueId and not world.findUniqueEntity(storage.actor.uniqueId):result()) then
      parameters.scriptConfig = {}
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
    actor:reset(i, Sexbound.Main.currentPosition())
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
  for _,v in ipairs(Sexbound.Main.getParameter("position")) do
    table.insert(self.sexboundData.positions, Sexbound.Position.new(v))
    
    self.sexboundData.positionCount = self.sexboundData.positionCount + 1
  end
end

--- Returns a reference to the current position.
function Sexbound.Main.currentPosition()
  -- If having sex is true, then return a position.
  if self.sexboundData.status.havingSex then
    return self.sexboundData.positions[self.sexboundData.positionIndex]:getData()
  end
  
  -- if not having sex then return idle position.
  return {animationState = Sexbound.Main.getParameter("animationStateIdle")}
end

--- Changes to the next position and returns it.
function Sexbound.Main.nextPosition()
  self.sexboundData.positionIndex = self.sexboundData.positionIndex + 1
  
  return Sexbound.Main.switchPosition(self.sexboundData.positionIndex)
end

--- Changes to the previous position and returns it.
function Sexbound.Main.previousPosition()
  self.sexboundData.positionIndex = self.sexboundData.positionIndex - 1
  
  return self.sexboundData.positions[self.sexboundData.positionIndex]:getData()
end

--- Switches to the specified position.
-- @param index
function Sexbound.Main.switchPosition( index )
  if Sexbound.Main.isHavingSex() and not Sexbound.Main.isClimaxing() and not Sexbound.Main.isReseting() then
    self.sexboundData.positionIndex = util.wrap(index, 1, self.sexboundData.positionCount)
    
    -- Set new animation state to match the position.
    animator.setAnimationState("sex", Sexbound.Main.currentPosition().animationState)
    
    -- Reset all actors.
    Sexbound.Main.resetActors()
  end
  
  return self.sexboundData.positions[self.sexboundData.positionIndex]:getData()
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
