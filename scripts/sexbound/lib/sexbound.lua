--- Sexbound Class Module.
-- @classmod Sexbound
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound = {}
Sexbound_mt = { __index = Sexbound }

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/lib/sexbound/actor.lua"
require "/scripts/sexbound/lib/sexbound/log.lua"
require "/scripts/sexbound/lib/sexbound/node.lua"
require "/scripts/sexbound/lib/sexbound/messenger.lua"
require "/scripts/sexbound/lib/sexbound/positions.lua"
require "/scripts/sexbound/lib/sexbound/statemachine.lua"
require "/scripts/sexbound/lib/sexbound/util.lua"

--- Returns a reference to a new instance of this class.
function Sexbound:new()
  local self = setmetatable({
    _logPrefix = "MAIN",
    _actors = {},
    _actorCount = 0,
    _animationRate = 1,
    _entityId = entity.id(),
    _nodes = {},
    _nodeCount = 0
  }, Sexbound_mt)
  
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
  
  return self
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

function Sexbound:update(dt, callback)
  -- Dispatch delayed messages on the 'main' channel
  Sexbound.Messenger.get("main"):dispatch()

  -- Update the state machine
  self:getStateMachine():update(dt)
  
  if type(callback) == "function" then
    callback()
  end
end

function Sexbound:addActor(actor, store)
  self._actorCount = self._actorCount + 1

  local actor = Sexbound.Actor:new(self, actor)
  
  if store then storage.actor = actor:getConfig() end
  
  self:getLog():info("Adding Actor: " .. actor:getName())
  
  table.insert(self._actors, actor)

  Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:AddActor", {}, false)
end

function Sexbound:addNode(tilePosition)
  table.insert(self._nodes, Sexbound.Node.new( self, tilePosition, true ))
  
  self._nodeCount = self._nodeCount + 1
end

--- Adds new node and tracks it as being this object.
function Sexbound:becomeNode()
  table.insert(self._nodes, Sexbound.Node.new(self, {0, 0}, false))
  
  self._nodeCount = self._nodeCount + 1
end

--- Handles a player interaction request.
-- @param args interact arguments
-- @usage function onInteraction(args) Sexbound.handleInteract(args) end
function Sexbound:handleInteract(args)
  -- Lounge-in next available node.
  for _,node in ipairs(self._nodes) do
    if not node:occupied() then
      node:lounge(args.sourceId)
      return
    end
  end
end

function Sexbound:initMessageHandlers()
  message.setHandler("sexbound-climax", function(_,_,args)
    local actor = self._actors[args.actorId]
    local climaxPlugin = actor:getPlugins("climax")
  
    Sexbound.Messenger.get("main"):send(self, climaxPlugin, "Sexbound:Climax:BeginClimax", {})
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

--- Returns loaded global configuration as a table.
function Sexbound:loadConfig()
  local _globalConfig = {}

  local _config = root.assetJson("/sexbound.config") or {}

  -- Overwrite global configuration with local mod's configuration
  _globalConfig = util.mergeTable(_config, config.getParameter("sexboundConfig", {}))

  return _globalConfig
end

function Sexbound:removeActor(entityId)
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

--- Resets all actors.
function Sexbound:resetAllActors()
  for i,actor in ipairs(self._actors) do
    actor:setActorNumber(i)
    
    actor:setRole(i)
    
    actor:reset()
  end
end

function Sexbound:respawnStoredActor()
  -- Respawn stored actor.
  if storage.actor then
    local position = vec2.add(object.position(), {0, 3})
    
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

--- Shifts all actors right by one element.
function Sexbound:switchActorRoles()
  if not self:getStateMachine():isClimaxing() then
    self:getLog():info("Actors are switching roles.")
    
    table.insert(self._actors, 1, table.remove(self._actors, #self._actors))
    
    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:SwitchRoles", {}, true)
  end
end

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

function Sexbound:uninit()
  while self._nodeCount > 0 do
    self._nodes[1]:uninit()
  
    table.remove(self._nodes, 1)
  
    self._nodeCount = self._nodeCount - 1
  end
end

-- Getters / Setters

function Sexbound:getActors()
  return self._actors
end

function Sexbound:setActors(newActors)
  self._actors = newActors
end

function Sexbound:getActorCount()
  return self._actorCount
end

function Sexbound:setActorCount(newCount)
  self.actorCount = newCount
end

function Sexbound:getAnimationRate()
  return self._animationRate
end

function Sexbound:setAnimationRate(value)
  self._animationRate = value
end

function Sexbound:getConfig()
  return self._config
end

function Sexbound:getEntityId()
  return self._entityId
end

function Sexbound:getLanguage()
  return self:getConfig().sex.defaultLanguage
end

function Sexbound:getLanguageSettings()
  return self:getConfig().sex.supportedLanguages[self:getLanguage()]
end

function Sexbound:getLog()
  return self._log
end

function Sexbound:getLogPrefix()
  return self._logPrefix
end

function Sexbound:getNodes()
  return self._nodes
end

function Sexbound:setNodes(newNodes)
  self._nodes = newNodes
end

function Sexbound:getNodeCount()
  return self._nodeCount
end

function Sexbound:setNodeCount(newCount)
  self._nodeCount = newCount
end

function Sexbound:getPositions()
  return self._positions
end

function Sexbound:getStateMachine()
  return self._stateMachine
end