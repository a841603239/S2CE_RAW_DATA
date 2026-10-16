dofile("ui/campaign ui/theatre_map_selector.lua")
local utils = require("CoreUtils")
local this = UIComponent(Address)
local panel_manager = PanelManager
local player_faction = CampaignUI.PlayerFactionId()
local theatre = CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId())
local message_handler = MessageManager

function Initialise(result_string, is_victory, can_continue)
  this:LockPriority(19)
  CampaignUI.PauseCampaign(true)
  local map_component = UIComponent(UIComponent(this:Find("event_log")):Find("japan"))
  InitialiseMapHolders(UIComponent(map_component:Parent()), CampaignUI.TheatreList(), player_faction, "campaign_radar")
  UIComponent(this:Find("dy_heading_text")):SetStateText(result_string)
  if can_continue == false then
    UIComponent(this:Find("button_continue")):SetState("inactive")
  end
  local event_log = UIComponent(this:Find("event_log"))
  event_log:InterfaceFunction("PopulateEventsList")
  this:InterfaceFunction("InitialiseCampaignVictory")
end

function InitialiseIndividualMap(map_component)
  local map = UIComponent(map_component:Find("map"))
  map:SetEventCallback("OnUpdatePulse", "OnUpdatePulse")
end

function HighlightRegion(...)
  return false
end

function OnExit()
  this:UnLockPriority()
  CampaignUI.PauseCampaign(false)
end
