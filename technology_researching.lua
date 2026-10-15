local utils = require("Utilities")
local CampaignUI, Localisation
local utils = require("Utilities")
local g_parent, g_root, g_area, g_tabs, g_tab_group, g_tech_categories, g_arrow_l, g_arrow_r, g_entities_clip, g_entities_pane, g_main_title, g_entities_title, g_current_tab, g_category, g_tab_titles, g_chain_components, g_details, g_localized_tooltips
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ZoomToEntity()
  local university = g_entities_clip:LuaCall("SelectedEntity")
  if university ~= nil then
    CampaignUI.SelectAndZoomToSlot(university.RegionKey, university.SlotKey, -1)
  end
end

function Initialise(details, tech_root_addr, actual_root_addr, ui_interface, localisation_interface)
  CampaignUI = ui_interface
  Localisation = localisation_interface
  InitialiseVars(details, tech_root_addr, actual_root_addr)
  UIComponent(g_parent:Find("no_building_text")):SetVisible(#g_details.universities == 0)
  if #g_details.universities > 0 then
    ShowUniversities(g_details.universities[g_details.starting_university_index])
  else
    ShowUniversities()
  end
  InitialiseCommon(details, tech_root_addr)
  g_main_title:SetState("Research")
  g_entities_title:SetState("Universities")
end

function HasFacilities()
  return #g_details.universities > 0
end

function TechnologiesUniversitySelected(key)
  local selected_university = g_entities_clip:LuaCall("SelectedEntity")
  return selected_university ~= nil and selected_university.Activity ~= nil and selected_university.Activity.Technology.Key == key
end

function UniversityResearchingThis(key)
  for i = 1, #g_details.universities do
    if g_details.universities[i].Activity ~= nil and g_details.universities[i].Activity.Technology.Key == key then
      return g_details.universities[i]
    end
  end
  return nil
end

function CancelResearch(university)
  ShaneOutput("CancelResearch")
  if university.Activity ~= nil then
    SetTechnologyAsResearchable(university.Activity.Technology.Key)
  end
  CampaignUI.CancelResearch(university.Address)
  university.Activity = nil
  university.Component:LuaCall("UpdateStatus", university)
end

function BeginResearch(university, key)
  ShaneOutput("BeginResearch: details table for university format is:")
  for h, v in pairs(university) do
    ShaneOutput("university." .. h .. " = " .. tostring(v))
  end
  if university.Activity ~= nil then
    ShaneOutput("Canceling research of " .. university.Activity.Technology.Key .. " to start researching " .. key)
    CancelResearch(university)
  end
  university.Activity = {}
  university.Activity = CampaignUI.BeginResearch(university.Address, key)
  university.Component:LuaCall("UpdateStatus", university)
  assert(university.Activity.TurnsToComplete ~= nil)
  ShaneOutput("::SetTechnologyAsBeingResearched: university.Health = " .. tostring(university.Health))
  SetTechnologyAsBeingResearched(key, true, university.Activity.TurnsToComplete, university.Health < 100)
end

function TechRightClicked(tech_key)
  ShaneOutput("Root TechRightClicked called with key: " .. tostring(tech_key))
  local nil_slot_key, nil_region_key
  g_root:LuaCall("ShowTechInfo", tech_key, nil_region_key, g_details.faction_key, nil_slot_key)
end

function TechLeftClicked(tech_key)
  local selected_university = g_entities_clip:LuaCall("SelectedEntity")
  if selected_university ~= nil then
    ShaneOutput("Root TechLeftClicked called with key: " .. tech_key .. ", selected university is " .. selected_university.Component:Id())
    local university_researching = UniversityResearchingThis(tech_key)
    if university_researching ~= selected_university then
      if CampaignUI.CanResearch(selected_university.Address, tech_key) == true then
        BeginResearch(selected_university, tech_key)
      end
    else
      CancelResearch(selected_university)
    end
  end
end

function TurnsToResearchOrChanceToSteal(tech_key)
  local selected_university = g_entities_clip:LuaCall("SelectedEntity")
  if selected_university ~= nil then
    return CampaignUI.TurnsToResearch(selected_university.Address, tech_key)
  end
  return nil
end

function SelectedEntityIncapacitated()
  local selected_university = g_entities_clip:LuaCall("SelectedEntity")
  return selected_university and selected_university.Health < 100
end

function SelectedEntityProgessingTech(key)
  local selected_university = g_entities_clip:LuaCall("SelectedEntity")
  ShaneOutput("XXXXXXXX SelectedEntityProgessingTech, tech = " .. tostring(key) .. ", selected_university = " .. tostring(selected_university))
  if selected_university ~= nil then
    local researching = CampaignUI.UniversityResearching(selected_university.Address)
    ShaneOutput("XXXXXXXX researching = " .. tostring(researching))
    if researching ~= nil then
      if researching.Technology.Key == key then
        ShaneOutput("XXXXXXXX Matched " .. tostring(researching.Technology.Key))
      end
      return researching.Technology.Key == key
    end
  end
  return false
end

function RefreshUniversities()
  g_details.universities = CampaignUI.FactionsUniversities(g_details.faction_key)
  ShowUniversities(g_entities_clip:LuaCall("SelectedEntity"))
end

function ShowUniversities(selected_university)
  ShaneOutput("Displaying " .. #g_details.universities .. " universities")
  g_entities_pane:LuaCall("Initialise", g_details.universities, selected_university, "university")
end

function SelectEntity(university)
  ShaneOutput("Selecting university")
  g_entities_clip:LuaCall("SelectEntity", university)
end

function SetTechnologyAsResearchable(key)
  SetTechnologyAvailable(key)
end

function SetTechnologyAsBeingResearched(key, researching_university_selected, turns_to_complete, incapacitated)
  SetTechnologyInProgress(key, researching_university_selected, turns_to_complete, nil, incapacitated)
end

function SwitchCategory(category)
  SwitchCategory(category)
end

function ShowEntityDetails(university)
  ShaneOutput("ShowEntityDetails: university.BuildingKey = " .. tostring(university.BuildingKey) .. ", g_details.faction_key = " .. tostring(g_details.faction_key) .. ", university.SlotKey = " .. tostring(university.SlotKey))
  g_root:LuaCall("ShowBuildingInfo", university.BuildingKey, university.RegionKey, university.FactionKey, university.SlotKey)
end

function InitialiseVars(details, parent_addr, root_addr)
  g_localized_tooltips = {
    Completed = Localisation.Get("technology_status_researched"),
    InProgress = Localisation.Get("technology_status_being_researched"),
    Available = Localisation.Get("technology_status_available"),
    AvailableNoFacilities = Localisation.Get("technology_status_available_no_facility"),
    Unavailable = Localisation.Get("technology_status_unavailable"),
    TooltipFunctionality = Localisation.Get("technology_tooltip_researching_functionality"),
    TooltipNumericInfo = Localisation.Get("technology_tooltip_researching_numeric_info")
  }
  g_parent = UIComponent(parent_addr)
  g_root = UIComponent(root_addr)
  g_area = nil
  g_tabs = {}
  g_tab_group = UIComponent(g_parent:Find("tabgroup"))
  g_tech_categories = {
    CampaignUI.LocalisationString("tech_category_military"),
    CampaignUI.LocalisationString("tech_category_industrial"),
    CampaignUI.LocalisationString("tech_category_enlightenment")
  }
  g_arrow_l = UIComponent(g_parent:Find("arrow_L"))
  g_arrow_r = UIComponent(g_parent:Find("arrow_R"))
  g_entities_clip = UIComponent(g_parent:Find("entities_clip"))
  g_entities_pane = UIComponent(g_parent:Find("entities_pane"))
  g_main_title = UIComponent(g_parent:Find("heading_tx"))
  g_entities_title = UIComponent(g_parent:Find("entities_title"))
  g_current_tab = nil
  g_category = nil
  g_tab_titles = {}
  g_chain_components = {}
  g_details = details
end

function InitialiseCommon(details, parent_addr)
  local close_button = UIComponent(g_parent:Find("button_close"))
  close_button:SetProperty("ParentPopup", parent_addr)
  if g_tab_group:ChildCount() > 0 then
    for t = 0, g_tab_group:ChildCount() - 1 do
      local tab = UIComponent(g_tab_group:Find(t))
      for x = 1, 3 do
        for y = 1, 6 do
          UIComponent(tab:Find(x .. "_" .. y)):DestroyChildren()
        end
      end
      g_tab_titles[t + 1] = tab:Id()
    end
  end
  InitList("tab_military", ShowMilitary)
  InitList("tab_industry", ShowIndustry)
  InitList("tab_enlightenment", ShowEnlightenment)
  local military_tab = UIComponent(g_parent:Find("tab_military"))
  local lists = g_details.layout[1]
  g_tab_group:LuaCall("SetTabVisibility", military_tab:Address(), 0 < #lists and military_tab:Visible())
  local industry_tab = UIComponent(g_parent:Find("tab_industry"))
  local lists = g_details.layout[2]
  g_tab_group:LuaCall("SetTabVisibility", industry_tab:Address(), 0 < #lists and industry_tab:Visible())
  local enlightenment_tab = UIComponent(g_parent:Find("tab_enlightenment"))
  local lists = g_details.layout[3]
  g_tab_group:LuaCall("SetTabVisibility", enlightenment_tab:Address(), 0 < #lists and enlightenment_tab:Visible())
  local initial_tab_id = military_tab:Visible() and "tab_military" or industry_tab:Visible() and "tab_industry" or enlightenment_tab:Visible() and "tab_enlightenment" or nil
  if initial_tab_id then
    g_tab_group:LuaCall("SetInitialTab", g_tabs[initial_tab_id].tab:Address())
  end
end

function InitList(tab, func)
  ShaneOutput("InitList called with " .. tostring(tab) .. ", " .. tostring(func))
  g_tabs[tab] = {}
  g_tabs[tab].tab = UIComponent(g_parent:Find(tab))
  g_tabs[tab].tab:LuaCall("SetPadding", 20)
  g_tabs[tab].init = func
  g_tabs[tab].display_area = UIComponent(g_tabs[tab].tab:Find("tabchild"))
end

function SelectTab(tab)
  ShaneOutput("SelectTab called with " .. tostring(tab))
  g_current_tab = tab
  g_tabs[tab].init(g_tabs[tab].display_area)
end

function ShowMilitary(display_area)
  ShaneOutput("Showing military tab sheet")
  ShowTabSheet(1, display_area)
end

function ShowIndustry(display_area)
  ShaneOutput("Showing industrial tab sheet")
  ShowTabSheet(2, display_area)
end

function ShowEnlightenment(display_area)
  ShaneOutput("Showing enlightenment tab sheet")
  ShowTabSheet(3, display_area)
end

function ShowTabSheet(category, area)
  ShaneOutput("**************************************************************************************")
  ShaneOutput("Showing " .. g_tech_categories[category] .. " tech tab sheet with " .. tostring(category) .. " and " .. tostring(area))
  if g_area ~= nil then
    for x = 1, 3 do
      for y = 1, 6 do
        ShaneOutput("Area-" .. UIComponent(g_area:Parent()):Id() .. ": Destroying children for chain " .. x .. " entry " .. y)
        UIComponent(g_area:Find(x .. "_" .. y)):DestroyChildren()
      end
    end
  end
  g_area = area
  g_category = category
  local pane_tabs = UIComponent(g_parent:Find("pane_tabs"))
  pane_tabs:DestroyChildren()
  local active_entities = g_entities_clip:LuaCall("ActiveEntities")
  local category_chains = g_details.layout[category]
  ShaneOutput("There are " .. #category_chains .. " chains in this category")
  for c = 1, #category_chains do
    g_chain_components[c] = {}
    local chain = category_chains[c]
    ShaneOutput("There are " .. #chain .. " buildings in chain " .. c)
    for i = 1, #chain do
      if i <= 6 then
        local entry_details = chain[i]
        ShaneOutput("Details for building " .. i .. " ( " .. entry_details.building_icon_name .. " ) in chain " .. c .. ":")
        local tech_box = area:Find(c .. "_" .. i)
        local item_name = g_tech_categories[category] .. "_tech_" .. c .. "_" .. i
        local image_list = {
          "{" .. "building" .. ":1}" .. entry_details.building_icon_name
        }
        local component = g_parent:LuaCall("CreateTechEntry", item_name, tech_box, image_list)
        g_chain_components[c][i] = UIComponent(component)
        g_chain_components[c][i]:LuaCall("Initialise", entry_details, g_tech_categories, active_entities, g_localized_tooltips, i == #chain)
      end
    end
  end
end

function ShowArrows()
  g_arrow_l:SetVisible(true)
  g_arrow_r:SetVisible(true)
end

function HideArrows()
  g_arrow_l:SetVisible(false)
  g_arrow_r:SetVisible(false)
end

function FindTechnology(key)
  for category_index = 1, #g_details.layout do
    local category_chains = g_details.layout[category_index]
    for chain_index = 1, #category_chains do
      local chain = category_chains[chain_index]
      for chain_entry = 1, #chain do
        for t = 1, #chain[chain_entry].tech_entries do
          local tech_entry = chain[chain_entry].tech_entries[t]
          if tech_entry.Key == key then
            if tech_entry.tech_status ~= utils.TECHNOLOGY_STATUS_NOT_PRESENT then
              return category_index, chain_index, chain_entry, tech_entry.ChainPosition + 1, tech_entry
            else
              ShaneOutput("FindTechnology found technology marked as utils.TECHNOLOGY_STATUS_NOT_PRESENT")
            end
          end
        end
      end
    end
  end
  ShaneOutput("Technology " .. tostring(key) .. " not found, this is what we have:")
  for category_index = 1, #g_details.layout do
    local category_chains = g_details.layout[category_index]
    for chain_index = 1, #category_chains do
      local chain = category_chains[chain_index]
      for chain_entry = 1, #chain do
        for t = 1, #chain[chain_entry].tech_entries do
          local tech_entry = chain[chain_entry].tech_entries[t]
          ShaneOutput(tech_entry.Key .. ". Category = " .. category_index .. ", Chain = " .. chain_index .. ", Cluster entry = " .. t)
        end
      end
    end
  end
end

function SetTechnologyAvailable(key)
  local category, chain_index, chain_position, tech_index, tech_entry = FindTechnology(key)
  tech_entry.tech_status = utils.TECHNOLOGY_STATUS_AVAILABLE
  if category == g_category then
    ShaneOutput("SetTechnologyAvailable " .. g_chain_components[chain_index][chain_position]:Id())
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyAvailable", tech_index)
  end
end

function SetTechnologyInProgress(key, entity_selected, numeric_value, percentile, incapacitated)
  ShaneOutput("::SetTechnologyInProgress: incapacitated = " .. tostring(incapacitated))
  local category, chain_index, chain_position, tech_index, tech_entry = FindTechnology(key)
  assert(category == g_category, "Trying to set a technology as being researched but it's on a different tab to the one we're showing!")
  tech_entry.tech_status = utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN
  if entity_selected == true then
    ShaneOutput("ShowTechnologyInProgressSelected " .. g_chain_components[chain_index][chain_position]:Id() .. ", entity_selected is " .. tostring(entity_selected))
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyInProgressSelected", tech_index, numeric_value, percentile, incapacitated)
  else
    ShaneOutput("ShowTechnologyInProgress " .. g_chain_components[chain_index][chain_position]:Id() .. ", entity_selected is " .. tostring(entity_selected))
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyInProgress", tech_index)
  end
end

function SwitchCategory(category)
  assert(g_category ~= category, "Trying to switch category to the one we're already in!")
  ShaneOutput("Switching tab to " .. g_tab_titles[category])
  SelectTab(g_tab_titles[category])
  g_tab_group:LuaCall("SetInitialTab", g_tabs[g_tab_titles[category]].tab:Address())
end

function TechAvailable(tech_entry)
  return tech_entry.tech_status == utils.TECHNOLOGY_STATUS_AVAILABLE
end

function TechCompleted(tech_entry)
  return tech_entry.tech_status == utils.TECHNOLOGY_STATUS_RESEARCHED
end

function TechInProgress(tech_entry)
  return tech_entry.tech_status == utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN
end

function TechProgressStalled(tech_entry)
  local university_researching = UniversityResearchingThis(tech_entry.Key)
  ShaneOutput("TechProgressStalled: Tech key = " .. tostring(tech_entry.Key) .. ", university_researching = " .. tostring(university_researching))
  if university_researching then
    ShaneOutput("TechProgressStalled: Health = " .. university_researching.Health)
  end
  return university_researching and university_researching.Health < 100
end
