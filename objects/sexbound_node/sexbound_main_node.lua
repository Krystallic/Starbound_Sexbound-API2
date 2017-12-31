require "/scripts/sexbound.lua"

function init()
  -- Check if mindControl is in storage before setting it.
  if storage.mindControl then
    smash()
    return 
  end
  
  storage.mindControl = config.getParameter("mindControl")
  
  Sexbound.API.init()
  
  Sexbound.API.becomeNode()
end

function update(dt)
  if self.isSmashing then return end

  Sexbound.API.update(dt, function()
    if storage.mindControl then
      local worldTime = world.day() + world.timeOfDay()
      
      if not Sexbound.API.Status.getStatus("havingSex") and worldTime >= storage.mindControl.timeout then
        smash()
      end
    end
  end)
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args) or nil
end

function smash()
  if not self.isSmashing then
    self.isSmashing = true
  
    object.smash(true)
  end
end

function die()
  Sexbound.API.respawnStoredActor()
end

function uninit()
  Sexbound.API.uninit()
end
  
