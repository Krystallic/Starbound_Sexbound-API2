--- Log Module.
-- @module Log
Sexbound.Log = {}
Sexbound.Log.__index = Sexbound.Log

--- Instantiates Log.
-- @param[opt] options
function Sexbound.Log.new(...)
  local self = setmetatable({}, Sexbound.Log)
  self:init(...)
  return self
end

--- Initializes Log.
-- @param[opt] options
function Sexbound.Log:init(options)
  self.options = options or {moduleName = "Unknown Module"}
  self.moduleName = "Log"
end

--- Instructs util API to log error.
-- @param text string value
function Sexbound.Log:error(text)
  sb.logError(self:prepare(text))
end

--- Instructs util API to log info.
-- @param text string value
function Sexbound.Log:info(text)
  sb.logInfo(self:prepare(text))
end

--- Instructs util API to warn info.
-- @param text string value
function Sexbound.Log:warn(text)
  sb.logWarn(self:prepare(text))
end

--- Prepares text to be logged.
-- @param text string value
function Sexbound.Log:prepare(text)
  local pretext = "[ Sexbound API | " .. self.options.moduleName .. " ]"
  
  if text then
    if type(text) == "table" then
      return pretext .. " : " .. sb.printJson( text )
    end 
    
    return pretext .. " : " .. text 
  end
  
  return pretext .. " : " .. "Null"
end