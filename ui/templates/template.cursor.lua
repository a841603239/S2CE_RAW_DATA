local lastUpdate = 0
local clicked = false
local this = UIComponent(Address)
local frame = 0

function ClickDown()
  clicked = true
  this:SetState("Click1")
  frame = 1
end

function ClickUp()
  clicked = false
end

function Update(time)
  local x, y = Component.CursorPosition()
  this:MoveTo(x, y)
  if frame ~= 0 and 50 < time - lastUpdate then
    if frame == 6 and clicked == false then
      this:SetState("Normal")
    else
      frame = frame + 1
      this:SetState("Click" .. frame)
    end
    lastUpdate = time
  end
end
