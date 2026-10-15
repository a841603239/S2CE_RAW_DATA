dofile("data/ui/templates/cards.lua")
local utils = require("Utilities")
local root = UIComponent(Component.Root())
local character_attribute = UIComponent(this:Find("CharacterAttribute"))
local experience = UIComponent(this:Find("Experience"))
local land_banner = UIComponent(this:Find("LandBanner"))
local naval_banner = UIComponent(this:Find("BannerNaval"))
local naval_banner_txt = UIComponent(naval_banner:Find("Banner"))
local ship_damage = UIComponent(this:Find("ShipDamage"))
local attribute_level = UIComponent(this:Find("Level"))
local hull_damage_l = UIComponent(this:Find("HullDamageBarL"))
local hull_damage_r = UIComponent(this:Find("HullDamageBarR"))
local land_replenish_component = UIComponent(this:Find("auto_replenish"))
local naval_replenish_component = UIComponent(this:Find("replenish"))
local g_unit_address, g_character_ptr, g_display_as_unit, g_unit_record, g_commanders_name, g_is_naval, g_knowledge_mask, g_spying_data_level, g_exposed
local g_in_transit = false
local g_merging_unit = false
local g_tooltip_function_state = "strat_army"
local localised_capped_string = CampaignUI.LocalisationString("limited_unit_type")
local PI = math.pi
ComponentType = "CampaignUnitCard"
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShaneOutputFocused(msg)
  out.shane(msg)
end

function InitState(state)
  if state.State == "selected" then
    CampaignUI.TriggerUnitSelectedEvent(m_item_address)
  end
end

