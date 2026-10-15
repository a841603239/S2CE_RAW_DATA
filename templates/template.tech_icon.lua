local utils = require("Utilities")
local this = UIComponent(Address)
local g_controller
local g_numeric_component = UIComponent(this:Find("Turns"))
local g_tech_entry, g_category_names, g_numeric_value, g_percentile, g_incapacitated
local g_numeric_value_postfix = ""
local g_tooltip_component
local g_localized_icon_tooltips = {
  Completed = Localisation.Get("technology_status_researched"),
  InProgress = Localisation.Get("technology_status_being_researched"),
  Available = Localisation.Get("technology_status_available"),
  AvailableNoFacilities = Localisation.Get("technology_status_available_no_facility"),
  Unavailable = Localisation.Get("technology_status_unavailable"),
  TooltipFunctionality = Localisation.Get("technology_tooltip_researching_functionality"),
  TooltipNumericInfo = Localisation.Get("technology_tooltip_researching_numeric_info")
}
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

function Initialise(controller, tech_entry, category_names, numeric_value, percentile, localized_icon_tooltips, incapacitated)
  g_tooltip_component = nil
  g_tech_entry = tech_entry
  g_category_names = category_names
  g_controller = controller
  g_numeric_value = numeric_value
  g_incapacitated = incapacitated
  if percentile == true then
    g_numeric_value_postfix = "%"
  else
    g_numeric_value_postfix = ""
  end
  if g_controller:GlobalExists("TechInProgress") ~= nil and g_controller:LuaCall("TechInProgress", g_tech_entry) == true then
    ShaneOutput("**************************************************************************************************************")
    ShaneOutput("* Numeric_value for tech being processed = " .. tostring(numeric_value) .. g_numeric_value_postfix)
    ShaneOutput("**************************************************************************************************************")
  end
  if localized_icon_tooltips ~= nil then
    g_localized_icon_tooltips = localized_icon_tooltips
  end
  ShaneOutput("Initialising " .. g_tech_entry.Key .. ", status is " .. utils.tech_status_strings[g_tech_entry.tech_status + 1])
  ShaneOutput("numeric_value is " .. tostring(g_numeric_value))
  ShaneOutput("percentile is " .. tostring(percentile))
  ShaneOutput("g_numeric_value_postfix is " .. tostring(g_numeric_value_postfix))
  ShaneOutput("*** g_incapacitated = " .. tostring(g_incapacitated))
  if g_controller:GlobalExists("TechCompleted") ~= nil and g_controller:LuaCall("TechCompleted", g_tech_entry) == true then
    SetCompleted()
  elseif g_controller:GlobalExists("TechInProgress") ~= nil and g_controller:LuaCall("TechInProgress", g_tech_entry) == true then
    if g_controller:GlobalExists("SelectedEntityProgessingTech") ~= nil and g_controller:LuaCall("SelectedEntityProgessingTech", tech_entry.Key) == true then
      SetInProgress(numeric_value, percentile, g_incapacitated)
    else
      SetInProgress(numeric_value)
    end
  elseif g_controller:GlobalExists("TechAvailable") ~= nil and g_controller:LuaCall("TechAvailable", g_tech_entry) == true then
    SetAvailable()
  else
    SetUnavailable()
  end
end

function BuildTooltip(component)
  ShaneOutputFocused("BuildTooltip component = " .. tostring(component))
  local stalled = g_controller:GlobalExists("TechProgressStalled") and g_controller:LuaCall("TechProgressStalled", g_tech_entry)
  local func
  if g_controller:GlobalExists("TechDisplayOnly") and g_controller:LuaCall("TechDisplayOnly", g_tech_entry) then
    func = nil
  elseif stalled then
    func = g_localized_icon_tooltips.Unavailable
  elseif g_controller:GlobalExists("TechCompleted") and g_controller:LuaCall("TechCompleted", g_tech_entry) then
    func = g_localized_icon_tooltips.Completed
  elseif g_controller:GlobalExists("TechInProgress") and g_controller:LuaCall("TechInProgress", g_tech_entry) then
    func = g_localized_icon_tooltips.InProgress
  elseif g_controller:GlobalExists("TechAvailable") and g_controller:LuaCall("TechAvailable", g_tech_entry) then
    if g_controller:GlobalExists("HasFacilities") and g_controller:LuaCall("HasFacilities") then
      func = g_localized_icon_tooltips.Available
    else
      func = g_localized_icon_tooltips.AvailableNoFacilities
    end
  else
    func = g_localized_icon_tooltips.Unavailable
  end
  component:LuaCall("InitialiseTechnology", g_tech_entry, func, g_tech_entry.ShortDescription)
  g_tooltip_component = component
  ShaneOutput("g_tooltip_component set to " .. tostring(g_tooltip_component))
  UpdateTooltipTurns()
end

