local utilities = require("Utilities")
local this = UIComponent(Address)
local name_component = UIComponent(this:Find("txt_name"))
local function_component = UIComponent(this:Find("txt_function"))
local description_component = UIComponent(this:Find("txt_window"))
local crew_component = UIComponent(this:Find("men_info_parent"))
local last_stat_component = UIComponent(this:Find("dy_stat4"))
local localised_strings, creation_time
local expanded = false
local expand_time = 1000

function Initialise(ui, function_state, unit_record, extra_info, commanders_name, regiment_name, unit_scale)
  InitialiseLocalisedString(ui)
  local name
  if commanders_name == nil then
    if unit_record.IsNaval then
      name = unit_record.Name
    else
      name = unit_record.Name .. " (" .. unit_record.Class .. ")"
    end
  else
    name = commanders_name .. ", " .. unit_record.Name
  end
  if regiment_name ~= nil and regiment_name ~= "" then
    name = name .. " - " .. regiment_name
  end
  name_component:SetStateText(name)
  if function_state == nil then
    function_component:SetVisible(false)
  else
    function_component:SetState(function_state)
    function_component:SetVisible(true)
  end
  local description = string.gsub(unit_record.Description, "||", "\n")
  if extra_info == nil then
    description_component:SetStateText(description)
  else
    description_component:SetStateText(description .. "\n" .. extra_info)
  end
  description_component:SetVisible(false)
  crew_component:SetVisible(false)
  local recruitment = function_state == "strat_recruit_options" or function_state == "frontend_recruit_options" or function_state == "frontend_insufficient_funds"
  if unit_record.IsNaval then
    if unit_record.Guns ~= nil and unit_record.Guns > 0 and recruitment then
      UIComponent(crew_component:Find("crew_icon")):SetState("cannon")
      UIComponent(crew_component:Find("txt_men")):SetStateText(unit_record.Guns)
      crew_component:SetVisible(true)
    else
      UIComponent(crew_component:Find("crew_icon")):SetState("men")
      local men = unit_record.Men
      if unit_record.Seamen ~= nil then
        men = men + unit_record.Seamen
      end
      if unit_record.Gunners ~= nil then
        men = men + unit_record.Gunners
      end
      UIComponent(crew_component:Find("txt_men")):SetStateText(men)
      crew_component:SetVisible(true)
    end
  elseif unit_record.Men ~= nil and recruitment then
    if unit_scale == nil then
      unit_scale = ui.UnitScaleFactor()
    end
    UIComponent(crew_component:Find("crew_icon")):SetState("men")
    UIComponent(crew_component:Find("txt_men")):SetStateText(utilities.TruncToInt(unit_record.Men * unit_scale))
    crew_component:SetVisible(true)
  end
  if unit_record.IsNaval then
    SetStat(1, "unit_stat_firepower", utilities.RoundToInt(unit_record.Firepower))
    SetStat(2, "unit_stat_speed", unit_record.Speed)
    manoeuvrability = ui.LocalisationString(unit_record.Manoeuvrability)
    SetStat(3, "unit_stat_manoeuvre", manoeuvrability)
    SetStat(4, "unit_stat_hull", unit_record.HullStrength)
  elseif unit_record.IsArtillery then
    AddOneMoreLine()
    SetStat(1, "unit_stat_range", unit_record.Range)
    SetStat(2, "unit_stat_accuracy", unit_record.Accuracy)
    SetStat(3, "unit_stat_melee", unit_record.Melee)
    SetStat(4, "unit_stat_defence", unit_record.Defence)
    SetStat(5, "unit_stat_morale", unit_record.Morale)
  elseif 0 < unit_record.Range then
    AddOneMoreLine()
    SetStat(1, "unit_stat_range", unit_record.Range)
    SetStat(2, "unit_stat_accuracy", unit_record.Accuracy)
    SetStat(3, "unit_stat_melee", unit_record.Melee)
    SetStat(4, "unit_stat_defence", unit_record.Defence)
    SetStat(5, "unit_stat_morale", unit_record.Morale)
  else
    SetStat(1, "unit_stat_melee", unit_record.Melee)
    SetStat(2, "unit_stat_charge", unit_record.Charge)
    SetStat(3, "unit_stat_defence", unit_record.Defence)
    SetStat(4, "unit_stat_morale", unit_record.Morale)
  end
  Resize()
  creation_time = nil
  expanded = false
