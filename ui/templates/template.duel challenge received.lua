local this = UIComponent(Address)

function InitDetails(attacker, defender)
  UIComponent(this:Find("challenger_panel")):LuaCall("Initialise", attacker)
  UIComponent(this:Find("defendant_panel")):LuaCall("Initialise", attacker)
end

function InstigateDuel(type)
  CampaignUI.FinaliseDuel(type)
  UIComponent(Component.Root()):LuaCall("ClosePopup", Address)
end
