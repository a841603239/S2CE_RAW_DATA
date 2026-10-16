local this = UIComponent(Address)
local parent = UIComponent(this:Parent())

function OnClickDown()
  this:InterfaceFunction("SetClicked", true)
end

function OnClickUp()
  this:InterfaceFunction("SetClicked", false)
end

function InitState()
  this:SetEventCallback("OnMouseLClickDown", OnClickDown)
  this:SetEventCallback("OnMouseLClickUp", OnClickUp)
end

function UpdateSlider()
  local value = parent:GetProperty("Value") + this:GetProperty("stepSize")
  parent:SetProperty("Value", value)
  parent:LuaCall("Update")
end
