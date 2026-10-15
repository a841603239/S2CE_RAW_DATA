local utils = require("Utilities")
local this = UIComponent(Address)
local vslider = UIComponent(this:Find("vslider"))

function OnMouseWheelPull()
  vslider:LuaCall("OnMouseWheelPull")
end

function OnMouseWheelPush()
  vslider:LuaCall("OnMouseWheelPush")
end

this:SetEventCallback("OnMouseWheelPush", OnMouseWheelPush)
this:SetEventCallback("OnMouseWheelPull", OnMouseWheelPull)
