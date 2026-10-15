local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local adjusted = false
local orig_x, orig_y = this:Position()
local message_handler = MessageManager

function ReInitialise(details)
  if details then
    Initialise(details)
  end
end

function Initialise(details)
  local settlement_name = UIComponent(this:Find("dy_settlement"))
  settlement_name:SetStateText(details.SettlementName)
  local looting_results = UIComponent(this:Find("panel_loot"))
  UIComponent(looting_results:Find("dy_money")):SetStateText(tostring(details.Looting.Loot))
  UIComponent(looting_results:Find("dy_wealth")):SetStateText(tostring(details.Looting.TownWealth))
  UIComponent(looting_results:Find("dy_public_order_upper")):SetStateText(tostring(details.Looting.UpperOrder))
  UIComponent(looting_results:Find("dy_public_order_lower")):SetStateText(tostring(details.Looting.LowerOrder))
  UIComponent(looting_results:Find("upper_class_reaction_icon")):LuaCall("init_state_from_value", details.Looting.UpperOrder)
  UIComponent(looting_results:Find("lower_class_reaction_icon")):LuaCall("init_state_from_value", details.Looting.LowerOrder)
  local occupation_results = UIComponent(this:Find("panel_occupy"))
  UIComponent(occupation_results:Find("dy_money")):SetStateText(tostring(details.Occupation.Loot))
  UIComponent(occupation_results:Find("dy_wealth")):SetStateText(tostring(details.Occupation.TownWealth))
  UIComponent(occupation_results:Find("dy_public_order_upper")):SetStateText(tostring(details.Occupation.UpperOrder))
  UIComponent(occupation_results:Find("dy_public_order_lower")):SetStateText(tostring(details.Occupation.LowerOrder))
  UIComponent(occupation_results:Find("upper_class_reaction_icon")):LuaCall("init_state_from_value", details.Occupation.UpperOrder)
  UIComponent(occupation_results:Find("lower_class_reaction_icon")):LuaCall("init_state_from_value", details.Occupation.LowerOrder)
  local can_liberate = details.Liberation ~= nil
  local liberation_results = UIComponent(this:Find("panel_liberate"))
  liberation_results:SetVisible(can_liberate)
  local y = can_liberate and utils.Max(0, orig_y - liberation_results:Height() * 0.5) or orig_y
  this:MoveTo(this:Position(), y)
  if can_liberate then
    UIComponent(liberation_results:Find("dy_faction_name")):SetStateText(tostring(details.Liberation.FactionLocation))
  end
  if CampaignUI.IsTimedMultiplayerGame() then
    this:InterfaceFunction("Initialise")
  end
  message_handler.SetCurrentMessageUnread()
end

function LootSettlement()
  CampaignUI.InformLootingSelection("loot")
  Close()
end

function OccupySettlement()
  CampaignUI.InformLootingSelection("occupy")
  Close()
end

function LiberateSettlement()
  CampaignUI.InformLootingSelection("liberate")
  Close()
end

function Close()
  root:LuaCall("ClearSettlementLootingOptions")
  message_handler.CheckForAutoOpen(false)
end
