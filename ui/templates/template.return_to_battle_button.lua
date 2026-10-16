function OnLeaveDepress()
  local parent = Component.GetProperty("ParentPopup")
  
  Component.Call("Root.LuaCall", "ClosePopup", parent)
end

function SetParentPopupAddress(addr)
  print("Setting parent address: " .. tostring(addr))
  Component.SetProperty("ParentPopup", addr)
end

function ReturnToGame()
  local parent = Component.GetProperty("ParentPopup")
  Component.Call("Root.LuaCall", "ReturnToBattleFromEscapeMenu", parent)
end
