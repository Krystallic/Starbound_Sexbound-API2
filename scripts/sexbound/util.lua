--- Util Module.
-- @module Util
Sexbound_Util = {}

--- Dumps all of the functions of a specfied table.
-- @param tbl
Sexbound_Util.deepdump = function(tbl)
  local checklist = {}
  local function innerdump( tbl, indent )
    checklist[ tostring(tbl) ] = true
    for k,v in pairs(tbl) do
      sb.logInfo(indent..k,v,type(v),checklist[ tostring(tbl) ])
      if (type(v) == "table" and not checklist[ tostring(v) ]) then innerdump(v,indent.."    ") end
    end
  end
  sb.logInfo("=== DEEPDUMP -----")
  checklist[ tostring(tbl) ] = true
  innerdump( tbl, "" )
  sb.logInfo("------------------")
end

---Creates and stores a new message.
-- @param message reference name of the message.
Sexbound_Util.resetMessenger = function(message)
  self.messenger[message] = {promise = nil, busy = false}
end

---Handles sending a message to a specified entity.
-- @param entityId String: A remote entity id or unique id.
-- @param message String: The message to send the remote entity.
-- @param args Table: Arguments to send to th remote entity.
-- @param wait Boolean: true = wait for response before sending again. false = send without waiting
Sexbound_Util.sendMessage = function(entityId, message, args, wait)
  if (self.messenger == nil) then self.messenger = {} end

  if (wait == nil) then wait = false end

  -- Prepare new message to store data
  if (self.messenger[message] == nil) then
    Sexbound_Util.resetMessenger(message)
  end
  
  -- If not already busy then send message
  if not (self.messenger[message].busy) then
    self.messenger[message].promise = world.sendEntityMessage(entityId, message, args)
    
    self.messenger[message].busy = wait
  end
end

---Handles response from the source entity.
-- @param message String: The message to send the remote entity.
-- @param callback
Sexbound_Util.updateMessage = function(message, callback)
  if (self.messenger == nil) then self.messenger = {} end

  if (self.messenger[message] == nil) then return end

  local promise = self.messenger[message].promise

  if (promise and promise:finished()) then
    local result = promise:result()
    
    Sexbound_Util.resetMessenger(message)
    
    callback(result)
  end
end