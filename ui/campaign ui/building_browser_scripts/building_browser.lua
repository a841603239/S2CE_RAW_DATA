local utils = require("Utilities")
local ENTRY_TYPE_NATIONAL_CAPITAL = 1
local ENTRY_TYPE_REGION_CAPITAL = 2
local ENTRY_TYPE_TOWN = 3
local ENTRY_TYPE_PORT = 4
local ENTRY_TYPE_RESOURCE = 5
local ENTRY_TYPE_FARM = 6
local ENTRY_TYPE_ROAD = 7
local ENTRY_TYPE_FORTIFICATION = 8
local STATE_LIST = 1
local STATE_MOVE_TO_TREE = 2
local STATE_TO_TREE = 3
local STATE_TREE = 4
local STATE_MOVE_TO_LIST = 5
local STATE_TO_LIST = 6
local g_entry_fadein_time = 0.5
local g_entry_fadeout_time = 0.3
local g_event_time = 0.5
local g_entry_y_spacing = 56
local g_localised_type_names = {
  CampaignUI.LocalisationString("capital"),
  CampaignUI.LocalisationString("region_capital"),
  CampaignUI.LocalisationString("town"),
  CampaignUI.LocalisationString("port"),
  CampaignUI.LocalisationString("farm"),
  CampaignUI.LocalisationString("road"),
  CampaignUI.LocalisationString("fortification"),
  CampaignUI.LocalisationString("resource")
}
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local g_sortable_list = UIComponent(this:Find("sortable_list"))
local g_list_clip = UIComponent(this:Find("list_clip"))
local g_list_box = UIComponent(g_list_clip:Find("list_box"))
local g_headers = UIComponent(this:Find("headers"))
local g_tree = UIComponent(this:Find("tree_parent"))
local g_background = UIComponent(this:Find("background"))
local g_slider = UIComponent(g_background:Find("vslider"))
local g_vline1 = UIComponent(this:Find("vline1"))
local g_vline2 = UIComponent(this:Find("vline2"))
local g_zoom_button = UIComponent(this:Find("button_zoom"))
local g_back_button = UIComponent(this:Find("button_back"))
local g_tree_slider_max, g_list_slider_max
local g_slider_restore_value = 0
local g_details = {}
local g_state = STATE_LIST
local g_tree_xpos = 0
local g_tree_ypos = 0
local g_tree_entry, g_entry_focus, g_event_start, g_entry_focus_home_y, g_tree_target_y, g_orig_entry_y
local g_headers_height = g_headers:Height()
local g_list_sized_with_headers = true
local g_list_sized_without_headers = false
local g_list_sized_state = g_list_sized_with_headers
local g_region
local g_stored_interactive_flags = {}
local g_selected_entry_slot, g_selected_entry_region
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShowBuildingInfo(building_key, region_key, faction_key, slot_key)
  if building_key ~= "empty" then
    ShaneOutput("Showing building record info with building_key " .. tostring(building_key) .. ", faction_key " .. tostring(faction_key) .. ", region_key " .. tostring(region_key) .. " and slot_key " .. tostring(slot_key))
    root:LuaCall("ShowBuildingInfo", building_key, region_key, faction_key, slot_key)
  end
end

function NextRegion()
  ShaneOutput("PreviousAutoSettlementSelection - g_region = " .. tostring(g_region))
  local region = CampaignUI.PreviousAutoSettlementSelection(g_region)
  if region ~= nil then
    g_region = region
    Initialise()
  end
end

function PreviousRegion()
  ShaneOutput("NextAutoSettlementSelection - g_region = " .. tostring(g_region))
  local region = CampaignUI.NextAutoSettlementSelection(g_region)
  if region ~= nil then
    g_region = region
    Initialise()
  end
end

function CleanUp()
  g_region = nil
  g_slider_restore_value = 0
  if g_list_sized_state == g_list_sized_without_headers then
    ResizeListWithHeaders()
    SetListEntriesInteractivity(true)
    ReassignSliderToList()
  end
  g_sortable_list:LuaCall("Reset")
  g_tree:DestroyChildren()
  g_list_box:DestroyChildren()
  SetHeadersNormalShaders()
end

