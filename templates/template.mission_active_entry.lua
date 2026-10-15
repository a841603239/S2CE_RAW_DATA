local this = UIComponent(Address)
local g_entry_type, g_entry_year, g_entry_status, g_entry_issuer, g_entry_location

function Initialise(details)
  local activity = UIComponent(this:Find("dy_action_dy"))
  local target = UIComponent(this:Find("target_dy"))
  local desc = UIComponent(this:Find("dy_details"))
  local issuer = UIComponent(this:Find("issuer_dy"))
  local turns = UIComponent(this:Find("Turns"))
  local noturns = UIComponent(this:Find("no_time_limit_tx"))
  local reward = UIComponent(this:Find("reward_dy"))
  local button_zoom = UIComponent(this:Find("button_zoom"))
  activity:SetStateText(details.Title)
  local d, text_width = activity:GetStateText()
  local activity_x, activity_y = activity:Position()
  local target_x, target_y = target:Position()
  target_x, target_y = target:Position()
  local this_x, this_y = this:Position()
  target:Resize(this_x + this:Width() - target_x - 4, target:Height())
  target:SetStateTextDetails({
    HBehaviour = "SplitByWord"
  })
  local objective_width, objective_height = target:SetStateText(details.Objective)
  if objective_height > target:Height() then
    target:Resize(target:Width(), objective_height)
  end
  desc:SetStateText(details.Description)
  issuer:SetStateText(details.Issuer)
  if details.Issuer == "" then
    UIComponent(this:Find("issuer_tx")):SetVisible(false)
  end
  reward:SetStateText(details.Reward)
  if details.RemainingTime > 0 then
    turns:SetVisible(true)
    noturns:SetVisible(false)
    turns:SetStateText(details.RemainingTime)
  else
    turns:SetVisible(false)
    noturns:SetVisible(true)
  end
  if details.Location then
    g_entry_location = details.Location
    button_zoom:SetVisible(true)
    button_zoom:SetEventCallback("OnMouseLClickUp", OnZoom)
  else
    button_zoom:SetVisible(false)
  end
end

function LessThan(c, column)
  if column == 0 then
    return g_entry_year < Component.CallByAddress(c, "LuaCall", "EntryYear")
  elseif column == 1 then
    return g_entry_type < Component.CallByAddress(c, "LuaCall", "EntryType")
  elseif column == 2 then
    return g_entry_status < Component.CallByAddress(c, "LuaCall", "EntryStatus")
  elseif column == 3 then
    return g_entry_issuer < Component.CallByAddress(c, "LuaCall", "EntryIssuer")
  else
    return false
  end
end

function EntryType()
  return g_entry_type
end

function EntryYear()
  return g_entry_year
end

function EntryStatus()
  return g_entry_status
end

function EntryIssuer()
  return g_entry_issuer
end

function OnZoom()
  CampaignUI.SetCameraTarget(g_entry_location.X, g_entry_location.Y, 1)
end
