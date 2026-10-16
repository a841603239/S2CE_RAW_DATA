local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local g_xp = UIComponent(this:Find("Experience"))
local g_garrison_size = UIComponent(this:Find("garrison_size"))
local g_tech_icon = UIComponent(this:Find("tech"))
local g_religion_icon = UIComponent(this:Find("religion_icon"))
local g_name, g_record_key, g_region_key, g_faction_key, g_slot_key, g_building_key, g_all_tech_requirements_met, g_all_building_requirements_met
local g_missing_technologies = {}
local g_missing_buildings = {}
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(details, region_key, faction_key, slot_key, building_key, for_garrison)
  if details.TechnologyRequirements ~= nil then
    ShaneOutput("details.TechnologyRequirements size = " .. tostring(#details.TechnologyRequirements))
  end
  if details.BuildingRequirements ~= nil then
    ShaneOutput("details.BuildingRequirements size = " .. tostring(#details.BuildingRequirements))
  end
  g_name = details.Name
  g_record_key = details.Key
  g_region_key = region_key
  g_faction_key = faction_key
  g_slot_key = slot_key
  g_building_key = building_key
  g_technology_requirements = details.TechnologyRequirements
  g_xp:SetState(details.Experience)
  g_missing_technologies = {}
  g_all_tech_requirements_met = true
  if g_technology_requirements ~= nil then
    for i = 1, #g_technology_requirements do
      if details.TechnologyRequirements[i].Status ~= utils.TECHNOLOGY_STATUS_RESEARCHED then
        g_missing_technologies[#g_missing_technologies + 1] = details.TechnologyRequirements[i]
      end
    end
    g_all_tech_requirements_met = #g_missing_technologies == 0
  end
  g_missing_buildings = {}
  g_all_building_requirements_met = true
  if g_building_requirements ~= nil then
    for i = 1, #g_building_requirements do
      if details.BuildingRequirements[i].Constructed == false then
        g_missing_buildings[#g_missing_buildings + 1] = details.BuildingRequirements[i]
      end
    end
    g_all_building_requirements_met = #g_missing_buildings == 0
  end
  g_tech_icon:SetVisible(g_all_tech_requirements_met == false)
  local is_ship = string.find(details.Icon, "Naval") ~= nil
  out.shane(details.Icon)
  if not is_ship then
    if g_tech_icon:Visible() or g_religion_icon:Visible() then
      this:SetState("inactive")
      out.shane("Setting recruitment entry state: inactive")
    end
  else
    if not g_tech_icon:Visible() and not g_religion_icon:Visible() then
      this:SetState("Default_ship")
      out.shane("Setting recruitment entry state: ship default")
    else
      this:SetState("inactive_ship")
      out.shane("Setting recruitment entry state: ship inactive")
    end
    if string.find(details.UnitType, "hull") then
      UIComponent(this:Find("unit_category_icon")):SetState(details.UnitType)
    end
  end
  if g_all_tech_requirements_met == false then
    local tech_key = g_missing_technologies[1].Key
    g_tech_icon:InterfaceFunction("SetTechKey", tech_key)
  end
  local unit_name_label = UIComponent(this:Find("unit_name"))
  unit_name_label:SetStateText(details.Name, true, 3)
  local w, h, l = unit_name_label:TextDimensions()
  if h > unit_name_label:Height() then
    local difference = h - unit_name_label:Height()
    unit_name_label:Resize(unit_name_label:Width(), h + 5)
    local effect_parent = UIComponent(this:Parent("building_info_recruitment_effects"))
    effect_parent:LuaCall("NotifyUnitEntryResized", effect_parent:Height() + difference)
  end
  if for_garrison and details.garrison_size then
    g_garrison_size:SetVisible(true)
    g_garrison_size:SetStateText(details.garrison_size)
  end
end

function OnMouseRClickUp()
end

function OnMouseOn()
end

function OnMouseOff()
end

function BuildTooltipForMissingTech(component)
  component:LuaCall("Initialise", g_name, g_missing_technologies, true)
end

function BuildTooltipForMissingBuildings(component)
  component:LuaCall("Initialise", g_name, g_missing_buildings, false)
end
