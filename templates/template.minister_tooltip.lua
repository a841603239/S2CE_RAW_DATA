local utilities = require("Utilities")
local this = UIComponent(Address)

function Initialise(details)
  local name_component = UIComponent(this:Find("dy_tech_name"))
  local name = details.Name
  if details.PostName then
    name = name .. " - " .. details.PostName
  end
  name_component:SetStateText(name)
  local longest_text = GetTextEndPosition(name_component)
  local i = 1
  for k, v in pairs(details.PostEffects) do
    local c = UIComponent(this:Find("dy_effect_name" .. i))
    c:SetStateText(v.Description)
    longest_text = utilities.Max(longest_text, GetTextEndPosition(c))
    local c = UIComponent(this:Find("effects_icons" .. i))
    c:SetState(k)
    i = i + 1
  end
  local frame = UIComponent(this:Find("frame"))
  local height = frame:Height()
  for j = i, 3 do
    UIComponent(this:Find("dy_effect_name" .. j)):SetVisible(false)
    UIComponent(this:Find("effects_icons" .. j)):SetVisible(false)
    if j == i then
      local this_x, this_y = this:Position()
      local x, y = UIComponent(this:Find("effects_icons" .. j)):Position()
      height = y - this_y
    end
  end
  local x, y = frame:Position()
  this:Resize(longest_text - x + 10, height, false)
  frame:Resize(longest_text - x + 10, height, false)
  utilities.PositionTooltip(Address)
end

function GetTextEndPosition(text_component)
  local details, text_width = text_component:GetStateText()
  if text_width == nil then
    text_width = 0
  end
  local text_x, text_y = text_component:Position()
  return text_x + text_width
end

function OnUpdatePulse(time)
  utilities.PositionTooltip(Address)
end
