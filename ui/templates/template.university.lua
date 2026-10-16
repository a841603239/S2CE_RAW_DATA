local utils = require("Utilities")
local this = UIComponent(Address)
local tech_parent = UIComponent(this:Parent("technology"))
local g_building = UIComponent(this:Find("building"))
local g_researchers = UIComponent(this:Find("character"))
local g_name = UIComponent(this:Find("uni_name"))
local g_tech_icon = UIComponent(this:Find("university_tech_icon"))
local g_turns_icon = UIComponent(this:Find("Turns"))
local g_damage_bar = UIComponent(this:Find("damaged"))
local g_university
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShaneOutputFocused(msg)
  if defined.debug then
    out.shane(msg)
  end
end

function ShowTableVars(table, table_name)
  for h, v in pairs(table) do
    if type(v) == "table" then
      local pre_appended = table_name
      table_name = table_name .. "." .. tostring(h)
      ShowTableVars(v, tostring(h))
      table_name = pre_appended
    end
    ShaneOutput(table_name .. "." .. h .. " = " .. tostring(v))
  end
end

function Initialise(university)
  ShaneOutput("**Initialising university, slot name = " .. tostring(university.SlotName))
  g_university = university
  local image = UIImage(university.IconFilename)
  image:SetComponentTexture(g_building:Address(), 1)
  g_name:SetStateText(university.SlotName)
  g_building:LuaCall("Initialise", university)
  UpdateStatus(university)
  ShowBuildingHealth(university.Health)
end

function UpdateStatus(university)
  ShaneOutput("Updating university, researching = " .. tostring(university.Activity ~= nil))
  local damaged = university.Health < 100
  if university.Activity then
    g_tech_icon:LuaCall("SetActiveTechnology", university.Activity.Technology)
    g_tech_icon:SetState(damaged and "not_available" or "researching")
    g_turns_icon:SetState(damaged and "blocked" or "queued")
    g_turns_icon:SetStateText(damaged and "" or university.Activity.TurnsToComplete)
  end
  g_researchers:SetStateText(university.ResearchersPresent)
  g_researchers:SetVisible(university.ResearchersPresent > 0)
  g_tech_icon:SetVisible(university.Activity ~= nil)
end

function SetSelected(selected)
  if Selectable() == true then
    if selected == true then
      g_building:SetState("selected")
    else
      g_building:SetState("normal")
    end
  end
end

function ShowBuildingHealth(health)
  ShaneOutput("Showing health for building " .. this:Id() .. " with health " .. tostring(health))
  local damaged = health < 100
  g_damage_bar:PropagateVisibility(damaged)
  local building = UIComponent(this:Find("building"))
  if damaged then
    building:ShaderTechniqueSet("buildingcard_burning_t0", true)
    building:ShaderVarsSet(0.4, 0, 0, 0, true)
  else
    building:ShaderTechniqueSet("normal_t0", true)
  end
  local clip = UIComponent(g_damage_bar:Find("fill_clip"))
  local clip_x, clip_y = clip:Position()
  local fill = UIComponent(g_damage_bar:Find("fill"))
  local health_unary = (100 - utils.Max(health, 2)) / 100
  fill:MoveTo(clip_x, clip_y + utils.TruncToInt(health_unary * clip:Height()))
end

function Selectable()
  return g_building:CurrentState() ~= "inactive"
end
