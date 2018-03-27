--- Sexbound.Actor.SexTalk Class Module.
-- @classmod Sexbound.Actor.SexTalk
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound/actor/plugin.lua"

Sexbound.Actor.SexTalk = Sexbound.Actor.Plugin:new()

Sexbound.Actor.SexTalk_mt = { __index = Sexbound.Actor.SexTalk } 

--- Instantiates a new instance of SexTalk.
-- @param parent
-- @param config
function Sexbound.Actor.SexTalk:new( parent, config )
  local self = setmetatable({
    _logPrefix      = "SEXT", 
    _config         = config,
    _currentMessage = "",
    _history        = {},
    _timer          = 0
  }, Sexbound.Actor.SexTalk_mt)

  self:init(parent, self._logPrefix, function()
    self._cooldown = self:refreshCooldown()
  end)
  
  self._dialog        = self:loadDialog()
  self._defaultDialog = self:loadDefaultDialog()
  
  return self
end

function Sexbound.Actor.SexTalk:onMessage(message)
  if message:getType() == "Sexbound:Positions:SwitchPosition" then
    self._dialog        = self:loadDialog()
    self._defaultDialog = self:loadDefaultDialog()

    self:sayRandom()
  end
  
  if message:getType() == "Sexbound:SwitchRoles" then
    self:sayRandom()
  end
end

function Sexbound.Actor.SexTalk:onEnterSexState()
  self._dialog = self:loadDialog()
  self._defaultDialog = self:loadDefaultDialog()
    
  self:resetTimer()
  
  self:sayRandom()
end

function Sexbound.Actor.SexTalk:onUpdateSexState(dt)
  self._timer = self._timer + dt

  if self:getTimer() >= self:getCooldown() then
    self:sayRandom()
  
    self:resetTimer()
  end
end

function Sexbound.Actor.SexTalk:onEnterClimaxState()
  self:resetTimer()
  
  -- Say random with 'climaxing' as the prioritized status for both actors.
  self:sayRandom("climaxing", "climaxing")
end

function Sexbound.Actor.SexTalk:onUpdateClimaxState(dt)
  self._timer = self._timer + dt

  if self:getTimer() >= self:getCooldown() then
    -- Say random with 'climaxing' as the prioritized status for both actors.
    self:sayRandom("climaxing", "climaxing")
    
    self:resetTimer()
  end
end

function Sexbound.Actor.SexTalk:loadDefaultDialog()
  local main = self:getRoot()
  local langCode  = main:getLanguageSettings().languageCode
  local positions = main:getPositions()
  local position  = positions:getCurrentPosition()
  local positionConfig  = position:getConfig()
  
  local dialog = positionConfig.dialog or {}
    
  local actor = self:getParent()
  local gender = actor:getGender()

  -- Get file path for default dialog
  local defaultDialog = dialog["default"]
  defaultDialog = util.replaceTag(defaultDialog, "gender", gender)
  defaultDialog = util.replaceTag(defaultDialog, "langcode", langCode)
  
  local defaultDialogConfig = {}
  
  -- Load default dialog file and handle errors
  if not pcall(function()
    defaultDialogConfig = root.assetJson(defaultDialog)
  end) then
    self:getLog():error("Unable to load default dialog file!")
    return defaultDialogConfig
  end

  return defaultDialogConfig
end

function Sexbound.Actor.SexTalk:loadDialog()
  local main = self:getRoot()
  local langCode  = main:getLanguageSettings().languageCode
  local positions = main:getPositions()
  local position  = positions:getCurrentPosition()
  local positionConfig  = position:getConfig()
  
  local dialog = positionConfig.dialog or {}
    
  local actor = self:getParent()
  local species = actor:getSpecies()
  local gender = actor:getGender()

  -- Try to get file path for species specific dialog
  local speciesDialog = dialog[species] or dialog["default"]
  speciesDialog = util.replaceTag(speciesDialog, "gender", gender)
  speciesDialog = util.replaceTag(speciesDialog, "langcode", langCode)
  
  local speciesDialogConfig = {}
  
  -- Load species specific dialog file and handle errors
  if not pcall(function()
    speciesDialogConfig = root.assetJson(speciesDialog)
  end) then
    self:getLog():error("Unable to load dialog file for species : " .. species)
    return speciesDialogConfig
  end
  
  return speciesDialogConfig
