dofile("data/ui/templates/cards.lua")
local utils = require("Utilities")
local this = UIComponent(Address)
local special_tooltip_method, special_tooltip_build_function
local RTPF_OWNED = 0
local RTPF_NEUTRAL = 1
local RTPF_ALLIED = 2
local RTPF_ENEMY = 3
local displayed_rtpf_states = {
  "neutral",
  "ally",
  "foe"
}
ComponentType = "CampaignCharacterCard"
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(details, display_faction_flag)
  m_item_address = details.Address
  if not details.ShowAttributes then
    Component.Destroy(this:Find("CharacterAttribute", false))
  else
    local character_attribute = UIComponent(this:Find("CharacterAttribute", false))
    if details.CommanderType == utils.CT_SECONDARY_GENERAL or details.CommanderType == utils.CT_BRIGADIER then
      character_attribute:SetState("secondary_land_command")
    elseif details.CommanderType == utils.CT_SECONDARY_ADMIRAL or details.CommanderType == utils.CT_COMMODORE then
      character_attribute:SetState("secondary_sea_command")
    end
    local is_general_or_admiral = details.CommanderType == utils.CT_PRIMARY_GENERAL or details.CommanderType == utils.CT_SECONDARY_GENERAL or details.CommanderType == utils.CT_PRIMARY_ADMIRAL or details.CommanderType == utils.CT_SECONDARY_ADMIRAL
    local show_command_level = is_general_or_admiral and details.Attributes
    UIComponent(character_attribute:Find("Level")):SetState(show_command_level and details.Attributes.PrimaryLevel or 0)
  end
  if not details.ShowFlag then
    Component.Destroy(this:Find("Flags"))
  else
    UIComponent(this:Find("Flags")):SetVisible(true)
  end
  local relationship = display_faction_flag and CampaignUI.CharactersRelationshipToPlayersFaction(m_item_address) or nil
  if relationship == RTPF_OWNED or display_faction_flag ~= true then
    Component.Destroy(this:Find("faction"))
  else
    local faction_flag = UIComponent(this:Find("dy_miniflag"))
    local flag_image = UIImage(details.SmallFlag)
    flag_image:SetComponentTexture(faction_flag:Address(), 0)
    faction_flag:SetInteractive(false)
    local faction_component = UIComponent(this:Find("faction"))
    faction_component:SetState(displayed_rtpf_states[relationship])
  end
  ShowTechnology(details.TechImage)
end

function SetTooltip(text)
  this:SetTooltipText(text, true)
end

function SetSpecialTooltip(method, build_function, user_data)
  this:SetEventCallback("OnMouseOn", OnMouseOn)
  this:SetEventCallback("OnMouseOff", OnMouseOff)
  special_tooltip_method = method
  special_tooltip_build_function = build_function
  special_tooltip_user_data = user_data
end

function OnMouseOn()
  local tooltip = UIComponent(Component.Root()):LuaCall("SetTooltipMethod", special_tooltip_method)
  if tooltip ~= nil then
    if type(special_tooltip_build_function) == "string" then
      UIComponent(tooltip):LuaCall(special_tooltip_build_function, special_tooltip_user_data)
    else
      special_tooltip_build_function(UIComponent(tooltip), special_tooltip_user_data)
    end
    OnRightClickUp()
  end
end

function OnMouseOff()
  UIComponent(Component.Root()):LuaCall("SetTooltipMethod", "standard")
  UIComponent(Component.Root()):LuaCall("CloseCharacterInfo")
end

function ShowTechnology(tech_image)
  local tech = this:Find("tech", false)
  if tech ~= nil then
    if tech_image == nil or tech_image == "" then
      ShaneOutput("Hiding character tech")
      Component.Destroy(tech)
    else
      tech = UIComponent(tech)
      ShaneOutput("Showing character tech " .. tech_image)
      local ui_image = UIImage(tech_image)
      ui_image:SetComponentTexture(tech:Address(), 0)
      tech:PropagateVisibility(true)
    end
  end
end

function OnRightClickUp()
end

function OnMouseLDblClick()
  ShaneOutput("CharacterCard OnLDblLClick")
  CampaignUI.ZoomToCharacter(m_item_address, utils.CAMERA_TARGET_POS_CENTRE)
end

function ResizeForList()
  this:Resize(41, 54, true)
  local attr = UIComponent(this:Find("CharacterAttribute"))
end

function UnitsCharacterButtonLClickUp()
  ShaneOutput("Showing units general info")
end

function UnitsCharacterButtonRClickUp()
  ShaneOutput("Showing units general info")
end

function UnitsCharacterButtonMouseOn()
  utils.PropagateShader(Address, "brighten_t0", 0.15)
end

function UnitsCharacterButtonMouseOff()
  utils.PropagateShader(Address, "normal_t0")
end
