local utils = require("Utilities")
local this = UIComponent(Address)
local technology_root = UIComponent(this:Parent("technology"))
local g_building = UIComponent(this:Find("building"))
local arrow = UIComponent(this:Find("tech_arrow"))
local g_icon_width = 28
local g_icon_height = 28
local g_icon_xspacing = 4
local g_icon_yspacing = 4
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShaneOutputFocused(msg)
  if defined.debug then
    out.shane(msg)
  end
end

function Initialise(entry_details, category_names, active_entities, localized_icon_tooltips, last_building_in_chain)
  local pane_tabs = UIComponent(technology_root:Find("pane_tabs"))
  local pt_x, pt_y = pane_tabs:Position()
  local show_arrow = false
  for i = 1, #entry_details.tech_entries do
    local Name = "tech_" .. i
    local tech_entry = entry_details.tech_entries[i]
    if tech_entry.tech_status ~= utils.TECHNOLOGY_STATUS_NOT_PRESENT then
      if last_building_in_chain == false and i == 5 then
        show_arrow = true
      end
      ShaneOutput("Creating tech: Position = " .. tech_entry.ChainPosition .. ". Icon = " .. tech_entry.IconFilename)
      local slot = this:Find("slot" .. i)
      if math.abs(tech_entry.ParentXoffset) > 0 or 0 < math.abs(tech_entry.ParentYoffset) then
        ShaneOutput("Visibly linking tech to parent at " .. tech_entry.ParentXoffset .. ", " .. tech_entry.ParentYoffset)
        local x = g_icon_width / 2
        local y = g_icon_height / 2
        if 0 < math.abs(tech_entry.ParentYoffset) then
          local horizontal_line = UIComponent(Component.CreateFromLayout("data/ui/common ui/general_purpose_pixel", "horizontal_link", pane_tabs:Address(), 0, 0))
          local length = (g_icon_width + g_icon_xspacing) * math.abs(tech_entry.ParentXoffset)
          if tech_entry.ParentXoffset < 0 then
            x = x - length
          end
          ShaneOutput("Connecting horizontal line: " .. x .. ", " .. y .. ", " .. length)
          local px, py = UIComponent(slot):Position()
          horizontal_line:MoveTo(pt_x + (px - pt_x) + x, pt_y + (py - pt_y) + y)
          horizontal_line:Resize(length, 1)
          if tech_entry.ParentXoffset > 0 then
            x = x + length
          end
        end
        if 0 < math.abs(tech_entry.ParentYoffset) then
          local vertical_line = UIComponent(Component.CreateFromLayout("data/ui/common ui/general_purpose_pixel", "vertical_link", pane_tabs:Address(), 0, 0))
          local height = (g_icon_height + g_icon_yspacing) * math.abs(tech_entry.ParentYoffset)
          ShaneOutput("Connecting line height is " .. height)
          if 0 < tech_entry.ParentYoffset then
            y = y - height
          end
          ShaneOutput("Connecting vertical line: " .. x .. ", " .. y .. ", " .. height)
          local px, py = UIComponent(slot):Position()
          vertical_line:MoveTo(pt_x + (px - pt_x) + x, pt_y + (py - pt_y) + y)
          vertical_line:Resize(1, height)
        end
      end
      local image_list = {
        "{" .. Name .. ":1}" .. tech_entry.IconFilename
      }
      local tech = UIComponent(Component.CreateComponentFromTemplate("tech_icon", Name, slot, 0, 0, image_list))
      local numeric_value, percentile, incapacitated = TurnsToCompleteOrChanceToSteal(tech_entry.Key, active_entities)
      tech:LuaCall("Initialise", this, tech_entry, category_names, numeric_value, percentile, localized_icon_tooltips, incapacitated)
    end
  end
  ShaneOutput("Show arrow = " .. tostring(show_arrow) .. ", last_building_in_chain = " .. tostring(last_building_in_chain))
  arrow:SetVisible(show_arrow)
  ReorderTechIcons()
  g_building:LuaCall("Initialise", entry_details)
  this:SetInteractive(true)
end

function TurnsToCompleteOrChanceToSteal(Key, active_entities)
  ShaneOutput("*** TurnsToCompleteIfTechIsInProgress with key " .. Key)
  for i = 1, #active_entities do
    if active_entities[i].Activity.Technology.Key == Key then
      if active_entities[i].Activity.TurnsToComplete ~= nil then
        return active_entities[i].Activity.TurnsToComplete, false, active_entities[i].Health < 100
      else
        assert(active_entities[i].Activity.ChanceToSteal ~= nil)
        return active_entities[i].Activity.ChanceToSteal, true, false
      end
    end
  end
  return nil, nil
end

function ShowTechnologyInProgressSelected(tech_index, turns, percentile, incapacitated)
  assert(turns ~= nil)
  UIComponent(UIComponent(this:Find("slot" .. tech_index)):Find(0)):LuaCall("SetInProgress", turns, percentile, incapacitated)
end

function ShowTechnologyInProgress(tech_index, turns)
  assert(turns ~= nil)
  UIComponent(UIComponent(this:Find("slot" .. tech_index)):Find(0)):LuaCall("SetInProgress", turns)
end

function ShowTechnologyAvailable(tech_index)
  UIComponent(UIComponent(this:Find("slot" .. tech_index)):Find(0)):LuaCall("SetAvailable")
end

function TechLeftClicked(tech_key)
  technology_root:LuaCall("TechLeftClicked", tech_key)
end

function TurnsToResearchOrChanceToSteal(tech_key)
  return technology_root:LuaCall("TurnsToResearchOrChanceToSteal", tech_key)
end

function TechRightClicked(tech_entry)
  technology_root:LuaCall("TechRightClicked", tech_entry)
end

function CloseInfo()
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOff", CloseInfo)

function SelectedEntityProgessingTech(tech_entry)
  return technology_root:LuaCall("SelectedEntityProgessingTech", tech_entry.Key)
end

function HasFacilities()
  return technology_root:LuaCall("HasFacilities")
end

function ReorderTechIcons()
  local new_order = {}
  for i = 0, this:ChildCount() - 1 do
    new_order[#new_order + 1] = this:Find(i)
  end
  if 1 < #new_order then
    local swapped = true
    while swapped == true do
      swapped = false
      for i = 1, #new_order - 1 do
        local x1, y1 = UIComponent(new_order[i]):Position()
        local x2, y2 = UIComponent(new_order[i + 1]):Position()
        if x1 > x2 then
          local temp = new_order[i]
          new_order[i] = new_order[i + 1]
          new_order[i + 1] = temp
          swapped = true
        end
      end
    end
  end
  this:ReorderChildren(new_order)
end

function TechAvailable(tech_entry)
  return technology_root:LuaCall("TechAvailable", tech_entry)
end

function TechCompleted(tech_entry)
  return technology_root:LuaCall("TechCompleted", tech_entry)
end

function TechInProgress(tech_entry)
  return technology_root:LuaCall("TechInProgress", tech_entry)
end

function TechProgressStalled(tech_entry)
  return technology_root:LuaCall("TechProgressStalled", tech_entry)
end

function SelectedEntityIncapacitated(tech_entry)
  return technology_root:LuaCall("SelectedEntityIncapacitated", tech_entry)
end
