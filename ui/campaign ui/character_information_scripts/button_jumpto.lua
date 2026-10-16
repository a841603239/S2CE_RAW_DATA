local this = UIComponent(Address)
local CharacterInfoPopup = UIComponent(this:Parent("CharacterInfoPopup"))

function OnMouseLClickUp()
  CharacterInfoPopup:LuaCall("JumpTo")
end
