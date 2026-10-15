local utilities = require("Utilities")
local this = UIComponent(Address)
local orig_h = this:Height()

function InitState(state)
  this:Resize(this:Width(), utilities.Max(orig_h, state.Text.DisplayHeight))
  local parent = UIComponent(this:Parent())
  parent:LuaCall("SetTextExtents", width, state.Text.DisplayHeight)
end
