local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())

function OnMouseLClickUp()
  local region_addr = CampaignUI.RegionFromSelection()
  if region_addr ~= nil then
    root:LuaCall("ShowRegionInfo", region_addr)
  end
end

function OnMouseRClickUp()
end
