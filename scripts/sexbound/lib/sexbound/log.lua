--- Sexbound.Log Class Module.
-- @classmod Sexbound.Log
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Log = {}
Sexbound.Log_mt = { __index = Sexbound.Log }

--- Returns a reference to a new instance of this class.
-- @param logPrefix a string (four letters)
-- @param sexboundConfig a table
function Sexbound.Log:new( logPrefix, sexboundConfig)
  local self = setmetatable({
    _logPrefix = logPrefix or "UNKN"
  }, Sexbound.Log_mt)

  self._config = self:loadConfig(sexboundConfig)
  
  return self
end

--- Returns a reference to this instance's config.
function Sexbound.Log:getConfig()
  return self._config
end

--- Returns a reference to this instance's log prefix.
function Sexbound.Log:getLogPrefix()
  return self._logPrefix
end

--- Loads and returns a reference to this instance's config.
-- @param sexboundConfig a table
function Sexbound.Log:loadConfig(sexboundConfig)
  if type(sexboundConfig) == "table" then
    return sexboundConfig.log
  end
end

--- Logs specified data as an error.
-- @param data a string or table
function Sexbound.Log:error(data)
  if self:getConfig().showError then
    sb.logError(self:prepare(data))
  end
end

--- Logs specified data as an informational message.
-- @param data a string or table
function Sexbound.Log:info(data)
  if self:getConfig().showInfo then
    sb.logInfo(self:prepare(data))
  end
end

--- Logs specified data as a warning.
-- @param data a string or table
function Sexbound.Log:warn(data)
  if self:getConfig().showWarn then
    sb.logWarn(self:prepare(data))
  end
end

--- Prepares specified data to be logged.
-- @param data a string or table
function Sexbound.Log:prepare(data)
  local pretext = "[SxB | " .. self:getLogPrefix() .. "]"
  
  if data and type(data) == "string" then
    return pretext .. " : " .. data 
  end
  
  if data and type(data) == "table" then
    return pretext .. " : " .. sb.printJson( data )
  end 
  
  return pretext .. " : " .. "Unable to display log data."
end