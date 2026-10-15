local utils = require("Utilities")
local this = UIComponent(Address)
local var_ids = {
  "Name",
  "Experience",
  "Deployed",
  "Lost",
  "Remaining",
  "Kills",
  "Healed"
}
local varvals = {}

function LessThan(c, column)
  if column < #var_ids then
    return varvals[column + 1] < UIComponent(c):LuaCall("GetVar", column + 1)
  end
  return false
end

function SetVar(var_id, var)
  varvals[VarColumn(var_id)] = var
end

function GetVar(column)
  return varvals[column]
end

function VarColumn(var_id)
  for i = 1, #var_ids do
    if var_ids[i] == var_id then
      return i
    end
  end
  return 1
end
