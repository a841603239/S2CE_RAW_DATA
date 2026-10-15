local utils = require("Utilities")
local army_manager = utils.Require("Army")
local this = UIComponent(Address)
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function OnMouseLClickUp()
  ShaneOutput("Build fort clicked")
  if this:CurrentState() ~= "inactive" then
    army_manager.BuildFort()
  end
end
