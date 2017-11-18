--- Sexbound.Core.Pregnant Class Module.
-- @classmod Sexbound.Core.Pregnant
Sexbound.Core.Pregnant = {}
Sexbound.Core.Pregnant.__index = Sexbound.Core.Pregnant

--- Instantiates a new instance of Pregnant.
-- @param parent
function Sexbound.Core.Pregnant.new(parent)
  local self = setmetatable({}, Sexbound.Core.Pregnant)
  
  self.parent = parent
  
  self.pregnant = {
    config = util.mergeTable({}, Sexbound.API.getParameter("pregnant")),
    data   = self.parent:storage().pregnant
  }
  
  return self
end

--- Update this instance.
-- @param dt
function Sexbound.Core.Pregnant:update(dt)

end

--- Returns a reference to this instance's config.
function Sexbound.Core.Pregnant:config()
  return self.pregnant.config
end

--- Makes this instance's Actor become pregnant.
function Sexbound.Core.Pregnant:becomePregnant()
  -- Try to insert new pregnancy.
  if not self:isPregnant() or self:config().allowMultipleImpregnations then
    local birthDate, dayCount = self:createRandomBirthDate()
    local birthTime = self:createRandomBirthTime()

    self.parent.log:info("This actor wants to become pregnant!")
    
    local pregnant = self.parent:storage().pregnant or {}
    
    table.insert(pregnant, {
      birthDate = birthDate,
      birthTime = birthTime,
      dayCount  = dayCount
    })
    
    self.parent:overwriteStorage("pregnant", pregnant)
  end
end

--- Returns whether of not this instance's Actor is pregnant.
function Sexbound.Core.Pregnant:isPregnant()
  if self.pregnant.data then
    return true
  end
  
  return false
end

--- Try to make actor become pregnant.
function Sexbound.Core.Pregnant:tryBecomePregnant(callback)
  if self:isImpregnationPossible() and self:isMateCompatible() then
    return self:becomePregnant()
  end
end

--- Returns the possibility for a pregnancy in current position.
function Sexbound.Core.Pregnant:isImpregnationPossible()
  local position = Sexbound.API.Positions.currentPosition():getData()
  
  return position.possiblePregnancy[self.parent:actorNumber()] or false
end

--- Returns whether or not this instance's parent actor is compatible with its mate.
function Sexbound.Core.Pregnant:isMateCompatible()
  for _,actor in ipairs(Sexbound.API.Actors.getActors()) do
    if actor:getClimax():isClimaxing() and self.parent:id() ~= actor:id() then
      -- Always return true for mates whose species matches with different genders.
      if self.parent:species() == actor:species() then
        if self.parent:gender() ~= actor:gender() then
          return true
        end
      end
    
      -- Check if additional mate compatibility options have been set.
      local selectedSpecies = self:config().compatibleMates[self.parent:species()]
      
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

--- Returns a random birth date and day count.
-- @return birthDate, dayCount
function Sexbound.Core.Pregnant:createRandomBirthDate()
  local trimesterCount  = util.randomIntInRange(self:config().trimesterCount or 3)
  local trimesterLength = self:config().trimesterLength or {5, 8}
  
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
