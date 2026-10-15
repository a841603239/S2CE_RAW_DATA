dofile("data/ui/templates/cards.lua")
local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local g_parent = UIComponent(this:Parent())
local g_initial_xoffs = 0
local g_initial_yoffs = 0
local g_target_xoffs = 0
local g_target_yoffs = 0
local g_initial_scale = 1
local g_target_scale = 1
local g_begin_time = 0
local g_end_time = 0
local g_item_address
local g_first_init = true
local g_original_width = this:Width()
local g_original_height = this:Height()
local g_initial_height = g_original_height
local g_manager, g_record, g_character, g_tooltip, g_unit_record, g_player_owned, g_faction_key
local g_state_change_time = 0.25
local status_tooltips = {
  CampaignUI.LocalisationString("no_slot_available"),
  CampaignUI.LocalisationString("unaffordable"),
  CampaignUI.LocalisationString("population_too_low"),
  CampaignUI.LocalisationString("damaged_building"),
  CampaignUI.LocalisationString("occupied_building"),
  CampaignUI.LocalisationString("settlement_under_siege"),
  CampaignUI.LocalisationString("maximum_permitted_amount_of_this_unit_type_reached"),
  CampaignUI.LocalisationString("technology_not_yet_researched_for_this_unit_type"),
  CampaignUI.LocalisationString("no_path_available")
}
local localised_capped_string = CampaignUI.LocalisationString("limited_unit_type")
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(recruitment_item, faction_key)
  g_faction_key = faction_key
  g_player_owned = g_faction_key == CampaignUI.PlayersFactionKey()
  g_item_address = recruitment_item.item_ptr
  g_manager = recruitment_item.manager
  g_record = recruitment_item.record
  g_character = recruitment_item.character
  g_unit_record = recruitment_item.unit_record
  if recruitment_item.status == "Unavailable" then
    local index = 1
    local bit_value = 1
    while bit.band(recruitment_item.reasons_unavailable, bit_value) == 0 and index < #status_tooltips do
      index = index + 1
      bit_value = bit_value * 2
    end
    assert(index <= #status_tooltips, "Status for recruitment item is out of range ( safe to continue )")
    g_tooltip = status_tooltips[index]
  end
  ShaneOutput("Initialising recruitment_item experience = " .. tostring(experience))
end

function ShowInfo()
  local id = this:Id()
  local record_key = string.sub(id, 1, string.find(id, "!") - 1)
  root:LuaCall("ShowRecruitableUnitInfo", record_key, g_faction_key, this:GlobalExists("RecruitmentCardCost"), this:GlobalExists("RecruitmentCardExperience"))
end

function Select()
  local status = Component.GetProperty("status")
  local id = this:Id()
  local actual_id = string.sub(id, 1, string.find(id, "!") - 1)
  if "Enqueued" == status or "Paused" == status then
    local slot_index = Component.GetProperty("SlotIndex")
    CampaignUI.CancelRecruitment(g_item_address)
  elseif "Available" == status then
    CampaignUI.RecruitUnit(g_character, g_manager, g_record)
  end
end

function CurrentGreyscale(time)
  local shaderVars = {
    Component.ShaderVarsGet()
  }
  local greyscale_start = shaderVars[1]
  local greyscale_end = shaderVars[2]
  local start_time = shaderVars[3]
  local end_time = shaderVars[4]
  local current_unary_greyscale = greyscale_start
  if 0 < end_time - start_time then
    local time_unary = (time - start_time) / (end_time - start_time)
    if 1 < time_unary then
      current_unary_greyscale = greyscale_end
    else
      current_unary_greyscale = greyscale_start + (greyscale_end - greyscale_start) * time_unary
    end
  end
  return current_unary_greyscale
end

function TargetStateSet(target_xoffs, target_yoffs, target_width, instant_update)
  local game_time = CampaignUI.Time()
  local current_unary_greyscale = CurrentGreyscale(game_time)
  local parent_x, parent_y = g_parent:Position()
  g_initial_height = this:Height()
  g_initial_xoffs, g_initial_yoffs = this:Position()
  g_initial_xoffs = g_initial_xoffs - parent_x
  g_initial_yoffs = g_initial_yoffs - parent_y
  g_initial_scale = this:Width() / g_original_width
  g_target_scale = target_width / g_original_width
  g_target_xoffs = target_xoffs
  g_target_yoffs = target_yoffs + utils.TruncToInt(g_original_height - g_original_height * g_target_scale)
  ShaneOutput("TargetStateSet:")
  ShaneOutput("g_target_scale = " .. tostring(g_target_scale))
  g_begin_time = game_time
  if instant_update == true then
    g_end_time = game_time
  else
    g_end_time = game_time + g_state_change_time
  end
  this:InterfaceFunction("TargetStateSet", g_end_time, g_begin_time, g_initial_height, g_target_scale, g_target_yoffs, g_target_xoffs, g_initial_scale, g_initial_yoffs, g_initial_xoffs)
  this:InterfaceFunction("Update")
end

function OnMouseOn()
  if this:IsInteractive() == true then
    local enqueued = Component.GetProperty("Enqueued")
    local current = root:LuaCall("RecruitmentCardSelected", Address)
    if enqueued == false and current == false then
      ShaneOutput("Selecting recruitment card " .. this:Id())
      root:LuaCall("SelectRecruitmentCard", Component.GetProperty("ChildIndex"), 1)
    end
  end
  local tooltip = root:LuaCall("SetTooltipMethod", "unitcard")
  if tooltip ~= nil then
    local function_state
    if string.sub(this:CurrentState(), 1, 6) == "queue_" then
      function_state = "strat_recruit_queue"
    else
      function_state = "strat_recruit_options"
    end
    local extra_info
    if g_player_owned == true and g_unit_record.UnitLimit > 0 then
      if g_tooltip ~= nil then
        extra_info = g_tooltip .. "\n"
      else
        extra_info = ""
      end
      extra_info = extra_info .. string.format(localised_capped_string, CampaignUI.PlayerUnitTypeCount(g_unit_record.Key), g_unit_record.UnitLimit)
    else
      extra_info = g_tooltip
    end
    UIComponent(tooltip):LuaCall("Initialise", CampaignUI, function_state, g_unit_record, extra_info)
    ShowInfo()
  end
end

function OnMouseOff()
  root:LuaCall("SetTooltipMethod", "standard")
  root:LuaCall("InfoPanelNotUsed")
end

function SelectionIndexGet()
  return Component.GetProperty("ChildIndex")
end

function SelectionIndexSet(index)
  return Component.SetProperty("ChildIndex", index)
end
