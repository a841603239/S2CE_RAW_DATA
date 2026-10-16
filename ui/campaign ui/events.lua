dofile("ui/campaign ui/theatre_map_selector.lua")
local utils = require("CoreUtils")
local this = UIComponent(Address)
local panel_manager = PanelManager
local player_faction = CampaignUI.PlayerFactionId()
local theatre = CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId())
local message_handler = MessageManager

function Initialise()
  this:InterfaceFunction("Opened")
end

function InitialiseIndividualMap(map_component)
  local map = UIComponent(map_component:Find("map"))
  map:SetEventCallback("OnUpdatePulse", "OnUpdatePulse")
end

function HighlightRegion(...)
  return false
end

function OnExit()
  this:InterfaceFunction("Exited")
end
