local this = UIComponent(Address)

function Initialise(details)
  this:SetStateText(details.Value)
  this:SetTooltipText(details.Name)
end
