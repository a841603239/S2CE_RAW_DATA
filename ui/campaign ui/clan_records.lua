dofile("ui/campaign ui/theatre_map_selector.lua")
local utils = require("CoreUtils")
local this = UIComponent(Address)
local panel_manager = PanelManager
local player_faction = CampaignUI.PlayerFactionId()
local theatre = CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId())
local message_handler = MessageManager

function Initialise()
  local map_component = UIComponent(UIComponent(this:Find("event_log")):Find("japan"))
  InitialiseMapHolders(UIComponent(map_component:Parent()), CampaignUI.TheatreList(), player_faction, "campaign_radar")
end

function InitialiseIndividualMap(map_component)
  local map = UIComponent(map_component:Find("map"))
  map:SetEventCallback("OnUpdatePulse", "OnUpdatePulse")
end

function HighlightRegion(...)
  return false
end
