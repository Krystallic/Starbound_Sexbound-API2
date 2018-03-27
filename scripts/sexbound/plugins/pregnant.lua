--- Sexbound.Actor.Pregnant Class Module.
-- @classmod Sexbound.Actor.Pregnant
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound/actor/plugin.lua"

Sexbound.Actor.Pregnant = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Pregnant_mt = { __index = Sexbound.Actor.Pregnant }

--- Instantiates a new instance of Pregnant.
-- @param parent
-- @param config
function Sexbound.Actor.Pregnant:new( parent, config )
  local self = setmetatable({
    _logPrefix = "PREG",
    _config    = config,
    _currentPregnancies = parent:getStorage("pregnant") or {}
  }, Sexbound.Actor.Pregnant_mt)
  
  self:init(parent, self._logPrefix)
  
  self._currentPregnanciesCount = self:getCurrentPregnancyCount()
  
  if self:isPregnant() then
    self:getParent():addStatus("pregnant")
  end
  
  return self
end

--- Handles message events.
-- @param message
function Sexbound.Actor.Pregnant:onMessage(message)
  if message:getType() == "Sexbound:Pregnant:BecomePregnant" then
    local otherActor = message:getData()
    
    self:tryBecomePregnant(otherActor)
  end
end

--- Returns a random birth gender.
-- @return birthGender
function Sexbound.Actor.Pregnant:createRandomBirthGender()
  return util.randomChoice({"male", "female"})
end

--- Returns a random birth date and day count.
-- @return birthDate, dayCount
function Sexbound.Actor.Pregnant:createRandomBirthDate()
  local trimesterCount  = util.randomIntInRange(self:getConfig().trimesterCount or 3)
  local trimesterLength = self:getConfig().trimesterLength or {5, 8}
  
  local dayCount = 0
  
  for i=1,trimesterCount do
    dayCount = dayCount + util.randomIntInRange(trimesterLength)
  end
  
  local birthDate = world.day() + dayCount
  
  return birthDate, dayCount
end

--- Returns a random birth time.
-- @return birthTime
function Sexbound.Actor.Pregnant:createRandomBirthTime()
  return util.randomInRange({0.0, 1.0})
end

--- Returns a reference to this Actor's current pregnancies table.
-- @param index
-- @return table
function Sexbound.Actor.Pregnant:getCurrentPregnancies(index)
  if index then return self._currentPregnancies[index] end

  return self._currentPregnancies
end

--- Returns the count of current pregnancies for this Actor.
function Sexbound.Actor.Pregnant:getCurrentPregnancyCount()
  self._currentPregnanciesCount = 0

  for _,pregnancy in ipairs(self._currentPregnancies) do
    self._currentPregnanciesCount = self._currentPregnanciesCount + 1
  end
  
  return self._currentPregnanciesCount
end

--- Returns a list of compatible mates for this actor.
function Sexbound.Actor.Pregnant:getCompatibleMates()
  local species = self:getParent():getSpecies()
  
  local gender  = self:getParent():getGender()

  local mates   = self:getConfig().compatibleMates[species] or {}

  return mates[gender]
end

--- Returns the possibility for a pregnancy in current position.
function Sexbound.Actor.Pregnant:isImpregnationPossible()
  local position = self:getRoot():getPositions():getCurrentPosition()
  local positionConfig = position:getConfig()

  return positionConfig.possiblePregnancy[self:getParent():getActorNumber()] or false
end

--- Returns if this actor is a compatible mate for the other actor
-- @param otherActor
function Sexbound.Actor.Pregnant:isOtherCompatible(otherActor)
  if true == self:getConfig().enableCompatibleMates then
    local mates = self:getCompatibleMates()
  
    if type(mates) == "table" then
      for _,mate in ipairs(mates) do
        local sMatch = mate.species == otherActor:getSpecies()

        local gMatch = mate.gender  == otherActor:getGender()
        
        if sMatch and gMatch then return true end
      end
    end
    
    return false
  end
  
  -- Otherwise make sure gender does not match
  return self:getParent():getGender() ~= otherActor:getGender()
end

