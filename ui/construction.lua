module((...), package.seeall)
local utils = require("Utilities")
local g_construction_groups = {}
local g_alternate_chain_groups = {}
local g_original_order_addresses = {}
local g_building_slot_components = {}
local AFFORDABLE = 1
local TECH_PRESENT = 2
local AVAILABLE = 3
local BUILDING_CARD_WIDTH = 96
local CONSTRUCTION_CARD_WIDTH = 104
local ALTERNATE_CHAIN_CARD_WIDTH = CONSTRUCTION_CARD_WIDTH
local g_root, g_card_group, g_passive_selection, g_explicit_selection, g_fort_ptr, g_infrastructure, g_constructables_id, g_num_slots, g_faded_items_store
local g_chain_upgrades_active = false
local g_under_repair_localised_string = CampaignUI.LocalisationString("under_repair")
local g_repair_cost_localised_string = CampaignUI.LocalisationString("repair_cost")
local g_cant_afford_localised_string = CampaignUI.LocalisationString("you_cannot_afford_to_repair_this_item")
local g_not_required_localised_string = CampaignUI.LocalisationString("no_repairs_required")
local g_dismantle_unable_localised_string = CampaignUI.LocalisationString("the_selected_item_may_not_be_dismantled")
local g_click_dismantle_localised_string = CampaignUI.LocalisationString("click_to_mark_current_selection_for_dismantling")
local g_marked_dismantle_localised_string = CampaignUI.LocalisationString("marked_for_dismantling")
local g_construction_site_localised_string = CampaignUI.LocalisationString("Construction_site")
local g_building_unaffordable_localised_string = CampaignUI.LocalisationString("unaffordable")
g_faction_key = nil
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

function RegisterRoot(root)
  g_root = UIComponent(root)
end

function ResetConstructionPanel(info)
  ShaneOutput("ResetConstructionPanel")
  assert(g_root ~= nil)
  g_construction_groups = {}
  g_alternate_chain_groups = {}
  g_building_slot_components = {}
  g_original_order_addresses = {}
  g_passive_selection = nil
  g_card_group = UIComponent(g_root:Find("ConstructionCardGroup"))
  g_fort_ptr = info.fort_ptr
  g_controlable = info.controlable
  g_faction_key = info.faction_key
  g_infrastructure = info.infrastructure ~= nil
  g_faded_items_store = {}
  g_chain_upgrades_active = false
  g_constructables_id = 1
  if info.slots then
    g_num_slots = #info.slots
  else
    g_num_slots = 1
  end
  ResetConstructionButtons()
end