function Initialise(unit, moveable, selectable, show_replenished, exposed)
  ShaneOutput("*** moveable = " .. tostring(moveable) .. ", selectable = " .. tostring(selectable) .. ", show_replenished = " .. tostring(show_replenished) .. ", exposed = " .. tostring(exposed))
  g_exposed = exposed
  ShaneOutputFocused("g_exposed = " .. tostring(g_exposed))
  if exposed then
    unit.knowledge_mask = utils.SPYING_UNIT_DATA_OWNED
    unit.spying_data_level = utils.SPYING_DATA_LEVEL_OWNED
  end
  local primary_commander = unit.CommanderType == utils.CT_PRIMARY_GENERAL or unit.CommanderType == utils.CT_PRIMARY_ADMIRAL
  local is_general_or_admiral = unit.CommanderType == utils.CT_PRIMARY_GENERAL or unit.CommanderType == utils.CT_SECONDARY_GENERAL or unit.CommanderType == utils.CT_PRIMARY_ADMIRAL or unit.CommanderType == utils.CT_SECONDARY_ADMIRAL
  local showing_in_character_format = unit.DisplayAsUnit == false and is_general_or_admiral == true
  ShaneOutput("CommanderType = " .. tostring(unit.CommanderType))
  ShaneOutput("primary_commander = " .. tostring(primary_commander))
  ShaneOutput("is_general_or_admiral = " .. tostring(is_general_or_admiral))
  ShaneOutput("showing_in_character_format = " .. tostring(showing_in_character_format))
  unit.selectable = selectable
  unit.moveable = moveable
  g_knowledge_mask = unit.knowledge_mask
  g_spying_data_level = unit.spying_data_level
  if exposed then
    g_knowledge_mask = utils.SPYING_UNIT_DATA_OWNED
    g_spying_data_level = utils.SPYING_DATA_LEVEL_OWNED
    ShaneOutput("EXPOSED knowledge_mask and spying_data_level")
  end
  ShaneOutput("knowledge_mask = " .. tostring(g_knowledge_mask))
  ShaneOutput("spying_data_level = " .. tostring(g_spying_data_level))
  this:SetDisabled(unit.spying_data_level < utils.SPYING_DATA_LEVEL_ADVANCED)
  if bit.band(g_knowledge_mask, utils.SPYING_UNIT_DATA_ICON_KNOWN) ~= 0 then
    if showing_in_character_format == true and 0 < string.len(unit.Portrait) then
      ShaneOutput("Setting portrait: " .. unit.Portrait)
      local image = UIImage(unit.Portrait)
      image:SetComponentTexture(Address, 0)
    else
      ShaneOutput("Setting icon: " .. unit.Icon .. ".tga")
      local image = UIImage(unit.Icon .. ".tga")
      image:SetComponentTexture(Address, 0)
    end
  end
  assert(unit.CommanderType ~= nil, "Nil commander type or missing variable initialising a unit")
  g_is_naval = unit.IsNaval
  SetOwnerAndId(UIComponent(this:Parent()):Id(), this:Id(), unit.Address)
  ShaneOutput("Initialising UNIT, Address = " .. tostring(unit.Address) .. ", m_item_address = " .. tostring(m_item_address))
  g_unit_address = unit.Address
  g_in_transit = unit.InTransit
  g_command_type = unit.CommanderType
  g_character_ptr = unit.CharacterPtr
  g_display_as_unit = unit.DisplayAsUnit == true or is_general_or_admiral == false
  g_unit_record = unit.UnitRecord
  this:SetMoveable(unit.moveable)
  g_commanders_name = nil
  local tooltip = ""
  if g_display_as_unit == false then
    tooltip = unit.CommandersName .. "||"
    g_commanders_name = unit.CommandersName
  end
  if not unit.IsNaval then
    naval_replenish_component:SetVisible(false)
    land_replenish_component:SetVisible(show_replenished == true and g_spying_data_level >= utils.SPYING_DATA_LEVEL_ADVANCED)
    InitialiseReplenishmentBars(unit.MenAsPercent, unit.EstimatedMenAsUnary, unit.ReplenishmentLevel, unit.SufferingAttrition)
  else
    land_replenish_component:SetVisible(false)
    naval_replenish_component:SetVisible(show_replenished == true and unit.Replenished == true and g_spying_data_level >= utils.SPYING_DATA_LEVEL_ADVANCED)
  end
  if bit.band(g_knowledge_mask, utils.SPYING_UNIT_DATA_ICON_KNOWN) == 0 then
    ShaneOutput("Setting card state to Unknown")
    this:SetState("Unknown")
    this:PropagateVisibility(false)
    this:SetVisible(true)
  else
    ShaneOutput("unit.spying_data_level = " .. tostring(unit.spying_data_level))
    tooltip = tooltip .. unit.Name
    if unit.spying_data_level >= utils.SPYING_DATA_LEVEL_ADVANCED then
      tooltip = tooltip .. "\n" .. unit.Description
    end
    this:SetTooltipText(tooltip, true)
    if not unit.selectable then
      ShaneOutput("Setting card state to UnSelectable")
      this:SetState("UnSelectable")
    end
    if g_is_naval then
      land_banner:PropagateVisibility(false)
      ship_damage:PropagateVisibility(true)
      naval_banner:PropagateVisibility(true)
      UpdateDamageBar(hull_damage_l, unit.hull_health_l, false)
      UpdateDamageBar(hull_damage_r, unit.hull_health_r, true)
    else
      land_banner:PropagateVisibility(true)
      ship_damage:PropagateVisibility(false)
      naval_banner:PropagateVisibility(false)
    end
    character_attribute:SetVisible(true)
    if primary_commander then
      ShaneOutput("Setting attribute image for general character to " .. unit.Attributes.PrimaryAttributePath)
      local ui_image = UIImage(unit.Attributes.PrimaryAttributePath)
      ui_image:SetComponentTexture(character_attribute:Address(), 0)
    elseif unit.CommanderType == utils.CT_SECONDARY_GENERAL or unit.CommanderType == utils.CT_BRIGADIER then
      character_attribute:SetState("secondary_land_command")
    elseif unit.CommanderType == utils.CT_SECONDARY_ADMIRAL or unit.CommanderType == utils.CT_COMMODORE then
      character_attribute:SetState("secondary_sea_command")
    else
      character_attribute:SetVisible(false)
    end
    local show_command_level = is_general_or_admiral and unit.Attributes
    attribute_level:SetState(show_command_level and unit.Attributes.PrimaryLevel or 0)
  end
  ShaneOutput("SPYING_UNIT_DATA_MEN_KNOWN AND value = " .. bit.band(g_knowledge_mask, utils.SPYING_UNIT_DATA_MEN_KNOWN))
  if g_is_naval then
    if bit.band(g_knowledge_mask, utils.SPYING_UNIT_DATA_GUNS_KNOWN) ~= 0 then
      naval_banner_txt:SetStateText(unit.Guns)
    else
      naval_banner_txt:SetStateText("?")
    end
  elseif bit.band(g_knowledge_mask, utils.SPYING_UNIT_DATA_MEN_KNOWN) ~= 0 then
    land_banner:SetStateText(tostring(unit.Men))
  else
    land_banner:SetStateText("?")
  end
  experience:SetVisible(bit.band(g_knowledge_mask, utils.SPYING_UNIT_DATA_XP_KNOWN) ~= 0)
  experience:SetState(tostring(unit.Experience))
  if unit.InTransit == true then
    this:SetImageColour(0, 255, 255, 255, 128)
    SetTooltipFunctionState("strat_army_in_transit")
  end
  g_merging_unit = CampaignUI.IsMergingUnit(m_item_address)
  this:SetInteractive(not g_merging_unit)
  this:SetVisible(not g_merging_unit)