end

function Sexbound.Actor.SexTalk:sayRandom(statusPriorityForActor, statusPriorityForOther)
  local dialog = self:getDialog() or {}
  local defaultDialog = self:getDefaultDialog() or {}
  
  local otherActor = self:getOtherActor()
  if otherActor == nil then return {} end
  local otherSpecies     = otherActor:getSpecies()
  local otherGender      = otherActor:getGender()
  local otherStatusList  = otherActor:getStatusList()
  local statusPriorityForOther = otherActor:findStatus(statusPriorityForOther)
  
  local otherStatus = util.randomChoice(otherStatusList)
  if type(statusPriorityForOther) == "string" then
    otherStatus = statusPriorityForOther
  end

  local actor  = self:getParent()
  local actorNumber     = actor:getActorNumber()
  local actorStatusList = actor:getStatusList()
  local statusPriorityForActor = actor:findStatus(statusPriorityForActor)
  
  local actorStatus = util.randomChoice(actorStatusList)
  if type(statusPriorityForActor) == "string" then
    actorStatus = statusPriorityForActor
  end

  dialog = dialog[actorNumber]  or {}
  dialog = dialog[actorStatus]  or dialog["default"] or dialog
  dialog = dialog[otherSpecies] or dialog["default"] or dialog
  dialog = dialog[otherGender]  or dialog["default"] or dialog
  dialog = dialog[otherStatus]  or dialog["default"] or {}
  
  defaultDialog = defaultDialog[actorNumber] or {}
  defaultDialog = defaultDialog[actorStatus] or defaultDialog["default"] or defaultDialog
  defaultDialog = defaultDialog["default"]   or defaultDialog
  defaultDialog = defaultDialog[otherGender] or defaultDialog["default"] or defaultDialog
  defaultDialog = defaultDialog[otherStatus] or defaultDialog["default"] or {}
  
  dialog = util.mergeTable(defaultDialog, dialog)
  
  if not isEmpty(dialog) and type(dialog) == "table" then
    dialog = util.randomChoice(dialog)
  end

  if type(dialog) == "string" then
    object.say(dialog)
    
    local actor = self:getParent()
    
    local emote = actor:getPlugins("emote")
    
    Sexbound.Messenger.get("main"):send(self, emote, "Sexbound:SexTalk:Talk", {})
  end
end

-- Getters / Setters

function Sexbound.Actor.SexTalk:getCooldown()
  return self._cooldown
end

function Sexbound.Actor.SexTalk:getCurrentMessage()
  return self._currentMessage
end

function Sexbound.Actor.SexTalk:getDialog()
  return self._dialog
end

function Sexbound.Actor.SexTalk:getDefaultDialog()
  return self._defaultDialog
end

function Sexbound.Actor.SexTalk:getDialogPool()
  return self._dialogPool
end

function Sexbound.Actor.SexTalk:targetRandomActor()
  local otherActors = {}
  
  -- Populate actor data with all actors that are not the parent actor.
  for i,actor in ipairs(self:getRoot():getActors()) do
    if self:getParent():getEntityId() ~= actor:getEntityId() then
      table.insert(otherActors, actor)
    end
  end
  
  if not isEmpty(otherActors) then
    return util.randomChoice(otherActors)
  else
    return nil
  end
end

--- Returns reference to targeted other actor.
function Sexbound.Actor.SexTalk:getOtherActor()
  self._otherActor = self._otherActor or self:targetRandomActor()

  return self._otherActor
end

function Sexbound.Actor.SexTalk:getTimer()
  return self._timer
end

-- Refreshes the cooldown time for this module.
function Sexbound.Actor.SexTalk:refreshCooldown()
  self._cooldown = util.randomInRange(self:getConfig().cooldown)
  
  return self._cooldown
end

function Sexbound.Actor.SexTalk:resetDialogPool()
  self._dialogPool = {}
end

function Sexbound.Actor.SexTalk:resetTimer()
  self._timer = 0
end
