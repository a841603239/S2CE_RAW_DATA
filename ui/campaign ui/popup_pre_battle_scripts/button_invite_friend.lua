local this = UIComponent(Address)

function click()
  local parent = UIComponent(this:Parent("dropin_matchmaking"))
  parent:LuaCall("InviteFriends")
end
