--- Node Module.
-- @module Node
Sexbound.Node = {}
Sexbound.Node.__index = Sexbound.Node

function Sexbound.Node.new(...)
  local self = setmetatable({nodeName = "sexbound_node_node", node = {controllerId = entity.id()}, isOccupied = false}, Sexbound.Node)
  self:init(...)
  return self
end

function Sexbound.Node:init(tilePosition)
  self.node.tilePosition = vec2.floor(vec2.add(entity.position(), tilePosition))

  self:create(self.node.tilePosition)
end

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

function Sexbound.Node:id()
  if not self.node.id then
    local objectNodeId = world.objectAt(self.node.tilePosition)
    
    if objectNodeId and world.entityName(objectNodeId) == self.nodeName then
      self.node.id = objectNodeId
    end
  end
  
  return self.node.id
end

function Sexbound.Node:lounge(entityId)
  Sexbound_Util.sendMessage(entityId, "sexbound-lounge", {loungeId = self:id()})
end

function Sexbound.Node:occupied()
  return self.isOccupied
end

function Sexbound.Node:uninit()
  if self:id() then
    Sexbound_Util.sendMessage(self:id(), "node-uninit")
  end
end