end

function IsMergingUnit()
  return g_merging_unit
end

function InitialiseReplenishmentBars(CurrentPercentMen, EstimatedMenAsUnary, ReplenishmentLevel, SufferingAttrition)
  out.dylan("UnaryReplenishing is: " .. tostring(UnaryReplenishing) .. ". CurrentPercentMen is: " .. tostring(CurrentPercentMen) .. ". ReplenishmentLevel is: " .. tostring(ReplenishmentLevel) .. ". SufferingAttrition is: " .. tostring(SufferingAttrition))
  local current_men_bar = UIComponent(land_replenish_component:Find("bar_men"))
  local regaining_men_bar = UIComponent(land_replenish_component:Find("bar_regain"))
  local replenish_icon = UIComponent(this:Find("replenish_icon"))
  local replenish_bar_width = land_replenish_component:Width()
  current_men_bar:Resize(utils.Max(CurrentPercentMen * replenish_bar_width, 0.01), current_men_bar:Height())
  regaining_men_bar:Resize(utils.Max(EstimatedMenAsUnary * replenish_bar_width, 0.01), regaining_men_bar:Height())
  if SufferingAttrition == true then
    replenish_icon:SetVisible(true)
    replenish_icon:SetState("attrition")
    current_men_bar:SetState("slow")
    return
  end
  if ReplenishmentLevel == 0 then
    replenish_icon:SetVisible(false)
    current_men_bar:SetVisible(false)
  else
    current_men_bar:SetState("fast")
    replenish_icon:SetVisible(true)
    if ReplenishmentLevel == 1 then
      replenish_icon:SetState("slow")
    elseif ReplenishmentLevel == 2 then
      replenish_icon:SetState("medium")
    elseif ReplenishmentLevel == 3 then
      replenish_icon:SetState("fast")
    end
  end
end

function UpdateDamageBar(bar, health_unary, rot_acw)
  local component_angle = PI * 0.5
  if health_unary ~= nil then
    local rot = component_angle - component_angle * health_unary
    if rot_acw == false then
      rot = -rot
    end
    bar:SetImageRotation(0, rot)
    if 0.7 < health_unary then
      red = (1 - health_unary) / 0.3
      green = 1
    elseif 0.4 < health_unary then
      red = 1
      green = 1 - (0.7 - health_unary) / 0.3
    else
      red = 1
      green = 0
    end
    bar:SetImageColour(0, 255 * red, 255 * green, 0, 255)
  end
end

function ResizeForList()
  this:Resize(41, 54)
  local x, y = this:Position()
  UIComponent(this:Find("LandBanner")):Resize(43, 15)
  UIComponent(this:Find("BannerNaval")):Resize(43, 15)
  UIComponent(this:Find("LandBanner")):MoveTo(x, y + 44)
  UIComponent(this:Find("BannerNaval")):MoveTo(x, y + 44)
  this:Adopt(this:Find("CharacterAttribute"))
  UIComponent(this:Find("CharacterAttribute")):MoveTo(x - 6, y + 33)
  UIComponent(this:Find("ShipDamage")):SetVisible(false)
  if g_is_naval then
    UIComponent(this:Find("replenish_icon")):SetVisible(false)
  end
