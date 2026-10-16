local Utils = require("Utilities")
local message_handler = MessageManager

function CloseDialog()
  message_handler.HideMessage(Address)
end

function OnInitialMove()
  Component.Call("text_panel.TextView.vslider.LuaCall", "Reset")
end
