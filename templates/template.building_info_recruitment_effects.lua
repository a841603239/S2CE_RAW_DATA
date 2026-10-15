local utils = require("Utilities")
local this = UIComponent(Address)
local g_max_entries = UIComponent(this:Find("entry_parent")):ChildCount()
local g_entry_height = this:Height()
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(entries, region_key, faction_key, slot_key, building_key, is_first, for_garrison)
  ShaneOutput("")
  ShaneOutput("")
  ShaneOutput("+++")
  ShaneOutput("+ building_info_recruitment_effects.lua: building_key = " .. tostring(building_key))
  ShaneOutput("+++")
  ShaneOutput("")
  ShaneOutput("")
  UIComponent(this:Find("title_parent")):SetVisible(is_first)
  local num_entries = #entries
  if num_entries > g_max_entries then
    num_entries = g_max_entries
  end
  local sorted_entries = {}
  for i = 1, num_entries do
    if entries[i].New ~= true then
      sorted_entries[#sorted_entries + 1] = entries[i]
    end
  end
  for i = 1, num_entries do
    if entries[i].New == true then
      sorted_entries[#sorted_entries + 1] = entries[i]
    end
  end
  local use_land_effect_icon = true
  for i = 1, num_entries do
    local unit = UIComponent(this:Find("unit_" .. i))
    unit:LuaCall("Initialise", sorted_entries[i], region_key, faction_key, slot_key, building_key, for_garrison)
    local image = UIImage(sorted_entries[i].Icon .. ".tga")
    image:SetComponentTexture(unit:Address(), 0)
    unit:SetTooltipText(sorted_entries[i].Name)
    unit:SetVisible(true)
    if use_land_effect_icon and string.find(sorted_entries[i].Icon, "Naval") ~= nil then
      use_land_effect_icon = false
    end
  end
  this:Resize(this:Width(), g_entry_height, false)
  if is_first then
    if for_garrison then
      UIComponent(this:Find("tx_enables")):SetState("garrison")
    end
    if use_land_effect_icon then
      UIComponent(this:Find("effect_icon")):SetState("army")
    else
      UIComponent(this:Find("effect_icon")):SetState("navy")
    end
  end
end

function NotifyUnitEntryResized(new_height)
  if new_height > g_entry_height then
    g_entry_height = new_height
  end
end
