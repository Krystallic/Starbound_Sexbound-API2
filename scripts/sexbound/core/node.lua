--- Sexbound.Core.Node Class Module.
-- @classmod Sexbound.Core.Node
Sexbound.Core.Node = {}
Sexbound.Core.Node.__index = Sexbound.Core.Node

--- Instantiates a new instance of Node.
-- @param tilePosition
-- @param placeObject
function Sexbound.Core.Node.new(tilePosition, placeObject)
  local self = setmetatable({nodeName = "sexbound_node_node", node = {controllerId = entity.id()}}, Sexbound.Core.Node)

  tilePosition = tilePosition or {0,0}

  self.node.tilePosition = vec2.floor(vec2.add(entity.position(), tilePosition))
  self.node.placeObject = placeObject
  
  if placeObject then
    self:create(self.node.tilePosition)
  else
    self.node.id = self.node.controllerId
  end
  
  return self
end

--- Updates this instance.
-- @param dt
function Sexbound.Core.Node:update(dt)
 if self.node.placeObject and not self:exists() then
   self:create(self.node.tilePosition)
 end
end

--- Attempt to place a new sexbound node object at specified tile position.
-- @param tilePosition
function Sexbound.Core.Node:create(tilePosition)
  self.node.uniqueId = sb.makeUuid()

  local params = {
    controllerId = self.node.controllerId,
    uniqueId = self.node.uniqueId
  }
  
  if not world.objectAt(tilePosition) then
    world.placeObject(self.nodeName, tilePosition, object.direction(), params)
  end
end

function Sexbound.Core.Node:exists()
  local entityId = world.objectAt(self.node.tilePosition)
  
  if entityId then
    return self.node.uniqueId == world.entityUniqueId(entityId)
  end
end

--- Returns the entityId for this node.
function Sexbound.Core.Node:id()
  local entityId = world.objectAt(self.node.tilePosition)
  
  if entityId and world.entityName(entityId) == self.nodeName then
    self.node.id = entityId
  end
  
  return self.node.id
end

--- Returns the uniqueId for this Node's object.
function Sexbound.Core.Node:uniqueId()
  return self.node.uniqueId
end

--- Sends "sexbound_lounge" message to interacting entity (player).
-- @param entityId
function Sexbound.Core.Node:lounge(entityId)
  Sexbound.API.Util.sendMessage(entityId, "sexbound-lounge", {controllerId = entity.id(), loungeId = self:id()})
end

--- Returns whether or not this node is occupied.
function Sexbound.Core.Node:occupied()
  return world.loungeableOccupied(self:id())
end

--- Uninitializes this instance.
function Sexbound.Core.Node:uninit()
  if self:id() then
    Sexbound.API.Util.sendMessage(self:id(), "node-uninit")
  end
end