end

function IsGeneral()
  return g_command_type == utils.CT_PRIMARY_GENERAL or g_command_type == utils.CT_SECONDARY_GENERAL
end

function IsAdmiral()
  return g_command_type == utils.CT_PRIMARY_ADMIRAL or g_command_type == utils.CT_SECONDARY_ADMIRAL
end

function IsGeneralOrAdmiral()
  ShaneOutput("Testing is general or admiral: type = " .. utils.commander_typenames[g_command_type + 1])
  return IsGeneral() or IsAdmiral()
end

function OnRightClickUp()
  if g_display_as_unit == true or g_character_ptr == nil then
  else
  end
end

function ShowInfoPanel()
  if g_display_as_unit == true or g_character_ptr == nil then
  else
    ShaneOutput("Showing CHARACTER info, g_character_ptr = " .. tostring(g_character_ptr))
    UIComponent(this:Parent("root")):LuaCall("ShowCharacterInfo", g_character_ptr)
  end
end

function CharactersUnitButtonLClickUp()
  ShaneOutput("Showing generals unit info, m_item_address = " .. tostring(m_item_address))
  if m_item_address ~= nil then
    ShaneOutput("Calling ShowCharacterInfoUnitInfo with m_item_address = " .. tostring(m_item_address))
  end
end

function CharactersUnitButtonRClickUp()
  ShaneOutput("Showing generals unit info, m_item_address = " .. tostring(m_item_address))
  if m_item_address ~= nil then
    ShaneOutput("Calling ShowCharacterInfoUnitInfo with m_item_address = " .. tostring(m_item_address))
  end
end

function CharactersUnitButtonMouseOn()
  utils.PropagateShader(Address, "brighten_t0", 0.15)
end

function CharactersUnitButtonMouseOff()
  utils.PropagateShader(Address, "normal_t0")
end

function OnMouseOn()
  if this:CurrentState() ~= "Unknown" and g_spying_data_level >= utils.SPYING_DATA_LEVEL_ADVANCED then
    CreateTooltip()
    CharactersUnitButtonRClickUp()
  end
end

function CreateTooltip()
  local tooltip = root:LuaCall("SetTooltipMethod", "unitcard")
  if tooltip then
    local extra_info = this:InterfaceFunction("BuildTooltip")
    UIComponent(tooltip):LuaCall("Initialise", CampaignUI, g_tooltip_function_state, g_unit_record, extra_info, g_commanders_name, CampaignUI.RegimentName(g_unit_address))
  end
end

function OnMouseLDblClick()
end

function OnMouseOff()
  if this:CurrentState() ~= "Unknown" then
    root:LuaCall("SetTooltipMethod", "standard")
  end
  UIComponent(this:Parent("root")):LuaCall("InfoPanelNotUsed")
end

function HandleDrop(dropped_items)
  if CampaignUI.IsUnitMergePossible() then
    local valid_units = {}
    for i, v in ipairs(dropped_items) do
      local c = UIComponent(v.Address)
      local type = c:GlobalExists("ComponentType")
      if type == "CampaignUnitCard" and c:LuaCall("IsNavalUnit") == false then
        local dropped_unit = c:InterfaceFunction("ItemAddress")
        if CampaignUI.CanUnitsMerge(m_item_address, dropped_unit) == true then
          valid_units[#valid_units + 1] = dropped_unit
          c:SetInteractive(false)
          c:SetVisible(false)
        end
      end
    end
    if 0 < #valid_units then
      CampaignUI.MergeUnitsWithFirst(valid_units, this:InterfaceFunction("ItemAddress"))
    end
  end
  return dropped_items
end

function IsNavalUnit()
  return g_is_naval
end

function SetTooltipFunctionState(state)
  g_tooltip_function_state = state
end

function OnMouseLDblClick()
  ShaneOutput("UnitCard OnLDblLClick")
  CampaignUI.ZoomToUnit(m_item_address, utils.CAMERA_TARGET_POS_CENTRE)
end
