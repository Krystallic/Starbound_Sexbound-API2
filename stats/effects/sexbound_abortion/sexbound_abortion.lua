function init()
  status.setStatusProperty("sexbound_abortion", true)
end

function update(dt)
  if not status.statusProperty("sexbound_abortion") then
    effect.expire()
  end
end