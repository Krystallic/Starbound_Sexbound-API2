--- Sexbound.Node Class Module.
-- @classmod Sexbound.Node
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Node = {}
Sexbound.Node_mt = {__index = Sexbound.Node}

--- Instantiates a new instance of Node.
-- @param parent
-- @param tilePosition
-- @param placeObject
function Sexbound.Node.new(parent, tilePosition, placeObject)
  local self = setmetatable({
    _controllerId = parent:getEntityId(),
    _controllerUniqueId = parent:getUniqueId(),
    _logPrefix    = "NODE",
    _name         = "sexbound_node_node",
    _parent       = parent,
    _placeObject  = placeObject
  }, Sexbound.Node_mt)

  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
  
  tilePosition = tilePosition or {0,0}

  self._tilePosition = vec2.floor(vec2.add(entity.position(), tilePosition))

  if self._placeObject then
    self:create(self._tilePosition)
  else
    self._id = self._controllerId
  end
  
  return self
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

--- Updates this instance.
-- @param dt
function Sexbound.Node:update(dt)
 if self._placeObject and not self:exists() then
   self:create(self._tilePosition)
 end
end

--- Attempt to place a new sexbound node object at specified tile position.
-- @param tilePosition
function Sexbound.Node:create(tilePosition)
  self._uniqueId = sb.makeUuid()

  local params = {
    controllerId = self._controllerUniqueId,
    uniqueId     = self._uniqueId
  }
  
  if not world.objectAt(tilePosition) then
    world.placeObject(self._name, tilePosition, object.direction(), params)
  end
end

function Sexbound.Node:exists()
  local entityId = world.objectAt(self._tilePosition)
  
  if entityId then
    return self._uniqueId == world.entityUniqueId(entityId)
  end
end

--- Returns the entityId for this node.
function Sexbound.Node:id()
  local entityId = world.objectAt(self._tilePosition)
  
  if entityId and world.entityName(entityId) == self._name then
    self._id = entityId
  end
  
  return self._id
end

--- Returns the uniqueId for this Node's object.
function Sexbound.Node:getUniqueId()
  return self._uniqueId
end

--- Sends "sexbound_lounge" message to interacting entity (player).
-- @param entityId
function Sexbound.Node:lounge(entityId)
  Sexbound.Util.sendMessage(entityId, "sexbound-lounge", {
    controllerId = entity.id(),
    loungeId     = self:id()
  })
end

--- Returns whether or not this node is occupied.
function Sexbound.Node:occupied()
  return world.loungeableOccupied(self:id())
end

--- Uninitializes this instance.
function Sexbound.Node:uninit()
  if self:id() then
    Sexbound.Util.sendMessage(self:id(), "sexbound-node-uninit")
  end
end
