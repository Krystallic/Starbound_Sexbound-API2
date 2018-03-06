--- Sexbound.Core.Pregnant Class Module.
-- @classmod Sexbound.Core.Pregnant
Sexbound.Core.Pregnant = {}
Sexbound.Core.Pregnant.__index = Sexbound.Core.Pregnant

--- Instantiates a new instance of Pregnant.
-- @param parent
function Sexbound.Core.Pregnant.new(parent)
  local self = setmetatable({}, Sexbound.Core.Pregnant)
  
  -- Reference to parent Actor
  self.parent = parent
  
  -- Init. config
  self.config = util.mergeTable({}, Sexbound.API.getParameter("pregnant"))
  
  -- Store current pregnancy for this Actor
  self.currentPregnancies = self.parent:storage().pregnant or {}
  
  -- Update the current pregnancy count
  self.currentPregnanciesCount = self:getCurrentPregnancyCount()
  
  return self
end

--- Update this instance.
-- @param dt
function Sexbound.Core.Pregnant:update(dt)

end

--- Returns a reference to this instance's config.
function Sexbound.Core.Pregnant:getConfig()
  return self.config
end

--- Returns a reference to an array of current pregnancies for this Actor.
function Sexbound.Core.Pregnant:getCurrentPregnancies()
  return self.currentPregnancies
end

--- Returns the count of current pregnancies for this Actor.
function Sexbound.Core.Pregnant:getCurrentPregnancyCount()
  self.currentPregnanciesCount = 0

  for _,pregnancy in ipairs(self.currentPregnancies) do
    self.currentPregnanciesCount = self.currentPregnanciesCount + 1
  end
  
  return self.currentPregnanciesCount
end

--- Returns a reference to a table of data for a specific pregnancy.
-- @param index
function Sexbound.Core.Pregnant:getCurrentPregnancy(index)
  return self.currentPregnancies[index]
end

--- Returns a reference to the last current pregnancy.
function Sexbound.Core.Pregnant:lastCurrentPregnancy()
  local currentPregnancyCount = self:getCurrentPregnancyCount()

  return self:getCurrentPregnancy(currentPregnancyCount)
end

--- Makes this instance's Actor become pregnant.
function Sexbound.Core.Pregnant:becomePregnant()
  -- Try to insert new pregnancy.
  if not self:isPregnant() or self:getConfig().allowMultipleImpregnations then
    local birthDate, dayCount = self:createRandomBirthDate()
    local birthTime   = self:createRandomBirthTime()
    local birthGender = self:createRandomBirthGender()
    local motherName  = self.parent:identity("name")
    
    local currentPregnancies = self:getCurrentPregnancies() or {}
    
    -- Insert new pregnancy into current pregnancies
    table.insert(currentPregnancies, {
      birthGender = birthGender,
      birthDate   = birthDate,
      birthTime   = birthTime,
      dayCount    = dayCount,
      motherName  = motherName
    })
    
    self.parent:overwriteStorage("pregnant", currentPregnancies)
    
    -- Update reference to pregnancy data
    self.currentPregnancies = self.parent:storage().pregnant
    
    -- Send players a message to highlight the new pregnancy
    self:sendSuccessMessage()
  end
end

-- Use radio broadcast to inform the player of pregnancy.
function Sexbound.Core.Pregnant:sendSuccessMessage()
  local messageId = "Pregnant:Success"

  local strDayCount = "day."
  
  local lastCurrentPregnancy = self:lastCurrentPregnancy()
  
  local dayCount = lastCurrentPregnancy.dayCount
  
  local otherActor = nil
  
  if dayCount > 1 then strDayCount = "days." end
  
  for _,actor in ipairs(Sexbound.API.Actors.getActors()) do
    if actor:id() ~= self.parent:id() then
      -- Set reference to other Actor
      otherActor = actor
      
      -- Send message when the other actor is a player
      if otherActor:entityType() == "player" then
        local text = "You just impregnanted ^green;" .. self.parent:identity("name") .. 
        "^reset;, and she will give birth in ^red;" .. dayCount .. "^reset; " .. 
        strDayCount
        
        world.sendEntityMessage(actor:id(), "queueRadioMessage", {
          messageId = messageId,
          unique    = false,
          text      = text
        })
      end
    end
  end
  
  -- Send Radio Message to the parent Actor if they are not an NPC.
  if self.parent:entityType() == "player" then
    local otherActorName = otherActor:identity("name") or "UNKNOWN"
  
    local text = "Oppsy! You were just impregnated by ^green;" ..  otherActorName ..
    "^reset;, and you will give birth in ^red;" .. dayCount .. "^reset; " ..
    strDayCount
  
    world.sendEntityMessage(self.parent:id(), "queueRadioMessage", {
      messageId = messageId,
      unique    = false,
      text      = text
    })
  end
end

--- Returns whether of not this instance's Actor is pregnant.
function Sexbound.Core.Pregnant:isPregnant()
  if self:getCurrentPregnancyCount() > 0 then
    return true
  end
  
  return false
end

--- Try to make actor become pregnant.
function Sexbound.Core.Pregnant:tryBecomePregnant(callback)
  -- Check if mate must be compatible to become pregnant
  if self:getConfig().enableCompatibleMates and not self:isMateCompatible() then return end
  
  if self:isImpregnationPossible() then
      return self:becomePregnant()
  end
end

--- Returns the possibility for a pregnancy in current position.
function Sexbound.Core.Pregnant:isImpregnationPossible()
  local positionData = Sexbound.API.Positions.currentPosition():getData()
  
  return positionData.possiblePregnancy[self.parent:actorNumber()] or false
end

--- Returns whether or not this instance's parent actor is compatible with its mate.
function Sexbound.Core.Pregnant:isMateCompatible()
  for _,actor in ipairs(Sexbound.API.Actors.getActors()) do
    -- Check if the compared actors have different ids
    if self.parent:id() ~= actor:id() and actor:getClimax():isClimaxing() then
      -- Always return true for mates whose species matches but they have different genders
      if self.parent:species() == actor:species() and self.parent:gender() ~= actor:gender() then
        return true
      end
    
      -- Check if additional breeding compatibility options have been set.
      local selectedSpecies = self:getConfig().compatibleMates[self.parent:species()]
      
      if selectedSpecies and self.parent:gender() == selectedSpecies.gender then
        for _,mate in ipairs(selectedSpecies.mates) do
          if actor:gender() == mate.gender and actor:species() == mate.species then
            return true
          end
        end
      end
    end
  end
  
  return false
end

function Sexbound.Core.Pregnant:createRandomBirthGender()
  return util.randomChoice({"male", "female"})
end

--- Returns a random birth date and day count.
-- @return birthDate, dayCount
function Sexbound.Core.Pregnant:createRandomBirthDate()
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
function Sexbound.Core.Pregnant:createRandomBirthTime()
  return util.randomInRange({0.0, 1.0})
end
