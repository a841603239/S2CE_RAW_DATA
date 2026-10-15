local utilities = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local row_template
local theatres = CampaignUI.TheatreList(true)
local faction_list, current_faction
local show_shane_output = false

function ShaneOutput(string)
  if defined.debug and show_shane_output then
    out.shane(string)
  end
end

function CollectEntries(list_box, entry_list)
  local child_count = list_box:ChildCount()
  for i = 0, child_count - 1 do
    local component = UIComponent(list_box:Find(i))
    local faction = component:GetProperty("Faction")
    entry_list[faction] = component
  end
end

function ReInitialise()
  this:InterfaceFunction("Initialise")
end

function Initialise(quick_deal_action_type)
  this:InterfaceFunction("Initialise", quick_deal_action_type)
end

function OpenNegotiations()
  this:InterfaceFunction("OpenNegotiations")
end

function Notify(button, state)
  local uiButton = UIComponent(button)
  local faction = uiButton:GetProperty("Faction")
  if state == "select roll depress" and faction == current_faction then
    uiButton:SetState("select roll")
  elseif state == "Selected_depress" and faction == current_faction then
    uiButton:SetState("Selected_roll")
  elseif state == "normal roll depress" or state == "Unselected_depress" then
    for i, v in ipairs(faction_list) do
      if v.Key == faction then
        this:InterfaceFunction("SetDisplayedFaction", tostring(i))
        break
      end
    end
  end
end

function StartSlide(direction)
  slide_details.sliding = direction
  slide_details.update_increment = 0
  slide_details.total_offset_this_slide = 0
  slide_details.update_increment = 0
end

function SelectNextMinorFaction()
  if slide_details.sliding == nil and slide_details.total_button_offset > -slide_details.scroll_range then
    StartSlide(-1)
  end
end

function SelectPrevMinorFaction()
  if slide_details.sliding == nil and slide_details.total_button_offset < 0 then
    StartSlide(1)
  end
end

function HighlightRegion(ownerKey, regionAddress)
  return faction_list[ownerKey] ~= nil
end

function RegionClicked(region)
  if faction_list[region.OwnerKey] ~= nil then
    this:InterfaceFunction("SetDisplayedFaction", tostring(region.OwnerKey))
  end
end

function UpdateCharacterCard()
end

function Sorted(address)
  RecolorList(UIComponent(UIComponent(address):Find("list_box")))
end

function ClearListSelection()
  current_faction = nil
  local sortable_list = UIComponent(this:Find("sortable_list"))
  local column, sort_type = sortable_list:LuaCall("LastSorted")
  sortable_list:LuaCall("InitialSort", column, sort_type)
end

function RecolorList(list)
  for i = 0, list:ChildCount() - 1 do
    local child = UIComponent(list:Find(i))
    local state1
    if i % 2 == 1 then
      state1 = "B_"
    else
      state1 = "A_"
    end
    local state2
    if child:GetProperty("Faction") == current_faction then
      state2 = "select"
    else
      state2 = "normal"
    end
    child:SetState(state1 .. state2)
  end
end

function OnDestroyed()
  if row_template ~= nil then
    Component.Destroy(row_template, true)
  end
end
