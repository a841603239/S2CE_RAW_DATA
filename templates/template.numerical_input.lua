dofile("data/ui/templates/template.text_input.lua")
local utilities = require("Utilities")
local this = UIComponent(Address)
local min = Component.GetProperty("MinValue")
local max = Component.GetProperty("MaxValue")
local inc = Component.GetProperty("Increment")
if max == 0 then
  max = 10000000
end
local old_set_value = SetValue
local old_char_input = CharacterInput
this:SetStateText(tostring(min))

function ToNumber(val)
  val = tonumber(val)
  if val == nil then
    val = min
  end
  return val
end

function SetMax(val)
  this:SetProperty("MaxValue", val)
  max = val
  SetValue(CheckMax(CurrentValue()))
end

function CheckMax(val)
  val = ToNumber(val)
  if 0 <= max then
    val = utilities.Min(max, val)
  end
  return val
end

function CheckMin(val)
  val = ToNumber(val)
  return utilities.Max(min, val)
end

function CharacterInput(ch)
  if UniChar.is_09(ch) then
    old_char_input(ch)
    local current_value = CurrentValue()
    out.tom("Character input value: " .. current_value)
    if current_value ~= nil then
      local valid_value = CheckMax(CheckMin(current_value))
      if valid_value ~= current_value then
        SetValue(valid_value)
      end
    end
  end
end

function SetValue(val)
  old_set_value(tostring(val))
  if g_notify_func then
    g_notify_func(CurrentValue())
  end
end

function IncreaseAmount()
  SetValue(CheckMax(CurrentValue() + inc))
end

function DecreaseAmount()
  SetValue(CheckMin(CurrentValue() - inc))
end

function CurrentValue()
  return ToNumber(Value())
end
