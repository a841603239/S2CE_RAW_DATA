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
  local gentleman = g_entities_clip:LuaCall("SelectedEntity")
  if gentleman ~= nil then
    CampaignUI.SelectAndZoomToCharacter(gentleman.Address, -1)
  end
end

function Initialise(details, tech_root_addr, actual_root_addr, ui_interface, localisation_interface)
  CampaignUI = ui_interface
  Localisation = localisation_interface
  InitialiseVars(details, tech_root_addr, actual_root_addr)
  UIComponent(g_parent:Find("no_building_text")):SetVisible(false)
  if #g_details.gentlemen > 0 then
    ShowGentlemen(g_details.gentlemen[g_details.start_gentlemen_index])
  else
    ShowGentlemen()
  end
  InitialiseCommon(details, tech_root_addr)
  g_main_title:SetState("Stealing")
  g_entities_title:SetState("Gentlemen")
end

function HasFacilities()
  return #g_details.gentlemen > 0
end

function TechnologiesGentlemanSelected(key)
  local selected_gentleman = g_entities_clip:LuaCall("SelectedEntity")
  return selected_gentleman ~= nil and selected_gentleman.Activity ~= nil and selected_gentleman.Activity.Technology.Key == key
end

function GentlemanStealingThis(key)
  for i = 1, #g_details.gentlemen do
    if g_details.gentlemen[i].Activity ~= nil and g_details.gentlemen[i].Activity.Technology.Key == key then
      return g_details.gentlemen[i]
    end
  end
  return nil
end

function CancelStealing(gentleman)
  ShaneOutput("CancelStealing")
  if gentleman.Activity ~= nil then
    SetTechnologyAsStealable(gentleman.Activity.Technology.Key)
  end
  CampaignUI.CancelStealing(gentleman.Address)
  gentleman.Activity = nil
  gentleman.Component:LuaCall("UpdateStatus", gentleman)
end

function BeginStealing(gentleman, key)
  ShaneOutput("BeginStealing: details table for gentleman format is:")
  for h, v in pairs(gentleman) do
    ShaneOutput("gentleman." .. h .. " = " .. tostring(v))
  end
  if gentleman.Activity ~= nil then
    ShaneOutput("Canceling stealing of " .. gentleman.Activity.Technology.Key .. " to start stealing " .. key)
    CancelStealing(gentleman)
  end
  gentleman.Activity = {}
  gentleman.Activity = CampaignUI.BeginStealing(gentleman.Address, key)
  gentleman.Component:LuaCall("UpdateStatus", gentleman)
  assert(gentleman.Activity.ChanceToSteal ~= nil)
  SetTechnologyAsBeingStolen(key, true, gentleman.Activity.ChanceToSteal)
end

function TechLeftClicked(tech_key)
  local selected_gentleman = g_entities_clip:LuaCall("SelectedEntity")
  if selected_gentleman ~= nil then
    ShaneOutput("Stealing: TechLeftClicked called with key: " .. tech_key .. ", selected gentleman is " .. selected_gentleman.Component:Id())
    local gentleman_stealing = GentlemanStealingThis(tech_key)
    if gentleman_stealing ~= selected_gentleman then
      local can_steal = CampaignUI.CanSteal(selected_gentleman.Address, tech_key)
      ShaneOutput("CanSteal returned " .. tostring(can_steal))
      if can_steal == true then
        BeginStealing(selected_gentleman, tech_key)
      end
    else
      CancelStealing(selected_gentleman)
    end
  end
end

function ChanceToSteal()
end

function TurnsToResearchOrChanceToSteal(tech_key)
  local selected_gentleman = g_entities_clip:LuaCall("SelectedEntity")
  if selected_gentleman ~= nil then
    local chance = CampaignUI.ChanceToSteal(selected_gentleman.Address, tech_key)
    if chance ~= nil then
      chance = chance .. "%"
    end
    return chance
  else
    return nil
  end
end

function TechRightClicked(tech_key)
  ShaneOutput("Stealing: TechRightClicked called with key: " .. tech_key)
  local nil_slot_key, nil_region_key
  g_root:LuaCall("ShowTechInfo", tech_key, nil_region_key, g_details.faction_key, nil_slot_key)
end

function SelectedEntityIncapacitated()
  return false
end

