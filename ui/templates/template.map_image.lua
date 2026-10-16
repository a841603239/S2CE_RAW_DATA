g_notify_lclickup = nil
g_notify_rclickup = nil
g_query_highlighting = nil
g_allow_click_transitions = true
local utilities = require("Utilities")
local region_details
local this = UIComponent(Address)
local overlay = UIComponent(this:Find("map_overlay"))
local UI = CampaignUI
local cursor = Cursor()
local current_mode, minBounds, maxBounds
local theatre_list_mode_enum_mapping = {
  diplomacy_status = 0,
  diplomacy_attitude_owner = 1,
  diplomacy_attitude_faction = 1,
  region_list = 2,
  public_order = 3,
  ownership = 4,
  radar = 4,
  campaign_radar = 4,
  railroads = 5
}

function SetHighlightQueryFunction(f)
  g_query_highlighting = f
  this:InterfaceFunction("SetHasHighlightQueryFunction", f ~= nil)
end

function SetUI(ui)
  UI = ui
end

function SetMinBounds(minW, minH)
  minBounds = {
    w = minW / 2,
    h = minH / 2
  }
end

function SetMaxBounds(maxW, maxH)
  maxBounds = {
    w = maxW / 2,
    h = maxH / 2
  }
end

function StartDrag()
end

function OnMouseOn()
  cursor:SetMode("grab", true)
end

function OnMouseOff()
  if cursor:ModeString() == "grab" then
    cursor:SetMode("normal", true)
  end
end

function ForceResize(w, h)
  this:Resize(w, h, false)
  overlay:Resize(w, h, false)
end

function LimitDrag(new_x, new_y)
  local parent = UIComponent(this:Parent())
  local clip_x, clip_y = parent:Position()
  local clip_w, clip_h = parent:Dimensions()
  local w, h = this:Dimensions()
  local out_x = new_x
  local out_y = new_y
  if new_x + w < clip_x + clip_w then
    out_x = clip_x + clip_w - w
  elseif new_x > clip_x then
    out_x = clip_x
  end
  if new_y < clip_y - (h - clip_h) then
    out_y = clip_y - (h - clip_h)
  elseif new_y > clip_y then
    out_y = clip_y
  end
  return out_x, out_y
end

function ClearShownRegions()
  this:InterfaceFunction("ClearShownRegions")
end

function ShowRegion(key, show)
  this:InterfaceFunction("ShowRegion", key, show)
end

function OnTexturePopulated(set)
end

function InitRegionMap(theatre, faction, mode, governorship)
  region_details = UI.RegionsInTheatre(theatre, faction, governorship, theatre_list_mode_enum_mapping[mode])
  current_mode = mode
  this:InterfaceFunction("InitRegionMap", region_details, faction, mode)
end

function ToggleZoom()
  this:InterfaceFunction("ToggleZoom")
end

function CurrentScale()
  return current_scale
end

function ZoomOut()
  return this:InterfaceFunction("ZoomOut")
end

function ZoomIn()
  return this:InterfaceFunction("ZoomIn")
end

function ZoomToFit(width, height)
  this:InterfaceFunction("ZoomToFit", width, height)
end

function SetInitialZoom(lvl, moveable)
  this:InterfaceFunction("SetInitialZoom", lvl, moveable)
end

function FindRegion(x, y)
  local region_index = this:InterfaceFunction("FindRegionIndex", x, y)
  if region_index ~= nil then
    for i, v in ipairs(region_details) do
      if v.PaletteEntry == region_index then
        return v
      end
    end
  end
  return nil
end

function CallQueryFunction(owner_key, region)
  if g_query_highlighting ~= nil then
    return g_query_highlighting(owner_key, region)
  end
  return false
end

function OnMouseMove(x, y)
  local tooltip = ""
  local v = FindRegion(x, y)
  if v ~= nil then
    tooltip = "[ALIGN:L]" .. CampaignUI.LocalisationString("region_colon") .. " " .. v.Name
    if current_mode ~= nil then
      tooltip = tooltip .. [=[

[ALIGN:L]]=] .. CampaignUI.LocalisationString("owner_colon") .. " " .. v.Owner
      if v.OwnerKnown then
        if #v.RelationshipString > 1 then
          tooltip = tooltip .. v.RelationshipString
        end
        if current_mode == "diplomacy_attitude_owner" and v.OwnerRelationshipDetails then
          local factors_text = this:InterfaceFunction("GetFormattedTooltip", v.OwnerName)
          tooltip = tooltip .. "||[NOWRAP][COLUMNS]" .. factors_text .. "\n" .. v.OwnerRelationshipDetails
        elseif current_mode == "diplomacy_attitude_faction" and v.FactionRelationshipDetailsTowardsOwner then
          local factors_text = this:InterfaceFunction("GetFormattedTooltip", v.FactionName)
          tooltip = tooltip .. "||[NOWRAP][COLUMNS]" .. factors_text .. "\n" .. v.FactionRelationshipDetailsTowardsOwner
        end
      end
    end
  end
  if tooltip ~= last_tooltip then
    this:SetTooltipText(tooltip)
    last_tooltip = tooltip
  end
  if v ~= nil then
    this:InterfaceFunction("CheckRegionHighlightOnMouseMove", v.PaletteEntry, v.OwnerKey, v.Address)
  end
end

function OnLClickUp(x, y)
  local notify = this:GetProperty("NotifyAboutClickedRegion", true)
  if notify ~= nil or g_notify_lclickup ~= nil then
    local v = FindRegion(x, y)
    if v ~= nil then
      if notify ~= nil then
        UIComponent(this:Parent(notify)):LuaCall("RegionClicked", v)
      end
      if g_notify_lclickup ~= nil then
        g_notify_lclickup(v)
      end
    end
  end
  if g_allow_click_transitions then
    notify = overlay:GlobalExists("OnLClickUp")
    if notify ~= nil then
      local posx, posy = this:Position()
      notify(x + posx, y + posy)
    end
  end
end

function OnRClickUp(x, y)
  if g_notify_lclickup ~= nil then
    local v = FindRegion(x, y)
    if v ~= nil then
      g_notify_rclickup(v)
    end
  end
end

function ClearHighlighting()
  this:InterfaceFunction("ClearHighlighting")
end

function SetHighlightedRegionByPaletteEntry(palette_entry)
  if palette_entry == nil then
  end
  this:InterfaceFunction("SetHighlightedRegion", palette_entry)
end

function SetHighlightedRegion(region)
  if region == nil then
  end
  this:InterfaceFunction("SetHighlightedRegion", region.PaletteEntry)
end

function SetHighlightedRegionByAddress(region)
  out.tom("Hightlighted region", region)
  if region == nil then
    ClearHighlighting()
  else
    for i, v in ipairs(region_details) do
      out.tom(i, v.Address)
      if v.Address == region then
        SetHighlightedRegion(v)
        break
      end
    end
  end
end
