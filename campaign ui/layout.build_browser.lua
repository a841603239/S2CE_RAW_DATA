local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function OnLeftClickUp()
  ShaneOutput("Building browser clicked")
  Component.Call("Root.LuaCall", "ShowBuildingBrowser")
end
