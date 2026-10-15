local utils = require("Utilities")
local this = UIComponent(Address)
local technology_root = UIComponent(this:Parent("technology_stealing"))
local icon_width = 28
local icon_height = 28
local icon_xspacing = 4
local icon_yspacing = 4
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

function Initialise(tech_entries, category_names)
  local pane_tabs = UIComponent(technology_root:Find("pane_tabs"))
  local pt_x, pt_y = pane_tabs:Position()
  for i = 1, #tech_entries do
    local Name = "tech_" .. i
    local tech_entry = tech_entries[i]
    if tech_entry.tech_status ~= utils.TECHNOLOGY_STATUS_NOT_PRESENT then
      ShaneOutput("Creating tech: Position = " .. tech_entry.ChainPosition .. ". Icon = " .. tech_entry.IconFilename)
      local slot = this:Find("slot" .. i)
      if math.abs(tech_entry.ParentXoffset) > 0 or 0 < math.abs(tech_entry.ParentYoffset) then
        ShaneOutput("Visibly linking tech to parent at " .. tech_entry.ParentXoffset .. ", " .. tech_entry.ParentYoffset)
        local x = icon_width / 2
        local y = icon_height / 2
        if math.abs(tech_entry.ParentXoffset) > 0 then
          local horizontal_line = UIComponent(Component.CreateFromLayout("data/ui/common ui/general_purpose_pixel", "horizontal_link", pane_tabs:Address(), 0, 0))
          local length = (icon_width + icon_xspacing) * math.abs(tech_entry.ParentXoffset)
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
          local height = (icon_height + icon_yspacing) * math.abs(tech_entry.ParentYoffset)
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
      local tech = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/tech_stealing_icon", Name, slot, 0, 0, image_list))
      tech:LuaCall("Initialise", tech_entry, category_names)
    end
  end
end

function ShowTechnologyThiefSelected(tech_index, turns)
  UIComponent(UIComponent(this:Find("slot" .. tech_index)):Find(0)):LuaCall("SetStealingSelected", turns)
end

function ShowTechnologyStealing(tech_index)
  UIComponent(UIComponent(this:Find("slot" .. tech_index)):Find(0)):LuaCall("SetStealing")
end

function ShowTechnologyStealable(tech_index)
  UIComponent(UIComponent(this:Find("slot" .. tech_index)):Find(0)):LuaCall("SetStealable")
end

function TechLeftClicked(Key)
  technology_root:LuaCall("TechLeftClicked", Key)
end

function TechRightClicked(Key)
  technology_root:LuaCall("TechRightClicked", Key)
end

function CloseInfo()
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOff", CloseInfo)
