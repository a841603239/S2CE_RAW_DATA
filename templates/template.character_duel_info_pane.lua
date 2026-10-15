local utilities = require("Utilities")
local this = UIComponent(Address)
local m_target, m_target_interface

function OnDestroyed()
  if m_target_interface ~= nil then
    m_target_interface:Release()
    m_target_interface = nil
  end
end

function InitCharacter(mode, details)
  m_target = details.Address
  m_target_interface = CampaignCharacter(m_target)
  this:SetEventCallback("OnDestroyed", OnDestroyed)
  UIComponent(this:Find("dy_char_name")):SetStateText(details.Name)
  UIComponent(this:Find("dy_chance")):SetStateText(details.Chance .. "%")
  UIComponent(this:Find("dy_faction_name")):SetStateText(details.Faction.Name)
  local card = UIComponent(this:Find("CampaignCharacterCard"))
  local off_x, off_y = utilities.OffsetFrom(this, card)
  Component.Destroy(card:Address())
  card = utilities.CreateCharacterCard(details, "CharacterCard", Address, off_x, off_y, false, false, true, false)
  UIComponent(card):SetMoveable(false)
  local diplomacy = CampaignUI.RetrieveDiplomaticStanceString(CampaignUI.PlayerFactionId(), details.Faction.Key)
  UIComponent(this:Find("dy_faction_stance")):SetStateText(diplomacy)
  UIComponent(this:Find("button_" .. mode)):SetVisible(true)
end

function NotifyCharacterDestroyed(character)
  if character == m_target then
    Component.Destroy(Address)
    m_target_interface = nil
  end
end

function NotifyMilitaryForceChanged()
end

function InstigateDuel()
  local scroll = UIComponent(this:Parent("agent_action"))
  scroll:LuaCall("InstigateDuel", m_target)
end

function InstigateAssassination()
  local scroll = UIComponent(this:Parent("agent_action"))
  scroll:LuaCall("InstigateAssassination", m_target)
end
