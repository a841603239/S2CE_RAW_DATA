local this = UIComponent(Address)
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function InitialiseCampaignUIUnitAbilityEntry(details)
  ShaneOutput("initialsing ability entry: " .. details.BulletText)
  this:SetStateText(details.BulletText)
  this:SetTooltipText(details.TooltipText)
end

function InitialiseBattleUIUnitAbilityEntry(details)
  out.dylan("initialsing ability entry")
  this:SetStateText(details.bullet_text)
  this:SetTooltipText(details.tooltip_text)
end
