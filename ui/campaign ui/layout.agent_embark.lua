local utils = require("Utilities")
local agent_manager = utils.Require("Agents")
local this = UIComponent(Address)
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function OnMouseLClickUp()
  ShaneOutput("Embark agent clicked")
  if this:CurrentState() ~= "inactive" then
    agent_manager.ShowExchangePanel()
  end
end
