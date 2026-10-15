local utils = require("Utilities")
local this = UIComponent(Address)
local handle = UIComponent(this:Find("handle"))
local min = this:GetProperty("minValue")
local max = this:GetProperty("maxValue")
local handle_width = handle:Width()
local width = this:Width()
local inverted = this:GetProperty("Inverted", true)
local scale = width / (max - min + 1)
local prev_value = min - 1
this:SetEventCallback("OnMouseLClickUp", OnMouseLClickUp)

function OnMouseLClickUp(rel_x, rel_y)
  local unary_position = rel_x / this:Width()
  out.shane([[



 OnMouseLClickUp, rel_x = ]] .. tostring(rel_x) .. ", this:Position() = " .. tostring(this:Position()) .. ", this:Width() = " .. tostring(this:Width()) .. ", unary_position = " .. tostring(unary_position))
  if inverted then
    unary_position = 1 - unary_position
  end
  ValueSet(min + (max - min) * unary_position)
end

inverted = inverted ~= nil and (0 < inverted or inverted == "true")

function Reset()
  min = Component.GetProperty("minValue")
  max = Component.GetProperty("maxValue")
  if 0 < max - min then
    scale = width / (max - min + 1)
  else
    scale = 0
  end
  handle:LuaCall("Reset")
end

function InitState()
  Reset()
end

function ValueSet(value)
  this:SetProperty("Value", utils.RoundToInt(value))
  Update()
end

function MaxValueSet(value)
  this:SetProperty("maxValue", utils.RoundToInt(value))
  Reset()
end

function MinValueSet(value)
  this:SetProperty("minValue", utils.RoundToInt(value))
  Reset()
end

function ValueGet()
  return utils.RoundToInt(this:GetProperty("Value"))
end

function Update()
  local value = utils.RoundToInt(Component.GetProperty("Value"))
  if value < min then
    value = min
  elseif value > max then
    value = max
  end
  this:SetProperty("Value", value)
  handleX, handleY = handle:Position()
  ourX, ourY = this:Position()
  handleX = utils.RoundToInt((value - min) * scale + scale / 2 - handle_width / 2)
  if inverted then
    handle:MoveTo(ourX + width - handleX, handleY)
  else
    handle:MoveTo(ourX + handleX, handleY)
  end
  if prev_value ~= value then
    prev_value = value
    notify = this:GetProperty("Notify", true)
    if notify ~= nil then
      Component.CallByAddress(notify, "LuaCall", "Notify", Address, value)
    end
    this:InterfaceFunction("NotifySelected", value)
  end
end

function Layout(dropped)
  Update()
end
