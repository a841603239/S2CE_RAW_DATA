local utilities = require("Utilities")
local this = UIComponent(Address)
local m_going = false
local m_start_time

function SetStatus(status)
  if status == 0 then
    m_going = true
  elseif status == 1 then
    this:SetImageColour(0, 255, 255, 255, 64)
  else
    utilities.PropagateShader(Address, "grey_over_time_t0", 1, 1, 0, 0)
    this:SetImageColour(0, 255, 255, 255, 192)
  end
end

function Update(update_time)
  if m_going then
    if m_start_time == nil then
      m_start_time = update_time
    else
      local scale = (update_time - m_start_time) % 2000 / 2000
      this:SetImageColour(0, 255, 255, 255, 255 - 255 * scale)
    end
  end
end
