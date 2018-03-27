require "/scripts/sexbound/util.lua"

function init()
  self.controllerCheck = {
    timer   = 0,
    timeout = 25
  }

  local ControllerId = config.getParameter("controllerId")

  if not ControllerId or world.findUniqueEntity(ControllerId):result() == nil then
    uninit()
  end
  
  object.setInteractive(config.getParameter("interactive", false))

  -- Handle Setup Actor
  message.setHandler("sexbound-setup-actor", function(_,_,args)
    Sexbound.Util.sendMessage(ControllerId, "sexbound-setup-actor", args)
  end)
  
  -- Handle Remove Actor
  message.setHandler("sexbound-remove-actor", function(_,_,args)
    Sexbound.Util.sendMessage(ControllerId, "sexbound-remove-actor", args)
  end)
  
    -- Handle Uninit Node
  message.setHandler("sexbound-node-uninit", function(_,_,args)
    sb.logInfo("Recieved message to uninit.")
  
    uninit()
  end)
end

function update(dt)
  self.controllerCheck.timer = self.controllerCheck.timer + dt

  if self.controllerCheck.timer >= self.controllerCheck.timeout then
    local ControllerId = config.getParameter("controllerId")

    if not ControllerId or world.findUniqueEntity(ControllerId):result() == nil then
      uninit()
    end
    
    self.controllerCheck.timer = 0
  end
end

function uninit()
  object.smash(true)
end
