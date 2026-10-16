local this = UIComponent(Address)
local icon_tooltips = {
  Sea = CampaignUI.UILocalisationString("route_pip_Sea_Tooltip_590079"),
  Land = CampaignUI.UILocalisationString("route_pip_Land_Tooltip_340071"),
  Blockaded = CampaignUI.UILocalisationString("route_pip_Blockaded_Tooltip_410019"),
  SeaRaided = CampaignUI.UILocalisationString("route_pip_SeaRaided_Tooltip_780052"),
  LandRaided = CampaignUI.UILocalisationString("route_pip_LandRaided_Tooltip_560003"),
  Piracy = CampaignUI.UILocalisationString("route_pip_Piracy_Tooltip_53000b"),
  Banditry = CampaignUI.UILocalisationString("route_pip_Banditry_Tooltip_4f0018")
}

function Initialise(nation_name, icon_state)
  local nation = UIComponent(this:Find("nation"))
  nation:SetStateText(nation_name)
  local icon = UIComponent(this:Find("route_pip"))
  icon:SetState(icon_state)
  icon:SetTooltipText(icon_tooltips[icon_state])
end

function IsOverRoutePip(x, y)
  local pip = UIComponent(this:Find("route_pip"))
  local pip_x, pip_y = pip:Position()
  local parent_x, parent_y = this:Position()
  x = x + parent_x
  y = y + parent_y
  return pip_x <= x and x < pip_x + pip:Width() and pip_y <= y and y < pip_y + pip:Height()
end

function NextSupplyTradeProblem(x, y)
  if IsOverRoutePip(x, y) then
    CampaignUI.NextSupplyTradeProblem(this:GlobalExists("key"))
  end
end

function NextExportTradeProblem(x, y)
  if IsOverRoutePip(x, y) then
    CampaignUI.NextExportTradeProblem(this:GlobalExists("key"))
  end
end
