local this = UIComponent(Address)
local parent = UIComponent(this:Parent())

function MinimiseParent()
  out.dylan("MinimiseParent called")
  parent:LuaCall("MinimiseThisWindow")
end

this:SetEventCallback("OnMouseLClickUp", MinimiseParent)
