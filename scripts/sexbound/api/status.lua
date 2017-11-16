--- Sexbound.API.Status Submodule.
-- @submodule Sexbound.API
Sexbound.API.Status = {}

--- Returns the value for the specified status.
-- @param statusName
function Sexbound.API.Status.getStatus(statusName)
  return self.sexboundData.status[statusName]
end

--- Sets the specified status.
-- @param statusName
-- @param value
function Sexbound.API.Status.setStatus(statusName, value)
  self.sexboundData.status[statusName] = value 
end

--- Returns whether or not this object is having sex.
function Sexbound.API.Status.isHavingSex()
  return Sexbound.API.Status.getStatus("havingSex")
end

--- Returns whether or not this object is climaxing.
function Sexbound.API.Status.isClimaxing()
  return Sexbound.API.Status.getStatus("climaxing")
end

--- Returns whether or not this object is reseting.
function Sexbound.API.Status.isReseting()
  return Sexbound.API.Status.getStatus("reseting")
end