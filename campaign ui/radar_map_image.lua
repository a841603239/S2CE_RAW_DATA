dofile("data/ui/templates/template.map_image.lua")
local this = UIComponent(Address)

function OnLDblClick(x, y)
  local radar = UIComponent(this:Parent("radar"))
  radar:InterfaceFunction("RegionDoubleClicked", x, y)
end
