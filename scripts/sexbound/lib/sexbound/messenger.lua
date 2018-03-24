--- Sexbound.Messenger Class Module.
-- @classmod Sexbound.Messenger
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Messenger = {Channels = {}}
Sexbound.Messenger.__index = Sexbound.Messenger

require "/scripts/sexbound/lib/sexbound/messenger/messagequeue.lua"

function Sexbound.Messenger.new(channel)
  if not Sexbound.Messenger.Channels[channel] then
    Sexbound.Messenger.Channels[channel] = Sexbound.MessageQueue.new()
  end
end

function Sexbound.Messenger.get(channel)
  return Sexbound.Messenger.Channels[channel]
end
