local utils = require("Utilities")
local this = UIComponent(Address)
local all_players = {}
local ffwd_votes = UIComponent(this:Find("ffwd_votes"))
local fwd_votes = UIComponent(this:Find("fwd_votes"))
local play_votes = UIComponent(this:Find("play_votes"))
local slomo_votes = UIComponent(this:Find("slomo_votes"))
local pause_votes = UIComponent(this:Find("pause_votes"))
local PAUSE_SPEED = 0
local SLOMO_SPEED = 0.4
local PLAY_SPEED = 1
local FWD_SPEED = 2
local FFWD_SPEED = 4
local CURRENT_SPEED = PLAY_SPEED
local speed_components = {}
speed_components[PAUSE_SPEED] = pause_votes
speed_components[SLOMO_SPEED] = slomo_votes
speed_components[PLAY_SPEED] = play_votes
speed_components[FWD_SPEED] = fwd_votes
speed_components[FFWD_SPEED] = ffwd_votes
local request_amounts = {}
request_amounts[PAUSE_SPEED] = 0
request_amounts[SLOMO_SPEED] = 0
request_amounts[PLAY_SPEED] = 0
request_amounts[FWD_SPEED] = 0
request_amounts[FFWD_SPEED] = 0

function SetupMultiplayerIndices(alliance_index_info_table)
  all_players = {}
  for index, value in ipairs(alliance_index_info_table) do
    for army_index, each_army in ipairs(value.armies_table) do
      local army = {}
      army.IsHuman = each_army.IsHuman
      army.Alliance = value.alliance_number
      army.ArmyNum = each_army.ArmyNum
      army.SpeedRequest = 1
      all_players[#all_players + 1] = army
    end
  end
end

function HandleMultiplayerTimeChange(change_request)
  if speed_components[change_request.player_multiplier] == nil then
    return false
  end
  out.dylan("change_request. is: " .. tostring(change_request.player_multiplier) .. "current time is: " .. tostring(change_request.overall_multiplier))
  CURRENT_SPEED = change_request.overall_multiplier
  for index, each_army in ipairs(all_players) do
    if each_army.IsHuman then
      CheckArmyAgainstRequest(each_army, change_request)
    end
  end
  ChangeRequestDisplay()
  return true
end

function CheckArmyAgainstRequest(army_to_check, change_request)
  if army_to_check.IsHuman and army_to_check.Alliance == change_request.alliance_index and army_to_check.ArmyNum == change_request.army_index then
    army_to_check.SpeedRequest = change_request.player_multiplier
    out.dylan("CheckArmyAgainstRequest; speed request is=" .. tostring(army_to_check.SpeedRequest) .. "Setting to" .. tostring(change_request.player_multiplier))
  end
end

function ChangeRequestDisplay()
  request_amounts[PAUSE_SPEED] = 0
  request_amounts[SLOMO_SPEED] = 0
  request_amounts[PLAY_SPEED] = 0
  request_amounts[FWD_SPEED] = 0
  request_amounts[FFWD_SPEED] = 0
  for index, each_army in ipairs(all_players) do
    if each_army.IsHuman then
      local current_tracked_amount = request_amounts[each_army.SpeedRequest]
      request_amounts[each_army.SpeedRequest] = current_tracked_amount + 1
      out.dylan("Speed:" .. tostring(each_army.SpeedRequest) .. ", Amount:" .. tostring(current_tracked_amount))
    end
  end
  change_display_for_index(PAUSE_SPEED)
  change_display_for_index(SLOMO_SPEED)
  change_display_for_index(PLAY_SPEED)
  change_display_for_index(FWD_SPEED)
  change_display_for_index(FFWD_SPEED)
end

function change_display_for_index(HASH_INDEX)
  local num_votes = UIComponent(speed_components[HASH_INDEX]:Find("dy_votes"))
  num_votes:SetStateText(request_amounts[HASH_INDEX])
  if request_amounts[HASH_INDEX] == 0 or HASH_INDEX == CURRENT_SPEED then
    speed_components[HASH_INDEX]:SetVisible(false)
  else
    speed_components[HASH_INDEX]:SetVisible(true)
  end
end
