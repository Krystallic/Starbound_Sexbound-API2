--- Sexbound.Message Class Module.
-- @classmod Sexbound.Message
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Message = {}
Sexbound.Message_mt = {__index = Sexbound.Message}

function Sexbound.Message.new(mFrom, mTo, mType, mData)
  local self = setmetatable({
    _from = mFrom,
    _to   = mTo,
    _type = mType, 
    _data = mData
  }, Sexbound.Message_mt)
  
  return self
end


function Sexbound.Message:getFrom()
  return self._from
end

function Sexbound.Message:getTo()
  return self._to
end

function Sexbound.Message:getType()
  return self._type
end

function Sexbound.Message:getData()
  return self._data
end