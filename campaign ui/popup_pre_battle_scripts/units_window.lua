local utils = require("Utilities")
local this = UIComponent(Address)

function Initialise(units, players_side)
  this:DestroyChildren()
  local total_men = 0
  local expose_units = players_side ~= true
  for u = 1, #units do
    local x, y = CardPosition(u)
    local cardComponent = UIComponent(utils.CreateUnitCard(units[u], units[u].Id, this:Address(), x, y, true, true, false, expose_units))
    cardComponent:SetState("NonInteractive")
    cardComponent:SetDisabled(true)
    cardComponent:Resize(60, 80)
    cardComponent:LuaCall("SetTooltipFunctionState", nil)
    total_men = total_men + units[u].Men
  end
  return total_men
end

function CardPosition(pos)
  local columns = 7
  local x_spacing = 60
  local y_spacing = 80
  local x = utils.TruncToInt((pos - 1) % columns) * x_spacing
  local y = utils.TruncToInt((pos - 1) / columns) * y_spacing
  return x, y
end
