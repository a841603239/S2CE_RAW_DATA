local utils = require("CoreUtils")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local slider_height = parent:Height()
local origX, origY = this:Position()
local sliderMin = parent:GetProperty("minValue")
local sliderMax = parent:GetProperty("maxValue")
local inverted = parent:GetProperty("Inverted", true)
inverted = inverted ~= nil and (0 < inverted or inverted == "true")
local half_height = this:Height() / 2

function HandleMove()
  local _, y = this:Position()
  parent:LuaCall("HandleMoved", y + half_height)
end

function LimitHandle(newX, newY)
  x, y = this:Position()
  if LimitToSelectedItem ~= nil then
    return LimitToSelectedItem(x, newY)
  else
    local _, sliderY = parent:Position()
    local maxY = sliderY + slider_height - half_height
    newY = utils.Clamp(newY, sliderY - half_height, maxY)
    return x, newY
  end
end

function Layout(children)
  return children
end

function Reset()
  sliderMin = parent:GetProperty("minValue")
  sliderMax = parent:GetProperty("maxValue")
  slider_height = parent:Height()
  origX, origY = this:Position()
end
