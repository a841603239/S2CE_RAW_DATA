function OnLClickUp()
  local notify = Component.GetProperty("Notify")
  
  Component.CallByAddress(notify, "LuaCall", "Notify", Address, Component.Call("CurrentState"))
end

function OnMouseOn()
  local notify = Component.GetProperty("NotifyMouseOn")
  if nil ~= notify then
    Component.CallByAddress(notify, "LuaCall", "NotifyMouseOn", Address, Component.Call("CurrentState"))
  end
end

function OnMouseOff()
  local notify = Component.GetProperty("NotifyMouseOff")
  if nil ~= notify then
    Component.CallByAddress(notify, "LuaCall", "NotifyMouseOff", Address, Component.Call("CurrentState"))
  end
end
