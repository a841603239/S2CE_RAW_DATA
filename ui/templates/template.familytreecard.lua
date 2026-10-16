local utils = require("Utilities")
local this = UIComponent(Address)
local layout = UIComponent(this:Parent("royal_family"))
local character_attribute = UIComponent(this:Find("CharacterAttribute"))
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function OnLeftClickUp()
  ShaneOutput("Reached OnLeftClickUp")
  layout:LuaCall("SelectHeir", this)
end
