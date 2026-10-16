function OnLClickUp()
  if Component.GetProperty("select_previous") then
    CampaignUI.PreviousAutoEntitySelection()
  else
    CampaignUI.NextAutoEntitySelection()
  end
end
