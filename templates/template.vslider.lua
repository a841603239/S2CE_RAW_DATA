local this = UIComponent(Address)
utils = require("Utilities")
local handle = UIComponent(this:Find("handle"))
local min = this:GetProperty("minValue")
local max = this:GetProperty("maxValue")
local height = this:Height()
local handle_height = handle:Height()
local inverted = this:GetProperty("Inverted", true)
inverted = inverted ~= nil and (0 < inverted or inverted == "true")
local scale = 1
local prev_value = min - 1
local scroll_weight = this:GetProperty("scrollWeight", true)
if scroll_weight == nil then
  scroll_weight = 10
end
this:SetEventCallback("OnMouseLClickUp", OnMouseLClickUp)

function OnMouseLClickUp(rel_x, rel_y)
  local unary_position = rel_y / height
  if inverted then
    unary_position = 1 - unary_position
  end
  ValueSet(min + (max - min) * unary_position)
end

function InitState()
  Update()
end

function Layout(children)
  Update()
  return children
end

function NotifyListeners(value)
  local notify = this:GetProperty("Notify")
  if notify ~= nil then
    Component.CallByAddress(notify, "LuaCall", "Notify", Address, value)
  end
  this:InterfaceFunction("NotifySelected", value)
end

function Reset()
  height = this:Height()
  min = this:GetProperty("minValue")
  max = this:GetProperty("maxValue")
  local range = max - min
  this:SetVisible(0 < range)
  scale = 0 < range and height / range or 1
  handle:LuaCall("Reset")
  ValueSet(prev_value)
end

function ValueSet(value)
  this:SetProperty("Value", utils.RoundToInt(utils.Clamp(value, min, max)))
  Update()
end

function ValueGet()
  return this:GetProperty("Value")
end

function HandleMoved(handleY)
  _, ourY = this:Position()
  local value = utils.RoundToInt((handleY - ourY) / scale)
  if inverted then
    value = max - value
  end
  if prev_value ~= value then
    this:SetProperty("Value", value)
    prev_value = value
    NotifyListeners(value)
  end
end

function Update()
  local value = utils.Clamp(ValueGet(), min, max)
  this:SetProperty("Value", value)
  handleX, handleY = handle:Position()
  ourX, ourY = this:Position()
  handleY = utils.RoundToInt((value - min) * scale - handle_height / 2)
  if inverted then
    handle:MoveTo(handleX, ourY + (height - (handleY + handle_height)))
  else
    handle:MoveTo(handleX, ourY + handleY)
  end
  if prev_value ~= value then
    this:SetProperty("Value", value)
    prev_value = value
    NotifyListeners(value)
  end
end

function MaxValue()
  return max
end

function MaxValueSet(value)
  this:SetProperty("maxValue", utils.RoundToInt(value))
  Reset()
end

function MinValueSet(value)
  this:SetProperty("minValue", utils.RoundToInt(value))
  Reset()
end

function MoveToBottom()
  ValueSet(max)
end

function OnMouseWheelPush()
  local range = this:GetProperty("maxValue") - this:GetProperty("minValue")
  local current = ValueGet()
  ValueSet(current - utils.Max(1, utils.TruncToInt(range / scroll_weight)))
end

function OnMouseWheelPull()
  local range = this:GetProperty("maxValue") - this:GetProperty("minValue")
  local current = ValueGet()
  ValueSet(current + utils.Max(1, utils.TruncToInt(range / scroll_weight)))
end
