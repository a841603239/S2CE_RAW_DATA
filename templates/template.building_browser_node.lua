local utils = require("utilities")
local this = UIComponent(Address)
local g_building_browser = UIComponent(this:Parent("building_browser"))
local g_region_key, g_faction_key, g_slot_key, g_building_record_key
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(building_record_key, region_key, faction_key, slot_key)
  ShaneOutput("Initialising building browser node with building_record_key " .. tostring(building_record_key) .. ", faction_key " .. tostring(faction_key) .. " and slot_key " .. tostring(slot_key))
  g_building_record_key = building_record_key
  g_region_key = region_key
  g_faction_key = faction_key
  g_slot_key = slot_key
  g_closest_region = nil
end

function OnMouseLDblClick()
  CampaignUI.SelectAndZoomToSlot(g_region_key, g_slot_key, -1)
end

function OnMouseRClickUp()
end

function ShowInfo()
  g_building_browser:LuaCall("ShowBuildingInfo", g_building_record_key, g_region_key, g_faction_key, g_slot_key)
end

function CloseInfoPanel()
  g_building_browser:LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", ShowInfo)
this:SetEventCallback("OnMouseOff", CloseInfoPanel)
