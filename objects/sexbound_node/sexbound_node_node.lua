require "/scripts/sexbound/util.lua"

function init()
  -- A sex node should always smash itself on the subsequent init.
  if storage.smashOnInit then
    self.isSmashing = true
    
    object.smash(true)
    return
  end
  
  storage.smashOnInit = true

  -- The 'controllerId' parameter has been set when this object is placed.
  self.controllerId = config.getParameter("controllerId")
  
  self.sendEntityId = false
  
  -- Makes this object interactive when the 'interactive' parameter is true.
  object.setInteractive(config.getParameter("interactive", false))
  
  -- Handle Setup Actor
  message.setHandler("sexbound-setup-actor", function(_,_,args)
    Sexbound.Util.sendMessage(self.controllerId, "sexbound-setup-actor", args)
  end)
  
  -- Handle Remove Actor
  message.setHandler("sexbound-remove-actor", function(_,_,args)
    Sexbound.Util.sendMessage(self.controllerId, "sexbound-remove-actor", args)
  end)
  
    -- Handle Uninit Node
  message.setHandler("sexbound-node-uninit", function(_,_,args)
    object.smash(true)
  end)
end

function update(dt)
  if self.isSmashing then return end

  if not self.sendEntityId then
    Sexbound.Util.sendMessage(self.controllerId, "sexbound-node-init", {
      entityId = entity.id(),
      uniqueId = entity.uniqueId()
    })
    
    self.sendEntityId = true
  end
end

-- The node is preparing to be removed from the world
function die()
  -- Placeholder
end

-- The node has been removed from the world
function uninit()
  Sexbound.Util.sendMessage(self.controllerId, "sexbound-node-uninit", {
    entityId = entity.id(),
    uniqueId = entity.uniqueId()
  })
end