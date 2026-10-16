local this = UIComponent(Address)
local screen_w, screen_h
local panel_w, panel_h = this:Dimensions()

function InitDraggablePanel()
  screen_w, screen_h = UIComponent(this:Parent("root")):Dimensions()
end

InitDraggablePanel()

function ClampDragging(current_x, current_y)
  if screen_w == nil or screen_h == nil then
    return
  end
  if current_x < 0 then
    current_x = 0
  end
  if current_y < 0 then
    current_y = 0
  end
  if current_x + panel_w > screen_w then
    current_x = screen_w - panel_w
  end
  if current_y + panel_h > screen_h then
    current_y = screen_h - panel_h
  end
  return current_x, current_y
end

this:SetEventCallback("OnMove", "ClampDragging")
