function InitState()
  print("Initialising Battle Escape Menu")
  
  local return_to_battle_button = Component.Call("FindComponent", "return_to_battle_button")
  Component.Call(return_to_battle_button .. ".LuaCall", "SetParentPopupAddress", Address)
  local quit_battle_button = Component.Call("FindComponent", "quit_battle_button")
  Component.Call(quit_battle_button .. ".LuaCall", "SetParentPopupAddress", Address)
end
