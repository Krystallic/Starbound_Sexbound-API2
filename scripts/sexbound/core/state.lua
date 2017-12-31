--- Sexbound.Core.StateMachine Class Module.
-- @classmod Sexbound.Core.StateMachine
Sexbound.Core.StateMachine = {}

Sexbound.Core.StateMachine.__index = Sexbound.Core.StateMachine

require "/scripts/stateMachine.lua"

--- Instantiates a new instance of StateMachine.
-- @param[opt] options
function Sexbound.Core.StateMachine.new(...)
  local self = setmetatable({}, Sexbound.Core.StateMachine)

  self.log = Sexbound.Core.Log.new({
    moduleName = "StateMachine"
  })

  local availableStates = { "idleState", "sexState", "climaxState", "exitState"}
  
  local stateTables = {
    --[Idle State]----------------------------------------------------------------------------------
    idleState = {
      enter = function()
        if not Sexbound.API.Status.getStatus("havingSex") then
          return {
            log = Sexbound.Core.Log.new({moduleName = "State:idleState"})
          }
        end
      end,
      
      enteringState = function(stateData)
        stateData.log:info("Entering the idle state.")
        
        animator.setAnimationState("main", Sexbound.API.getParameter("animationStateIdle"), true)
        
        Sexbound.API.Actors.resetAll()
      end,
      
      update = function(dt, stateData)
        -- Exit condition
        if Sexbound.API.Status.getStatus("havingSex") then return true end
      end,
      
      leavingState = function(stateData)
      
      end
    },
    
    --[Sex State]-----------------------------------------------------------------------------------
    sexState = {
      enter = function()
        local status = {
          Sexbound.API.Status.getStatus("havingSex"),
          not Sexbound.API.Status.getStatus("climaxing"),
          not Sexbound.API.Status.getStatus("reseting"),
        }
        
        if status[1] and status[2] and status[3] then
          return {
            log = Sexbound.Core.Log.new({moduleName = "State:sexState"})
          }
        end
      end,
      
      enteringState = function(stateData)
        stateData.log:info("Entering the sex state.")
        
        local position = Sexbound.API.Positions.currentPosition():getData()
        
        if position.animationState then
          animator.setAnimationState("main", position.animationState, true)
        else
          -- Set the default state animation for the sexState state. Start new animation.
          animator.setAnimationState("main", Sexbound.API.getParameter("animationStateSex"), true)
        end
        
        Sexbound.API.Actors.resetAll()
      end,
      
      update = function(dt, stateData)
        local status = {
          not Sexbound.API.Status.getStatus("havingSex"),
          Sexbound.API.Status.getStatus("climaxing"),
          Sexbound.API.Status.getStatus("reseting"),
        }
        
        -- Exit condition
        if status[1] or status[2] or status[3] then
          return true
        end
      end,
      
      leavingState = function(stateData)
      
      end
    },
    
    --[Climax State]--------------------------------------------------------------------------------
    climaxState = {
      enter = function()
        local status = {
          Sexbound.API.Status.getStatus("havingSex"),
          Sexbound.API.Status.getStatus("climaxing")
        }

        if status[1] and status[2] then
          return {
            log = Sexbound.Core.Log.new({moduleName = "State:climaxState"})
          }
        end
      end,
      
      enteringState = function(stateData)
        stateData.log:info("Entering the climax state.")
        
        local position = Sexbound.API.Positions.currentPosition():getData()
        
        local animationState = position.climaxAnimationState or Sexbound.API.getParameter("animationStateClimax")
        
        if not pcall(function()
          animator.setAnimationState("main", animationState, true)
        end) then
          stateData.log:error("The animator could not enter the animation state : " .. animationState)
        end
        
        animator.setAnimationRate(1)
      end,
      
      update = function(dt, stateData)
        local status = {
          not Sexbound.API.Status.getStatus("havingSex"),
          not Sexbound.API.Status.getStatus("climaxing")
        }
        
        -- Exit condition
        if status[1] or status[2] then
          return true
        end
      end,
      
      leavingState = function(stateData)
        Sexbound.API.Status.setStatus("climaxing", false)
      end
    },
    
    --[Exit State]----------------------------------------------------------------------------------
    exitState = {
      enter = function()
        local status = {
          Sexbound.API.Status.getStatus("havingSex"),
          Sexbound.API.Status.getStatus("reseting")
        }

        if status[1] and status[2] then
          return {
            log = Sexbound.Core.Log.new({moduleName = "State:resetState"})
          }
        end
      end,
      
      enteringState = function(stateData)
        stateData.log:info("Entering the exit state.")
        
        animator.setAnimationState("main", Sexbound.API.getParameter("animationStateExit"), true)
      end,
      
      update = function(dt, stateData)
        local status = {
          not Sexbound.API.Status.getStatus("havingSex"),
          not Sexbound.API.Status.getStatus("reseting")
        }
        
        -- Exit condition
        if status[1] or status[2] then
          return true
        end
      end,
      
      leavingState = function(stateData)
        Sexbound.API.Status.setStatus("reseting", false)
      end
    }
  }
  
  -- Create default states
  self.states = stateMachine.create(availableStates, stateTables)
  
  return self
end

--- Updates the state machine.
-- @param dt
function Sexbound.Core.StateMachine:update(...)
  self.states.update(dt)
end
