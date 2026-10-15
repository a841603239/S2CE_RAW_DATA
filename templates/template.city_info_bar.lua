local utils = require("CoreUtils")
local this = UIComponent(Address)
local name_bar = UIComponent(this:Find("name_bar"))
local pop_text = UIComponent(this:Find("text_pop_growth"))
local info_bar = UIComponent(this:Find("info_bar"))
local capital_icon = UIComponent(this:Find("capital_icon"))
local pop_change = UIComponent(this:Find("pop_growth_arrow"))
local income_change = UIComponent(this:Find("income_arrow"))
local income_string = UIComponent(this:Find("text_gold"))
local upper_order = UIComponent(this:Find("icon_upper_class"))
local lower_order = UIComponent(this:Find("icon_lower_class"))
local religion = UIComponent(this:Find("pip_religion", true))
local fill = UIComponent(this:Find("fill"))
local previous_state = {}
local settlement_interface
local original = {}
local change_rates = {
  "increase_large",
  "increase_medium",
  "increase_small",
  "decrease_medium",
  "decrease_large"
}

function StateFromOrder(order)
  if order < 0 then
    return "unhappy"
  elseif 0 < order then
    return "happy"
  else
    return "neutral"
  end
end

function OnDestroyed()
  if settlement_interface ~= nil then
    settlement_interface:Release()
    settlement_interface = nil
  end
end

this:SetEventCallback("OnDestroyed", OnDestroyed)

function Initialise(d)
  if settlement_interface == nil then
    original.X, original.Y = this:Position()
  end
  if settlement_interface == nil or d.Address ~= settlement_interface:Settlement() then
    if settlement_interface ~= nil then
      settlement_interface:Release()
    end
    settlement_interface = CampaignSettlement(d.Address)
    details = settlement_interface:LabelDetails()
    details.ScreenPos = d.ScreenPos
    SetCommonDetails()
    HideBottomRow()
  else
    details.ScreenPos = d.ScreenPos
    this:MoveTo(d.ScreenPos.X - name_bar:Width() / 2, d.ScreenPos.Y)
  end
end

function SetCommonDetails()
  capital_icon:SetVisible(details.IsCapital)
  name_bar:SetStateText(details.Name .. ", " .. details.Region.Name)
  for i = 0, 2 do
    fill:SetImageColour(i, details.FactionRGB.R, details.FactionRGB.G, details.FactionRGB.B, 255)
  end
  name_bar:SetStateTextDetails({
    XOffset = details.IsCapital and capital_icon:Width() or 0,
    Colour = utils.PickFGColour(details.FactionRGB)
  })
end

function NotifySettlementUpdated(d)
  local show_bottom_row = details.ShowBottomRow
  d.ScreenPos = details.ScreenPos
  details = d
  SetCommonDetails()
  if show_bottom_row then
    ShowBottomRow()
  else
    HideBottomRow()
  end
end

function HideBottomRow()
  details.ShowBottomRow = false
  info_bar:SetVisible(details.ShowBottomRow)
  local txt, t_w = name_bar:GetStateText()
  local x, y = this:Position()
  local additional_space = details.IsCapital and 20 + (capital_icon:Width() + 2) * 2 or 20
  local w, h = this:Dimensions()
  name_bar:Resize(t_w + additional_space, name_bar:Height())
  fill:Resize(t_w + additional_space, fill:Height())
  this:MoveTo(details.ScreenPos.X - name_bar:Width() / 2, details.ScreenPos.Y)
end

function ShowBottomRow()
  details.ShowBottomRow = true
  info_bar:SetVisible(details.ShowBottomRow)
  local additional_space = details.IsCapital and 20 + (capital_icon:Width() + 2) * 2 or 20
  local txt, t_w = name_bar:GetStateText()
  local w, h = this:Dimensions()
  local line_width = utils.Max(w, t_w + additional_space)
  name_bar:Resize(line_width, name_bar:Height())
  fill:Resize(line_width, fill:Height())
  info_bar:Resize(line_width, info_bar:Height())
  pop_change:SetState(change_rates[details.Region.PopulationChange + 1])
  income_change:SetState(change_rates[details.Region.WealthChange + 1])
  income_string:SetStateText(tostring(details.Region.Wealth))
  religion:SetState(details.Region.ReligionKey)
  pop_text:SetStateText(details.PopulationGrowthString)
  local upper, lower = CampaignUI.RegionsPublicOrders(details.Region.Region)
  upper_order:SetState(StateFromOrder(upper))
  lower_order:SetState(StateFromOrder(lower))
  this:MoveTo(details.ScreenPos.X - name_bar:Width() / 2, details.ScreenPos.Y)
end
