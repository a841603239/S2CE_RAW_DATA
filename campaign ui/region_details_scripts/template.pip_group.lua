local utils = require("utilities")
local this = UIComponent(Address)
local pos_bar = UIComponent(UIComponent(this:Find("positive_bar")):Find("icon_row"))
local neg_bar = this:Find("negative_bar", false)
neg_bar = neg_bar and UIComponent(UIComponent(neg_bar):Find("icon_row"))

function init_pips(pip_details, sig_fig)
  local pos_x = pos_bar:Width() - 6
  local pos_y = (pos_bar:Height() - 30) / 2
  local neg_x = neg_bar and neg_bar:Width() - 6 or 0
  local neg_y = (neg_bar:Height() - 30) / 2
  local pip_size = 28
  local total = string.format("%." .. sig_fig .. "f", pip_details.Total)
  pos_bar:DestroyChildren()
  if neg_bar then
    neg_bar:DestroyChildren()
  end
  if pip_details.IsPercentage then
    total = total .. "%"
  end
  UIComponent(this:Find("total")):SetStateText(tostring(total))
  local total_pos = 0
  local total_neg = 0
  local loop = true
  local current_scale = pip_details.PipValue
  out.tom("Calculating scale for " .. this:Id())
  local last_pos = 0
  local last_neg = 0
  while loop do
    local pos_pips = 0
    local neg_pips = 0
    for i, v in ipairs(pip_details) do
      if v.Lost == nil then
        v.Lost = 0
      end
      if v.Positive then
        pos_pips = pos_pips + utils.Max(utils.RupToInt((v.Total + v.Lost) / current_scale), utils.RupToInt((v.Total + v.Lost + v.Predicted) / current_scale))
      else
        neg_pips = neg_pips + utils.Max(utils.RupToInt((v.Total + v.Lost) / current_scale), utils.RupToInt((v.Total + v.Lost + v.Predicted) / current_scale))
      end
    end
    out.tom("Pos/neg/current scale", pos_pips, neg_pips, current_scale)
    if last_pos == pos_pips and last_neg == neg_pips then
      out.tom("Failed to scale pips")
      current_scale = current_scale == 5 and 1 or current_scale / 10
      loop = false
    elseif pos_x > pos_pips * pip_size and (neg_x == 0 or neg_x > neg_pips * pip_size) then
      loop = false
    elseif current_scale == 1 then
      current_scale = current_scale * 5
    else
      current_scale = current_scale * 10
    end
    last_pos = pos_pips
    last_neg = neg_pips
  end
  for n = 1, #pip_details do
    local images = {
      pip_details[n].Pip
    }
    local lost_pips = utils.RoundToInt(pip_details[n].Lost / current_scale)
    local pips = utils.RupToInt((pip_details[n].Total + pip_details[n].Lost) / current_scale)
    local predicted_pips = utils.RupToInt((pip_details[n].Total + pip_details[n].Lost + pip_details[n].Predicted) / current_scale)
    out.tom(pip_details[n].Total, pip_details[n].Predicted, pips, predicted_pips)
    for a = 1, utils.Max(predicted_pips, pips) do
      if pip_details[n].Positive then
        pos_x = pos_x - pip_size
        parent = pos_bar:Address()
        local pip = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/region_info_pip", "pip" .. n, parent, pos_x, pos_y, images))
        if predicted_pips < a then
          pip:InterfaceFunction("SetStatus", 0)
          pip:SetTooltipText(pip_details[n].PredictedTooltip)
        elseif pips < a then
          pip:InterfaceFunction("SetStatus", 1)
          pip:SetTooltipText(pip_details[n].PredictedTooltip)
        elseif a == pips and a == predicted_pips and pip_details[n].Predicted ~= 0 then
          pip:SetTooltipText(pip_details[n].EqualPipPredictedTooltip)
        elseif lost_pips >= a then
          pip:InterfaceFunction("SetStatus", 2)
          pip:SetTooltipText(pip_details[n].LostTooltip)
        else
          pip:SetTooltipText(pip_details[n].Tooltip)
        end
      elseif neg_bar then
        neg_x = neg_x - pip_size
        parent = neg_bar:Address()
        local pip = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/region_info_pip", "pip" .. n, parent, neg_x, neg_y, images))
        if predicted_pips < a then
          pip:InterfaceFunction("SetStatus", 0)
          pip:SetTooltipText(pip_details[n].PredictedTooltip)
        elseif pips < a then
          pip:InterfaceFunction("SetStatus", 1)
          pip:SetTooltipText(pip_details[n].PredictedTooltip)
        elseif a == pips and a == predicted_pips and pip_details[n].Predicted ~= 0 then
          pip:SetTooltipText(pip_details[n].EqualPipPredictedTooltip)
        elseif lost_pips >= a then
          pip:InterfaceFunction("SetStatus", 2)
          pip:SetTooltipText(pip_details[n].LostTooltip)
        else
          pip:SetTooltipText(pip_details[n].Tooltip)
        end
      end
    end
  end
end
