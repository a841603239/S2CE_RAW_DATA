local utils = require("Utilities")
local theatre_map = utils.NamespaceFile("theatre_map")
local this = UIComponent(Address)
local radar = UIComponent(this:Find("radar"))
theatre_map.SetUI(CampaignUI, CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId()), false, true)

function CurrentTheatre()
  return theatre_map.theatre
end

function RefreshRadar()
  theatre_map.InitialiseMap()
end

function RadarZoomIn()
  local radarmap = UIComponent(this:Find("radar"))
  local themap = UIComponent(radarmap:Find("map"))
  local ratio = themap:Width() / themap:Height()
  if ratio < 1.4 then
    local zresult = themap:InterfaceFunction("SetInitialZoom", "third", false)
  else
    local zresult = themap:InterfaceFunction("SetInitialZoom", "special", false)
  end
end

function RadarZoomOut()
  local radarmap = UIComponent(this:Find("radar"))
  local themap = UIComponent(radarmap:Find("map"))
  local ratio = themap:Width() / themap:Height()
  if ratio < 1.4 then
    local zresult = themap:InterfaceFunction("SetInitialZoom", "sixth", false)
  else
    local zresult = themap:InterfaceFunction("SetInitialZoom", "special_half", false)
  end
end

function SetRadarMapFaction(new_faction)
  theatre_map.SetFactionAndResize(tostring(new_faction))
end

function OnStartTurn()
  theatre_map.SetFaction(CampaignUI.PlayerFactionId())
end

function InitState()
  out.tom("Initialising campaign hud")
  theatre_map.RegisterComponents(radar:Address(), "campaign_radar", nil)
  theatre_map.SetMode("campaign_radar")
  theatre_map.SetFaction(CampaignUI.PlayerFactionId())
  theatre_map.SelectTheatre(CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId()))
  InitialiseMap()
  RadarZoomOut()
  UIComponent(this:Find("button_decrease")):InterfaceFunction("PositionEffects", false)
end

function SetMapMode(new_mode)
  theatre_map.SetModeAndResize(tostring(new_mode))
end

function InitialiseMap()
  theatre_map.InitialiseMap()
end
