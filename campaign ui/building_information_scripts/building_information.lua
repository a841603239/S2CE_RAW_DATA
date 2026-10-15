local core_utils = require("CoreUtils")
local utils = require("Utilities")
local this = UIComponent(Address)
local effects_window = UIComponent(this:Find("effects_window"))
local effect_entries_window = UIComponent(this:Find("entries_window"))
local original_height = this:Height()
local g_original_width = this:Width()
local original_effect_height = effect_entries_window:Height()
local g_details = {}
local g_effect_entries
local g_effect_list_components = {}
PanelIDForAdviceTrigger = nil
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(is_for_building, main_key, faction_key, region_key, slot_key, interactive)
  if is_for_building then
    g_details.building_key = main_key
    PanelIDForAdviceTrigger = "BuildingInfoPanel"
    PanelIDForAdviceTrigger = "TechnologyInfoPanel"
    if not g_effect_entries then
      g_effect_entries = CampaignUI.BuildingEffects(main_key, faction_key, region_key, slot_key)
    end
  else
    g_details.tech_key = main_key
    PanelIDForAdviceTrigger = "TechnologyInfoPanel"
    if not g_effect_entries then
      g_effect_entries = CampaignUI.TechEffects(main_key, region_key, faction_key, slot_key)
    end
  end
  g_details.faction_key = faction_key
  g_details.region_key = region_key
  g_details.slot_key = slot_key
  InitialiseEffectsWindow(g_details, interactive)
  g_effect_entries = nil
end

function InitialiseBuildingInfoPanel(is_for_building, main_key, faction_key, region_key, slot_key, name, desc, image_path, effects)
  if effects ~= nil then
    g_effect_entries = effects
  end
  this:InterfaceFunction("InitialiseFromLua", is_for_building, main_key, faction_key, region_key, slot_key, name, "", desc, image_path)
end

function ClosePopup()
end

function InitialiseEffectsWindow(details, interactive)
  ShaneOutput("")
  ShaneOutput("")
  ShaneOutput("+++")
  ShaneOutput("+ building_information.lua InitialiseEffectsWindow: details.building_key = " .. tostring(details.building_key))
  ShaneOutput("+++")
  ShaneOutput("")
  ShaneOutput("")
  effect_entries_window:DestroyChildren()
  local slider_max = 0
  if g_effect_entries then
    OrderEffects(g_effect_entries.generic)
    slider_max = ShowEffectEntries(g_effect_entries, details.region_key, details.faction_key, details.slot_key, details.building_key, interactive)
    ShaneOutput("Setting effects window slider max position to " .. slider_max)
  end
  local effects_slider = UIComponent(effects_window:Find("vslider"))
  effects_slider:SetProperty("maxValue", slider_max)
  effects_slider:SetProperty("Notify", Address)
  effects_slider:LuaCall("Reset")
  effects_slider:LuaCall("ValueSet", 0)
  effects_slider:SetVisible(0 < slider_max)
end

function Notify(notifier, value)
  local parent = UIComponent(UIComponent(notifier):Parent())
  if parent:Id() == "effects_window" then
    local parent_x, parent_y = effect_entries_window:Position()
    local last_yoffset = 0
    for i = 1, #g_effect_list_components do
      local x, y = g_effect_list_components[i]:Position()
      g_effect_list_components[i]:MoveTo(x, parent_y + last_yoffset - value)
      local custom_height = tonumber(g_effect_list_components[i]:GetProperty("CustomHeight"))
      if 0 < custom_height then
        last_yoffset = last_yoffset + custom_height
      else
        last_yoffset = last_yoffset + g_effect_list_components[i]:Height()
      end
    end
  end
end