function Initialise()
  CleanUp()
  local close_button = UIComponent(this:Find("button_close"))
  close_button:SetProperty("ParentPopup", Address)
  g_zoom_button:SetState("inactive")
  g_back_button:SetVisible(false)
  g_details = CampaignUI.BuildingBrowserDetails(g_region)
  g_region = g_details.region
  g_state = STATE_LIST
  g_tree_xpos = 0
  g_tree_ypos = 0
  g_tree_entry = nil
  g_entry_focus = nil
  g_event_start = nil
  g_entry_focus_home_y = nil
  UIComponent(this:Find("dy_region")):SetStateText(g_details.region_name)
  if 0 < #g_details.slots then
    local entries
    entries, g_list_slider_max = CreateListEntries()
    g_sortable_list:LuaCall("Initialise", entries, 2)
  end
end

function CreateListEntries()
  local entries = {}
  for i = 1, #g_details.slots do
    local images = {
      "{dy_icon:1}" .. g_details.slots[i].image
    }
    entries[#entries + 1] = Component.CreateFromLayout("data/ui/campaign ui/building_browser_entry", "building_browser_entry" .. i, Address, 5, (i - 1) * g_entry_y_spacing, images)
    g_details.slots[i].component = entries[#entries]
    UIComponent(entries[#entries]):LuaCall("Initialise", g_details.slots[i], g_localised_type_names, i % 2)
  end
  local slider_max = utils.Min(0, g_entry_y_spacing * #g_details.slots - g_list_box:Height())
  return entries, slider_max
end

function SetListEntryInteractivity(component, interactive)
  for c = 0, component:ChildCount() - 1 do
    SetListEntryInteractivity(UIComponent(component:Find(c)), interactive)
  end
  local is_not_vslider = component:Id() ~= "vslider"
  local parent_is_not_nil = component:Parent() ~= nil
  local parent_is_not_vslider = parent_is_not_nil == false or UIComponent(component:Parent()):Id() ~= "vslider"
  if is_not_vslider and parent_is_not_nil and parent_is_not_vslider then
    local parent_name = UIComponent(component:Parent()):Id()
    local setting_non_interactive = interactive == false
    local is_not_browser_entry_child = string.find(parent_name, "building_browser_entry") == nil
    local find_value = string.find(parent_name, "building_browser_entry")
    local parents_parent_is_nil = UIComponent(component:Parent()):Parent() == nil
    local id = UIComponent(UIComponent(component:Parent()):Parent()):Id()
    local is_not_headers = string.find(id, "headers") == nil
    if setting_non_interactive or is_not_browser_entry_child and (parents_parent_is_nil or is_not_headers) then
      component:SetInteractive(interactive)
    end
  end
end

function SetListEntriesInteractivity(interactive)
  for c = 0, g_sortable_list:ChildCount() - 1 do
    SetListEntryInteractivity(UIComponent(g_sortable_list:Find(c)), interactive)
  end
  g_sortable_list:SetInteractive(interactive)
end

function FadeoutHeaders(time)
  utils.PropagateShader(g_headers:Address(), "alpha_over_time_t0", 1, 0, time, time + g_entry_fadeout_time)
  utils.PropagateShader(g_vline1:Address(), "alpha_over_time_t0", 1, 0, time, time + g_entry_fadeout_time)
  utils.PropagateShader(g_vline2:Address(), "alpha_over_time_t0", 1, 0, time, time + g_entry_fadeout_time)
end

function FadeinHeaders(time)
  utils.PropagateShader(g_headers:Address(), "alpha_over_time_t0", 0, 1, time, time + g_entry_fadein_time)
  utils.PropagateShader(g_vline1:Address(), "alpha_over_time_t0", 0, 1, time, time + g_entry_fadein_time)
  utils.PropagateShader(g_vline2:Address(), "alpha_over_time_t0", 0, 1, time, time + g_entry_fadein_time)
end

function ResizeListWithHeaders()
  ShaneOutput("**** Resizing list with headers, g_headers_height = " .. g_headers_height)
  g_list_sized_state = g_list_sized_with_headers
  local lc_x, lc_y = g_list_clip:Position()
  g_list_clip:MoveTo(lc_x, lc_y + g_headers_height)
  g_list_clip:Resize(g_list_clip:Width(), g_list_clip:Height() - g_headers_height, false)
  ShaneOutput("**** New list clip y position = " .. lc_y + g_headers_height)
end

function ResizeListWithoutHeaders()
  ShaneOutput("**** Resizing list without headers, g_headers_height = " .. g_headers_height)
  g_list_sized_state = g_list_sized_without_headers
  local lc_x, lc_y = g_list_clip:Position()
  g_list_clip:MoveTo(lc_x, lc_y - g_headers_height)
  g_list_clip:Resize(g_list_clip:Width(), g_list_clip:Height() + g_headers_height, false)
  ShaneOutput("**** New list clip y position = " .. lc_y - g_headers_height)
end

function RepositionListEntriesWithoutHeaders()
  for i = 1, #g_details.slots do
    local entry = UIComponent(g_details.slots[i].component)
    local x, y = entry:Position()
    entry:MoveTo(x, y + g_headers_height)
  end
end

function RepositionListEntriesWithHeaders()
  for i = 1, #g_details.slots do
    local entry = UIComponent(g_details.slots[i].component)
    local x, y = entry:Position()
    entry:MoveTo(x, y - g_headers_height)
  end
end

function SlidingFadeoutListEntries(time)
  ResizeListWithoutHeaders()
  RepositionListEntriesWithoutHeaders()
  for i = 1, #g_details.slots do
    if g_details.slots[i] ~= g_entry_focus then
      utils.PropagateShader(g_details.slots[i].component, "alpha_over_time_t0", 1, 0, time, time + g_entry_fadeout_time)
    end
  end
  g_tree:SetVisible(true)
end

function SlidingFadeinListEntries(time)
  ResizeListWithHeaders()
  RepositionListEntriesWithHeaders()
  for i = 1, #g_details.slots do
    local entry = UIComponent(g_details.slots[i].component)
    entry:SetVisible(true)
    if g_details.slots[i] ~= g_entry_focus then
      utils.PropagateShader(g_details.slots[i].component, "alpha_over_time_t0", 0, 1, time, time + g_entry_fadein_time)
    end
  end
end

function HideListEntries()
  for i = 1, #g_details.slots do
    if g_details.slots[i] ~= g_entry_focus then
      UIComponent(g_details.slots[i].component):SetVisible(false)
    end
  end
end

function ReassignSliderToTree()
  g_slider:SetProperty("Notify", Address)
  g_slider:SetProperty("maxValue", g_tree_slider_max)
  g_slider:LuaCall("ValueSet", 0)
  g_slider:LuaCall("Reset")
  g_slider:LuaCall("Update")
end

function ReassignSliderToList()
  g_slider:SetProperty("Notify", g_sortable_list:Address())
  g_slider:SetProperty("maxValue", g_list_slider_max)
  g_slider:LuaCall("ValueSet", g_slider_restore_value)
  g_slider:LuaCall("Reset")
  g_list_box:Layout()
  g_slider:LuaCall("Update")
  g_sortable_list:LuaCall("ScrollTo", g_slider_restore_value)
end

function SetHeadersNormalShaders()
  utils.PropagateShader(g_headers:Address(), "normal_t0", 0, 0, 0, 0)
  utils.PropagateShader(g_vline1:Address(), "normal_t0", 0, 0, 0, 0)
  utils.PropagateShader(g_vline2:Address(), "normal_t0", 0, 0, 0, 0)
end

function SetEntriesNormalShaders()
  for i = 1, #g_details.slots do
    utils.PropagateShader(g_details.slots[i].component, "normal_t0", 0, 0, 0, 0)
  end
end

function OnUpdate(time_ms)
  local time = time_ms * 0.001
  if g_state == STATE_MOVE_TO_TREE then
    FadeoutHeaders(time)
    SetListEntriesInteractivity(false)
    UIComponent(g_entry_focus.component):SetInteractive(true)
    SlidingFadeoutListEntries(time)
    g_state = STATE_TO_TREE
  elseif g_state == STATE_TO_TREE then
    local time_unary = (time - g_event_start) / g_event_time
    if 1 < time_unary then
      HideListEntries()
      ReassignSliderToTree()
      g_zoom_button:SetState("normal")
      g_back_button:SetVisible(true)
      time_unary = 1
      g_state = STATE_TREE
    end
    local parent_x, parent_y = UIComponent(g_tree:Parent()):Position()
    local tree_x, tree_y = g_tree:Position()
    local entry = UIComponent(g_entry_focus.component)
    local entry_x, entry_y = entry:Position()
    local headers_x, headers_y = g_headers:Position()
    local window_x, window_y = g_list_box:Position()
    g_tree_target_y = headers_y + entry:Height()
    g_tree:MoveTo(tree_x, utils.TruncToInt(tree_y - (tree_y - g_tree_target_y) * time_unary))
    tree_x, tree_y = g_tree:Position()
    local delta = utils.TruncToInt(entry_y + entry:Height() - tree_y)
    if 0 <= delta then
      entry:MoveTo(entry_x, utils.TruncToInt(tree_y - entry:Height()))
    elseif g_tree_target_y > entry_y + entry:Height() then
      entry:MoveTo(entry_x, entry_y + utils.TruncToInt((g_tree_target_y - (entry_y + entry:Height())) * time_unary))
    end
  elseif g_state == STATE_MOVE_TO_LIST then
    FadeinHeaders(time)
    SlidingFadeinListEntries(time)
    g_state = STATE_TO_LIST
  elseif g_state == STATE_TO_LIST then
    local time_unary = (time - g_event_start) / g_event_time
    if 1 <= time_unary then
      SetHeadersNormalShaders()
      SetListEntriesInteractivity(true)
      SetEntriesNormalShaders()
      ReassignSliderToList()
      g_zoom_button:SetState("inactive")
      g_back_button:SetVisible(false)
      time_unary = 1
      g_state = STATE_LIST
    end
    local entry = UIComponent(g_entry_focus.component)
    local entry_x, entry_y = entry:Position()
    local parent_x, parent_y = UIComponent(g_tree:Parent()):Position()
    local tree_x, tree_y = g_tree:Position()
    local list_x, list_y = g_list_clip:Position()
    local tree_target_y = parent_y + UIComponent(g_tree:Parent()):Height()
    if tree_target_y < g_entry_focus_home_y + entry:Height() then
      tree_target_y = g_entry_focus_home_y + entry:Height()
    end
    g_tree:MoveTo(tree_x, utils.TruncToInt(tree_y + (tree_target_y - tree_y) * time_unary))
    tree_x, tree_y = g_tree:Position()
    if tree_y < g_entry_focus_home_y + entry:Height() then
      local y = utils.TruncToInt(tree_y - entry:Height())
      ShaneOutput("Entry positioned above tree at y = " .. y)
      entry:MoveTo(entry_x, y)
    else
      ShaneOutput("Entry positioned at home y = " .. g_entry_focus_home_y)
      entry:MoveTo(entry_x, g_entry_focus_home_y)
    end
  end
end

function BackButtonClicked()
  UIComponent(g_entry_focus.component):LuaCall("OnLeftClickUp")
end

function SetListEntryFocus(id)
  g_entry_focus = nil
  for i = 1, #g_details.slots do
    if UIComponent(g_details.slots[i].component):Id() == id then
      g_entry_focus = g_details.slots[i]
      break
    end
  end
  assert(g_entry_focus ~= nil)
end

function EntryClicked(id, region_key, slot_key)
  ShaneOutput("EntryClicked: " .. id)
  g_selected_entry_slot = slot_key
  g_selected_entry_region = region_key
  if g_state == STATE_LIST then
    g_event_start = CampaignUI.Time()
    SetListEntryFocus(id)
    TreeDisplay()
  elseif g_state == STATE_TREE then
    g_event_start = CampaignUI.Time()
    g_state = STATE_MOVE_TO_LIST
  end
end

function ZoomToSlot()
  ShaneOutput("ZoomToSlot:")
  ShaneOutput("g_selected_entry_region = " .. tostring(g_selected_entry_region))
  ShaneOutput("g_selected_entry_slot = " .. tostring(g_selected_entry_slot))
  if g_selected_entry_region and g_selected_entry_slot then
    CampaignUI.SelectAndZoomToSlot(g_selected_entry_region, g_selected_entry_slot, -1)
  end
end

function TreeDisplay()
  local win_x, win_y = g_list_clip:Position()
  g_tree:MoveTo(win_x + g_list_clip:Width() / 2 - g_tree:Width() / 2, win_y + g_list_clip:Height())
  g_tree:SetVisible(true)
  local tree_height = CampaignUI.ConstructBuildingTree(g_entry_focus.slot, g_tree:Address())
  if tree_height > g_list_clip:Height() - UIComponent(g_entry_focus.component):Height() then
    g_tree_slider_max = tree_height - (g_list_clip:Height() - UIComponent(g_entry_focus.component):Height())
  else
    g_tree_slider_max = 0
  end
  local x, y = UIComponent(g_entry_focus.component):Position()
  g_entry_focus_home_y = y
  g_state = STATE_MOVE_TO_TREE
  g_slider_restore_value = g_slider:LuaCall("ValueGet")
end

function Notify(notifier, value)
  if g_state == STATE_TREE then
    local x, y = g_tree:Position()
    g_tree:MoveTo(x, g_tree_target_y - value)
  end
end

function ShowBrowserEntries()
  local parent = g_list_box:Address()
  local p_x, p_y = UIComponent(parent):Position()
  local h_x, h_y = g_headers:Position()
  local lc_x, lc_y = g_list_clip:Position()
  local h_h = g_headers:Height()
  ShaneOutput("Headers y pos = " .. h_y)
  ShaneOutput("ListClip y pos = " .. lc_y)
  ShaneOutput("ListBox y pos = " .. p_y)
  ShaneOutput("Headers height = " .. h_h)
  for f = 1, #g_details.slots do
    ShaneOutput("Creating browser entry with image: " .. g_details.slots[f].image .. ", at y pos " .. p_y + (f - 1) * g_entry_y_spacing)
    local image_replacements = {
      "{dy_icon:1}" .. g_details.slots[f].image
    }
    g_details.slots[f].component = Component.CretaeFromLayout("data/ui/campaign ui/building_browser_entry", "building_browser_entry" .. f, parent, 5, (f - 1) * g_entry_y_spacing, image_replacements)
    local entry_component = UIComponent(g_details.slots[f].component)
    entry_component:LuaCall("Initialise", g_details.slots[f], g_localised_type_names, f % 2)
  end
  g_list_box:Layout()
  local amount_larger_than_window = g_entry_y_spacing * #g_details.slots - g_list_box:Height()
  if 0 < amount_larger_than_window then
    return amount_larger_than_window
  end
  return 0
end

function BuildingBrowserSetJunctionRouteUnavailableEntries(root_component)
  local base = UIComponent(root_component)
  local junctions = {}
  for i = 0, base:ChildCount() - 1 do
    local chain_root = UIComponent(base:Find(i))
    BuildingBrowserLocateJunctions(chain_root, junctions)
  end
  for i = 1, #junctions do
    for c = 0, junctions[i].component:ChildCount() - 1 do
      if c ~= junctions[i].route then
        BuildingBrowserMakeJunctionRouteUnavailable(UIComponent(junctions[i].component:Find(c)))
      end
    end
  end
end

function BuildingBrowserMakeJunctionRouteUnavailable(component)
  for c = 0, component:ChildCount() - 1 do
    local child = UIComponent(component:Find(c))
    BuildingBrowserMakeJunctionRouteUnavailable(child)
  end
  component:SetState("unavailable")
end

function BuildingBrowserLocateJunctions(component, junctions)
  for c = 0, component:ChildCount() - 1 do
    local child = UIComponent(component:Find(c))
    BuildingBrowserLocateJunctions(child, junctions)
  end
  if component:ChildCount() > 1 then
    local selected_route = BuildingBrowserSelectedRoute(component)
    if -1 ~= selected_route then
      local junction_entry = {component = component, route = selected_route}
      table.insert(junctions, junction_entry)
    end
  end
end

function BuildingBrowserSelectedRoute(component)
  for c = 0, component:ChildCount() - 1 do
    local child = UIComponent(component:Find(c))
    if "normal" == child:CurrentState() then
      return c
    end
  end
  return -1
end

function CloseBuildingInfoPanel()
  root:LuaCall("InfoPanelNotUsed")
end
