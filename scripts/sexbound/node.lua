--- Node Module.
-- @module Sexbound.Node
Sexbound.Node = {}
Sexbound.Node.__index = Sexbound.Node

function Sexbound.Node.new(...)
  local self = setmetatable({nodeName = "sexbound_node_node", node = {controllerId = entity.id()}}, Sexbound.Node)
  self:init(...)
  return self
end

--- Initializes this instance.
function Sexbound.Node:init(tilePosition, placeObject)
  tilePosition = tilePosition or {0,0}

  self.node.tilePosition = vec2.floor(vec2.add(entity.position(), tilePosition))

  if placeObject then
    self:create(self.node.tilePosition)
  else
    self.node.id = self.node.controllerId
  end
end

--- Attempt to place a new sexbound node object at specified tile position.
-- @param tilePosition
function Sexbound.Node:create(tilePosition)
  local params = {
    controllerId = self.node.controllerId
  }

  local objectNodeId = world.objectAt(tilePosition)

  if objectNodeId and world.entityName(objectNodeId) == self.nodeName then
    -- Sync the existing node with the main controller.
    Sexbound_Util.sendMessage(objectNodeId, "node-sync-main", params)
  else
    -- Attempt to place new node.
    world.placeObject(self.nodeName, tilePosition, object.direction(), params)
  end
end

--- Returns the entityId for this node.
function Sexbound.Node:id()
  if not self.node.id then
    local objectNodeId = world.objectAt(self.node.tilePosition)
    
    if objectNodeId and world.entityName(objectNodeId) == self.nodeName then
      self.node.id = objectNodeId
    end
  end
  
  return self.node.id
end

--- Sends "sexbound_lounge" message to interacting entity (player).
-- @param entityId
function Sexbound.Node:lounge(entityId)
  Sexbound_Util.sendMessage(entityId, "sexbound-lounge", {controllerId = entity.id(), loungeId = self:id()})
end

--- Returns whether or not this node is occupied.
function Sexbound.Node:occupied()
  return world.loungeableOccupied(self:id())
end

--- Uninitializes this instance.
function Sexbound.Node:uninit()
  if self:id() then
    Sexbound_Util.sendMessage(self:id(), "node-uninit")
  end
end