local utilities = require("Utilities")
local UI, governorships, governorship, banner, map, map_clip
local max_w = 0
local max_h = 0
local root, faction, mode, left_edge, right_edge, theatres, m_ignore_trade_on_cycle

function SetUI(ui, initial_theatre, exclude_trade_theatres, ignore_trade_on_cycle)
  UI = ui
  theatres = UI.TheatreList(exclude_trade_theatres)
  theatre = initial_theatre
  m_ignore_trade_on_cycle = ignore_trade_on_cycle
end

function SetMapMinBounds(w, h)
  map:LuaCall("SetMinBounds", w, h)
end

function SetMapMaxBounds(w, h)
  map:LuaCall("SetMaxBounds", w, h)
end

function ForceResize(w, h)
  map:LuaCall("ForceResize", w, h)
end

function SelectNextGovernorship()
  for i = 1, #governorships do
    if governorship == nil or governorships[i].Key == governorship then
      if i < #governorships then
        theatre = governorships[i + 1].TheatreKey
        governorship = governorships[i + 1].Key
        name = governorships[i + 1].Name
        break
      end
      theatre = governorships[1].TheatreKey
      governorship = governorships[1].Key
      name = governorships[1].Name
      break
    end
  end
  SetTheatre(name)
  return governorship
end

function SelectPrevGovernorship()
  for i = 1, #governorships do
    if governorship == nil or governorships[i].Key == governorship then
      if 1 < i then
        theatre = governorships[i - 1].TheatreKey
        governorship = governorships[i - 1].Key
        name = governorships[i - 1].Name
        break
      end
      theatre = governorships[#governorships].TheatreKey
      governorship = governorships[#governorships].Key
      name = governorships[#governorships].Name
      break
    end
  end
  SetTheatre(name)
  return governorship
end

function SetGovernorship(gship)
  governorship = gship
  for i, v in ipairs(governorships) do
    if v.Key == gship then
      theatre = v.TheatreKey
      SetTheatre(v.Name)
      break
    end
  end
end

function FindNextTheatre(i)
  if m_ignore_trade_on_cycle == true then
    repeat
      if i == #theatres then
        i = 1
      else
        i = i + 1
      end
    until theatres[i].SeaTrade == false
  elseif i < #theatres then
    i = i + 1
  else
    i = 1
  end
  return i
end

function FindPrevTheatre(i)
  if m_ignore_trade_on_cycle == true then
    repeat
      if i == 1 then
        i = #theatres
      else
        i = i - 1
      end
    until theatres[i].SeaTrade == false
  elseif 1 < i then
    i = i - 1
  else
    i = #theatres
  end
  return i
end

function SelectNextTheatre()
  local name
  for i = 1, #theatres do
    if theatres[i].Key == theatre then
      i = FindNextTheatre(i)
      theatre = theatres[i].Key
      name = theatres[i].Name
      break
    end
  end
  SetTheatre(name)
  return theatre
end

function SelectPrevTheatre()
  local name
  for i = 1, #theatres do
    if theatres[i].Key == theatre then
      i = FindPrevTheatre(i)
      theatre = theatres[i].Key
      name = theatres[i].Name
      break
    end
  end
  SetTheatre(name)
  return theatre
end

function InitialiseMap()
  if theatre and faction then
    if mode == "public_order" then
      map:LuaCall("InitRegionMap", theatre, faction, mode, governorship)
    else
      map:LuaCall("InitRegionMap", theatre, faction, mode)
    end
  end
end

function SetFaction(fac)
  faction = fac
  governorships = UI.GovernorshipList(faction)
  if map ~= nil then
    InitialiseMap()
    ResizeMapClip()
  end
end

function SetFactionAndResize(fac)
  faction = fac
  governorships = UI.GovernorshipList(faction)
  if map ~= nil then
    InitialiseMap()
  end
end

function SetMode(mde)
  mode = mde
  if map ~= nil then
    InitialiseMap()
    ResizeMapClip()
  end
end

function SetModeAndResize(mde)
  mode = mde
  if map ~= nil then
    InitialiseMap()
  end
end

function ShowRegion(region, show)
  map:LuaCall("ShowRegion", region, show)
  InitialiseMap()
end

function ShowRegions(regions, rgba, clear)
  if clear == nil or clear then
    map:LuaCall("ClearShownRegions")
  end
  for i, v in ipairs(regions) do
    map:LuaCall("ShowRegion", v.Address, utilities.CopyTable(rgba))
  end
  InitialiseMap()
end

function SelectTheatreByMeaningfulId(th)
  local name
  for i, v in ipairs(theatres) do
    if v.Id == th then
      name = v.Name
      theatre = v.Key
      break
    end
  end
  SetTheatre(name)
  return theatre
end

function FindMeaningfulNameFromKey(key)
  for i, v in ipairs(theatres) do
    if v.Key == key then
      return v.Id
    end
  end
  return nil
end

function SelectTheatre(th)
  theatre = th
  local name
  for i, v in ipairs(theatres) do
    if v.Key == theatre then
      name = v.Name
      break
    end
  end
  SetTheatre(name)
end

function SetTheatre(name)
  if name ~= nil then
    if root:Find("banner 270", false) ~= nil then
      UIComponent(root:Find("TX_Theatre_DY")):SetStateText(name)
    elseif banner ~= nil then
      banner:SetStateText(name)
    end
  end
  InitialiseMap()
  ResizeMapClip()
  local clip_x, clip_y = map_clip:Position()
  local clip_w, clip_h = map_clip:Dimensions()
  local map_w, map_h = map:Dimensions()
end

function ResizeMapClip()
  local map_w, map_h = map:Dimensions()
  map_clip:Resize(utilities.Min(map_w, max_w), utilities.Min(map_h, max_h), false)
  local panel_x, panel_y = root:Position()
  map_w, map_h = map_clip:Dimensions()
  panel_x = panel_x + utilities.TruncToInt((root:Width() - map_w) / 2)
  panel_y = panel_y + utilities.TruncToInt((root:Height() - map_h) / 2)
  local map_x, map_y = map:Position()
  map_x, map_y = map:LuaCall("LimitDrag", map_x, map_y)
end

function RegisterComponents(r, m, b)
  if root == nil then
    mode = m
    root = UIComponent(r)
    if b ~= nil then
      banner = UIComponent(b)
    end
    map_clip = UIComponent(root:Find("Blank"))
    map = UIComponent(map_clip:Find("map"))
    map:LuaCall("SetUI", UI)
    max_w, max_h = map_clip:Dimensions()
    if root:Find("scroll_edge_L", false) then
      left_edge = UIComponent(root:Find("scroll_edge_L"))
      right_edge = UIComponent(root:Find("scroll_edge_R"))
    end
  end
end

function ToggleZoom()
  map:LuaCall("ToggleZoom")
  SetTheatre()
end

function ZoomIn()
  local result = map:LuaCall("ZoomIn")
  SetTheatre()
  return result
end

function ZoomOut()
  local result = map:LuaCall("ZoomOut")
  SetTheatre()
  return result
end

function ZoomToFit(width, height)
  map:LuaCall("ZoomToFit", width, height)
  SetTheatre()
end

function SetInitialZoom(lvl, moveable)
  map:LuaCall("SetInitialZoom", lvl, moveable)
  SelectTheatre(theatre)
end
