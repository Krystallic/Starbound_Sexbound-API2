--- Sexbound.Core.Log Class Module.
-- @classmod Sexbound.Core.Log
Sexbound.Core.Log = {}
Sexbound.Core.Log.__index = Sexbound.Core.Log

--- Instantiates Log.
-- @param[opt] options
function Sexbound.Core.Log.new(...)
  local self = setmetatable({}, Sexbound.Core.Log)
  self:init(...)
  return self
end

--- Initializes Log.
-- @param[opt] options
function Sexbound.Core.Log:init(options)
  self.options = options or {moduleName = "Unknown Module"}
  self.moduleName = "Log"
end

--- Instructs util API to log error.
-- @param text string value
function Sexbound.Core.Log:error(text)
  sb.logError(self:prepare(text))
end

--- Instructs util API to log info.
-- @param text string value
function Sexbound.Core.Log:info(text)
  sb.logInfo(self:prepare(text))
end

--- Instructs util API to warn info.
-- @param text string value
function Sexbound.Core.Log:warn(text)
  sb.logWarn(self:prepare(text))
end

--- Prepares text to be logged.
-- @param text string value
function Sexbound.Core.Log:prepare(text)
  local pretext = "[ Sexbound API | " .. self.options.moduleName .. " ]"
  
  if text then
    if type(text) == "table" then
      return pretext .. " : " .. sb.printJson( text )
    end 
    
    return pretext .. " : " .. text 
  end
  
  return pretext .. " : " .. "Null"
end