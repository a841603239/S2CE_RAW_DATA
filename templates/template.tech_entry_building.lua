local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local g_building_key, g_faction_key, g_closest_slot
local g_slot_ptrs = {}
local g_slot_keys = {}
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShaneOutputFocused(msg)
  if defined.debug then
    out.shane(msg)
  end
end

function Initialise(details)
  g_building_key = details.building_key
  g_faction_key = details.faction_key
  g_slot_ptrs = {}
  g_slot_keys = {}
  ShaneOutput("Initialising building browser node with building_record_key " .. tostring(details.building_key) .. ", faction_key " .. tostring(details.faction_key))
  ShaneOutput("ASSOCIATED SLOTS ARE:")
  for i = 1, #details.slots do
    ShaneOutput(details.slots[i].key)
    g_slot_keys[i] = details.slots[i].key
    g_slot_ptrs[i] = details.slots[i].address
  end
  ShaneOutput("*** details.constructed = " .. tostring(details.constructed))
  if details.constructed == false then
    ShaneOutput("*** details.constructable = " .. tostring(details.constructable))
    if details.constructable == true then
      utils.PropagateShader(Address, "set_greyscale_t0", 0, 0.5)
    else
      utils.PropagateShader(Address, "set_greyscale_t0", 1, 0.5)
    end
  end
  this:SetTooltipText(details.building_name)
end

function OnMouseLDblClick()
  ShaneOutput("Double left click up on tech entry building. Slot keys to be evaluated are: ")
  for i = 1, #g_slot_keys do
    ShaneOutput(tostring(g_slot_keys[i]))
  end
  if g_closest_slot == nil then
    g_closest_slot = CampaignUI.ClosestSlotToCamera(g_slot_ptrs)
  end
  ShaneOutput("Closest valid slot to camera is: " .. tostring(CampaignUI.SlotKeyFromAddress(g_closest_slot)))
  if g_closest_slot ~= nil then
    local closest_slot_key = CampaignUI.SlotKeyFromAddress(g_closest_slot)
    local closest_region_key = CampaignUI.RegionKeyFromSlot(g_closest_slot)
    CampaignUI.SelectAndZoomToSlot(closest_region_key, closest_slot_key, -1)
  end
end

function OnMouseRClickUp()
  if g_closest_slot == nil then
    g_closest_slot = CampaignUI.ClosestSlotToCamera(g_slot_ptrs)
  end
  ShaneOutput("Closest valid slot to camera is: " .. tostring(CampaignUI.SlotKeyFromAddress(g_closest_slot)))
  local closest_slot_key, closest_region_key
  if g_closest_slot ~= nil then
    closest_slot_key = CampaignUI.SlotKeyFromAddress(g_closest_slot)
    closest_region_key = CampaignUI.RegionKeyFromSlot(g_closest_slot)
  end
end

function OpenInfoPanel()
  ShaneOutput("Showing info for tech building node" .. g_building_key)
  if g_closest_slot == nil then
    g_closest_slot = CampaignUI.ClosestSlotToCamera(g_slot_ptrs)
  end
  ShaneOutput("Closest valid slot to camera is: " .. tostring(CampaignUI.SlotKeyFromAddress(g_closest_slot)))
  local closest_slot_key, closest_region_key
  if g_closest_slot ~= nil then
    closest_slot_key = CampaignUI.SlotKeyFromAddress(g_closest_slot)
    closest_region_key = CampaignUI.RegionKeyFromSlot(g_closest_slot)
  end
  root:LuaCall("ShowBuildingInfo", g_building_key, closest_region_key, g_faction_key, closest_slot_key)
end

function CloseInfoPanel()
  root:LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", OpenInfoPanel)
this:SetEventCallback("OnMouseOff", CloseInfoPanel)
