local utilities = require("Utilities")
local this = UIComponent(Address)
local change_rates = {
  "increase_large",
  "increase_medium",
  "increase_small",
  "decrease_medium",
  "decrease_large"
}

function PopulationString(population)
  if population < 100000 then
    return "<0.1m"
  elseif population < 100000000 then
    return string.format("%0.1fm", population / 1000000)
  else
    return string.format("%dm", population / 10000000)
  end
end

function Initialise(details)
  UIComponent(this:Find("income_arrow")):SetState(change_rates[details.WealthChange + 1])
  UIComponent(this:Find("text_gold")):SetStateText(details.Wealth)
  UIComponent(this:Find("pop_growth_arrow")):SetState(change_rates[details.PopulationChange + 1])
  UIComponent(this:Find("text_pop_growth")):SetStateText(PopulationString(tonumber(details.Population)))
  UIComponent(this:Find("pip_religion")):SetState(details.ReligionKey)
end

function OnUpdatePulse(time)
  utilities.PositionTooltip(Address)
end
