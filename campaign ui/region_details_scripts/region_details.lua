local utilities = require("Utilities")
local this = UIComponent(Address)
local current_region, details_table, religion_list, last_refresh_time
local visible_region_rows = 4

function Reinitialise()
  local details = CampaignUI.InitialiseRegionInfoDetails(current_region)
  if utilities.CompareByValue(details, details_table) ~= true then
    InitialiseFromDetails(details, true)
  end
end

function InitialisePublicOrderPips(region)
  local details = CampaignUI.InitialiseRegionInfoDetails(region)
  local public_order_panel = this:Find("Public order panel layout", false)
  if public_order_panel ~= nil then
    public_order_panel = UIComponent(public_order_panel)
    if public_order_panel:Visible() then
      UIComponent(public_order_panel:Find("upper_public_order")):LuaCall("init_pips", details.UpperOrder, 0)
    end
  end
end

function InitialiseFromDetails(details, reintialising)
  details_table = details
  current_region = details_table.Address
  UIComponent(this:Find("region_name")):SetStateText(details_table.Name)
  local player_controls = details_table.OwningFactionKey == CampaignUI.PlayerFactionId() and not CampaignUI.PlayerPlayingAsRevolutionaries()
  if reintialising ~= true then
    UIComponent(UIComponent(this:Find("Exempt from tax panel layout")):Find("button_taxes")):SetVisible(player_controls)
  end
  local can_cycle = CampaignUI.HasNextItem()
  UIComponent(this:Find("arrow R")):SetVisible(player_controls and can_cycle)
  UIComponent(this:Find("arrow L")):SetVisible(player_controls and can_cycle)
  UIComponent(UIComponent(this:Find("Exempt from tax panel layout")):Find("checkbox")):SetVisible(player_controls)
  local spawn_info_parent = this:Find("tx_turns_until...", false)
  if spawn_info_parent then
    Component.Destroy(spawn_info_parent)
  end
  local public_order_panel = this:Find("Public order panel layout", false)
  if public_order_panel ~= nil then
    public_order_panel = UIComponent(public_order_panel)
    if public_order_panel:Visible() then
      UIComponent(public_order_panel:Find("upper_public_order")):LuaCall("init_pips", details_table.UpperOrder, 0)
    end
  end
  last_refresh_time = nil
end

function RegionShown()
  return current_region
end

function OnMouseOnTaxIncome()
  local tooltip = UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "tax_income")
  if tooltip then
    BuildTooltip(UIComponent(tooltip), details_table.TaxExempt)
  end
end

function OnMouseOffTaxIncome()
  UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "standard")
end

function BuildTooltip(component, exempt)
  local tax_rate_dy = UIComponent(component:Find("tax_rate_dy"))
  local technology_dy = UIComponent(component:Find("technology_dy"))
  local government_building_dy = UIComponent(component:Find("government_building_dy"))
  local governor_effect_dy = UIComponent(component:Find("governor_effect_dy"))
  local admin_cost_dy = UIComponent(component:Find("admin_cost_dy"))
  local sum_dy = UIComponent(component:Find("sum_dy"))
  local values = {
    tax_rate_dy,
    technology_dy,
    government_building_dy,
    governor_effect_dy,
    admin_cost_dy,
    sum_dy
  }
  local tax_rate_tx = UIComponent(component:Find("tax_rate_tx"))
  local technology_tx = UIComponent(component:Find("technology_tx"))
  local government_building_tx = UIComponent(component:Find("government_building_tx"))
  local governor_effect_tx = UIComponent(component:Find("governor_effect_tx"))
  local admin_cost_tx = UIComponent(component:Find("admin_cost_tx"))
  local sum_tx = UIComponent(component:Find("sum_tx"))
  local texts = {
    tax_rate_tx,
    technology_tx,
    government_building_tx,
    governor_effect_tx,
    admin_cost_tx,
    sum_tx
  }
  local longest_text_length = 0
  for i, v in ipairs(texts) do
    v:SetStateTextDetails({HBehaviour = "NeverSplit"})
    local text, width = v:GetStateText()
    v:SetStateText(text)
    text, width = v:GetStateText()
    longest_text_length = utilities.Max(longest_text_length, width)
  end
  local width = longest_text_length + 20
  local offset = width - tax_rate_tx:Width()
  if 0 < offset then
    for i, v in ipairs(texts) do
      v:Resize(width, v:Height(), false)
      local pos_x, pos_y = values[i]:Position()
      values[i]:MoveTo(pos_x + offset, pos_y)
    end
    local line_addr = component:Find("top_bar")
    if line_addr ~= nil then
      local line = UIComponent(line_addr)
      line:Resize(line:Width() + offset, line:Height())
    end
    component:Resize(component:Width() + offset, component:Height(), false)
  end
  local value = not exempt and details_table.TaxPercentage * 100 or 0
  tax_rate_dy:SetStateText(string.format("%.1f", value) .. "%")
  value = not exempt and details_table.TechnologyPercentage * 100 or 0
  technology_dy:SetStateText(string.format("%.1f", value) .. "%")
  if CampaignUI.IsBoshin() then
    technology_tx:SetStateText(CampaignUI.LocalisationString("bos_town_factor_technology"))
  end
  value = not exempt and details_table.BuildingPercentage * 100 or 0
  government_building_dy:SetStateText(string.format("%.1f", value) .. "%")
  value = not exempt and details_table.GovernorPercentage * 100 or 0
  governor_effect_dy:SetStateText(string.format("%.1f", value) .. "%")
  value = not exempt and details_table.AdministrationCostPercentage * (details_table.TaxPercentage + details_table.BuildingPercentage + details_table.GovernorPercentage + details_table.TechnologyPercentage) * 100 or 0
  admin_cost_dy:SetStateText(string.format("%.1f", value) .. "%")
  value = not exempt and (details_table.UpperTax + details_table.LowerTax) * 100 or 0
  sum_dy:SetStateText(string.format("%.1f", value) .. "%")
end

function OnDestroyed()
  if religion_template then
    Component.Destroy(religion_template:Address(), true)
  end
end

function PreviousRegion()
  local new_region = this:InterfaceFunction("SelectAndZoomToPreviousRegion", current_region)
  if new_region then
    current_region = new_region
    Reinitialise()
  end
end

function NextRegion()
  local new_region = this:InterfaceFunction("SelectAndZoomToNextRegion", current_region)
  if new_region then
    current_region = new_region
    Reinitialise()
  end
end
