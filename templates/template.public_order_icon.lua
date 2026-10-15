local this = UIComponent(Address)

function init_state_from_value(val)
  if 0 < val then
    this:SetState("Happy")
  elseif val < 0 then
    this:SetState("Angry")
  else
    this:SetState("Neutral")
  end
end
