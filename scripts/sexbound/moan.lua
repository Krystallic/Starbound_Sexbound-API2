--- Moan Module.
-- @module Sexbound.Moan
Sexbound.Moan = {}
Sexbound.Moan.__index = Sexbound.Moan

function Sexbound.Moan.new(...)
  local self = setmetatable({}, Sexbound.Moan)
  self:init(...)
  return self
end

--- Initialize this instance.
function Sexbound.Moan:init()
  self.moan = {
    config = Sexbound.Main.getParameter("moan")
  }
end

function Sexbound.Moan:getRandomEmote()
  return util.randomChoice(self.moan.config.emote)
end

--- Plays a random moan sound effect for the specified gender.
-- @param gender
function Sexbound.Moan:playRandom(gender)
  gender = gender or "female"
  
  local pitch = util.randomInRange( self.moan.config.pitch[gender] )
  
  -- Check if animator has sound
  if (animator.hasSound(gender .. "moan")) then
    animator.setSoundPitch(gender .. "moan", pitch, 0)
    animator.playSound(gender .. "moan")
  end
end