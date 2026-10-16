function InitState(state)
  local textWidth = state.Text.DisplayWidth
  
  state.Images[2].Width = textWidth + 10
  state.Images[3].X = textWidth + 10 + state.Images[1].Width
  Component.Call("Parent.LuaCall", "Notify", Component.Messages.Move, Address)
  return state
end

function LClick()
  Component.Call("Parent.LuaCall", "Notify", Component.Messages.LClickUp, Address)
end
