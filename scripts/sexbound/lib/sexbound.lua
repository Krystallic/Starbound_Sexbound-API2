--- Sexbound Class Module.
-- @classmod Sexbound
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound = {}
Sexbound_mt = { __index = Sexbound }

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/util.lua"

require "/scripts/sexbound/lib/sexbound/actor.lua"
require "/scripts/sexbound/lib/sexbound/log.lua"
require "/scripts/sexbound/lib/sexbound/node.lua"
require "/scripts/sexbound/lib/sexbound/messenger.lua"
require "/scripts/sexbound/lib/sexbound/positions.lua"
require "/scripts/sexbound/lib/sexbound/statemachine.lua"

--- Returns a reference to a new instance of this class.
function Sexbound:new()
  local self = setmetatable({
    _logPrefix = "MAIN",
    _actors = {},
    _actorCount = 0,
    _animationRate = 1,
    _nodes = {},
    _nodeCount = 0
  }, Sexbound_mt)
  
  -- Sets this object to be interactive when its interactive configuration parameter is set to true.
  object.setInteractive(config.getParameter("interactive", false))
  
  -- Load global config
  self._config = self:loadConfig()
  
  -- Initialize new instance of Log
  self._log = Sexbound.Log:new ( self._logPrefix, self._config )
  
  -- Create new messenger using 'main' channel
  Sexbound.Messenger.new("main")
  
  -- Add self as message broadcast recipient
  Sexbound.Messenger.get("main"):addBroadcastRecipient(self)
  
  -- Initialize new instance of StateMachine
  self._stateMachine = Sexbound.StateMachine.new( self )

  -- Initialize new instance of Positions (After state machine)
  self._positions = Sexbound.Positions.new( self )

  self:initMessageHandlers()
  
  local flipped = self:getConfig().animation.flipped or false
  
  if flipped and animator.hasTransformationGroup("actors") then
    animator.scaleTransformationGroup("actors", {-1, 1}, {0, 0})
  end
  
  self:getLog():info("Init. Object: " .. object.name())
  
  return self
end

--- Updates this instance.
-- @param dt The delta time.
function Sexbound:update(dt)
  -- Update the state machine
  self:getStateMachine():update(dt)

  -- Dispatch queued messages on the 'main' channel
  Sexbound.Messenger.get("main"):dispatch()

  -- Update each node 
  self:updateNodes(dt)
end

--- Handles message event.
-- @param message
function Sexbound:onMessage(message)
  if message:getType() == "Sexbound:AddActor" then
    self:resetAllActors()
  
    -- Automatically shift actor roles based on gender preference
    if self:getActorCount() == 2 then
      if self._actors[1]:getGender() == "female" and self._actors[2]:getGender() == "male" then
        self:switchActorRoles()
      end
    end
  end
  
  if message:getType() == "Sexbound:RemoveActor" then
    self:resetAllActors()
  end
  
  if message:getType() == "Sexbound:Positions:SwitchPosition" then
    self:resetAllActors()
  end
  
  if message:getType() == "Sexbound:SwitchRoles" then
    self:resetAllActors()
  end
end

--- Adds a new instance of Actor to the actors table.
-- @param actorConfig
-- @param store
function Sexbound:addActor(actorConfig, store)
  self._actorCount = self._actorCount + 1

  local actor = Sexbound.Actor:new(self, actorConfig)
  
  actor:setRole(self._actorCount)
  
  if store then storage.actor = actor:getConfig() end
  
  self:getLog():info("Adding Actor: " .. actor:getName())
  
  table.insert(self._actors, actor)

  Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:AddActor", {}, true)
end

--- Adds a new instance of Node to the nodes table.
-- @param tilePosition
-- @param sitPosition
function Sexbound:addNode(tilePosition, sitPosition)
  local node = Sexbound.Node.new( self, tilePosition, sitPosition, true )

  table.insert(self._nodes, node)
  
  self._nodeCount = self._nodeCount + 1
  
  self._nodes[self._nodeCount]:create()
end

--- Adds a new instance of Node to the nodes table and tracks it as being this object.
-- @param sitPosition
function Sexbound:becomeNode(sitPosition)
  local tilePosition = {0, 0}

  table.insert(self._nodes, Sexbound.Node.new( self, tilePosition, sitPosition, false ))
  
  self._nodeCount = self._nodeCount + 1
end

