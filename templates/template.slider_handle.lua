local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local origX, origY = this:Position()
local sliderLength = parent:Width() - this:Width()
local sliderMin = parent:GetProperty("minValue")
local sliderMax = parent:GetProperty("maxValue")
local inverted = parent:GetProperty("Inverted", true)
inverted = inverted ~= nil and (0 < inverted or inverted == "true")

function Reset()
  sliderMin = parent:GetProperty("minValue")
  sliderMax = parent:GetProperty("maxValue")
  origX, origY = this:Position()
end

function HandleMove()
  local newX, unused = this:Position()
  local sliderX, sliderY = parent:Position()
  if newX < sliderX then
    newX = sliderX
  elseif newX > sliderX + sliderLength then
    newX = sliderX + sliderLength
  end
  this:MoveTo(newX, origY)
  local value = sliderMin + (sliderMax - sliderMin) * ((newX - sliderX) / sliderLength)
  parent:LuaCall("ValueSet", value)
end

function LimitHandle(new_x, new_y)
  x, y = this:Position()
  return new_x, y
end
