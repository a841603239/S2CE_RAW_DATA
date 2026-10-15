local this = UIComponent(Address)
local g_entry_type, g_entry_year, g_entry_status, g_entry_issuer
local g_status_strings = {
  CampaignUI.LocalisationString("Cancelled"),
  CampaignUI.LocalisationString("Failed"),
  CampaignUI.LocalisationString("Completed")
}

function Initialise(details)
  local year = UIComponent(this:Find("year_dy"))
  local type = UIComponent(this:Find("type_dy"))
  local target = UIComponent(this:Find("target_dy"))
  local status = UIComponent(this:Find("status_dy"))
  local issuer = UIComponent(this:Find("issuer_dy"))
  year:SetStateText(details.Year)
  type:SetStateText(details.Activity)
  target:SetStateText(details.Objective)
  issuer:SetStateText(details.Issuer)
  status:SetStateText(g_status_strings[details.Status])
  g_entry_type = details.Activity
  g_entry_year = details.Year
  g_entry_status = g_status_strings[details.Status]
  g_entry_issuer = details.Issuer
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
