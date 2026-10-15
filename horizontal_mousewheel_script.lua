local utils = require("Utilities")
local this = UIComponent(Address)
local slider = UIComponent(this:Find("slider"))
local left = UIComponent(slider:Find("left"))
local right = UIComponent(slider:Find("right"))

function OnMouseWheelPull()
  right:LuaCall("UpdateSlider")
end

function OnMouseWheelPush()
  left:LuaCall("UpdateSlider")
end