function UpdateTooltipTurns()
  ShaneOutput("UpdateTooltipTurns g_tooltip_component = " .. tostring(g_tooltip_component))
  if g_tooltip_component and g_tooltip_component:Address() == UIComponent(Component.Root()):LuaCall("GetTooltipComponent") and (g_controller:GlobalExists("TechDisplayOnly") == nil or g_controller:LuaCall("TechDisplayOnly", g_tech_entry) == false) then
    local turns, turns_state
    local stealing = g_controller:GlobalExists("ChanceToSteal") ~= nil
    if g_controller:GlobalExists("TurnsToResearchOrChanceToSteal") ~= nil and g_controller:LuaCall("TurnsToResearchOrChanceToSteal", g_tech_entry.Key) ~= nil then
      turns = g_controller:LuaCall("TurnsToResearchOrChanceToSteal", g_tech_entry.Key)
      ShaneOutputFocused("turns = " .. tostring(turns))
      local tech_in_progress = g_controller:GlobalExists("TechInProgress") ~= nil and g_controller:LuaCall("TechInProgress", g_tech_entry) == true
      local blocked = g_controller:GlobalExists("TechProgressStalled") ~= nil and g_controller:LuaCall("TechProgressStalled", g_tech_entry) == true
      local incapacitated = g_controller:GlobalExists("SelectedEntityIncapacitated") ~= nil and g_controller:LuaCall("SelectedEntityIncapacitated") == true
      local completed = g_controller:GlobalExists("TechCompleted") and g_controller:LuaCall("TechCompleted", g_tech_entry) == true
      ShaneOutput("function = " .. tostring(g_controller:GlobalExists("TechProgressStalled")))
      ShaneOutput("UpdateTooltipTurns: STALLED = " .. tostring(stalled))
      if blocked then
        turns_state = "blocked"
      elseif stealing then
        turns_state = "percentage"
      elseif tech_in_progress then
        turns_state = "queued"
      elseif not completed then
        turns_state = incapacitated and "blocked" or "not queued"
      end
    end
    g_tooltip_component:LuaCall("UpdateTurns", turns_state, turns)
  end
end

function OnMouseLClickUp()
  ShaneOutput("Tech " .. g_tech_entry.Key .. " left clicked")
  if g_controller:GlobalExists("TechLeftClicked") ~= nil then
    ShaneOutput("Tech " .. g_tech_entry.Key .. " left clicked")
    g_controller:LuaCall("TechLeftClicked", g_tech_entry.Key, Address)
  end
end

function OnMouseRClickUp()
  ShowInfo()
end

function ShowInfo()
  if g_controller:GlobalExists("TechRightClicked") ~= nil then
    ShaneOutput("Tech " .. g_tech_entry.Key .. " right clicked")
    g_controller:LuaCall("TechRightClicked", g_tech_entry.Key)
  end
end

function OnMouseOn()
  ShaneOutput("Tech " .. g_tech_entry.Key .. " mouse on with status: " .. utils.tech_status_strings[g_tech_entry.tech_status + 1])
  if g_tech_entry.tech_status ~= utils.TECHNOLOGY_STATUS_NOT_PRESENT then
    ShaneOutput("Tooltip for tech created = " .. tostring(tooltip))
    local tooltip = UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "technology")
    if tooltip ~= nil then
      BuildTooltip(UIComponent(tooltip))
    end
  end
  ShowInfo()
end

function OnMouseOff()
  ShaneOutput("Tech " .. g_tech_entry.Key .. " mouse off")
  g_tooltip_component = nil
  UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "standard")
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
end

function SetCompleted()
  ShaneOutput("tech_icon - SetCompleted")
  g_numeric_value = nil
  g_numeric_component:SetVisible(false)
  this:SetState("researched")
  UpdateTooltipTurns()
end

function SetCompletedHighlighted()
  ShaneOutput("tech_icon - SetCompletedHighlighted")
  g_numeric_value = nil
  g_numeric_component:SetVisible(false)
  this:SetState("researched")
  UpdateTooltipTurns()
end

function SetInProgress(numeric_value, percentile, incapacitated)
  if numeric_value ~= nil then
    g_numeric_value = numeric_value
  end
  if percentile ~= nil then
    g_percentile = percentile
  end
  if incapacitated ~= nil then
    g_incapacitated = incapacitated
  end
  ShaneOutput(">>> SetInProgress: " .. g_tech_entry.Key .. ", g_numeric_value = " .. tostring(g_numeric_value) .. ", g_percentile = " .. tostring(g_percentile) .. ", incapacitated = " .. tostring(incapacitated))
  if numeric_value ~= nil then
    g_numeric_value = numeric_value
    if percentile == true then
      g_numeric_value_postfix = "%"
    end
  end
  local visible = g_numeric_value ~= nil
  g_numeric_component:SetVisible(visible)
  if visible then
    if 0 < #g_numeric_value_postfix then
      g_numeric_component:SetState("percentage")
    else
      g_numeric_component:SetState("queued")
    end
    if g_incapacitated then
      this:SetState("blocked")
      CampaignUI.Time()
      g_numeric_component:SetState("blocked")
    else
      g_numeric_component:SetStateText(g_numeric_value .. g_numeric_value_postfix)
      this:SetState("researching")
    end
  end
  UpdateTooltipTurns()
end

function SetAvailable()
  ShaneOutput("tech_icon - SetAvailable")
  ShaneOutput(g_tech_entry.Key .. " SetAvailable")
  g_numeric_value = nil
  g_numeric_component:SetVisible(false)
  this:SetState("available")
  UpdateTooltipTurns()
end

function SetAvailableHighlighted()
  ShaneOutput(g_tech_entry.Key .. " SetAvailableHighlighted")
  g_numeric_value = nil
  g_numeric_component:SetVisible(false)
  this:SetState("available")
  UpdateTooltipTurns()
end

function SetUnavailable()
  ShaneOutput("tech_icon - SetUnavailable")
  ShaneOutput(g_tech_entry.Key .. " SetUnavailable")
  g_numeric_value = nil
  g_numeric_component:SetVisible(false)
  this:SetState("not_available")
  UpdateTooltipTurns()
end

function RecordAddress()
  return g_tech_entry.Record
end
