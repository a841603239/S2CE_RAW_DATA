local utils = require("Utilities")
local g_parent, g_root, g_area, g_tabs, g_tab_group, g_tech_categories, g_arrow_l, g_arrow_r, g_entities_clip, g_entities_pane, g_main_title, g_entities_title, g_current_tab, g_category, g_tab_titles, g_chain_components, g_details, g_localized_tooltips
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function InitialiseVars(details, parent_addr, localized_icon_tooltips)
  g_parent = UIComponent(parent_addr)
  ShaneOutput("g_parent success!")
  g_root = UIComponent(Component.Root())
  ShaneOutput("g_root success!")
  g_area = nil
  g_tabs = {}
  g_tab_group = UIComponent(g_parent:Find("tabgroup"))
  ShaneOutput("g_tab_group success!")
  g_tech_categories = {
    CampaignUI.LocalisationString("tech_category_military"),
    CampaignUI.LocalisationString("tech_category_industrial"),
    CampaignUI.LocalisationString("tech_category_enlightenment")
  }
  g_arrow_l = UIComponent(g_parent:Find("arrow_L"))
  ShaneOutput("g_arrow_l success!")
  g_arrow_r = UIComponent(g_parent:Find("arrow_R"))
  ShaneOutput("g_arrow_r success!")
  g_entities_clip = UIComponent(g_parent:Find("entities_clip"))
  ShaneOutput("g_entities_clip success!")
  g_entities_pane = UIComponent(g_parent:Find("entities_pane"))
  ShaneOutput("g_entities_pane success!")
  g_main_title = UIComponent(g_parent:Find("heading_tx"))
  ShaneOutput("g_main_title success!")
  g_entities_title = UIComponent(g_parent:Find("entities_title"))
  ShaneOutput("g_entities_title success!")
  g_current_tab = nil
  g_category = nil
  g_tab_titles = {}
  g_chain_components = {}
  g_details = details
  g_localized_tooltips = localized_icon_tooltips
end

function InitialiseCommon(details, parent_addr, localized_icon_tooltips)
  ShaneOutput("technology_common - InitialiseCommon")
  InitialiseVars(details, parent_addr, localized_icon_tooltips)
  ShaneOutput("Initialising technology_common button_close")
  local close_button = UIComponent(g_parent:Find("button_close"))
  close_button:SetProperty("ParentPopup", parent_addr)
  ShaneOutput("Initialising technology_common tabgroup")
  local tabgroup = UIComponent(g_parent:Find("tabgroup"))
  if tabgroup:ChildCount() > 0 then
    for t = 0, tabgroup:ChildCount() - 1 do
      ShaneOutput("Initialising technology_common tab " .. t)
      g_tab_titles[t + 1] = UIComponent(tabgroup:Find(t)):Id()
    end
  end
  ShaneOutput("Initialising tab_military")
  InitList("tab_military", ShowMilitary)
  ShaneOutput("Initialising tab_industry")
  InitList("tab_industry", ShowIndustry)
  ShaneOutput("Initialising tab_enlightenment")
  InitList("tab_enlightenment", ShowEnlightenment)
  ShaneOutput("Initialising selecttab tab_military")
  SelectTab("tab_military")
  g_tab_group:LuaCall("SetInitialTab", g_tabs.tab_military.tab:Address())
  SelectTab("tab_military")
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
        local component = Component.CreateComponentFromTemplate("tech_entry", item_name, tech_box, 0, 0, image_list)
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

function SetTechnologyInProgress(key, entity_selected, turns_to_complete, incapacitated)
  local category, chain_index, chain_position, tech_index, tech_entry = FindTechnology(key)
  assert(category == g_category, "Trying to set a technology as being researched but it's on a different tab to the one we're showing!")
  ShaneOutput("SetTechnologyAsBeingManipulated " .. g_chain_components[chain_index][chain_position]:Id() .. ", entity_selected is " .. tostring(entity_selected))
  tech_entry.tech_status = utils.TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN
  if entity_selected == true then
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyInProgressSelected", tech_index, turns_to_complete, incapacitated)
  else
    g_chain_components[chain_index][chain_position]:LuaCall("ShowTechnologyInProgress", tech_index)
  end
end

function SwitchCategory(category)
  assert(g_category ~= category, "Trying to switch category to the one we're already in!")
  ShaneOutput("Switching tab to " .. g_tab_titles[category])
  SelectTab(g_tab_titles[category])
  g_tab_group:LuaCall("SetInitialTab", g_tabs[g_tab_titles[category]].tab:Address())
end