function ShowGenericEffectEntries(parent, entries, region_key, faction_key, slot_key, y_offset, interactive)
  for i = 1, #entries do
    image_replacements = {
      "{effect_icon:1}" .. entries[i].IconFilename
    }
    local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_info_generic_entry", "building_info_generic_entry" .. i, parent, 0, y_offset, image_replacements))
    g_effect_list_components[#g_effect_list_components + 1] = component
    component:Resize(effect_entries_window:Width(), component:Height())
    utils.PropagateInteractive(component:Address(), interactive ~= false)
    local description = UIComponent(component:Find("description_dy"))
    description:SetStateText(entries[i].Description)
    local w, h, l = description:TextDimensions()
    component:Resize(component:Width(), h + 12)
    y_offset = y_offset + component:Height()
  end
  return y_offset
end

function ShowCharacterEffectEntries(parent, entries, y_offset)
  local pad_size = 0
  if 0 < #entries then
    local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_info_character_effects", "building_info_character_effects", parent, 0, y_offset))
    local entry_parent = UIComponent(component:Find("entry_parent"))
    g_effect_list_components[#g_effect_list_components + 1] = component
    for i = 1, #entries do
      local key = entries[i].key
      local entry = entry_parent:Find(i - 1)
      if entry then
        entry = UIComponent(entry)
        local image = UIImage(entries[i].image_path)
        image:SetComponentTexture(entry:Address(), 0)
        local name_box = UIComponent(entry:Find("name"))
        name_box:SetStateText(entries[i].name)
        entry:SetVisible(true)
      end
    end
    y_offset = y_offset + component:Height()
  end
  return y_offset
end

function ShowTechnologyEffectEntries(parent, entries, region_key, faction_key, slot_key, y_offset, interactive)
  local num_entries = #entries
  if 0 < num_entries then
    local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_info_tech_entry", "building_info_tech_entry", parent, 0, y_offset))
    g_effect_list_components[#g_effect_list_components + 1] = component
    component:LuaCall("Initialise", entries, region_key, faction_key, slot_key)
    utils.PropagateInteractive(component:Address(), interactive ~= false)
    y_offset = y_offset + component:Height()
  end
  return y_offset
end

function ShowConstructionEffectEntries(parent, entries, region_key, faction_key, slot_key, y_offset, interactive)
  local num_entries = #entries
  if 0 < num_entries then
    local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_info_build_entry", "building_info_build_entry", parent, 0, y_offset))
    local total_height = component:Height() * num_entries + 10
    if 0 < #entries[num_entries].potential_recruitment then
      total_height = total_height + 50
    end
    component:SetProperty("CustomHeight", total_height)
    g_effect_list_components[#g_effect_list_components + 1] = component
    component:LuaCall("Initialise", entries, region_key, faction_key, slot_key)
    utils.PropagateInteractive(component:Address(), interactive ~= false)
    y_offset = y_offset + total_height
  end
  return y_offset
end

function ShowRecruitmentEffectEntries(parent, entries, region_key, faction_key, slot_key, building_key, y_offset, interactive, for_garrison)
  ShaneOutput("")
  ShaneOutput("")
  ShaneOutput("+++")
  ShaneOutput("+ building_information.lua ShowRecruitmentEffectEntries: building_key = " .. tostring(building_key))
  ShaneOutput("+++")
  ShaneOutput("")
  ShaneOutput("")
  local pad_size = 0
  if 0 < #entries then
    local num_entries_per_row = 3
    local lists_required = (#entries + (num_entries_per_row - 1)) / num_entries_per_row
    pad_size = 20
    ShaneOutput("Showing recruitment effects, " .. lists_required .. " lists required.")
    for i = 1, lists_required do
      local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_info_recruitment_effects", "building_info_recruitment_effects", parent, 0, y_offset))
      g_effect_list_components[#g_effect_list_components + 1] = component
      utils.PropagateInteractive(component:Address(), interactive ~= false)
      local entries_portion = {}
      local start_unit_index = 1 + (i - 1) * num_entries_per_row
      for u = start_unit_index, start_unit_index + (num_entries_per_row - 1) do
        if u <= #entries then
          entries_portion[#entries_portion + 1] = entries[u]
        end
      end
      ShaneOutput("Recruitment effects list " .. i .. " has " .. #entries_portion .. " entries")
      local is_first = i == 1
      component:LuaCall("Initialise", entries_portion, region_key, faction_key, slot_key, building_key, is_first, for_garrison)
      y_offset = y_offset + (component:Height() - pad_size)
    end
  end
  return y_offset + pad_size
end

function ShowEffectEntries(entries, region_key, faction_key, slot_key, building_key, interactive)
  ShaneOutput("")
  ShaneOutput("")
  ShaneOutput("+++")
  ShaneOutput("+ building_information.lua ShowEffectEntries: building_key = " .. tostring(building_key))
  ShaneOutput("+++")
  ShaneOutput("")
  ShaneOutput("")
  ShaneOutput("Showing effect entries: ")
  ShaneOutput("region = " .. tostring(region_key))
  ShaneOutput("faction = " .. tostring(faction_key))
  local effect_entries_window_addr = effect_entries_window:Address()
  effect_entries_window:Resize(effect_entries_window:Width(), original_effect_height)
  g_effect_list_components = {}
  local y_offset = 0
  y_offset = ShowGenericEffectEntries(effect_entries_window_addr, entries.generic, region_key, faction_key, slot_key, y_offset, interactive)
  y_offset = ShowTechnologyEffectEntries(effect_entries_window_addr, entries.technology, region_key, faction_key, slot_key, y_offset, interactive)
  if entries.character_recruitment then
    y_offset = ShowCharacterEffectEntries(effect_entries_window_addr, entries.character_recruitment, y_offset, interactive)
  end
  if entries.garrison then
    y_offset = ShowRecruitmentEffectEntries(effect_entries_window_addr, entries.garrison, region_key, faction_key, slot_key, building_key, y_offset, interactive, true)
  end
  y_offset = ShowRecruitmentEffectEntries(effect_entries_window_addr, entries.recruitment, region_key, faction_key, slot_key, building_key, y_offset, interactive, false)
  y_offset = ShowConstructionEffectEntries(effect_entries_window_addr, entries.construction, region_key, faction_key, slot_key, y_offset, interactive)
  local amount_larger_than_window = y_offset - effect_entries_window:Height()
  if interactive ~= false then
    this:Resize(this:Width(), original_height + amount_larger_than_window, false)
  end
  effect_entries_window:Resize(effect_entries_window:Width(), original_effect_height + amount_larger_than_window, false)
  UIComponent(effect_entries_window:Parent()):Resize(effect_entries_window:Width(), original_effect_height + amount_larger_than_window, false)
  return 0
end

function OrderEffects(entries)
  if 1 < #entries then
    local swapped = true
    while swapped == true do
      swapped = false
      for i = 1, #entries - 1 do
        if entries[i].Priority < entries[i + 1].Priority then
          local store = entries[i]
          entries[i] = entries[i + 1]
          entries[i + 1] = store
          swapped = true
        end
      end
    end
  end
  return entries
end