function SelectedEntityProgessingTech(key)
  local selected_gentleman = g_entities_clip:LuaCall("SelectedEntity")
  if selected_gentleman ~= nil then
    local stealing = CampaignUI.GentlemanStealing(selected_gentleman.Address)
    if stealing ~= nil then
      return stealing.Technology.Key == key
    else
      return false
    end
  end
  return false
end

function RefreshGentlemen()
  g_details.gentlemen = CampaignUI.VisitingGentlemen(g_details.slot_key)
  ShowGentlemen(g_entities_clip:LuaCall("SelectedEntity"))
end

function ShowGentlemen(selected_gentleman)
  ShaneOutput("Displaying " .. #g_details.gentlemen .. " gentlemen")
  g_entities_pane:LuaCall("Initialise", g_details.gentlemen, selected_gentleman, "gentleman")
end

function SelectEntity(gentleman)
  ShaneOutput("Selecting gentleman")
  g_entities_clip:LuaCall("SelectEntity", gentleman)
end

function SetTechnologyAsStealable(key)
  SetTechnologyAvailable(key)
end

function SetTechnologyAsBeingStolen(key, gentleman_selected, chance_to_steal)
  SetTechnologyInProgress(key, gentleman_selected, chance_to_steal, true)
end

function SwitchCategory(category)
  SwitchCategory(category)
end

function ShowEntityDetails(gentleman)
  g_root:LuaCall("ShowCharacterInfo", gentleman.Address)
end

function InitialiseVars(details, parent_addr, root_addr)
  g_localized_tooltips = {
    Completed = Localisation.Get("technology_status_stolen"),
    InProgress = Localisation.Get("technology_status_being_stolen"),
    Available = Localisation.Get("technology_status_available_to_steal"),
    AvailableNoFacilities = Localisation.Get("technology_status_available_to_steal_no_gentlemen"),
    Unavailable = Localisation.Get("technology_status_unavailable_to_steal"),
    TooltipFunctionality = Localisation.Get("technology_tooltip_stealing_functionality"),
    TooltipNumericInfo = Localisation.Get("technology_tooltip_stealing_numeric_info")
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
  ShowTabSheet(1, display_area)
end

function ShowIndustry(display_area)
  ShowTabSheet(2, display_area)
end

function ShowEnlightenment(display_area)
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
  tech_entry.tech_status = utils.TECHNOLOGY_STATUS_RESEARCHED
  if category == g_category then
    ShaneOutput("SetTechnologyAvailable " .. g_chain_components[chain_index][chain_position]:Id())
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyAvailable", tech_index)
  end
end

function SetTechnologyInProgress(key, entity_selected, numeric_value, percentile)
  local category, chain_index, chain_position, tech_index, tech_entry = FindTechnology(key)
  assert(category == g_category, "Trying to set a technology as being researched but it's on a different tab to the one we're showing!")
  tech_entry.tech_status = utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN
  if entity_selected == true then
    ShaneOutput("ShowTechnologyInProgressSelected " .. g_chain_components[chain_index][chain_position]:Id() .. ", entity_selected is " .. tostring(entity_selected))
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyInProgressSelected", tech_index, numeric_value, percentile)
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
  local gentleman = g_entities_clip:LuaCall("SelectedEntity")
  local researched = tech_entry.tech_status == utils.TECHNOLOGY_STATUS_RESEARCHED
  local no_gent = gentleman == nil
  local can_steal = false
  local already_stealing = false
  local gent_stealing = GentlemanStealingThis(tech_entry.Key)
  if gentleman ~= nil then
    can_steal = CampaignUI.CanSteal(gentleman.Address, tech_entry.Key)
    already_stealing = gent_stealing == gentleman
  end
  local result = already_stealing == false and tech_entry.tech_status == utils.TECHNOLOGY_STATUS_RESEARCHED and gentleman ~= nil and CampaignUI.CanSteal(gentleman.Address, tech_entry.Key)
  ShaneOutput("TechAvailable = " .. tostring(result) .. ". researched = " .. tostring(researched) .. ", no_gent = " .. tostring(no_gent) .. ", can_steal = " .. tostring(can_steal) .. ", already_stealing = " .. tostring(already_stealing))
  return result
end

function TechCompleted(tech_entry)
  local result = false
  ShaneOutput("TechCompleted = " .. tostring(result))
  return result
end

function TechInProgress(tech_entry)
  local result = GentlemanStealingThis(tech_entry.Key) ~= nil
  ShaneOutput("TechInProgress = " .. tostring(result))
  return result
end

function TechProgressStalled(tech_entry)
  return false
end
