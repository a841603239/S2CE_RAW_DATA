local utils = require("Utilities")
local this = UIComponent(Address)
local g_turns = UIComponent(this:Find("Turns"))
local g_tech_parent = UIComponent(this:Parent("technology_stealing"))
local g_building_parent = UIComponent(UIComponent(this:Parent()):Parent())
local g_tech_entry, g_turns_to_completion
local g_icon_state_tooltips = {
  BeingStolen = CampaignUI.LocalisationString("technology_status_being_stolen"),
  AvailableToSteal = CampaignUI.LocalisationString("technology_status_available_to_steal"),
  UnavailableToSteal = CampaignUI.LocalisationString("technology_status_unavailable_to_steal")
}
local g_category_names, g_tooltip_component
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

function Initialise(tech_entry, category_names)
  g_tech_entry = tech_entry
  g_category_names = category_names
  ShaneOutput("Initialising " .. g_tech_entry.Key .. ", status is " .. utils.tech_status_strings[g_tech_entry.tech_status + 1])
  if g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN then
    if g_tech_parent:LuaCall("TechnologiesThiefSelected", tech_entry.Key) == true then
      SetStealingSelected()
    else
      SetStealing()
    end
  elseif g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE then
    SetStealable()
  else
    SetUnavailable()
  end
  g_turns:SetVisible(false)
end

function BuildTooltip(component)
  local func
  if g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN then
    func = g_icon_state_tooltips.BeingStolen
  elseif g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE then
    func = g_icon_state_tooltips.AvailableToSteal
  else
    func = g_icon_state_tooltips.UnavailableToSteal
  end
  component:LuaCall("InitialiseTechnology", g_tech_entry, func, g_tech_entry.tech_short_description)
  g_tooltip_component = component
  UpdateTooltipTurns()
end

function UpdateTooltipTurns()
  if g_tooltip_component ~= nil then
    local turns_state
    if g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN then
      turns_state = "queued"
    elseif g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE then
      turns_state = "not queued"
    end
    g_tooltip_component:LuaCall("UpdateTurns", turns_state, g_turns_to_completion)
  end
end

function OnMouseLClickUp()
  ShaneOutput("Tech " .. g_tech_entry.Key .. " left clicked ")
  g_building_parent:LuaCall("TechLeftClicked", g_tech_entry.Key)
end

function OnMouseRClickUp()
end

function ShowInfo()
  ShaneOutput("Tech " .. g_tech_entry.Key .. " right clicked ")
  g_building_parent:LuaCall("TechRightClicked", g_tech_entry.Key)
end

function OnMouseOn()
  ShaneOutput("Tech " .. g_tech_entry.Key .. " mouse on with status: " .. utils.tech_status_strings[g_tech_entry.tech_status + 1])
  if (g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE or g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN) and g_tech_parent:LuaCall("SelectedThiefNotStealingThis", g_tech_entry.Key) == true then
    utils.PropagateShader(Address, "brighten_t0", 0.15)
  end
  if g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN or g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE or g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_UNAVAILABLE then
    local tooltip = UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "technology")
    if tooltip ~= nil then
      BuildTooltip(UIComponent(tooltip))
    end
  end
  ShowInfo()
end

function OnMouseOff()
  if (g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE or g_tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN) and g_tech_parent:LuaCall("SelectedThiefNotStealingThis", g_tech_entry.Key) == true then
    ShaneOutput("Tech " .. g_tech_entry.Key .. " mouse off")
    utils.PropagateShader(Address, "normal_t0")
  end
  UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "standard")
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
  g_tooltip_component = nil
end

function SetStealingSelected(turns)
  g_turns:SetVisible(true)
  if turns ~= nil then
    g_turns_to_completion = turns
    g_turns:SetStateText(turns)
  else
    g_turns:SetStateText("")
  end
  this:SetState("stealing")
  utils.PropagateShader(Address, "glow_pulse_t0", 1, 2, 1, 0)
  UpdateTooltipTurns()
end

function SetStealing()
  g_turns:SetVisible(false)
  this:SetState("stealing")
  utils.PropagateShader(Address, "normal_t0")
  UpdateTooltipTurns()
end

function SetStealable()
  g_turns:SetVisible(false)
  this:SetState("available_steal")
  utils.PropagateShader(Address, "normal_t0")
  UpdateTooltipTurns()
end

function SetUnavailable()
  g_turns:SetVisible(false)
  this:SetState("not_available")
  utils.PropagateShader(Address, "set_greyscale_t0", 0.8, 1, 1)
  UpdateTooltipTurns()
end

function RecordAddress()
  return g_tech_entry.Record
end
