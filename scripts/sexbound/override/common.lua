require "/scripts/vec2.lua" -- Chucklefish's vector script

require "/scripts/sexbound/util.lua"

Sexbound.Common = {}
Sexbound.Common_mt = { __index = Sexbound.Common }

function Sexbound.Common:new()
  local self = setmetatable({}, Sexbound.Common_mt)
  
  self._config = self:loadConfig()
  
  self._notifications = self:loadNotifications()
  
  return self
end

function Sexbound.Common:loadConfig()
  local sexboundConfig = {}

  if not pcall(function()
    sexboundConfig = root.assetJson("/sexbound.config")
  end) then
    sb.logInfo("Unable to load main sexbound.config file.")
    return
  end
  
  return sexboundConfig
end

function Sexbound.Common:loadNotifications()
  local sexboundConfig = self:getConfig()
  local defaultLanguage = sexboundConfig.defaultLanguage or "english"
  local supportedLanguages = sexboundConfig.supportedLanguages or {}
  supportedLanguages = supportedLanguages[defaultLanguage] or {}
  
  local langcode = supportedLanguages.languageCode or "en"
  
  local notifications = "/dialog/sexbound/" .. langcode .. "/notifications.config"
  
  if not pcall(function()
    notifications = root.assetJson(notifications)
  end) then
    sb.logInfo("Unable to load dialog from notifications file.")
    return
  end
  
  return notifications
end

function Sexbound.Common:getConfig()
  return self._config
end

function Sexbound.Common:getNotifications()
  return self._notifications
end