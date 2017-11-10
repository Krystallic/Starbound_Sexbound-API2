require "/scripts/sexbound/controller/node.lua"

function init()
  NodeController.init()
end

function die()
  NodeController.destroy()
end

function uninit()
  NodeController.destroy()
end