--- Handles a player interaction request.
-- @param args interact arguments
function Sexbound:handleInteract(args)
  -- Lounge-in next available node.
  for _,node in ipairs(self._nodes) do
    if not node:occupied() then
      node:lounge(args.sourceId)
      
      local config = root.assetJson( "/interface/sexbound/default.config" )
    
      config.config.controllerId = self:getEntityId()
    
      local positions = self:getPositions():getPositions()
      
      util.each(positions, function(index, position)
        local name        = position:getFriendlyName()
        local buttonImage = position:getButtonImage()
        config.config.buttons[index].name = name
        config.config.buttons[index].image = buttonImage
      end)
    
      self:getLog():info(config)
    
      return {"ScriptPane", config}
    end
  end
end

--- Initializes message handlers.
function Sexbound:initMessageHandlers()
  message.setHandler("sexbound-climax", function(_,_,args)
    local actor = self._actors[args.actorId]
    local climaxPlugin = actor:getPlugins("climax")
  
    Sexbound.Messenger.get("main"):send(self, climaxPlugin, "Sexbound:Climax:BeginClimax", {})
  end)
  
  message.setHandler("sexbound-node-init", function(_,_,args)
    local nodes    = self:getNodes()
    local entityId = args.entityId
    local uniqueId = args.uniqueId
    
    for _,node in ipairs(nodes) do
      if node:getUniqueId() == uniqueId then
        node:setEntityId(entityId)
      end
    end
  end)
  
  message.setHandler("sexbound-node-uninit", function(_,_,args)
    local nodes    = self:getNodes()
    local entityId = args.entityId
    local uniqueId = args.uniqueId
  
    util.each(self:getNodes(), function(index, node)
      if node:getUniqueId() == uniqueId then
        node:uninit()
      end
    end)
  end)
  
  message.setHandler("sexbound-remove-actor", function(_,_,args)
    self:removeActor(args)
  end)

  message.setHandler("sexbound-setup-actor", function(_,_,args)
    self:addActor(args, false)
  end)
  
  message.setHandler("sexbound-store-actor", function(_,_,args)
    self:addActor(args, true)
  end)
  
  message.setHandler("sexbound-switch-role", function(_,_,args)
    self:switchActorRoles()
  end)
  
  message.setHandler("sexbound-sync-ui", function(_,_,args)
    local data = {}
    data.actors = {}
    
    for _,actor in ipairs(self._actors) do
      table.insert(data.actors, {
        climax = {
          currentPoints = actor:getPlugins("climax"):getCurrentPoints(),
          maxPoints     = actor:getPlugins("climax"):getMaxPoints()
        }
      })
    end
    
    return data
  end)
end

--- Returns a reference to the running configuration.
function Sexbound:loadConfig()
  local _globalConfig = {}

  local _config = root.assetJson("/sexbound.config") or {}

  -- Overwrite global configuration with local mod's configuration
  _globalConfig = util.mergeTable(_config, config.getParameter("sexboundConfig", {}))

  return _globalConfig
end

--- Removes the specified Actor instance from the actors table.
-- @param entityId
function Sexbound:removeActor(entityId)
  Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:PrepareRemoveActor", {}, true)

  for i,actor in ipairs(self._actors) do
    actor:resetTransformations()
  
    actor:resetGlobalAnimatorTags()
  end

  for i,actor in ipairs(self._actors) do
    if entityId == actor:getEntityId() then
      actor:uninit()
    
      table.remove(self._actors, i)
      
      self._actorCount = self._actorCount - 1
      
      Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:RemoveActor", {}, true)
    end
  end
end

--- Resets all instances of Actor in the actors table.
-- @param stateName
function Sexbound:resetAllActors(stateName)
  for i,actor in ipairs(self._actors) do
    actor:setActorNumber(i)
    
    actor:setRole(i)
    
    actor:reset(stateName)
  end
end

--- Respawns the stored actor if it exists in this object's storage.
function Sexbound:respawnStoredActor()
  -- Respawn stored actor.
  if storage.actor then
    local uniqueId = storage.actor.uniqueId
    
    if uniqueId and world.findUniqueEntity(uniqueId):result() ~= nil then return end

    -- Message the actor's respawner that it is turning back into an NPC.
    if storage.actor.storage.respawner then
      world.sendEntityMessage(storage.actor.storage.respawner, "transform-into-npc", {uniqueId = uniqueId})
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
    if (uniqueId) then
      parameters.scriptConfig = {
        uniqueId = uniqueId
      }
    end
    
    local position = vec2.add(object.position(), {0, 3})
    local species = storage.actor.identity.species
    local entityType = storage.actor.type
    local level = storage.actor.level
    local seed = storage.actor.seed
    
    world.spawnNpc(position, species, entityType, level, seed, parameters)
  end
