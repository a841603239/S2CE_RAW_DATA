local utils = require("CoreUtils")
local map_holders_by_id = {}
local map_holders_by_key = {}
local theatre_maps = {}

function InitialiseIndividualMap()
end

function InitialiseMapHolders(root_panel, theatre_list, current_faction, attitude_mode, ...)
  for i = 0, root_panel:ChildCount() - 1 do
    local c = UIComponent(root_panel:Find(i))
    local theatre = c:GetProperty("Theatre", true)
    if theatre ~= nil then
      map_holders_by_id[theatre] = c
      c:PropagateVisibility(true)
      c:SetVisible(false)
    end
  end
  theatre_maps = {}
  for i, v in ipairs(theatre_list) do
    local map_component = map_holders_by_id[v.Id]
    local theatre = v.Key
    map_holders_by_key[theatre] = map_component
    map_component:SetVisible(true)
    local map = utils.NamespaceFile("theatre_map")
    map.SetUI(CampaignUI, theatre, true)
    map.RegisterComponents(map_component:Address(), attitude_mode)
    map.SelectTheatre(theatre)
    map.SetFaction(current_faction)
    theatre_maps[v.Id] = map
    map.ZoomToFit(map_component:Width() / 2, map_component:Height() / 2)
    InitialiseIndividualMap(map_component, map, ...)
  end
end

function SetMapAttitudes(attitude_mode)
  for k, v in pairs(theatre_maps) do
    v.SetMode(attitude_mode)
  end
end

function SetMapFaction(faction)
  for k, v in pairs(theatre_maps) do
    v.SetFaction(faction)
  end
end

function SetMapGovernorship(gov)
  for k, v in pairs(theatre_maps) do
    v.SetGovernorship(gov)
  end
end

function MapShowRegions(...)
  for k, v in pairs(theatre_maps) do
    v.ShowRegions(...)
  end
end

function MapShowRegion(...)
  for k, v in pairs(theatre_maps) do
    v.ShowRegion(...)
  end
end

function SetMapTheatre(theatre)
  for k, v in pairs(map_holders_by_id) do
    v:SetVisible(k == theatre)
  end
end

function GetTheatreMapComponentByKey(theatre_key)
  return map_holders_by_key[theatre_key]
end

function SetMapTheatreByKey(theatre_key)
  for k, v in pairs(map_holders_by_key) do
    v:SetVisible(k == theatre_key)
  end
end

function SelectNextMapGovernorship()
  return theatre_maps[1].SelectNextGovernorship()
end

function SelectPrevMapGovernorship()
  return theatre_maps[1].SelectPrevGovernorship()
end

function ToggleZoom()
  theatre_maps[1].ToggleZoom()
end

function MapSelectNextTheatre()
  return theatre_maps[1].SelectNextTheatre()
end

function MapSelectPrevTheatre()
  return theatre_maps[1].SelectPrevTheatre()
end
