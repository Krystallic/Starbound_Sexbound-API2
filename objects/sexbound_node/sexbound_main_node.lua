require "/scripts/sexbound.lua"

function init()
  -- Check if mindControl is in storage before setting it.
  if storage.mindControl then
    Sexbound.API.uninit()
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
      Sexbound.API.uninit()
    end
  end
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args) or nil
end

function uninit()
  Sexbound.API.uninit()
end
  
