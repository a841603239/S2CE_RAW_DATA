function UpdateSlider()
  local value = Component.GetProperty("Parent.Value") - Component.GetProperty("stepSize")
  
  Component.SetProperty("Parent.Value", value)
  Component.Call("Parent.LuaCall", "Update")
end