--- Returns whether of not this instance's Actor is pregnant.
function Sexbound.Actor.Pregnant:isPregnant()
  if self:getCurrentPregnancyCount() > 0 then
    return true
  end
  
  return false
end

--- Returns a reference to the last current pregnancy.
function Sexbound.Actor.Pregnant:lastCurrentPregnancy()
  local currentPregnancyCount = self:getCurrentPregnancyCount()

  return self:getCurrentPregnancies(currentPregnancyCount)
end

--- Makes this instance's Actor become pregnant.
function Sexbound.Actor.Pregnant:becomePregnant(otherActor)
  self:getLog():info("Actor has been impregnanted: " .. self:getParent():getName())

  local birthDate, dayCount = self:createRandomBirthDate()
  local birthTime   = self:createRandomBirthTime()
  local birthGender = self:createRandomBirthGender()
  local motherName  = self:getParent():getIdentity("name")
  
  local currentPregnancies = self:getCurrentPregnancies()
  
  -- Insert new pregnancy into current pregnancies
  table.insert(currentPregnancies, {
    birthGender = birthGender,
    birthDate   = birthDate,
    birthTime   = birthTime,
    dayCount    = dayCount,
    motherName  = motherName
  })
  
  self:getParent():overwriteStorage("pregnant", currentPregnancies)
  
  self._currentPregnancies = self:getParent():getStorage("pregnant") or {}
  
  if not isEmpty(self._currentPregnancies) then
    self:sendSuccessMessage(otherActor)
  end
end

-- Use radio broadcast to inform the player of pregnancy.
function Sexbound.Actor.Pregnant:sendSuccessMessage(otherActor)
  local notifications = self:getConfig().notifications
  local langcode = self:getRoot():getLanguageSettings().languageCode
  notifications = util.replaceTag(notifications, "langcode", langcode)
  
  if not pcall(function()
    notifications = root.assetJson(notifications)
  end) then
    self:getLog():error("Unable to load notifications dialog!")
    return
  end

  notifications = notifications.plugins  or {}
  notifications = notifications.pregnant or {}
  
  local messageId = "Pregnant:Success"

  local lastCurrentPregnancy = self:lastCurrentPregnancy()
  
  local dayCount = lastCurrentPregnancy.dayCount
  
  local message = notifications.impregnatedMessage1
  
  if dayCount > 1 then
    message = notifications.impregnatedMessage2
  end
  
  local actor = self:getParent()
  
  local name = "^green;" .. actor:getName() .. "^reset;"
  
  local dayCountText = "^red;" .. dayCount .. "^reset;"
  
  message = util.replaceTag(message, "name", name)
  
  message = util.replaceTag(message, "daycount", dayCountText)

  if otherActor:getEntityType() == "player" then
    world.sendEntityMessage(otherActor:getEntityId(), "queueRadioMessage", {
      messageId = messageId,
      unique    = false,
      text      = message
    })
  end
  
  message = notifications.impregnatedMessage3
  
  if dayCount > 1 then
    message = notifications.impregnatedMessage4
  end
  
  local name = "^green;" .. otherActor:getName() .. "^reset;"
  
  message = util.replaceTag(message, "name", name)
  
  message = util.replaceTag(message, "daycount", dayCountText)
  
  -- Send Radio Message to the parent Actor if they are not an NPC.
  if actor:getEntityType() == "player" then
    world.sendEntityMessage(actor:getEntityId(), "queueRadioMessage", {
      messageId = messageId,
      unique    = false,
      text      = message
    })
  end
end

--- Attempts to make this actor become pregnant.
function Sexbound.Actor.Pregnant:tryBecomePregnant(otherActor)
  -- Prevent actor from impregnating itself.
  if otherActor:getEntityId() == self:getParent():getEntityId() then return end
  
  self:getLog():info("Actor is attempting to become pregnant: " .. self:getParent():getName())
  
  -- Check if mate must be compatible to become pregnant
  if self:isImpregnationPossible() and self:isOtherCompatible(otherActor) then
    if not self:isPregnant() or self:getConfig().allowMultipleImpregnations then
      self:becomePregnant(otherActor)
    end
  end
end