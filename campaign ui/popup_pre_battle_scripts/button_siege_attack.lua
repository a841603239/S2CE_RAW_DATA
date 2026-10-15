local this = UIComponent(Address)
local parent = UIComponent(this:Parent("popup_pre_battle"))

function click()
  if this:CurrentState() ~= "Inactive" then
    parent:LuaCall("PreBattleSiegeAttack", Address)
  end
end
