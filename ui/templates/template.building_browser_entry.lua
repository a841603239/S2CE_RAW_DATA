local utils = require("Utilities")
local this = UIComponent(Address)
local g_details
local g_tooltip_id = 0
local g_max_level_display = 7
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShowBuildingInfo()
  UIComponent(this:Parent("building_browser")):LuaCall("ShowBuildingInfo", g_details.building_key, g_details.region_key, g_details.faction_key, g_details.slot_key)
end

function Initialise(details, type_names, odd_or_even_line)
  g_details = details
  local name = UIComponent(this:Find("dy_name"))
  local location = UIComponent(this:Find("dy_location"))
  local entry_type = UIComponent(this:Find("dy_type"))
  local icon = UIComponent(this:Find("dy_icon"))
  this:SetTooltipText(details.entry_tooltip1, true)
  if odd_or_even_line == 1 then
    this:SetState("B_normal")
  else
    this:SetState("A_normal")
  end
  name:SetStateText(details.name)
  location:SetStateText(details.location)
  if details.slot_type_name then
    entry_type:SetStateText(details.slot_type_name)
  else
    entry_type:SetStateText(type_names[details.type])
  end
  for i = 1, g_max_level_display do
    UIComponent(this:Find("Level Pip " .. i)):SetVisible(false)
  end
  local construction_site = details.level < 0
  if construction_site == false then
    for i = 1, details.max_level + 1 do
      UIComponent(this:Find("Level Pip " .. i)):SetVisible(true)
    end
    for i = 1, details.level + 1 do
      UIComponent(this:Find("Level Pip " .. i)):SetState("filled")
    end
  else
    local state_name = "normal"
    if details.slot_type == "settlement_army-admin" then
      state_name = "placeholder_army"
    elseif details.slot_type == "settlement_navy-admin" then
      state_name = "placeholder_navy"
    elseif details.slot_type == "settlement_ordnance" then
      state_name = "placeholder_artillery"
    elseif details.slot_type == "settlement_culture" then
      state_name = "placeholder_culture"
    elseif details.slot_type == "settlement_government" then
      state_name = "placeholder_government"
    elseif details.slot_type == "settlement_fortification" then
      state_name = "placeholder_fortifications"
    end
    icon:SetState(state_name)
  end
end

function OnLeftClickUp()
  if g_tooltip_id == 0 then
    g_tooltip_id = 1
    this:SetTooltipText(g_details.entry_tooltip2, true)
  else
    g_tooltip_id = 0
    this:SetTooltipText(g_details.entry_tooltip1, true)
  end
  UIComponent(this:Parent("building_browser")):LuaCall("EntryClicked", this:Id(), g_details.region_key, g_details.slot_key)
end

function OnMouseRClickUp()
end

function LessThan(c, column)
  if column == 0 then
    local this_name = g_details.name
    local that_name = UIComponent(c):LuaCall("EntryName")
    ShaneOutput(this_name .. " < " .. that_name .. " = " .. tostring(this_name < that_name))
    return this_name < that_name
  elseif column == 1 then
    local this_type = g_details.type
    local that_type = UIComponent(c):LuaCall("EntryType")
    ShaneOutput(this_type .. " < " .. that_type .. " = " .. tostring(this_type < that_type))
    return this_type < that_type
  elseif column == 2 then
    local this_level = g_details.level
    local that_level = UIComponent(c):LuaCall("EntryLevel")
    local this_maxlevel = g_details.max_level
    local that_maxlevel = UIComponent(c):LuaCall("MaxLevel")
    ShaneOutput(this_level .. " < " .. that_level .. " = " .. tostring(this_level < that_level))
    ShaneOutput(this_maxlevel .. " < " .. that_maxlevel .. " = " .. tostring(this_maxlevel < that_maxlevel))
    return this_level == that_level and this_maxlevel < that_maxlevel or this_level < that_level
  end
  return false
end

function EntryName()
  return g_details.name
end

function EntryType()
  return g_details.type
end

function EntryLevel()
  return g_details.level
end

function MaxLevel()
  return g_details.max_level
end

function CloseBuildingInfo()
  UIComponent(this:Parent("building_browser")):LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", ShowBuildingInfo)
this:SetEventCallback("OnMouseOff", CloseBuildingInfo)