end

--- Shifts all actors in the actors table one element to the right.
function Sexbound:switchActorRoles()
  if not self:getStateMachine():isClimaxing() then
    self:getLog():info("Actors are switching roles.")
    
    table.insert(self._actors, 1, table.remove(self._actors, #self._actors))
    
    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:SwitchRoles", {}, true)
  end
end

--- Updates the animation rate of the animator based on the delta time.
-- @param dt The delta time
function Sexbound:updateAnimationRate(dt)
  self._animationRate = self._animationRate + ( self:getPositions():getMaxTempo() / (self:getPositions():getSustainedInterval() / dt))
  
  self._animationRate = util.clamp(self._animationRate, self:getPositions():getMinTempo(), self:getPositions():getMaxTempo())
  
  -- Set the animator's animation rate
  animator.setAnimationRate(self._animationRate)
  
  if (self._animationRate >= self:getPositions():getMaxTempo()) then
    self._animationRate = self:getPositions():nextMinTempo()
    
    self:getPositions():nextMaxTempo()
      
    self:getPositions():nextSustainedInterval()
  end
end

--- Updates each node in this instance's nodes table.
function Sexbound:updateNodes(dt)
  local nodes = self:getNodes()
  
  for _,node in ipairs(nodes) do
    node:update(dt)
  end
end

--- Uninitializes this instance.
function Sexbound:uninit()
  self:getLog():info("Uniniting..")
  
  self:uninitActors()
  
  self:uninitNodes()
end

--- Uninitializes each instance of Actor in the actors table.
function Sexbound:uninitActors()
  self:getLog():info("Uniniting Actors.")

  local actors = self:getActors()
  
  for _,actor in ipairs(actors) do
    actor:uninit()
  end
  
  self._actors = {}
  self._actorCount = 0
end

--- Uninitializes each instance of Node in the nodes table.
function Sexbound:uninitNodes()
  self:getLog():info("Uniniting Nodes.")

  local nodes  = self:getNodes()
  
  for _,node in ipairs(nodes) do
    node:uninit()
  end
  
  self._nodes = {}
  self._nodeCount = 0
end

-- Getters / Setters

--- Returns a reference to this instance's actors table.
function Sexbound:getActors()
  return self._actors
end

--- Sets this instance's actors table to a specified table.
-- @param newActors
function Sexbound:setActors(newActors)
  self._actors = newActors
end

--- Returns the current count of actors in the actors table.
function Sexbound:getActorCount()
  return self._actorCount
end

--- Sets this instances' current actor count.
-- @param newCount
function Sexbound:setActorCount(newCount)
  self.actorCount = newCount
end

--- Returns that current animation rate for this object's animator.
function Sexbound:getAnimationRate()
  return self._animationRate
end

--- Sets the animation rate for this object's animator.
-- @param value
function Sexbound:setAnimationRate(value)
  self._animationRate = value
end

--- Returns a reference to this instance's running configuration.
function Sexbound:getConfig()
  return self._config
end

--- Returns this object's entityId.
function Sexbound:getEntityId()
  return entity.id()
end

--- Returns a reference to the current default langauge.
function Sexbound:getLanguage()
  return self:getConfig().sex.defaultLanguage
end

--- Returns a reference to the current language settings.
function Sexbound:getLanguageSettings()
  return self:getConfig().sex.supportedLanguages[self:getLanguage()]
end

--- Returns a reference to this instance's log utility.
function Sexbound:getLog()
  return self._log
end

--- Returns this instance's log prefix.
function Sexbound:getLogPrefix()
  return self._logPrefix
end

--- Returns a reference to this instance's nodes table.
function Sexbound:getNodes()
  return self._nodes
end

--- Sets this instance's nodes table to a specified table.
-- @param newNodes
function Sexbound:setNodes(newNodes)
  self._nodes = newNodes
end

--- Returns the current count of nodes in the nodes table.
function Sexbound:getNodeCount()
  return self._nodeCount
end

--- Sets this instances' current node count.
-- @param newCount
function Sexbound:setNodeCount(newCount)
  self._nodeCount = newCount
end

--- Returns a reference to this instance's Positions component.
function Sexbound:getPositions()
  return self._positions
end

--- Returns a reference to this instance's State Machine component.
function Sexbound:getStateMachine()
  return self._stateMachine
end