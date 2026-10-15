local this = UIComponent(Address)

function OnMouseLDblClick()
  this:InterfaceFunction("DoubleLeftClicked")
end

function OnMouseOn()
  this:InterfaceFunction("MouseOn")
end

function OnMouseOff()
  this:InterfaceFunction("MouseOff")
end

function CloseInfoPanel()
end

function OnMouseLClickUp()
  this:InterfaceFunction("LeftClicked")
end

function ShowInfo()
  this:InterfaceFunction("RightClicked")
end

function TechRightClickUp(component)
  this:InterfaceFunction("TechRightClicked", component:Address())
end

function OnUpdate(time_ms)
end
