dofile("ui/campaign ui/theatre_map_selector.lua")
utilities = require("Utilities")
local panel_manager = PanelManager
local this = UIComponent(Address)
local shane_output = true

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise()
  InitialiseMapHolders(UIComponent(this:Find("Map panel")), CampaignUI.TheatreList(), CampaignUI.PlayerFactionId(), "railroads")
end

function InitialiseIndividualMap(map_component)
  local map = UIComponent(map_component:Find("map"))
  map:SetEventCallback("OnMouseLClickUp", "OnLClickUp")
  map:SetEventCallback("OnMouseRClickUp", "OnRClickUp")
  map:SetEventCallback("OnUpdatePulse", "OnUpdatePulse")
  map:SetGlobal("g_notify_lclickup", RegionLClickUp)
  map:SetGlobal("g_notify_rclickup", RegionRClickUp)
  map:SetGlobal("g_allow_click_transitions", false)
  map:LuaCall("SetHighlightQueryFunction", HighlightRegion)
end

function HighlightRegion(ownerKey, regionAddress)
  this:InterfaceFunction("ShowRegionMouseOverInfo", regionAddress)
  return false
end

function RegionClicked()
end

function RegionLClickUp(region)
  this:InterfaceFunction("RegionLClickUp", region.Address)
end

function RegionRClickUp(region)
  this:InterfaceFunction("RegionRClickUp", region.Address)
end
