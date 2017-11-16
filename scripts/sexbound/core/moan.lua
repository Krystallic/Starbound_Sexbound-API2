--- Sexbound.Core.Moan Class Module.
-- @classmod Sexbound.Core.Moan
Sexbound.Core.Moan = {}
Sexbound.Core.Moan.__index = Sexbound.Core.Moan

function Sexbound.Core.Moan.new(...)
  local self = setmetatable({}, Sexbound.Core.Moan)
  self:init(...)
  return self
end

--- Initializes this instance.
-- @param parent
function Sexbound.Core.Moan:init(parent)
  self.parent = parent
  
  self.moan = {
    config = util.mergeTable({}, Sexbound.API.getParameter("moan"))
  }
  
  self.moan.cooldown = self:refreshCooldown()
  
  self.timer = {moan = 0}
end

--- Updates this module.
-- @param dt
function Sexbound.Core.Moan:update(dt)
  if Sexbound.API.Status.isHavingSex() then
    self.timer.moan = self.timer.moan + dt
    
    if self.timer.moan >= self.moan.cooldown then
      local emote = self.parent:getEmote()
    
      -- Set isMoaning to true in the emote module.
      emote:setIsMoaning(true)
      
      -- Play a random sound effect.
      self:playRandom()
      
      -- Reset the moan timer
      self.timer.moan = 0
      self:refreshCooldown()
    end
  end
end

--- Returns a reference to this module's config.
function Sexbound.Core.Moan:config()
  return self.moan.config
end

--- Plays a random moan sound effect for the specified gender.
-- @param gender
function Sexbound.Core.Moan:playRandom()
  local gender = self.parent:gender() or "female"
  
  local pitch = util.randomInRange( self.moan.config.pitch[gender] )
  
  -- Check if animator has sound
  if (animator.hasSound("moan" .. gender)) then
    animator.setSoundPitch("moan" .. gender, pitch, 0)
    
    animator.playSound("moan" .. gender)
  end
end

--- Refreshes the cooldown time for this module.
function Sexbound.Core.Moan:refreshCooldown()
  self.moan.cooldown = util.randomInRange(self:config().cooldown)
  
  return self.moan.cooldown
end