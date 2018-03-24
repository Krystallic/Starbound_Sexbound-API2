--- Sexbound.StateMachine Class Module.
-- @classmod Sexbound.StateMachine
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.StateMachine = {}
Sexbound.StateMachine_mt = {__index = Sexbound.StateMachine}

require "/scripts/stateMachine.lua" -- Chucklefish's StateMachine

function Sexbound.StateMachine.new( parent )
  local self = setmetatable({
    _logPrefix = "STMN",
    _parent = parent,
    _states = { "idleState", "sexState", "climaxState", "exitState" },
    _status = {
      havingSex = false,
      climaxing = false,
      reseting  = false
    }
  }, Sexbound.StateMachine_mt)
  
  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
  
  self._stateDefinitions = {
    --[Idle State]----------------------------------------------------------------------------------
    idleState = {
      enter = function()
        if not self:getStatus("havingSex") then
          return {
            actors = self:getParent():getActors()
          }
        end
      end,
      
      enteringState = function(stateData)
        self:getLog():info("Entering Idle State.")
        
        local animationState = parent:getConfig().animationStateIdle
        
        if (animator) then
          if not pcall(function ()
            animator.setAnimationState("main", animationState, true)
          end) then
            self:getLog():error("The animator could not enter the animation state : " .. animationState)
          end
        end
        
        self:getParent():getPositions():resetIndex()
        
        self:getParent():resetAllActors()
        
        animator.setAnimationRate(1)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onEnterIdleState()
        end
      end,
      
      update = function(dt, stateData)
        -- Exit condition
        if self:getParent():getActorCount() > 1 then
          self:setStatus("havingSex", true)
          return true
        end
        
        for _,actor in ipairs(stateData.actors) do
          actor:onUpdateIdleState(dt)
        end
      end,
      
      leavingState = function(stateData)
        self:getParent():getPositions():resetIndex()
        
        for _,actor in ipairs(stateData.actors) do
          actor:onExitIdleState()
        end
      end
    },
    
    --[Sex State]-----------------------------------------------------------------------------------
    sexState = {
      enter = function()
        if self:getStatus("havingSex") and not self:getStatus("climaxing") and not self:getStatus("reseting") then
          return {
            actors = self:getParent():getActors()
          }
        end
      end,
      
      enteringState = function(stateData)
        self:getLog():info("Entering Sex State.")
      
        local positionConfig = self:getParent():getPositions():getCurrentPosition():getConfig()
        
        local animationState = positionConfig.animationState or self:getParent():getConfig().animationStateSex
        
        if not pcall(function ()
          if positionConfig.animationState then
            animator.setAnimationState("main", animationState, true)
          end
        end) then
          self:getLog():error("The animator could not enter the animation state : " .. animationState)
        end
        
        self:getParent():resetAllActors()
        
        animator.setAnimationRate(1)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onEnterSexState()
        end
      end,
      
      update = function(dt, stateData)
        -- Exit condition #1
        if self:getParent():getActorCount() <= 1 then
          self:setStatus("havingSex", false)
          return true
        end
      
        -- Exit condition #2
        if self:getStatus("climaxing") or self:getStatus("reseting") then
          return true
        end
        
        -- Update the animation playback rate
        self:getParent():updateAnimationRate(dt)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onUpdateSexState(dt)
        end
      end,
      
      leavingState = function(stateData) 
        self:getParent():setAnimationRate(1)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onExitSexState()
        end
      end
    },
    
    --[Climax State]--------------------------------------------------------------------------------
    climaxState = {
      enter = function()
        if self:getStatus("havingSex") and self:getStatus("climaxing") then
          return {
            actors = self:getParent():getActors()
          }
        end
      end,
      
      enteringState = function(stateData)
        self:getLog():info("Entering Climax State.")
      
        local positionConfig = self:getParent():getPositions():getCurrentPosition():getConfig()
        
        local animationState = positionConfig.climaxAnimationState or self:getParent():getConfig().animationStateClimax
        
        if not pcall(function()
          animator.setAnimationState("main", animationState, true)
        end) then
          self:getLog():error("The animator could not enter the animation state : " .. animationState)
        end
        
        animator.setAnimationRate(1)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onEnterClimaxState()
        end
      end,
      
      update = function(dt, stateData)
        -- Exit condition #1
        if self:getParent():getActorCount() <= 1 then
          self:setStatus("havingSex", false)
          return true
        end
      
        -- Exit condition #2
        if not self:getStatus("havingSex") or not self:getStatus("climaxing") then
          return true
        end
        
        for _,actor in ipairs(stateData.actors) do
          actor:onUpdateClimaxState(dt)
        end
      end,
      
      leavingState = function(stateData)
        self:setStatus("climaxing", false)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onExitClimaxState()
        end
      end
    },
    
    --[Exit State]----------------------------------------------------------------------------------
    exitState = {
      enter = function()
        if self:getStatus("havingSex") and self:getStatus("reseting") then 
          return {
            actors = self:getParent():getActors()
          }
        end
      end,
      
      enteringState = function(stateData)
        self:getLog():info("Entering Exit State.")
        
        local animationState = self:getParent():getConfig().animationStateExit
        
        if not pcall(function()
          animator.setAnimationState("main", animationState, true)
        end) then
          self:getLog():error("The animator could not enter the animation state : " .. animationState)
        end
        
        animator.setAnimationRate(1)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onEnterExitState()
        end
      end,
      
      update = function(dt, stateData)
        -- Exit condition #1
        if self:getParent():getActorCount() <= 1 then
          self:setStatus("havingSex", false)
          return true
        end
      
        -- Exit condition #2
        if not self:getStatus("havingSex") or not self:getStatus("reseting") then
          return true
        end
        
        for _,actor in ipairs(stateData.actors) do
          actor:onUpdateExitState(dt)
        end
      end,
      
      leavingState = function(stateData)
        self:setStatus("reseting", false)
        
        for _,actor in ipairs(stateData.actors) do
          actor:onExitExitState()
        end
      end
    }
  }
  
  -- Create default states
  self._stateMachine = stateMachine.create(self._states, self._stateDefinitions)
  
  return self
end

--- Updates the state machine.
-- @param dt
function Sexbound.StateMachine:update(dt)
  self._stateMachine.update(dt)
end

-- Getters / Setters

function Sexbound.StateMachine:getLog()
  return self._log
end

function Sexbound.StateMachine:getLogPrefix()
  return self._logPrefix
end

function Sexbound.StateMachine:getParent()
  return self._parent
end

function Sexbound.StateMachine:getStatus(name)
  return self._status[name]
end

function Sexbound.StateMachine:setStatus(name, value)
  self._status[name] = value
end

function Sexbound.StateMachine:isClimaxing()
  return self:getStatus("climaxing")
end

function Sexbound.StateMachine:isHavingSex()
  return self:getStatus("havingSex")
end

function Sexbound.StateMachine:isReseting()
  return self:getStatus("reseting")
end
