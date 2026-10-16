local this = UIComponent(Address)

function InitialiseTrait(traitInfo)
  UIComponent(this:Find("dy_name")):SetStateText(traitInfo.Name)
  UIComponent(this:Find("dy_icon")):SetStateText(traitInfo.Name)
  local info_pic = UIComponent(this:Find("dy_icon"))
  local portrait = UIImage(traitInfo.IconFilename)
  portrait:SetComponentTexture(info_pic:Address(), 0)
  local tooltip = ""
  for i = 1, #traitInfo do
    if tooltip ~= "" then
      tooltip = tooltip .. "\n"
    end
    tooltip = tooltip .. traitInfo[i]
  end
  this:SetTooltipText(tooltip)
  this:SetTooltipText(traitInfo.ExplanationText)
end