function GenerateConstructionPanel(info)
  ResetConstructionPanel(info)
  ShaneOutputFocused("GenerateConstructionPanel for " .. #info.slots .. " slots")
  if #info.slots > 0 and 0 < #info.slots[1].buildings then
    local first_selectable_slot
    for slot = 1, #info.slots do
      local first_building = info.slots[slot].buildings[1]
      if utils.BUILDING_ICON_TYPE_CONSTRUCTING == first_building.type then
        ShaneOutputFocused("::CreateBuildingUnderConstruction:: for slot " .. tostring(slot) .. " type = " .. tostring(first_building.type))
        first_slot_empty = CreateBuildingUnderConstruction(first_building, info, slot) or first_slot_empty
      elseif utils.BUILDING_ICON_TYPE_BUILT == first_building.type then
        ShaneOutputFocused("::CreateBuildingConstructed:: for slot " .. tostring(slot) .. " type = " .. tostring(first_building.type))
        CreateBuildingConstructed(first_building, info, slot)
        if first_selectable_slot == nil then
          first_selectable_slot = slot
        end
      else
        ShaneOutputFocused("::CreateBuildingFoundation:: for slot " .. tostring(slot))
        first_slot_empty = CreateBuildingFoundation(first_building, info, slot) or first_slot_empty
        if first_selectable_slot == nil then
          first_selectable_slot = slot
        end
      end
    end
    g_passive_selection = nil
    g_explicit_selection = nil
    if g_controlable and first_selectable_slot then
      SelectExplicitConstructionSlotExclusive(first_selectable_slot)
      SelectPassiveConstructionSlotExclusive(first_selectable_slot)
    end
  end
end

function CreateBuildingFrame(item, name, id, x, y, images, text_list, show_tech, hidden)
  local component_addr = Component.CreateComponentFromTemplate("BuildingFrame", name, g_card_group:Address(), x, y, images, text_list)
  ShaneOutputFocused("--")
  ShaneOutputFocused("CreateBuildingFrame: " .. tostring(name))
  ShaneOutputFocused("Address = " .. tostring(component_addr))
  ShaneOutputFocused("Id = " .. tostring(id))
  ShaneOutputFocused("slot_key = " .. tostring(item.slot_key))
  ShaneOutputFocused("show_tech = " .. tostring(show_tech))
  ShaneOutputFocused("hidden = " .. tostring(hidden))
  ShaneOutputFocused("can_repair = " .. tostring(item.can_repair))
  ShaneOutputFocused("--")
  g_original_order_addresses[#g_original_order_addresses + 1] = component_addr
  if show_tech then
    ShowTechnologies(item, component_addr)
  end
  local component = UIComponent(component_addr)
  if item.health and item.health < 100 then
    ShowBuildingHealth(component, item.health)
  else
    HideBuildingHealth(component)
  end
  if hidden then
    component:PropagateVisibility(false)
    HideBaseImages(component)
  end
  component:SetTooltipText(item.name .. "\n" .. "[ALIGN:L]" .. item.short_description, true)
  component:SetGlobal("id", id)
  component:SetGlobal("faction_key", g_faction_key)
  component:SetGlobal("controlable", g_controlable)
  component:SetGlobal("name", item.name)
  component:SetGlobal("long_description", item.long_description)
  component:SetGlobal("short_description", item.short_description)
  component:SetGlobal("building_key", item.building_key)
  component:SetGlobal("region_key", item.region_key)
  component:SetGlobal("slot_key", item.slot_key)
  component:SetGlobal("type", item.type)
  component:SetGlobal("damaged", item.health < 100)
  component:SetGlobal("being_repaired", item.being_repaired)
  component:SetGlobal("repairable", item.can_repair)
  component:SetGlobal("can_afford_repair", item.can_afford_repair)
  component:SetGlobal("repair_cost", item.repair_cost)
  component:SetGlobal("dismantling", item.dismantling)
  component:SetGlobal("alternate_chain", item.alternate_chain)
  component:SetGlobal("affordable", bit.band(item.availability, AFFORDABLE) ~= 0)
  component:SetGlobal("tech_present", bit.band(item.availability, TECH_PRESENT) ~= 0)
  component:SetGlobal("is_tribal_restricted", string.find(item.building_key, "tribal") ~= nil)
  component:SetState("unselected")
  return component_addr
end

function CreateBuildingConstructed(building, info, slot)
  ShaneOutputFocused("")
  ShaneOutputFocused("Slot " .. slot .. " is a constructed building: " .. building.name)
  local text_list = {}
  text_list.Title = building.name
  text_list.turns_center = building.turns_to_completion
  text_list.turns_corner = building.turns_to_completion
  local b_x, b_y = BuildingCardPosition(slot, #info.slots)
  local image_replacements = {
    "{building:1}" .. building.image
  }
  g_building_slot_components[slot] = CreateBuildingFrame(building, "Building" .. slot, slot, b_x, b_y, image_replacements, text_list, false, false)
  local building_component = UIComponent(g_building_slot_components[slot])
  building_component:SetGlobal("altchain_building", nil)
  local turns_centre = UIComponent(building_component:Find("turns_center"))
  local constructing_animation = UIComponent(building_component:Find("constructing_animation"))
  if building.dismantling then
    turns_centre:SetVisible(true)
    turns_centre:SetStateText("1")
    constructing_animation:SetVisible(true)
    constructing_animation:SetState("1")
    constructing_animation:SetImageColour(0, 128, 0, 0, 255)
  elseif building.being_repaired then
    turns_centre:SetVisible(true)
    turns_centre:SetStateText(building.turns_to_completion)
    constructing_animation:SetVisible(true)
    constructing_animation:SetState("1")
    constructing_animation:SetImageColour(0, 0, 128, 0, 255)
  end
  local upgrades_list = info.slots[slot].upgrades
  if upgrades_list then
    ShaneOutput("Num upgrades for Building" .. slot .. " = " .. #upgrades_list)
    building_component:SetGlobal("upgrades", #upgrades_list)
    local parent_x, parent_y = building_component:Position()
    g_construction_groups[slot] = {}
    g_alternate_chain_groups[slot] = {}
    local upgrade_index = 1
    local altchain_index = 1
    for u = 1, #upgrades_list do
      local upgrade = upgrades_list[u]
      if upgrade then
        local u_x, u_y, upgrade_icon_directly_under_slot = ConstructionItemPosition(u, slot, #info.slots, #upgrades_list)
        local text_list = {}
        text_list.Title = upgrade.name
        text_list.building_cost = upgrade.cost
        text_list.turns_center = upgrade.turns_to_completion
        text_list.turns_corner = upgrade.turns_to_completion
        local item_name
        if upgrade.alternate_chain then
          item_name = "Building" .. slot .. "_" .. "Alternate chain" .. altchain_index
        else
          item_name = "Building" .. slot .. "_" .. "Upgrade" .. upgrade_index
        end
        local image_replacements = {
          "{building:1}" .. upgrade.image
        }
        local component_ptr = CreateBuildingFrame(upgrade, item_name, slot, u_x, u_y, image_replacements, text_list, true, true)
        local component = UIComponent(component_ptr)
        component:SetState("unselected")
        UIComponent(component:Find("building_cost")):SetStateText(upgrade.cost)
        ShaneOutputFocused(tostring(item_name) .. " : alternate_chain = " .. tostring(upgrade.alternate_chain))
        if not upgrade.alternate_chain then
          ShaneOutput("Adding upgrade to g_construction_group")
          g_construction_groups[slot][upgrade_index] = component_ptr
          upgrade_index = upgrade_index + 1
        else
          ShaneOutput("Adding alt chain to g_construction_group")
          g_alternate_chain_groups[slot][altchain_index] = component_ptr
          altchain_index = altchain_index + 1
        end
      end
    end
  end
end

function CreateBuildingUnderConstruction(building, info, slot)
  ShaneOutputFocused("Slot " .. slot .. " is constructing " .. building.name)
  local text_list = {}
  text_list.Title = building.name
  text_list.turns_center = building.turns_to_completion
  text_list.turns_corner = building.turns_to_completion
  local b_x, b_y = BuildingCardPosition(slot, #info.slots)
  local image_replacements = {
    "{building:1}" .. building.image
  }
  g_building_slot_components[slot] = CreateBuildingFrame(building, "Building" .. slot, slot, b_x, b_y, image_replacements, text_list, false, false)
  local building_component = UIComponent(g_building_slot_components[slot])
  UIComponent(building_component:Find("turns_center")):SetVisible(true)
  UIComponent(building_component:Find("turns_corner")):SetVisible(false)
  UIComponent(building_component:Find("constructing_animation")):SetVisible(true)
  local clockface = utils.TruncToInt(utils.TruncToInt(1 + building.percent_complete / 100 * 11) % 12)
  UIComponent(building_component:Find("constructing_animation")):SetState(clockface)
  return slot == 1
end

function CreateBuildingFoundation(building, info, slot)
  ShaneOutputFocused("Slot " .. slot .. " is a building site")
  local b_x, b_y = BuildingCardPosition(slot, #info.slots)
  g_building_slot_components[slot] = Component.CreateComponentFromTemplate("BuildingFrame", "Slot" .. slot, g_card_group:Address(), b_x, b_y)
  ShowTechnologies(building, g_building_slot_components[slot])
  g_original_order_addresses[#g_original_order_addresses + 1] = g_building_slot_components[slot]
  local slot_component = UIComponent(g_building_slot_components[slot])
  slot_component:SetState("unselected")
  slot_component:SetTooltipText(g_construction_site_localised_string, true)
  slot_component:SetGlobal("controlable", g_controlable)
  slot_component:SetGlobal("type", utils.BUILDING_ICON_TYPE_EMPTY)
  slot_component:SetGlobal("id", slot)
  slot_component:SetGlobal("name", "Slot" .. slot)
  slot_component:SetGlobal("long_description", "")
  slot_component:SetGlobal("short_description", "")
  slot_component:SetGlobal("building_key", "No key")
  slot_component:SetGlobal("region_key", building.region_key)
  slot_component:SetGlobal("slot_key", building.slot_key)
  HideBuildingHealth(slot_component)
  local constructables = info.slots[slot].buildings
  g_construction_groups[slot] = {}
  ShaneOutput("Creating " .. #constructables .. " constructables")
  for c = 1, #constructables do
    local constructable = constructables[c]
    local c_x, c_y, construction_icon_directly_under_slot = ConstructionItemPosition(c, slot, #info.slots, #constructables)
    local text_list = {}
    text_list.Title = "Constructable"
    text_list.building_cost = constructable.cost
    text_list.turns_center = constructable.turns_to_completion
    text_list.turns_corner = constructable.turns_to_completion
    local image_replacements = {
      "{building:1}" .. constructable.image
    }
    ShaneOutput("Creating constructable with image: " .. constructable.image)
    g_construction_groups[slot][c] = CreateBuildingFrame(constructable, "Constructable" .. g_constructables_id, g_constructables_id, b_x, b_y + c_y, image_replacements, text_list, true, true)
    g_constructables_id = g_constructables_id + 1
  end
  return slot == 1
end

function DemolishCurrentSelection()
  if g_explicit_selection then
    local component = UIComponent(g_building_slot_components[g_explicit_selection])
    if g_fort_ptr then
      CampaignUI.DemolishFort(g_fort_ptr)
    else
      local slot_key = component:GlobalExists("slot_key")
      local building_key = component:GlobalExists("building_key")
      if CampaignUI.CanDemolishBuilding(slot_key) == true then
        CampaignUI.DemolishBuilding(building_key, slot_key)
      end
    end
  end
end

function RepairCurrentSelection()
  ShaneOutputFocused("RepairCurrentSelection")
  ShaneOutputFocused("g_fort_ptr = " .. tostring(g_fort_ptr))
  ShaneOutputFocused("g_explicit_selection = " .. tostring(g_explicit_selection))
  if g_explicit_selection then
    local component = UIComponent(g_building_slot_components[g_explicit_selection])
    ShaneOutputFocused("repairable = " .. tostring(component:GlobalExists("repairable")))
    if component:GlobalExists("repairable") == true then
      if g_fort_ptr then
        CampaignUI.RepairFort(g_fort_ptr)
      else
        local slot_key = component:GlobalExists("slot_key")
        local building_key = component:GlobalExists("building_key")
        CampaignUI.RepairBuilding(building_key, slot_key)
      end
    end
  end
end

function ResetConstructionButtons(slot)
  local construction_buttons = UIComponent(g_root:Find("buttons_build"))
  construction_buttons:SetVisible(g_controlable)
  if g_controlable and not g_infrastructure then
    construction_buttons:PropagateVisibility(true)
    local repair_button = UIComponent(g_root:Find("build_repair"))
    repair_button:SetState("inactive")
    local demolish_button = UIComponent(g_root:Find("build_demolish"))
    demolish_button:SetState("inactive")
    local chain_upgrade_button = UIComponent(g_root:Find("build_upgrade_altchain"))
    chain_upgrade_button:SetState("inactive")
  else
    construction_buttons:PropagateVisibility(false)
  end
end

function ShowConstructionButtons(empty)
  ShaneOutputFocused("ShowConstructionButtons")
  local construction_buttons = UIComponent(g_root:Find("buttons_build"))
  construction_buttons:SetVisible(g_controlable)
  if g_controlable and not g_infrastructure then
    local repair_button = UIComponent(g_root:Find("build_repair"))
    local demolish_button = UIComponent(g_root:Find("build_demolish"))
    local chain_upgrade_button = UIComponent(g_root:Find("build_upgrade_altchain"))
    if empty then
      repair_button:SetState("inactive")
      demolish_button:SetState("inactive")
      chain_upgrade_button:SetState("inactive")
    elseif g_explicit_selection then
      local component = UIComponent(g_building_slot_components[g_explicit_selection])
      local building_item_index = component:GlobalExists("id")
      ShaneOutputFocused(tostring(g_alternate_chain_groups[building_item_index]))
      if g_alternate_chain_groups[building_item_index] then
        ShaneOutputFocused(tostring(#g_alternate_chain_groups[building_item_index]))
      end
      if g_alternate_chain_groups[building_item_index] and 0 < #g_alternate_chain_groups[building_item_index] then
        chain_upgrade_button:SetState("unselected")
      else
        chain_upgrade_button:SetState("inactive")
      end
      ShaneOutput("Showing construction buttons: Repairable = " .. tostring(component:GlobalExists("repairable")) .. ", Can afford repair = " .. tostring(component:GlobalExists("can_afford_repair")) .. ", Dismantling = " .. tostring(component:GlobalExists("dismantling")))
      if component:GlobalExists("dismantling") then
        repair_button:SetState("inactive")
        demolish_button:SetState("inactive")
        demolish_button:SetTooltipText(g_marked_dismantle_localised_string, true)
      else
        if g_fort_ptr then
          demolish_button:SetVisible(false)
        elseif component:GlobalExists("slot_key") and CampaignUI.CanDemolishBuilding(component:GlobalExists("slot_key")) then
          demolish_button:SetState("normal")
          demolish_button:SetTooltipText(g_click_dismantle_localised_string, true)
        else
          demolish_button:SetTooltipText(g_dismantle_unable_localised_string, true)
        end
        if component:GlobalExists("being_repaired") then
          repair_button:SetState("inactive")
          repair_button:SetTooltipText(g_under_repair_localised_string, true)
        elseif component:GlobalExists("repairable") and component:GlobalExists("can_afford_repair") then
          repair_button:SetState("normal")
          repair_button:SetTooltipText(g_repair_cost_localised_string .. " " .. component:GlobalExists("repair_cost"), true)
        else
          repair_button:SetState("inactive")
          if component:GlobalExists("repairable") and not component:GlobalExists("can_afford_repair") then
            repair_button:SetTooltipText(g_cant_afford_localised_string .. " " .. component:GlobalExists("repair_cost"), true)
          elseif component:GlobalExists("damaged") ~= true then
            repair_button:SetTooltipText(g_not_required_localised_string, true)
          end
        end
      end
    else
      chain_upgrade_button:SetState("inactive")
    end
  end
end

function ConstructionSlotSelection()
  return g_passive_selection
end

function ClearConstructionSlotSelection()
  for s = 1, #g_building_slot_components do
    ShaneOutput("Deselecting construction slot " .. s)
    UIComponent(g_building_slot_components[s]):SetState("unselected")
  end
  for s = 1, #g_construction_groups do
    for c = 1, #g_construction_groups[s] do
      UIComponent(g_construction_groups[s][c]):PropagateVisibility(false)
    end
  end
  for s = 1, #g_alternate_chain_groups do
    for c = 1, #g_alternate_chain_groups[s] do
      UIComponent(g_alternate_chain_groups[s][c]):PropagateVisibility(false)
    end
  end
  g_passive_selection = nil
end

function ReorderAlternateChainOptions(building, alternatives)
  local new_order_addresses = {}
  for i = 1, #alternatives do
    table.insert(new_order_addresses, 1, alternatives[i])
  end
  new_order_addresses[#new_order_addresses + 1] = building
  ReorderCardgroupChildren(new_order_addresses)
end

function ReorderConstructionOptions(lead_position, items)
  local new_order = {}
  for i = 1, #items do
    if i == lead_position then
      for left_position = 1, lead_position - 1 do
        new_order[#new_order + 1] = left_position
      end
      for right_position = lead_position + 1, #items do
        new_order[#new_order + 1] = #items + 1 - (right_position - lead_position)
      end
      new_order[#new_order + 1] = lead_position
      break
    end
  end
  ShaneOutput("New items order as follows:")
  for i = 1, #new_order do
    ShaneOutput(new_order[i])
  end
  local new_order_addresses = {}
  for i = 1, #new_order do
    new_order_addresses[i] = items[new_order[i]]
    ShaneOutput("Address: " .. tostring(new_order_addresses[i]) .. " Original: " .. tostring(items[i]))
  end
  ReorderCardgroupChildren(new_order_addresses)
end

function ReorderCardgroupChildren(new_order_addresses)
  for i = 1, #g_original_order_addresses do
    local found = false
    for n = 1, #new_order_addresses do
      if new_order_addresses[n] == g_original_order_addresses[i] then
        found = true
        break
      end
    end
    if not found then
      new_order_addresses[#new_order_addresses + 1] = g_original_order_addresses[i]
    end
  end
  g_card_group:ReorderChildren(g_original_order_addresses)
  g_card_group:ReorderChildren(new_order_addresses)
end

function SelectExplicitConstructionSlotExclusive(building_item_index)
  assert(g_building_slot_components[building_item_index])
  local building_item = UIComponent(g_building_slot_components[building_item_index])
  if g_explicit_selection ~= building_item_index then
    if g_explicit_selection then
      local previous_building_item = UIComponent(g_building_slot_components[g_explicit_selection])
      UIComponent(previous_building_item:Find("selected_highlight")):SetVisible(false)
    end
    UIComponent(building_item:Find("selected_highlight")):SetVisible(true)
    g_explicit_selection = building_item_index
    local empty = building_item:GlobalExists("type") == utils.BUILDING_ICON_TYPE_EMPTY
    ShowConstructionButtons(empty)
  end
end

function SelectPassiveConstructionSlotExclusive(building_item_index)
  if g_passive_selection ~= building_item_index then
    assert(g_building_slot_components[building_item_index])
    if g_construction_groups and g_construction_groups[building_item_index] then
      local temp_x, temp_y, temp_icon_under_slot = ConstructionItemPosition(1, building_item_index, #g_building_slot_components, #g_construction_groups[building_item_index])
      ReorderConstructionOptions(temp_icon_under_slot, g_construction_groups[building_item_index])
    end
    assert(g_building_slot_components[building_item_index])
    local building_ptr = g_building_slot_components[building_item_index]
    local building = UIComponent(building_ptr)
    building:SetState("selected")
    ShaneOutputFocused(">> Passively selecting building " .. building:Id() .. ", at building item index " .. building_item_index)
    if g_passive_selection then
      if g_passive_selection ~= g_explicit_selection then
        assert(g_building_slot_components[g_passive_selection])
        local old_component = UIComponent(g_building_slot_components[g_passive_selection])
        old_component:SetState("unselected")
      end
      if g_construction_groups and g_construction_groups[g_passive_selection] then
        ShaneOutputFocused("Setting old component group " .. g_passive_selection .. " to fade out")
        local time = CampaignUI.Time()
        for construction_item_index = 1, #g_construction_groups[g_passive_selection] do
          assert(g_construction_groups[g_passive_selection][construction_item_index])
          local construction_item = UIComponent(g_construction_groups[g_passive_selection][construction_item_index])
          construction_item:LuaCall("Fade", time, false)
        end
      end
    end
    for other_buildings_item_index = 1, #g_building_slot_components do
      if other_buildings_item_index ~= building_item_index then
        UIComponent(g_building_slot_components[other_buildings_item_index]):SetState("unselected")
      end
    end
    if g_construction_groups and g_construction_groups[building_item_index] then
      ShaneOutputFocused("Component construction_items group size for building_item_index is " .. #g_construction_groups[building_item_index])
      for construction_item_index = 1, #g_construction_groups[building_item_index] do
        local construction_ptr = g_construction_groups[building_item_index][construction_item_index]
        local buildings_in_group = #g_building_slot_components
        local construction_items_in_group = #g_construction_groups[building_item_index]
        InitialiseConstructionItem(construction_ptr, building_ptr, construction_item_index, building_item_index, buildings_in_group, construction_items_in_group)
      end
    end
    g_passive_selection = building_item_index
  end
end

function InitialiseAltChainBuilding(building_ptr)
  local building = UIComponent(building_ptr)
  local x, y = g_card_group:Position()
  ShaneOutput("InitialiseAltChainBuilding with " .. building:Id())
  if g_chain_upgrades_active then
    local slot = UIComponent(building_ptr):GlobalExists("id")
    local b_x, b_y = BuildingCardPosition(slot, g_num_slots)
    x = x + b_x
    y = y + b_y
  else
    x = x + building:Width() * 0.25
    y = y + g_card_group:Height() * 0.5 - building:Height() * 0.5
    building:SetGlobal("altchain_building", true)
  end
  building:LuaCall("SetAlternateChainTargetState", x, y, building_ptr, g_chain_upgrades_active)
end

function InitialiseAltChainItem(alternate_chain_ptr, building_ptr, alternate_chain_item_index)
  local building_item = UIComponent(building_ptr)
  local alternate_chain_item = UIComponent(alternate_chain_ptr)
  if g_chain_upgrades_active then
    local building_x, building_y = building_item:Position()
    local x, y = alternate_chain_item:Position()
    local targ_x_offset = x - building_x
    local targ_y_offset = y + 50
    alternate_chain_item:LuaCall("SetAlternateChainTargetState", targ_x_offset, targ_y_offset, building_ptr, g_chain_upgrades_active)
  else
    alternate_chain_item:PropagateVisibility(true)
    UIComponent(alternate_chain_item:Find("damaged")):PropagateVisibility(false)
    UIComponent(alternate_chain_item:Find("turns_center")):PropagateVisibility(false)
    UIComponent(alternate_chain_item:Find("constructing_animation")):PropagateVisibility(false)
    UIComponent(alternate_chain_item:Find("upgradable")):PropagateVisibility(false)
    local building_x, building_y = building_item:Position()
    alternate_chain_item:MoveTo(building_x, building_y)
    local targ_x_offset = alternate_chain_item_index * alternate_chain_item:Width() * 1.25
    local targ_y_offset = 0
    alternate_chain_item:LuaCall("SetAlternateChainTargetState", targ_x_offset, targ_y_offset, building_ptr, g_chain_upgrades_active)
    local upgrade_box = UIComponent(alternate_chain_item:Find("upgrade-box"))
    upgrade_box:PropagateVisibility(true)
    upgrade_box:SetState("one")
    UIComponent(upgrade_box:Find("pointer")):SetVisible(false)
  end
  if not ItemAvailable(alternate_chain_item) then
    SetItemVisuallyUnavailable(alternate_chain_item)
  end
end

function InitialiseConstructionItem(construction_ptr, building_ptr, construction_item_index, building_item_index, buildings_in_group, construction_items_in_group)
  assert(building_ptr ~= nil)
  assert(construction_ptr ~= nil)
  local building_item = UIComponent(building_ptr)
  local construction_item = UIComponent(construction_ptr)
  ShaneOutputFocused("::InitialiseConstructionItem")
  ShaneOutputFocused("construction_ptr = " .. tostring(construction_ptr))
  ShaneOutputFocused("building_ptr = " .. tostring(building_ptr))
  ShaneOutputFocused("construction_item_index = " .. tostring(construction_item_index))
  ShaneOutputFocused("building_item_index = " .. tostring(building_item_index))
  ShaneOutputFocused("buildings_in_group = " .. tostring(buildings_in_group))
  ShaneOutputFocused("construction_items_in_group = " .. tostring(construction_items_in_group))
  ShaneOutputFocused("slot_key = " .. tostring(UIComponent(construction_ptr):GlobalExists("slot_key")))
  construction_item:PropagateVisibility(true)
  UIComponent(construction_item:Find("damaged")):PropagateVisibility(false)
  UIComponent(construction_item:Find("turns_center")):PropagateVisibility(false)
  UIComponent(construction_item:Find("constructing_animation")):PropagateVisibility(false)
  UIComponent(construction_item:Find("upgradable")):PropagateVisibility(false)
  local tooltip = ""
  tooltip = tooltip .. tostring(construction_item:GlobalExists("name"))
  if construction_item:GlobalExists("affordable") == false then
    tooltip = tooltip .. "\n" .. g_building_unaffordable_localised_string
  end
  tooltip = tooltip .. "\n" .. "[ALIGN:L]" .. tostring(construction_item:GlobalExists("short_description"))
  ShaneOutput("Setting tooltip for component " .. construction_item:Id() .. " to " .. tooltip)
  construction_item:SetTooltipText(tooltip, true)
  local building_x, building_y = building_item:Position()
  construction_item:MoveTo(building_x, building_y)
  local construction_x, construction_y, item_index_directly_under_slot = ConstructionItemPosition(construction_item_index, building_item_index, buildings_in_group, construction_items_in_group)
  local leading_construction_ptr = g_construction_groups[building_item_index][item_index_directly_under_slot]
  local initialising = g_passive_selection == nil
  construction_item:LuaCall("SetUpgradeTargetState", building_x + construction_x, building_y + construction_y, leading_construction_ptr, initialising)
  local start_x = building_x
  local start_y = building_y
  if initialising then
    start_y = start_y + construction_y
  end
  construction_item:MoveTo(start_x, start_y)
  local state
  if construction_item_index == 1 then
    if #g_construction_groups[building_item_index] == 1 then
      state = "one"
    else
      state = "left"
    end
  elseif construction_item_index == #g_construction_groups[building_item_index] then
    state = "right"
  else
    state = "center"
  end
  local upgrade_box = UIComponent(construction_item:Find("upgrade-box"))
  upgrade_box:PropagateVisibility(true)
  upgrade_box:SetState(state)
  if item_index_directly_under_slot ~= construction_item_index then
    UIComponent(upgrade_box:Find("pointer")):SetVisible(false)
  end
  if not ItemAvailable(construction_item) then
    SetItemVisuallyUnavailable(construction_item)
  end
end

function ItemAvailable(item)
  return item:GlobalExists("affordable") and item:GlobalExists("tech_present")
end

function SetItemVisuallyUnavailable(item)
  local upgrade_box = UIComponent(item:Find("upgrade-box"))
  UIComponent(item:Find("building")):SetState("greyed")
  UIComponent(item:Find("turns_corner")):SetState("greyed")
  if not item:GlobalExists("affordable") then
    UIComponent(upgrade_box:Find("building_cost")):SetState("red")
  end
  item:SetGlobal("unavailable", true)
end

function ShowBuildingHealth(building, health)
  local damage = UIComponent(building:Find("damaged"))
  local damaged = health < 100
  damage:PropagateVisibility(damaged)
  local building_image = UIComponent(building:Find("building"))
  if damaged then
    building_image:ShaderTechniqueSet("buildingcard_burning_t0", true)
    building_image:ShaderVarsSet(0.4, 0, 0, 0)
  else
    building_image:ShaderTechniqueSet("normal_t0", true)
  end
  local clip = UIComponent(damage:Find("fill_clip"))
  local clip_x, clip_y = clip:Position()
  local fill = UIComponent(damage:Find("fill"))
  local health_unary = (100 - utils.Max(health, 2)) / 100
  fill:MoveTo(clip_x, clip_y + utils.TruncToInt(health_unary * clip:Height()))
end

function HideBuildingHealth(building)
  local damage = UIComponent(building:Find("damaged"))
  damage:PropagateVisibility(false)
end

function GenerateFortConstructionPanel(info)
  ShaneOutput("******************************************************************************************************************************************************************************************************")
  ShaneOutput("* GenerateFortConstructionPanel")
  ShaneOutput("******************************************************************************************************************************************************************************************************")
  ResetConstructionPanel(info)
  ShaneOutput("Num fort items: " .. #info.forts)
  for i = 1, #info.forts do
    local fort = info.forts[i]
    local fort_name = "Fort"
    ShaneOutput("fort.type = " .. tostring(fort.type))
    local b_x, b_y = BuildingCardPosition(1, 1)
    if fort.type == utils.BUILDING_ICON_TYPE_BUILT then
      local text_list = {}
      text_list.Title = fort.name
      text_list.turns_center = fort.turns_to_completion
      text_list.turns_corner = fort.turns_to_completion
      local image_replacements = {
        "{building:1}" .. fort.image
      }
      g_building_slot_components[i] = Component.CreateComponentFromTemplate("BuildingFrame", fort_name, g_card_group:Address(), b_x, b_y, image_replacements, text_list)
      g_original_order_addresses[#g_original_order_addresses + 1] = g_building_slot_components[i]
      local fortComponent = UIComponent(g_building_slot_components[i])
      HideBaseImages(fortComponent)
      RemoveTechIcons(fortComponent)
      fortComponent:SetGlobal("controlable", g_controlable)
      fortComponent:SetState("unselected")
      UIComponent(fortComponent:Find("turns_center")):SetVisible(false)
      UIComponent(fortComponent:Find("turns_corner")):SetVisible(false)
      UIComponent(fortComponent:Find("selected_highlight")):SetVisible(true)
      fortComponent:SetTooltipText(fort.name .. "\n" .. "[ALIGN:L]" .. fort.description, true)
      fortComponent:SetGlobal("id", 1)
      fortComponent:SetGlobal("name", fort.name)
      fortComponent:SetGlobal("long_description", "")
      fortComponent:SetGlobal("short_description", fort.description)
      fortComponent:SetGlobal("type", fort.type)
      fortComponent:SetGlobal("being_repaired", fort.being_repaired)
      fortComponent:SetGlobal("repairable", fort.can_repair)
      fortComponent:SetGlobal("can_afford_repair", fort.can_afford_repair)
      fortComponent:SetGlobal("repair_cost", fort.repair_cost)
      ShaneOutput("Setting building key for fort: " .. tostring(fort.building_key))
      fortComponent:SetGlobal("building_key", fort.building_key)
      fortComponent:SetGlobal("faction_key", g_faction_key)
      ShaneOutput("Setting slot key for fort: " .. tostring(fort.slot_key))
      fortComponent:SetGlobal("slot_key", "Fort")
      ShowBuildingHealth(fortComponent, fort.health)
      ShaneOutput("Setting slot fort_ptr for fort: " .. tostring(info.fort_ptr))
      fortComponent:LuaCall("SetFortPtr", info.fort_ptr)
    elseif fort.type == utils.BUILDING_ICON_TYPE_CONSTRUCTING then
      local text_list = {}
      text_list.Title = fort.name
      text_list.turns_center = fort.turns_to_completion
      text_list.turns_corner = fort.turns_to_completion
      local image_replacements = {
        "{building:1}" .. fort.image
      }
      g_building_slot_components[i] = Component.CreateComponentFromTemplate("BuildingFrame", fort_name, g_card_group:Address(), b_x, b_y, image_replacements, text_list)
      g_original_order_addresses[#g_original_order_addresses + 1] = g_building_slot_components[i]
      local fortComponent = UIComponent(g_building_slot_components[i])
      HideBaseImages(fortComponent)
      RemoveTechIcons(fortComponent)
      HideBuildingHealth(fortComponent)
      fortComponent:SetGlobal("controlable", g_controlable)
      fortComponent:SetState("building")
      UIComponent(fortComponent:Find("turns_center")):SetVisible(true)
      UIComponent(fortComponent:Find("turns_corner")):SetVisible(false)
      UIComponent(fortComponent:Find("constructing_animation")):SetVisible(true)
      local clockface = utils.TruncToInt(1 + fort.percent_complete / 100 * 11)
      if 11 < clockface then
        clockface = 0
      end
      UIComponent(fortComponent:Find("constructing_animation")):SetState(clockface)
      fortComponent:SetGlobal("id", 1)
      fortComponent:SetGlobal("name", fort.name)
      fortComponent:SetGlobal("long_description", "")
      fortComponent:SetGlobal("short_description", fort.description)
      fortComponent:SetGlobal("building_key", fort.building_key)
      fortComponent:SetGlobal("faction_key", g_faction_key)
      fortComponent:SetGlobal("slot_key", "Fort")
      fortComponent:SetGlobal("type", fort.type)
      fortComponent:SetGlobal("being_repaired", fort.being_repaired)
      ShaneOutput("fort.being_repaired = " .. tostring(fort.being_repaired))
      if fort.being_repaired == true then
        local turns_centre = UIComponent(fortComponent:Find("turns_center"))
        local constructing_animation = UIComponent(fortComponent:Find("constructing_animation"))
        turns_centre:SetVisible(true)
        turns_centre:SetStateText("1")
        constructing_animation:SetVisible(true)
        constructing_animation:SetState("1")
        constructing_animation:SetImageColour(0, 0, 128, 0, 255)
      end
      fortComponent:LuaCall("SetFortPtr", info.fort_ptr)
    elseif fort.type == utils.BUILDING_ICON_TYPE_UPGRADE then
      ShaneOutput("Adding upgrade to fort display")
      local upgrade = fort
      local u_x, u_y, upgrade_icon_directly_under_slot = ConstructionItemPosition(1, 1, 1, 1)
      local text_list = {}
      text_list.Title = upgrade.name
      text_list.building_cost = upgrade.cost
      text_list.turns_center = upgrade.turns_to_completion
      text_list.turns_corner = upgrade.turns_to_completion
      local image_replacements = {
        "{building:1}" .. upgrade.image
      }
      g_construction_groups[1] = {}
      g_construction_groups[1][1] = Component.CreateComponentFromTemplate("BuildingFrame", "Fort upgrade", g_card_group:Address(), b_x, b_y + u_y, image_replacements, text_list)
      assert(g_construction_groups[1][1] ~= nil)
      local upgradeComponent = UIComponent(g_construction_groups[1][1])
      HideBaseImages(upgradeComponent)
      RemoveTechIcons(upgradeComponent)
      HideBuildingHealth(upgradeComponent)
      upgradeComponent:PropagateVisibility(false)
      upgradeComponent:SetState("unselected")
      upgradeComponent:SetTooltipText(upgrade.name .. "\n" .. "[ALIGN:L]" .. upgrade.description, true)
      UIComponent(upgradeComponent:Find("building_cost")):SetStateText(upgrade.cost)
      upgradeComponent:SetGlobal("controlable", g_controlable)
      upgradeComponent:SetGlobal("id", 1)
      upgradeComponent:SetGlobal("name", upgrade.name)
      upgradeComponent:SetGlobal("long_description", "")
      upgradeComponent:SetGlobal("short_description", upgrade.description)
      upgradeComponent:SetGlobal("building_key", upgrade.building_key)
      upgradeComponent:SetGlobal("faction_key", g_faction_key)
      upgradeComponent:SetGlobal("slot_key", "Fort")
      upgradeComponent:SetGlobal("type", upgrade.type)
      upgradeComponent:SetGlobal("affordable", upgrade.affordable)
      upgradeComponent:SetGlobal("tech_present", true)
      upgradeComponent:LuaCall("SetFortPtr", info.fort_ptr)
    end
  end
  g_passive_selection = nil
  g_explicit_selection = nil
  SelectPassiveConstructionSlotExclusive(1)
  SelectExplicitConstructionSlotExclusive(1)
end

function ShowTechnologies(item, component_addr)
  local component = UIComponent(component_addr)
  ShaneOutput("ShowTechnologies for " .. component:Id() .. ", num technologies = " .. tostring(#item.technologies))
  local unknown_tech = {}
  for i = 1, #item.technologies do
    if not item.technologies[i].researched then
      unknown_tech[#unknown_tech + 1] = item.technologies[i]
    end
  end
  local num_tech_icons = #unknown_tech
  if 3 < num_tech_icons then
    num_tech_icons = 3
  end
  for t = 1, 3 do
    if t > num_tech_icons then
      ShaneOutput("Destroying tech icon " .. t .. " for component " .. component:Id())
      Component.Destroy(component:Find("tech" .. t))
    else
      local technology = item.technologies[t]
      local icon = UIComponent(component:Find("tech" .. t))
      icon:SetGlobal("Key", technology.Key)
      local image = UIImage(technology.IconFilename)
      image:SetComponentTexture(icon:Address(), 0)
      icon:SetTooltipText(technology.Name .. "\n" .. technology.tooltip, true)
      icon:PropagateVisibility(true)
      if technology.researched then
        utils.PropagateShader(icon:Address(), "brighten_t0", 0.5)
      else
        utils.PropagateShader(icon:Address(), "set_greyscale_t0", 1, 1)
      end
    end
  end
end

function AlternateChainItemPosition(position_index, building_ptr)
  local panel = UIComponent(g_root:Find("review_DY"))
  local p_x, p_y = UIComponent(building_ptr):Position()
  local indent = UIComponent(building_ptr):Width() * 0.5
  return p_x + utils.TruncToInt(BUILDING_CARD_WIDTH * 1.25 + ALTERNATE_CHAIN_CARD_WIDTH * 1.25 * (position_index - 1)), p_y
end

function ConstructionItemPosition(position_index, slot, num_slots, num_components)
  assert(g_root ~= nil)
  local panel_width = UIComponent(g_root:Find("review_DY")):Width()
  local slot_xposition = BuildingCardPosition(slot, num_slots)
  ShaneOutput("ConstructionItemPosition: panel width = " .. panel_width)
  ShaneOutput("ConstructionItemPosition: slot" .. slot)
  ShaneOutput("ConstructionItemPosition: num slots = " .. num_slots)
  ShaneOutput("ConstructionItemPosition: num components = " .. num_components)
  local over = slot_xposition + num_components * CONSTRUCTION_CARD_WIDTH - panel_width
  ShaneOutput("ConstructionItemPosition: pixels over = " .. over)
  local positions_over = 0
  if 0 < over then
    positions_over = utils.TruncToInt((over + (CONSTRUCTION_CARD_WIDTH - 1)) / CONSTRUCTION_CARD_WIDTH)
    position_index = position_index - positions_over
  end
  return (position_index - 1) * CONSTRUCTION_CARD_WIDTH, 84, positions_over + 1
end

function BuildingCardPosition(slot, num_slots)
  assert(g_root ~= nil)
  local x_spacing = 12
  local y_pos = 6
  local panel_width = UIComponent(g_root:Find("review_DY")):Width()
  local total_width = num_slots * (BUILDING_CARD_WIDTH + x_spacing) - x_spacing
  local x_pos = (panel_width - total_width) / 2 + (slot - 1) * (BUILDING_CARD_WIDTH + x_spacing)
  return x_pos, y_pos
end

function RemoveTechIcons(component)
  for t = 1, 3 do
    Component.Destroy(component:Find("tech" .. t))
  end
end

function ToggleAltChainUpgrade()
  if g_explicit_selection then
    local selected_component = g_building_slot_components[g_explicit_selection]
    if selected_component and UIComponent(selected_component):GlobalExists("building_key") then
      local building_item_index = UIComponent(selected_component):GlobalExists("id")
      ShaneOutputFocused("ToggleAltChainUpgrade: g_alternate_chain_groups = " .. tostring(g_alternate_chain_groups) .. ", building_item_index = " .. tostring(building_item_index) .. ", g_alternate_chain_groups[building_item_index] = " .. tostring(g_alternate_chain_groups[building_item_index]))
      if g_alternate_chain_groups[building_item_index] then
        ShaneOutput("Valid selection for ToggleAltChainUpgrade")
        local items_involved = {}
        InitialiseAltChainBuilding(selected_component)
        for alternate_chain_item_index = 1, #g_alternate_chain_groups[building_item_index] do
          local alternate_chain_ptr = g_alternate_chain_groups[building_item_index][alternate_chain_item_index]
          InitialiseAltChainItem(alternate_chain_ptr, selected_component, alternate_chain_item_index)
          items_involved[#items_involved + 1] = alternate_chain_ptr
        end
        ReorderAlternateChainOptions(selected_component, items_involved)
        items_involved[#items_involved + 1] = selected_component
        AlternateChainItemFade(items_involved, g_chain_upgrades_active)
        g_chain_upgrades_active = not g_chain_upgrades_active
      end
    end
  end
end

function AlternateChainItemFade(exceptions, fade_in)
  local time = CampaignUI.Time()
  if fade_in then
    for i = 1, #g_faded_items_store do
      g_faded_items_store[i].component:SetInteractive(g_faded_items_store[i].previously_interactive)
      g_faded_items_store[i].component:LuaCall("Fade", time, true)
    end
  else
    g_faded_items_store = {}
    for i = 1, g_card_group:ChildCount() do
      local component = g_card_group:Find(i - 1)
      local exempt = not UIComponent(component):Visible()
      if not exempt then
        for e = 1, #exceptions do
          if component == exceptions[e] then
            exempt = true
            break
          end
        end
      end
      if not exempt then
        local item = UIComponent(g_card_group:Find(i - 1))
        g_faded_items_store[#g_faded_items_store + 1] = {}
        g_faded_items_store[#g_faded_items_store].component = item
        g_faded_items_store[#g_faded_items_store].previously_interactive = item:IsInteractive()
        item:SetInteractive(false)
        item:LuaCall("Fade", time, false)
      end
    end
  end
end

function HideBaseImages(component)
  component:SetImageColour(0, 255, 255, 255, 0)
  component:SetImageColour(1, 255, 255, 255, 0)
end
