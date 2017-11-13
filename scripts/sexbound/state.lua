require "/scripts/stateMachine.lua"

Sexbound.StateMachine = {}

Sexbound.StateMachine.__index = Sexbound.StateMachine

function Sexbound.StateMachine.new(...)
  local self = setmetatable({}, Sexbound.StateMachine)
  self:init(...)
  return self
end

function Sexbound.StateMachine:init(options)
  self.log = Sexbound.Log.new({
    moduleName = "StateMachine"
  })

  -- Create default states
  self.states = stateMachine.create({ "idleState", "sexState", "climaxState", "exitState" })
end

--- Updates the state machine.
-- @param dt
function Sexbound.StateMachine:update(...)
  self.states.update(dt)
end

--[Idle State]--------------------------------------------------------------------------------------

idleState = {}

function idleState.enter()
  if not Sexbound.Main.getStatus("havingSex") then
    return {
      log = Sexbound.Log.new({moduleName = "State:idleState"})
    }
  end
end

function idleState.enteringState(stateData)
  stateData.log:info("Entering the idle state.")
  
  animator.setAnimationState("main", Sexbound.Main.getParameter("animationStateIdle"), true)
  
  Sexbound.Main.resetActors()
end

function idleState.update(dt, stateData)
  -- Exit condition
  if Sexbound.Main.getStatus("havingSex") then return true end
end

function idleState.leavingState(stateData)

end

--[Sex State]---------------------------------------------------------------------------------------

sexState = {}

function sexState.enter()
  local status = {
    Sexbound.Main.getStatus("havingSex"),
    not Sexbound.Main.getStatus("climaxing"),
    not Sexbound.Main.getStatus("reseting"),
  }
  
  if status[1] and status[2] and status[3] then
    return {
      log = Sexbound.Log.new({moduleName = "State:sexState"})
    }
  end
end

function sexState.enteringState(stateData)
  stateData.log:info("Entering the sex state.")
  
  local position = Sexbound.Main.currentPosition():getData()
  
  if position.animationState then
    animator.setAnimationState("main", position.animationState, true)
  else
    -- Set the default state animation for the sexState state. Start new animation.
    animator.setAnimationState("main", Sexbound.Main.getParameter("animationStateSex"), true)
  end
  
  Sexbound.Main.resetActors()
end

function sexState.update(dt, stateData)
  local status = {
    not Sexbound.Main.getStatus("havingSex"),
    Sexbound.Main.getStatus("climaxing"),
    Sexbound.Main.getStatus("reseting"),
  }
  
  -- Exit condition
  if status[1] or status[2] or status[3] then
    return true
  end
end

function sexState.leavingState(stateData)

end

--[Climax State]------------------------------------------------------------------------------------

climaxState = {}

function climaxState.enter()
  local status = {
    Sexbound.Main.getStatus("havingSex"),
    Sexbound.Main.getStatus("climaxing")
  }

  if status[1] and status[2] then
    return {
      log = Sexbound.Log.new({moduleName = "State:climaxState"})
    }
  end
end

function climaxState.enteringState(stateData)
  stateData.log:info("Entering the climax state.")
  
  local position = Sexbound.Main.currentPosition():getData()
  
  local animationState = position.climaxAnimationState or Sexbound.Main.getParameter("animationStateClimax")
  
  if not pcall(function()
    animator.setAnimationState("main", animationState, true)
  end) then
    stateData.log:error("The animator could not enter the animation state : " .. animationState)
  end
  
  animator.setAnimationRate(1)
end

function climaxState.update(dt, stateData)
  local status = {
    not Sexbound.Main.getStatus("havingSex"),
    not Sexbound.Main.getStatus("climaxing")
  }
  
  -- Exit condition
  if status[1] or status[2] then
    return true
  end
end

function climaxState.leavingState(stateData)

end

--[Exit State]--------------------------------------------------------------------------------------

exitState = {}

function exitState.enter()
  local status = {
    Sexbound.Main.getStatus("havingSex"),
    Sexbound.Main.getStatus("reseting")
  }

  if status[1] and status[2] then
    return {
      log = Sexbound.Log.new({moduleName = "State:resetState"})
    }
  end
end

function exitState.enteringState(stateData)
  stateData.log:info("Entering the exit state.")
  
  animator.setAnimationState("main", Sexbound.Main.getParameter("animationStateExit"), true)
end

function exitState.update(dt, stateData)
  local status = {
    not Sexbound.Main.getStatus("havingSex"),
    not Sexbound.Main.getStatus("reseting")
  }
  
  -- Exit condition
  if status[1] or status[2] then
    return true
  end
end

function exitState.leavingState(stateData)

end