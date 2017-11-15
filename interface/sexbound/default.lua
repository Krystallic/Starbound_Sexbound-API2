require "/scripts/interp.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/util.lua"

require "/interface/sexbound/climax/climax.lua"
require "/interface/sexbound/positions/positions.lua"

require "/interface/sexbound/custombutton.lua"

-- Hook - init
function init()
  self.debug = config.getParameter("config.debug") or false
  
  self.sharedAlpha = 0
  
  local extraConfig = config.getParameter("config")
  
  -- Initialize 'climax' UI element.
  local cGUIConfig = config.getParameter("gui.climax")
  self.climax = Climax.new(widget.bindCanvas("climax"), cGUIConfig, extraConfig)
  
  -- Initialize 'positions' UI element.
  local pGUIConfig = config.getParameter("gui.positions")
  self.positions = Positions.new(widget.bindCanvas("positions"), pGUIConfig, extraConfig)
   
  -- Store the main Sexbound controller ID.
  self.controllerId = config.getParameter("config.controllerId")
  
  -- Initialize timers.
  initTimers()
  
  -- Initially focus the player's mouse on the 'positions' canvas widget.
  widget.focus("positions")
  
  -- Initialize buttons.
  self.buttons = {}
  for _,v in ipairs( extraConfig.buttons ) do
    table.insert(self.buttons, CustomButton.new(v))
  end
end

-- Hook - update
function update(dt)
  -- Dismiss this pane when player is no longer lounging.
  if not player.isLounging() then pane.dismiss() end
  
  -- Sync the UI with the Main Sexbound controller.
  self.timer.sync = self.timer.sync + dt
  if self.timer.sync >= self.timeout.sync then
    self.timer.sync = 0
    
    syncUI()
  end
  
  Sexbound_Util.updateMessage("main-sync-ui", function(result)
    if result then
      self.climax:updateProgressBars(result.actors)
    end
  end)
  
  -- Fade in / out this element.
  if self.positions:mousePosition() then
    if rect.contains({0,0,258,258}, self.positions:mousePosition()) then
      self.timer.fadeOut = 0
      fadeIn(dt)
    else
      self.timer.fadeIn = 0
      fadeOut(dt)
    end
  end
  
  -- Update climax
  self.climax:update(dt, function(climax)
    climax:updateAlphaForAllImages( self.sharedAlpha )
  end)
  
  -- Update positions
  self.positions:update(dt, function(position)
    position:updateAlphaForAllImages( self.sharedAlpha )
  end)
  
  render()
end

--- Renders all elements
function render()
  -- Render climax
  self.climax:render()
  
  -- Render position
  self.positions:render()
  
  for _,button in ipairs(self.buttons) do
    if self.debug then
      button:drawPoly(self.positions:canvas())
      button:drawBoundingBox(self.positions:canvas())
    end

    if button:boundingBoxContains(self.positions:mousePosition()) then
      if self.debug then button:drawBoundingBox(self.positions:canvas(), "blue") end
    
      if button:polyContains(self.positions:mousePosition()) then
        -- Draw hover image
        if button:hoverImage() then
          if self.debug then button:drawPoly(self.positions:canvas(), "white") end
          
          self.positions:canvas():drawImage(button:hoverImage(), {129,129}, 1.0, {255,255,255,128}, true)
        end
      end
    end
    
    -- Draw button image
    if button:image() then
      self.positions:canvas():drawImage(button:image(), button:imagePosition(), 1.0, self.positions:config().colorButtons, true)
    end
  end
end

--- Initializes timers.
function initTimers()
  self.timer = {
    fadeIn  = 0,
    fadeOut = 0,
    sync = 0
  }
  
  self.timeout = {
    fadeIn = 0.5,
    fadeOut = 0.5,
    sync = 0.1
  }
end

--- Gradually increases the sharedAlpha value to the value stored in fadeInAlpha.
function fadeIn(dt)
  self.timer.fadeIn = math.min(self.timeout.fadeIn, self.timer.fadeIn + dt)
  
  local ratio = self.timer.fadeIn / self.timeout.fadeIn
  
  self.sharedAlpha = interp.linear(ratio, self.sharedAlpha, 255)
end

--- Gradually decreases the sharedAlpha value to 0.
function fadeOut(dt)
  self.timer.fadeOut = math.min(self.timeout.fadeOut, self.timer.fadeOut + dt)
  
  local ratio = self.timer.fadeOut / self.timeout.fadeOut
  
  self.sharedAlpha = interp.linear(ratio, self.sharedAlpha, 0)
end

function clickEventPositions(position, button, isButtonDown)
  if rect.contains({0,0,258,258}, position) then
    for _,button in ipairs(self.buttons) do
      -- Check if player click within bounding box to save processing.
      if button:boundingBoxContains(position) and button:polyContains(position) then
        if isButtonDown then
          button:playSound()
          
          return button:callAction(function(methodName, methodArgs)
            runAction(methodName, methodArgs)
          end)
        end
      end
    end
  end
end

function runAction(methodName, methodArgs)
  if methodName == "climax" then
    doClimax(methodArgs)
  end
  
  if methodName == "switchPosition" then
    doSwitchPosition(methodArgs)
  end
  
  if methodName == "switchRole" then
    doSwitchRole(methodArgs)
  end
end

function doClimax(args)
  if self.climax:progressBars()[args.actorId].amount >= 0.5 then
    Sexbound_Util.sendMessage(self.controllerId, "main-climax", args)
  end
end

--- Commands the player to open a specified ScriptPane.
function doOpenScriptPane(args)
  player.interact("ScriptPane", args.config)
end

--- Sends a message to the main controller to "switch sex positions".
function doSwitchPosition(args)
  Sexbound_Util.sendMessage(self.controllerId, "main-switch-position", args)
end

--- Sends a message to the main controller to "switch actor roles".
function doSwitchRole(args)
  Sexbound_Util.sendMessage(self.controllerId, "main-switch-role", args)
end

--- Sends a message to the main controller to sync the UI.
function syncUI()
  Sexbound_Util.sendMessage(self.controllerId, "main-sync-ui", nil, true)
end