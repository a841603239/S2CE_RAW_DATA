local this = UIComponent(Address)
local s2_review_controls = UIComponent(this:Parent("s2_review_controls"))

function OnMouseLClickUp()
  s2_review_controls:InterfaceFunction("LeftClickUp", Address)
end
