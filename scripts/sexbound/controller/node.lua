--- NodeController Module.
-- @module NodeController

NodeController = {}

require "/scripts/sexbound/util.lua"

function NodeController.init()
  object.setInteractive(config.getParameter("interactive", false))

  NodeController.initMessageHandlers()
end

function NodeController.destroy()
  if object then object.smash(true) end
end

function NodeController.initMessageHandlers()
  -- Relay "main-remove-actor" message to the controller.
  message.setHandler("node-remove-actor", function(_, _, args)
    self.controllerId = self.controllerId or config.getParameter("controllerId") or entity.id()
    
    Sexbound_Util.sendMessage(self.controllerId, "main-remove-actor", args)
  end)
  
  -- Relay "main-setup-actor" message to the controller.
  message.setHandler("node-setup-actor", function(_, _, args)
    self.controllerId = self.controllerId or config.getParameter("controllerId") or entity.id()
  
    Sexbound_Util.sendMessage(self.controllerId, "main-setup-actor", args)
  end)
  
  -- Relay "main-store-actor" message to the controller.
  message.setHandler("node-store-actor", function(_, _, args)
    self.controllerId = self.controllerId or config.getParameter("controllerId") or entity.id()
    
    Sexbound_Util.sendMessage(self.controllerId, "main-store-actor", args)
  end)
  
  -- Relay "main-switch-position" message to the controller.
  message.setHandler("node-switch-position", function(_, _, args)
    Sexbound_Util.sendMessage(self.controllerId, "main-switch-position", args)
  end)
  
  -- Relay "main-switch-role" message to the controller.
  message.setHandler("node-switch-role", function(_, _, args)
    Sexbound_Util.sendMessage(self.controllerId, "main-switch-role", args)
  end)
  
  -- Sync the node with the main controller.
  message.setHandler("node-sync-main", function(_, _, args)
    self.controllerId = args.controllerId
  end)
  
  -- Uninit the node
  message.setHandler("node-uninit", function(_, _, args)
    NodeController.destroy()
  end)
end
