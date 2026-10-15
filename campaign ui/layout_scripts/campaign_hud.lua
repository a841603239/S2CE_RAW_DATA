local utils = require("Utilities")
local theatre_map = utils.NamespaceFile("theatre_map")
local this = UIComponent(Address)
theatre_map.SetUI(CampaignUI, CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId()), false, true)

function CurrentTheatre()
  return theatre_map.theatre
end

function SelectNextTheatre()
  theatre = theatre_map.SelectNextTheatre()
  SetWorldMapVisibility(false)
  CampaignUI.SetCameraTarget(theatre)
end

function SelectPrevTheatre()
  theatre = theatre_map.SelectPrevTheatre()
  SetWorldMapVisibility(false)
  CampaignUI.SetCameraTarget(theatre)
end

function RefreshRadar()
  theatre_map.InitialiseMap()
end

function SetRadarTheatreAndPosition(theatre, pos_x, pos_y)
  if theatre ~= theatre_map.theatre then
    theatre_map.SelectTheatre(theatre)
    local meaningful = theatre_map.FindMeaningfulNameFromKey(theatre)
    theatre_buttons:LuaCall("SelectButton", theatre_buttons:Find(meaningful))
  end
  radar:LuaCall("ShowPosition", theatre, pos_x, pos_y)
end

function RadarZoomIn()
  zoom_out_button:SetState("unselected")
  if theatre_buttons:Visible() == true then
    SetWorldMapVisibility(false)
    if theatre_map.ZoomIn() == false then
      zoom_in_button:SetState("inactive")
    end
  else
    theatre_map.ZoomIn()
    zoom_in_button:SetState("inactive")
  end
end

function RadarZoomOut()
  zoom_in_button:SetState("unselected")
  if theatre_buttons:Visible() == true then
    if theatre_map.ZoomOut() == false then
      SetWorldMapVisibility(true)
    end
    zoom_out_button:SetState("inactive")
  else
    theatre_map.ZoomOut()
    zoom_out_button:SetState("inactive")
  end
end

function OnStartTurn()
  theatre_map.SetFaction(CampaignUI.PlayerFactionId())
end

function InitState()
end

function ReassignHudFlags()
  local faction = CampaignUI.PlayerFactionId()
  player_details = CampaignUI.FactionDetails(faction)
  local i = UIImage(player_details.FlagPath .. "/HUD_right.tga")
  i:SetComponentTexture(this:Find("faction_hud_flags"), 0)
  i = UIImage(player_details.FlagPath .. "/HUD_left.tga")
  i:SetComponentTexture(this:Find("flag_L_DY"), 0)
end

function ToggleWorldMap()
  local visible = theatre_buttons:Visible()
  SetWorldMapVisibility(not visible)
end

function SetWorldMapVisibility(visible)
  UIComponent(this:Find("world_map")):SetVisible(visible)
  theatre_buttons:SetVisible(visible)
  radar:LuaCall("SetViewBoundVisibility", not visible)
  local current_theatre = theatre_map.FindMeaningfulNameFromKey(theatre_map.theatre)
  if visible == true then
    for i = 0, theatre_buttons:ChildCount() - 1 do
      local child = UIComponent(theatre_buttons:Find(i))
      child:SetState(child:Id() == current_theatre and "selected" or "normal")
    end
  end
end

function NotifyTheatreSelected(addr)
  SetWorldMapVisibility(false)
  local th = theatre_map.SelectTheatreByMeaningfulId(UIComponent(addr):Id())
  CampaignUI.SetCameraTarget(th)
  zoom_out_button:SetState("unselected")
end

function HandleDrop(items)
  for i, v in ipairs(items) do
    out.tom("Component type", UIComponent(v.Address):GlobalExists("ComponentType"))
    v.Handled = UIComponent(v.Address):GlobalExists("ComponentType") ~= "MinisterCard"
  end
  return items
end
