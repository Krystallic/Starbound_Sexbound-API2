--- Sexbound.Actor.Moan Class Module.
-- @classmod Sexbound.Actor.Moan
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound/actor/plugin.lua"

Sexbound.Actor.Moan = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Moan_mt = { __index = Sexbound.Actor.Moan }

--- Instantiates a new instance of Moan.
-- @param parent
-- @param config
function Sexbound.Actor.Moan:new( parent, config )
  local self = setmetatable({
    _logPrefix    = "MOAN",
    _config       = config,
    _timer        = {moan = 0},
    _soundEffects = {}
  }, Sexbound.Actor.Moan_mt)

  self:init(parent, self._logPrefix, function()
    self._cooldown = self:refreshCooldown()
  end)
  
  -- Initialize female moan sound effect.
  if (animator.hasSound("moanfemale")) then
    self._soundEffects.moanfemale = self._config.sounds.female
    
    animator.setSoundPool("moanfemale", self._soundEffects.moanfemale)
  end
  
  -- Initialize male moan sound effect.
  if (animator.hasSound("moanmale")) then
    self._soundEffects.moanmale = self._config.sounds.male

    animator.setSoundPool("moanmale", self._soundEffects.moanmale)
  end
  
  return self
end

function Sexbound.Actor.Moan:onMessage(message)

end

function Sexbound.Actor.Moan:getCooldown()
  return self._cooldown
end

function Sexbound.Actor.Moan:getSoundEffects(name)
  if name then return self._soundEffects[name] end
  
  return self._soundEffects
end

function Sexbound.Actor.Moan:getTimer(name)
  if name then return self._timer[name] end
  
  return self._timer
end

function Sexbound.Actor.Moan:onEnterSexState()
  self._timer.moan = 0
  
  self:refreshCooldown()
end

function Sexbound.Actor.Moan:onUpdateSexState(dt)
  self._timer.moan = self._timer.moan + dt
  
  if self:getTimer("moan") >= self:getCooldown() then
    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:Moan:Moan", {})

    -- Play a random sound effect.
    self:playRandom()
    
    -- Reset the moan timer
    self._timer.moan = 0
    
    self:refreshCooldown()
  end
end

--- Plays a random moan sound effect for the specified gender.
-- @param gender
function Sexbound.Actor.Moan:playRandom()
  local gender = self:getParent():getGender() or "female"
  
  local pitch = util.randomInRange( self:getConfig().pitch[gender] )
  
  -- Check if animator has sound
  if (animator.hasSound("moan" .. gender)) then
    animator.setSoundPitch("moan" .. gender, pitch, 0)
    
    animator.playSound("moan" .. gender)
  end
end

--- Refreshes the cooldown time for this module.
function Sexbound.Actor.Moan:refreshCooldown()
  self._cooldown = util.randomInRange(self:getConfig().cooldown)
  
  return self._cooldown
end