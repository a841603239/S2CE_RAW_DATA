local this = UIComponent(Address)
local enlist_commander_entry, blank_commander_entry
local list_box = UIComponent(this:Find("list_box"))
local m_military_force, m_current_selected_commander
local m_confirm_button = UIComponent(this:Find("button_ok"))
local m_max_commanders_in_display = 3
local utils = require("Utilities")
local local_clamp = utils.Clamp

function InitEnlistCommander(naval, military_force)
  out.dylan("InitEnlistCommander")
  m_military_force = military_force
  if enlist_commander_entry == nil then
    enlist_commander_entry = list_box:Find("enlist_commander_entry")
    local parent = UIComponent(enlist_commander_entry):Parent()
    UIComponent(parent):Divorce(enlist_commander_entry)
  end
  if blank_commander_entry == nil then
    blank_commander_entry = list_box:Find("new_general_window")
    local parent = UIComponent(blank_commander_entry):Parent()
    UIComponent(parent):Divorce(blank_commander_entry)
  end
  FillOutInformation(military_force, naval)
  SetSelectedCommander(nil)
end

function FillOutInformation(military_force, is_naval)
  commanders_table = CampaignUI.AvailableCommandersForRecruitment(military_force, is_naval)
  FillAvailableCommanders(commanders_table)
  local num_generals_enlisted = UIComponent(UIComponent(this:Find("tx_generals_enlisted")):Find("dy_number"))
  num_generals_enlisted:SetStateText(commanders_table.CurrentNumGenerals .. " / " .. commanders_table.MaxGeneralsAllowed)
  local distance_frame = UIComponent(this:Find("distance_frame"))
  g_distance_bar_width = distance_frame:Width()
  local percent_distance = 0.01
  if commanders_table.MaxDistanceToTrack > 0 then
    percent_distance = commanders_table.DistanceToCapital / commanders_table.MaxDistanceToTrack
  end
  out.dylan("percent_distance is: " .. tostring(percent_distance) .. ". DistanceToCapital is: " .. tostring(commanders_table.DistanceToCapital) .. ". MaxDistanceToTrack" .. tostring(commanders_table.MaxDistanceToTrack))
  out.dylan("g_distance_bar_width is: " .. tostring(g_distance_bar_width))
  local distance_to_unit = local_clamp(percent_distance, 0.01, 1)
  local distance_bar = UIComponent(distance_frame:Find("bar"))
  distance_bar:Resize(distance_to_unit * g_distance_bar_width, distance_bar:Height())
  local text_turns = UIComponent(this:Find("tx_turns"))
  if #commanders_table < m_max_commanders_in_display then
    local time_till_next_fill = UIComponent(UIComponent(this:Find("tx_turns")):Find("Turns"))
    time_till_next_fill:SetState("queued")
    time_till_next_fill:SetStateText(commanders_table.TurnsToNextPoolFill)
    text_turns:SetVisible(true)
  else
    text_turns:SetVisible(false)
  end
end

function FillAvailableCommanders()
  list_box:DestroyChildren()
  list_box:LuaCall("SetListSpacing", 5)
  local num_available_commanders = 0
  for s, v in ipairs(commanders_table) do
    local c
    c = UIComponent(Component.CreateFromComponent(enlist_commander_entry, "commander_" .. v.Name, list_box:Address(), 0, 0, {}, {}))
    c:LuaCall("InitEnlistCommanderEntry", v)
    num_available_commanders = num_available_commanders + 1
  end
  list_box:Layout()
end

function DismissWithCurrentSelection()
  if m_current_selected_commander ~= nil then
    CampaignUI.PromoteUnits(m_military_force, m_current_selected_commander)
  end
  DismissWithNoSelection()
end

function DismissWithNoSelection()
  Component.Call("Root.LuaCall", "ClosePopup", Address)
end

function SetSelectedCommander(unique_id)
  out.dylan("unique ID to be searched for is: " .. tostring(unique_id))
  m_current_selected_commander = nil
  m_confirm_button:SetState("inactive")
  for i = 0, list_box:ChildCount() - 1 do
    local c = UIComponent(list_box:Find(i))
    local state = c:CurrentState()
    out.dylan("component unique id: " .. tostring(c:LuaCall("UniqueID")))
    if c:LuaCall("Recruitable") == false then
      c:LuaCall("MakeEnlistmentInactive")
    elseif unique_id ~= c:LuaCall("UniqueID") then
      c:SetState("unselected")
    else
      c:SetState("selected")
      m_current_selected_commander = c:LuaCall("CommanderPointer")
      m_confirm_button:SetState("normal")
    end
  end
end

function EnlistDestroyed()
  Component.Destroy(enlist_commander_entry)
  Component.Destroy(blank_commander_entry)
end
