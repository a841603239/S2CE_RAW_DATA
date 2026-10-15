local utils = require("Utilities")
local this = UIComponent(Address)
local map = UIComponent(this:Parent())

function OnLClickUp(x, y)
  local posx, posy = this:Position()
  local offset_x = x - posx
  local offset_y = y - posy
  local theatre = CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId())
  local w, h = this:Dimensions()
  offset_x = offset_x / w
  offset_y = offset_y / h
  local theatre_off_x, theatre_off_y, theatre_w, theatre_h = CampaignUI.TheatreMapDimensionsBL(theatre)
  theatre_off_x = theatre_off_x + theatre_w * offset_x
  theatre_off_y = theatre_off_y + theatre_h * (1 - offset_y)
  CampaignUI.SetCameraTarget(theatre_off_x, theatre_off_y)
end

function OnLDblClick(x, y)
end

function ShowPosition(theatre, map_x, map_y)
  local theatre_x, theatre_y, theatre_w, theatre_h = CampaignUI.TheatreMapDimensionsBL(theatre)
  local w, h = this:Dimensions()
  map_x = (map_x - theatre_x) / theatre_w
  map_y = 1 - (map_y - theatre_y) / theatre_h
  local offset_x = w * map_x
  local offset_y = h * map_y
  local map_off_x, map_off_y = utils.OffsetFrom(UIComponent(this:Parent()), this)
  return offset_x + map_off_x, offset_y + map_off_y
end
