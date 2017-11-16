require "/scripts/sexbound.lua"

function init()
  -- Check if mindControl is in storage before setting it.
  if storage.mindControl then
    object.smash(true)
  end
  
  storage.mindControl = config.getParameter("mindControl")
  
  Sexbound.API.init()
  
  Sexbound.API.becomeNode()
end

function update(dt)
  Sexbound.API.update(dt)
  
  if storage.mindControl then
    local worldTime = world.day() + world.timeOfDay()
    
    if not Sexbound.API.Status.getStatus("havingSex") and worldTime >= storage.mindControl.timeout then
      object.smash(true)
    end
  end
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args) or nil
end

function die()
  Sexbound.API.respawnNPC()
end
  
