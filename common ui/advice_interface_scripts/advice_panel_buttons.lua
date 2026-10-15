local this = UIComponent(Address)
local parent = UIComponent(this:Parent("advice_interface"))

function OptionsButtonClick()
  out.dylan("OptionsButtonClick")
  UIComponent(Component.Root()):LuaCall("ShowEscapeMenu", parent)
end

function ChatNewMessageClick()
  out.dylan("ChatNewMessageClick")
  parent:LuaCall("ChatNewMessageClick")
end

function DismissCurrentAdvice(from_end_turn)
  out.dylan("DismissCurrentAdvice")
  parent:LuaCall("DismissCurrentAdvice", from_end_turn)
end
