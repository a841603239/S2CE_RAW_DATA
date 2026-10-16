local this = UIComponent(Address)
local utils = require("Utilities")

function InitialiseTrait(traitInfo)
  UIComponent(this:Find("tx_enables")):SetStateText(traitInfo.Name)
  local info_pic = UIComponent(this:Find("effect_icon"))
  local portrait = UIImage(traitInfo.IconFilename)
  portrait:SetComponentTexture(info_pic:Address(), 0)
  SetTraitTooltip(traitInfo)
end

function SetTraitTooltip(traitInfo)
  UIComponent(this:Find("tx_enables")):SetStateText(traitInfo.Name)
  local tooltip = utils.GetEffectList(traitInfo.Effects, traitInfo.AttributeEffects)
  if traitInfo.ColourText ~= nil and traitInfo.ColourText ~= "" then
    if tooltip ~= "" then
      tooltip = tooltip .. "||"
    end
    tooltip = tooltip .. traitInfo.ColourText
  end
  if traitInfo.ExplanationText ~= nil and traitInfo.ExplanationText ~= "" then
    if tooltip ~= "" then
      tooltip = tooltip .. "||"
    end
    tooltip = tooltip .. traitInfo.ExplanationText
  end
  if traitInfo.RemovalText ~= nil and traitInfo.RemovalText ~= "" then
    if tooltip ~= "" then
      tooltip = tooltip .. "||"
    end
    tooltip = tooltip .. traitInfo.RemovalText
  end
  this:SetTooltipText(tooltip)
end
