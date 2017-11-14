--- Moan Module.
-- @module Sexbound.Moan
Sexbound.Moan = {}
Sexbound.Moan.__index = Sexbound.Moan

function Sexbound.Moan.new(...)
  local self = setmetatable({}, Sexbound.Moan)
  self:init(...)
  return self
end

--- Initializes this instance.
-- @param parent
function Sexbound.Moan:init(parent)
  self.parent = parent
  
  self.moan = {
    config = util.mergeTable({}, Sexbound.Main.getParameter("moan"))
  }
  
  self.moan.cooldown = self:refreshCooldown()
  
  self.timer = {moan = 0}
end

--- Updates this module.
-- @param dt
function Sexbound.Moan:update(dt)
  if Sexbound.Main.isHavingSex() then
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
function Sexbound.Moan:config()
  return self.moan.config
end

--- 
function Sexbound.Moan:getRandomEmote()
  local emotes = self:config().emote

  return util.randomChoice(emotes)
end

--- Plays a random moan sound effect for the specified gender.
-- @param gender
function Sexbound.Moan:playRandom()
  local gender = self.parent:gender() or "female"
  
  local pitch = util.randomInRange( self.moan.config.pitch[gender] )
  
  -- Check if animator has sound
  if (animator.hasSound(gender .. "moan")) then
    animator.setSoundPitch(gender .. "moan", pitch, 0)
    animator.playSound(gender .. "moan")
  end
end

--- Refreshes the cooldown time for this module.
function Sexbound.Moan:refreshCooldown()
  self.moan.cooldown = util.randomInRange(self:config().cooldown)
  
  return self.moan.cooldown
end