local utils = require("Utilities")
local this = UIComponent(Address)
local button_group = UIComponent(this:Find("time_limit_ButtonGroup"))
local checks = {
  CPU_moves = UIComponent(this:Find("CPU_moves"))
}
local dropdowns = {
  battle_advice = UIComponent(this:Find("battle_advice")),
  campaign_advice = UIComponent(this:Find("dropdown_campaign"))
}

function Initialise(prefs, prefs_manager)
  local current_options = CampaignUI.CurrentGameOptions()
  for k, v in pairs(current_options) do
    prefs[k] = v
  end
  local options = CampaignUI.LocalisationString("none") .. "|" .. CampaignUI.LocalisationString("low") .. "|" .. CampaignUI.LocalisationString("high")
  for k, v in pairs(dropdowns) do
    v:LuaCall("SetOptions", options)
    v:LuaCall("SelectOption", prefs[k])
  end
  for k, v in pairs(checks) do
    if prefs[k] and v:CurrentState() ~= "inactive" then
      v:SetState("selected")
    end
  end
  local battle_diff_slider = UIComponent(this:Find("battle_diff_slider"))
  battle_diff_slider:SetProperty("maxValue", 3)
  battle_diff_slider:LuaCall("Reset")
  battle_diff_slider:LuaCall("ValueSet", prefs.battle_difficulty)
  for i = 0, button_group:ChildCount() - 2 do
    local c = UIComponent(UIComponent(button_group:Find(i)):Find(0))
    c:SetStateText(string.format(CampaignUI.LocalisationString("battle_time_limit"), utils.battle_timeout_limits[i + 1]))
  end
  if prefs.battle_time_limit ~= -1 then
    for i, v in ipairs(utils.battle_timeout_limits) do
      if prefs.battle_time_limit == v then
        out.tom(prefs.battle_time_limit, i, v)
        button_group:LuaCall("SelectButton", button_group:Find(i - 1))
        break
      end
    end
  else
    button_group:LuaCall("SelectButton", button_group:Find("unlimited"))
  end
end

function GetCurrentOptions()
  local o = {}
  for k, v in pairs(dropdowns) do
    o[k] = v:LuaCall("SelectedOption")
    out.tom(k, o[k])
  end
  for k, v in pairs(checks) do
    o[k] = v:CurrentState() == "selected"
  end
  o.battle_difficulty = UIComponent(this:Find("battle_diff_slider")):GetProperty("Value")
  local tl = button_group:LuaCall("SelectedButton")
  o.battle_time_limit = utils.battle_timeout_limits[tl + 1]
  return o
end
