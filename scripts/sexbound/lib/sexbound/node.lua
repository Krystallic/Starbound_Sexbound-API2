--- Sexbound.Node Class Module.
-- @classmod Sexbound.Node
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Node = {}
Sexbound.Node_mt = {__index = Sexbound.Node}

--- Instantiates a new instance of Node.
-- @param parent
-- @param tilePosition
-- @param sitPosition
-- @param placeObject
function Sexbound.Node.new(parent, tilePosition, sitPosition, placeObject)
  local self = setmetatable({
    _controllerId = parent:getEntityId(),
    _logPrefix    = "NODE",
    _name         = "sexbound_node_node",
    _sitPosition  = sitPosition or {0, 0},
    _parent       = parent,
    _placeObject  = placeObject,
    _respawnTimer = 0,
    _respawnTime  = 5
  }, Sexbound.Node_mt)
  
  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
  
  -- Adjust sit position based on object's facing direction
  self._sitPosition[1] = self._sitPosition[1] * object.direction()
  
  tilePosition = tilePosition or {0,0}

  self._tilePosition = vec2.floor(vec2.add(entity.position(), tilePosition))

  if not self._placeObject then
    self:setEntityId(self._controllerId) 
  end
  
  return self 
end

function Sexbound.Node:update(dt)
  if not self._placeObject then return end
  
  self._respawnTimer = self._respawnTimer + dt
  
  if self._respawnTimer >= self._respawnTime then
    local uniqueId = self:getUniqueId()

    if not uniqueId or world.findUniqueEntity(uniqueId):result() == nil then
      self:create()
    end
    
    self._respawnTimer = 0
  end
end

function Sexbound.Node:getLog()
  return self._log
end

function Sexbound.Node:getLogPrefix()
  return self._logPrefix
end

function Sexbound.Node:getParent()
  return self._parent
end

--- Place a new sexbound node object at specified tile position.
-- @param tilePosition
function Sexbound.Node:create()
  local uniqueId = sb.makeUuid()

  local params = {
    sitPosition  = self._sitPosition,
    controllerId = self._controllerId,
    uniqueId     = uniqueId
  }
  
  if world.placeObject(self._name, self._tilePosition, object.direction(), params) then
    self._uniqueId = uniqueId
  end
end

--- Returns the entityId for this node.
function Sexbound.Node:getEntityId()
  return self._entityId
end

function Sexbound.Node:setEntityId(entityId)
  self._entityId = entityId
end

function Sexbound.Node:getControllerId()
  return self._controllerId
end

--- Returns the uniqueId for this Node's object.
function Sexbound.Node:getUniqueId()
  return self._uniqueId
end

function Sexbound.Node:setUniqueId(uniqueId)
  self._uniqueId = uniqueId
end

--- Sends "sexbound_lounge" message to interacting entity (player).
-- @param entityId
function Sexbound.Node:lounge(entityId)
  local playerId = entityId
  local entityId = self:getEntityId()
  
  if entityId then
    local controllerId = self:getControllerId()
  
    Sexbound.Util.sendMessage(playerId, "sexbound-lounge", {
      controllerId = controllerId,
      loungeId     = entityId
    })
  end
end

--- Returns whether or not this node is occupied.
function Sexbound.Node:occupied()
  local entityId = self:getEntityId()

  if entityId and world.entityExists(entityId) then
    return world.loungeableOccupied(entityId)
  end
  
  return true
end

--- Uninitializes this instance.
function Sexbound.Node:uninit()
  local msgId = self:getUniqueId() or self:getEntityId()
  
  if msgId then
    Sexbound.Util.sendMessage(msgId, "sexbound-node-uninit")
  end
end
