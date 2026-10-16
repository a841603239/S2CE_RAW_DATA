local utils = require("Utilities")
local this = UIComponent(Address)
sort_columns = {}

function LessThan(c, column)
  local rhs_value = UIComponent(c):GlobalExists("sort_columns")[column + 1]
  return column ~= 0 and sort_columns[column + 1] == rhs_value and sort_columns[1] < UIComponent(c):GlobalExists("sort_columns")[1] or rhs_value > sort_columns[column + 1]
end

function Initialise(clan, route, acquired, exports, value)
  sort_columns = {
    clan,
    tonumber(route),
    tonumber(acquired),
    tonumber(exports),
    tonumber(value)
  }
end
