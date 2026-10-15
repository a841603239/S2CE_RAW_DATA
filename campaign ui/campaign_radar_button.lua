local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())

function LClickUp()
  this:InterfaceFunction("OnLClickUp")
  local menu = UIComponent(parent:Find("radar_menu"))
  menu:InterfaceFunction("RefreshAll")
end
