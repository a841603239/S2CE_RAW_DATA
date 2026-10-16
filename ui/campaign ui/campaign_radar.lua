local utils = require("Utilities")
local this = UIComponent(Address)
local map = UIComponent(this:Find("map"))
local map_overlay = UIComponent(this:Find("map_overlay"))
local last_cam_x, last_cam_z, last_scale, last_theatre

function InitState()
  map:SetGlobal("OnLeftClickUp", OnLeftClickUp)
  map:SetEventCallback("OnUpdatePulse", "OnUpdatePulse")
  map:SetGlobal("OnUpdatePulse", UpdateCamera)
  CampaignUI.AttachRadarView(map_overlay:Address())
end

function UpdateCamera()
  local x, y, z, theatre = CampaignUI.CameraTarget()
  local scale = map:LuaCall("CurrentScale")
  if last_cam_x ~= x or last_cam_z ~= z or scale ~= last_scale then
    if theatre ~= nil then
      ShowPosition(theatre, x, z)
    end
    UpdateViewBounds()
    last_cam_x = x
    last_cam_z = z
    last_scale = scale
  end
end

function OnLeftClickUp(offset_x, offset_y)
end

function ShowPosition(theatre, map_x, map_y)
  local offset_x, offset_y = map_overlay:LuaCall("ShowPosition", theatre, map_x, map_y)
  local x, y = this:Position()
  local w, h = this:Dimensions()
end

function ScaleMapPosition(theatre, x, y, map_offset_x, map_offset_y)
  local map_off_x, map_off_y, map_w, map_h = CampaignUI.TheatreMapDimensions(theatre)
  local offset_x = x - map_off_x
  local offset_y = y - map_off_y
  local w, h = map:Dimensions()
  return utils.RoundToInt(offset_x * (w / map_w)) - map_offset_x, utils.RoundToInt(h - offset_y * (h / map_h)) - map_offset_y
end

local lines = {}

function UpdateViewBounds()
  local theatre = CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId())
  local theatre_offset_x, theatre_offset_y, theatre_w, theatre_h = CampaignUI.TheatreMapDimensions(theatre)
  local map_w, map_h = map_overlay:Dimensions()
  local update_details = {
    map_dimensions = {w = map_w, h = map_h},
    theatre_offset = {x = theatre_offset_x, y = theatre_offset_y},
    theatre_dimensions = {w = theatre_w, h = theatre_h}
  }
  CampaignUI.UpdateRadarView(update_details)
end

function SetViewBoundVisibility(visible)
  for i, v in ipairs(lines) do
    v:SetVisible(visible)
  end
end
