require "/scripts/sexbound/util.lua"

CustomButton = {}
CustomButton.__index = CustomButton

function CustomButton.new(...)
  local self = setmetatable({}, CustomButton)
  self:init(...)
  return self
end

function CustomButton:init(button)
  self.button = button

  -- Assumes at least one pair of coordinates is given.
  self.button.xmin = self.button.poly[1][1]
  self.button.ymin = self.button.poly[1][2]
  self.button.xmax = self.button.xmin
  self.button.ymax = self.button.ymin
  
  self.button.vertCount = 0
  
  self.debug = {
    defaultBoundingBoxAltColor = "blue",
    defaultBoundingBoxColor = "yellow",
    boundingBoxLineWidth = 2.0,
    defaultPolyAltColor = "white",
    defaultPolyColor = "red",
    polyLineWidth = 2.0
  }
  
  self.debug.boundingBoxColor = self.debug.defaultBoundingBoxColor
  self.debug.boundingBoxAltColor = self.debug.defaultBoundingBoxAltColor
  self.debug.polyAltColor = self.debug.defaultPolyAltColor
  self.debug.polyColor = self.debug.defaultPolyColor
  
  for _,v in ipairs(self.button.poly) do
    self.button.xmin = math.min(self.button.xmin, v[1])
    self.button.xmax = math.max(self.button.xmax, v[1])
    self.button.ymin = math.min(self.button.ymin, v[2])
    self.button.ymax = math.max(self.button.ymax, v[2])
    
    self.button.vertCount = self.button.vertCount + 1
  end
  
  self.button.boundingBox = {
    {self.button.xmin, self.button.ymin},
    {self.button.xmin, self.button.ymax},
    {self.button.xmax, self.button.ymax},
    {self.button.xmax, self.button.ymin},
  }
  
  self.button.rect = {
    self.button.xmin, self.button.ymin, self.button.xmax, self.button.ymax
  }
  
  if self.button.image then
    self.button.imageOffset = self.button.imageOffset or {0, 0}

    self.button.imagePosition = vec2.add(rect.center( self.button.rect ), self.button.imageOffset)
  end
end

function CustomButton:drawDebug(canvas)
  -- Draw bounding box
  for i,v in ipairs(self.button.boundingBox) do
    local j = util.wrap(i + 1, 1, 4)
    
    canvas:drawLine(v, self.button.boundingBox[j], self.debug.boundingBoxColor, self.debug.boundingBoxLineWidth)
  end

  -- Draw poly
  for i,v in ipairs(self.button.poly) do
    local j = util.wrap(i + 1, 1, self.button.vertCount)
    
    canvas:drawLine(v, self.button.poly[j], self.debug.polyColor, self.debug.polyLineWidth)
  end
end

function CustomButton:image()
  return self.button.image
end

function CustomButton:imagePosition()
  return self.button.imagePosition
end

function CustomButton:action()
  local methodName = self.button.clickAction.method
  local methodArgs = self.button.clickAction.args
  
  return _ENV[methodName](methodArgs)
end

function CustomButton:boundingBoxContains(point)
  local cond = {
    point[1] < self.button.xmin,
    point[1] > self.button.xmax,
    point[2] < self.button.ymin,
    point[2] > self.button.ymax
  }
  
  if cond[1] or cond[2] or cond[3] or cond[4] then
    self.debug.boundingBoxColor = self.debug.defaultBoundingBoxColor
    return false
  end

  self.debug.boundingBoxColor = self.debug.boundingBoxAltColor
  
  return true
end

function CustomButton:polyContains(point)
  local c = false
  local j = self.button.vertCount
  
  for i=1,self.button.vertCount do
    local vertx1 = self.button.poly[i][1]
    local verty1 = self.button.poly[i][2]
    local vertx2 = self.button.poly[j][1]
    local verty2 = self.button.poly[j][2]
    local pointx = point[1]
    local pointy = point[2]
    
    if ((verty1 > pointy) ~= (verty2 > pointy)) and (pointx < (vertx2 - vertx1) * (pointy - verty1) / (verty2 - verty1) + vertx1) then
      c = not c
    end
    
    j = i
  end
  
  return c;
end

function CustomButton:name()
  return self.button.name
end

function CustomButton:playSound()
  widget.playSound(self.button.clickSound)
end

function CustomButton:poly()
  return self.button.poly
end