local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local region_key, building_key, faction_key, slot_key
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(building_details, region, faction, slot, potential_recruitment)
  region_key = region
  faction_key = faction
  building_key = building_details.Key
  slot_key = slot
  local image = UIImage(building_details.IconFilename)
  image:SetComponentTexture(Address, 0)
  this:SetTooltipText(building_details.Name, true)
  UIComponent(this:Find("building_name")):SetStateText(building_details.Name)
  this:SetVisible(true)
  this:SetInteractive(true)
  if 0 < #potential_recruitment then
    local init_x = 100
    local init_y = -15
    local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_info_recruitment_effects", "building_info_recruitment_effects", Address, init_x, init_y))
    component:LuaCall("Initialise", potential_recruitment, region_key, faction_key, slot_key, building_key, false, false)
  end
end

function OnMouseRClickUp()
end

function ShowInfo()
  ShaneOutput("ShowBuildingInfo - Building = " .. tostring(building_key) .. ", Faction = " .. tostring(faction_key) .. " Region = " .. tostring(region_key) .. " Slot = " .. tostring(slot_key))
  root:LuaCall("ShowBuildingInfo", building_key, region_key, faction_key, slot_key)
end

function OnMouseOn()
  local tooltip = UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "technology")
  if tooltip ~= nil then
    BuildTooltip(UIComponent(tooltip))
    ShowInfo()
  end
end

function OnMouseOff()
  UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "standard")
  g_tooltip_component = nil
  root:LuaCall("InfoPanelNotUsed")
end
