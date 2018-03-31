--- Sexbound.Util Module.
-- @module Sexbound.Util
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound = Sexbound or {}
Sexbound.Util = {}

--- Dumps all of the functions of a specfied table.
-- @param tbl A lua table.
-- @usage Sexbound.Util.deepdump(myTable)
Sexbound.Util.deepdump = function(tbl)
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

--- Searches for entity with the specified uniqueId.
-- @param uniqueId String value.
-- @usage local found = Sexbound.Util.findEntityWithUid(uniqueId)
Sexbound.Util.findEntityWithUid = function(uniqueId)
  if world.findUniqueEntity(uniqueId):result() then return true end
  return false
end

--[ Messaging ]---------------------------------------------------------------------[ Messaging ]--#

---Private: Creates and stores a new message.
-- @param name Reference name of the message.
local function Sexbound_Util_ResetMessenger(name)
  self.messenger[name] = {promise = nil, busy = false}
end

---Handles sending a message to a specified entity.
-- @param entityId String: A remote entity id or unique id.
-- @param name String: The name of the message to send the remote entity.
-- @param args Table: Arguments to send to th remote entity.
-- @param wait Boolean: true = wait for response before sending again. false = send without waiting
-- @usage Sexbound.Util.sendMessage(entityId, "sexbound-node-init", {}, false)
-- @usage Sexbound.Util.sendMessage(uniqueId, "sexbound-node-init", {}, false)
Sexbound.Util.sendMessage = function(entityId, name, args, wait)
  if (self.messenger == nil) then self.messenger = {} end

  if (wait == nil) then wait = false end

  -- Prepare new message to store data
  if (self.messenger[name] == nil) then
    Sexbound_Util_ResetMessenger(name)
  end
  
  -- If not already busy then send message
  if not (self.messenger[name].busy) then
    self.messenger[name].promise = world.sendEntityMessage(entityId, name, args)
    
    self.messenger[name].busy = wait
  end
end

---Handles response from the source entity.
-- @param name The name of the message to send the remote entity.
-- @param callback An anonymous function.
-- @usage Sexbound.Util.sendMessage("sexbound-node-init", function(args) local name = args.name end)
Sexbound.Util.updateMessage = function(name, callback)
  if (self.messenger == nil) then self.messenger = {} end

  if (self.messenger[name] == nil) then return end

  local promise = self.messenger[name].promise

  if (promise and promise:finished()) then
    local result = promise:result()
    
    Sexbound_Util_ResetMessenger(name)
    
    if type(callback) == "function" then
      callback(result)
    end
  end
end

