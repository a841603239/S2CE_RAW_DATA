dofile("ui/campaign ui/theatre_map_selector.lua")
utilities = require("Utilities")
local panel_manager = PanelManager
local tabs = {}
local selected, lowest_public_order
local this = UIComponent(Address)
local slider_tax_lower = UIComponent(UIComponent(this:Find("tx_classes_lower")):Find("slider"))
local imports_slider = UIComponent(UIComponent(this:Find("imports")):Find("vslider"))
local price_change_rates = {
  "increase_large",
  "increase_medium",
  "increase_small",
  "decrease_small",
  "decrease_medium",
  "decrease_large"
}
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ReInitialise()
  Initialise()
end

function RegionClicked()
end

function OnExit()
  this:InterfaceFunction("OnExit")
end

function Initialise()
  this:InterfaceFunction("Initialise")
  slider_tax_lower:SetProperty("Notify", Address)
  imports_slider:SetProperty("Notify", Address)
  tabs.taxes = UIComponent(this:Find("tab_taxes"))
  tabs.trade = UIComponent(this:Find("tab_trade"))
  InitialiseMapHolders(UIComponent(this:Find("Map panel")), CampaignUI.TheatreList(), CampaignUI.PlayerFactionId(), "public_order")
  SelectTab("taxes")
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
  return true
end

function RegionLClickUp(region)
  if region.OwnerKey == CampaignUI.PlayersFactionKey() then
    CampaignUI.SelectAndZoomToRegion(region.Address, utilities.CAMERA_TARGET_POS_CENTRE)
  else
    CampaignUI.ZoomToRegion(region.Address, utilities.CAMERA_TARGET_POS_CENTRE)
  end
end

function RegionRClickUp(region)
  if region.OwnerKey == CampaignUI.PlayersFactionKey() then
    local root = UIComponent(Component.Root())
    root:LuaCall("ShowRegionInfo", region.Address)
  end
end

function OpenLowestPublicOrderRegionDetails()
  lowest_public_order = this:InterfaceFunction("OpenLowestPublicOrder")
  local root = UIComponent(Component.Root())
  root:LuaCall("ShowRegionInfo", lowest_public_order)
  CampaignUI.SelectAndZoomToRegion(lowest_public_order, utilities.CAMERA_TARGET_POS_CENTRE)
end

function Notify(notifier, value)
  if notifier == slider_tax_lower:Address() then
    this:InterfaceFunction("UpdateTaxes", value)
  elseif notifier == imports_slider:Address() then
    this:InterfaceFunction("UpdateImportsSlider", value)
  end
end

function SelectTab(tab)
  this:InterfaceFunction("RefreshTaxEffectImages")
  if selected ~= tab and tabs[tab] ~= nil then
    if selected ~= nil then
      tabs[selected]:SetState("active")
      if tabs[selected]:ChildCount() > 0 then
        assert(tabs[selected]:Find(0) ~= nil)
        UIComponent(tabs[selected]:Find(0)):SetVisible(false)
      end
    end
    tabs[tab]:SetState("selected")
    if tabs[tab]:ChildCount() > 0 then
      assert(tabs[tab]:Find(0) ~= nil)
      UIComponent(tabs[tab]:Find(0)):SetVisible(true)
    end
    selected = tab
    child_order = {}
    for k, v in pairs(tabs) do
      if k ~= tab then
        child_order[#child_order + 1] = v:Address()
      end
    end
    child_order[#child_order + 1] = tabs[tab]:Address()
    UIComponent(this:Find("TabGroup")):ReorderChildren(child_order)
    return true
  end
  return false
end