end

function InitialiseAgent(ui, agent)
  InitialiseLocalisedString(ui)
  name_component:SetStateText(agent.name .. " (" .. agent.agent_type_name .. ")")
  function_component:SetState("strat_army")
  crew_component:SetVisible(false)
  UIComponent(this:Find("dy_stat1")):SetVisible(false)
  UIComponent(this:Find("dy_stat2")):SetVisible(false)
  UIComponent(this:Find("dy_stat3")):SetVisible(false)
  UIComponent(this:Find("dy_stat4")):SetVisible(false)
  Resize()
  expanded = true
end

function InitialiseLocalisedString(ui)
  localised_strings = {
    unit_stat_accuracy = ui.LocalisationString("unit_stat_accuracy"),
    unit_stat_charge = ui.LocalisationString("unit_stat_charge"),
    unit_stat_defence = ui.LocalisationString("unit_stat_defence"),
    unit_stat_firepower = ui.LocalisationString("unit_stat_firepower"),
    unit_stat_hull = ui.LocalisationString("unit_stat_hull"),
    unit_stat_manoeuvre = ui.LocalisationString("unit_stat_manoeuvre"),
    unit_stat_melee = ui.LocalisationString("unit_stat_melee"),
    unit_stat_morale = ui.LocalisationString("unit_stat_morale"),
    unit_stat_range = ui.LocalisationString("unit_stat_range"),
    unit_stat_reloading = ui.LocalisationString("unit_stat_reloading"),
    unit_stat_speed = ui.LocalisationString("unit_stat_speed")
  }
end

function SetStat(i, text, value)
  local c = UIComponent(this:Find("dy_stat" .. i))
  c:SetStateText(localised_strings[text])
  local v = UIComponent(c:Find("dy_value"))
  v:SetStateText(value)
  v:Resize(500, v:Height())
end

function AddOneMoreLine()
  if this:Find("dy_stat5", false) == nil then
    local this_x, this_y = this:Position()
    local stat3 = UIComponent(this:Find("dy_stat3"))
    local stat4 = UIComponent(this:Find("dy_stat4"))
    local stat3_x, stat3_y = stat3:Position()
    local stat4_x, stat4_y = stat4:Position()
    local offset = stat4_y - stat3_y
    last_stat_component = UIComponent(Component.CreateFromComponent(stat4:Address(), "dy_stat5", Address, stat4_x - this_x, stat4_y + offset - this_y, {}, {}))
    local description_x, description_y = description_component:Position()
    description_component:MoveTo(description_x, description_y + offset)
  end
end

function Expand()
  description_component:SetVisible(true)
  ResizeExpanded()
  expanded = true
end

function Resize()
  local this_x, this_y = this:Position()
  local name_details, name_width, name_height = name_component:GetStateText()
  local function_details, function_width, function_height = function_component:GetStateText()
  local crew_width = 0
  if crew_component:Visible() then
    crew_width = crew_component:Width() + 15
  end
  local width = 300
  width = utilities.Max(name_width + crew_width + 15, width)
  width = utilities.Max(function_width + 15, width)
  if not last_stat_component:Visible() then
    last_stat_component = function_component
  end
  local bottom_x, bottom_y = last_stat_component:Position()
  local height = bottom_y + last_stat_component:Height() + 5 - this_y
  UIComponent(this:Find("frame")):Resize(width, height)
  this:Resize(width, height, false)
  description_component:Resize(width - 12, description_component:Height())
  local crew_x, crew_y = crew_component:Position()
  crew_component:MoveTo(this_x + width - crew_component:Width() - 5, crew_y)
  utilities.PositionTooltip(Address)
end

function ResizeExpanded()
  local this_x, this_y = this:Position()
  local description_x, description_y = description_component:Position()
  local desc_details, desc_width, desc_height = description_component:GetStateText()
  local height = description_y + desc_height + 5 - this_y
  UIComponent(this:Find("frame")):Resize(this:Width(), height)
  this:Resize(this:Width(), height, false)
  utilities.PositionTooltip(Address)
end

function OnUpdatePulse(time)
  if creation_time == nil then
    creation_time = time
  elseif not expanded and time - creation_time >= expand_time then
    Expand()
  end
  utilities.PositionTooltip(Address)
end
