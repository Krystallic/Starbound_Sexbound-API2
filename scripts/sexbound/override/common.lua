--- Sexbound_Common Module.
-- @module Sexbound_Common

Sexbound_Common = {}

-- Override the init hook
sexbound_old_init = init
Sexbound_Common.init = function()
  status.setStatusProperty("sexbound_sex", false)

  status.setStatusProperty("sexbound_abortion", false)
  
  sexbound_old_init()
  
  Sexbound_Common.initMessageHandlers()
  
  Sexbound_Common.restorePreviousStorage()
  
  self.sexbound = {
    hasSetupActor = false,
    mindControl = {
      damageSourceKind = "sexbound_mind_control"
    }
  }
end

-- Override the update hook
sexbound_old_update = update
Sexbound_Common.update = function(dt)
  sexbound_old_update(dt)
  
  -- Check for abortion
  if status.statusProperty("sexbound_abortion") == true then
    Sexbound_Common.abortPregnancy()
  end
end

-- Attempts to abort all current pregnancies.
Sexbound_Common.abortPregnancy = function()
  status.setStatusProperty("sexbound_abortion", false)
  
  if storage.pregnant == nil then return end
  
  storage.pregnant = nil
  
  -- Send radio message to inform player of abortion
  if entity.entityType() == "player" then
    world.sendEntityMessage(entity.id(), "queueRadioMessage", {
      messageId = "Pregnant:Abort",
      unique    = false,
      text      = "All vital scans indicate that you are no longer pregnant!"
    })
  end
end

--- Attempt to invoke entity to give birth.
Sexbound_Common.tryToGiveBirth = function(callback)
  local worldTime = world.day() + world.timeOfDay()
  
  for i,v in ipairs(storage.pregnant) do
    local birthTime = v.birthDate + v.birthTime
    
    if worldTime >= birthTime then
      local birthData = util.mergeTable({}, v)
      
      table.remove(storage.pregnant, i)
    
      if type(callback) == "function" then
        callback(birthData)
      end
    end
  end
end

Sexbound_Common.initMessageHandlers = function()
  message.setHandler("sexbound-sync-storage", function(_,_,args)
    storage = util.mergeTable(storage, args or {})
    
    sb.logInfo("Received request to sync storage.")
    sb.logInfo(sb.printJson( storage ))
  end)
 
  message.setHandler("sexbound-ui-dismiss", function(_,_,args)
    -- Do something when UI says player has dismissed it.
  end)
end

--- Attempt to restore this entity's previous storage parameters.
Sexbound_Common.restorePreviousStorage = function()
  storage = util.mergeTable(storage, config.getParameter("sexbound.previousStorage") or {})
end

Sexbound_Common.splashDamage = function()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self.sexbound.mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

