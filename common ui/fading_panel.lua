local this = UIComponent(Address)
local time_to_wait_before_fading = 60000
local duration_of_fade_out = 10000
local unary_fadeout_limit = 0
local last_update_time, m_current_time
local m_fully_faded = false
local all_fading_cancelled = false

function ChangeFadingPanelVisibility(visible)
  if visible == false then
    this:SetVisible(false)
    m_fully_faded = true
  else
    last_update_time = m_current_time
    this:PropagateOpacity(true, 255)
    this:SetVisible(true)
    m_fully_faded = false
  end
end

function IncrementFadeout()
  if m_fully_faded == false then
    local duration_of_fadeout = m_current_time - (time_to_wait_before_fading + last_update_time)
    local percent_of_fadeout = 1 - duration_of_fadeout / duration_of_fade_out
    if percent_of_fadeout > unary_fadeout_limit then
      this:PropagateOpacity(true, percent_of_fadeout * 255)
    else
      if percent_of_fadeout <= 0 then
        ChangeFadingPanelVisibility(false)
      end
      m_fully_faded = true
    end
    return m_fully_faded
  end
  return false
end

function DisallowFading()
  all_fading_cancelled = true
end

function AllowFading()
  if all_fading_cancelled == true then
    last_update_time = m_current_time
  end
  all_fading_cancelled = false
end

function UpdateFadingPanel(time)
  m_current_time = time
  if last_update_time == nil or all_fading_cancelled == true or m_fully_faded then
    return
  end
  if this:IsMouseOverChildren() == true then
    ChangeFadingPanelVisibility(true)
    return
  end
  if m_current_time > time_to_wait_before_fading + last_update_time then
    return IncrementFadeout()
  end
end
