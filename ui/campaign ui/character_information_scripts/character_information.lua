local this = UIComponent(Address)
local root = UIComponent(Component.Root())

function Initialise(character)
  this:InterfaceFunction("InitialiseFromLua", character)
end

function OnHide()
  this:InterfaceFunction("OnHide")
end

function OnExit()
  this:InterfaceFunction("OnHide")
end

function ManageSelection(card, click_up)
  if click_up then
    root:LuaCall("ShowFullCharacterInfo", UIComponent(card):LuaCall("ItemAddress"))
  end
end
