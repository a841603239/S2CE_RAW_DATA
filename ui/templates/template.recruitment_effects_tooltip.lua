local utilities = require("Utilities")
local this = UIComponent(Address)
local name_component = UIComponent(this:Find("dy_unit_name"))
local requires_component = UIComponent(this:Find("txt_requires"))
local requires_tech_list_box = UIComponent(this:Find("requires_tech_list_box"))
local requires_building_list_box = UIComponent(this:Find("requires_building_list_box"))
local row_templates = {}
local longest_text_end
local margin = 8
local list_template, active_list_box, inactive_list_box
requires_component:SetStateText(CampaignUI.UILocalisationString("txt_header_requires_Text_110015"))
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(unit_name, requirements, displaying_technology)
  ShaneOutput("Initialising recruitment effects tooltip: unit_name = " .. tostring(unit_name) .. ", requirements size is " .. #requirements .. ", displaying_technology = " .. tostring(displaying_technology))
  if list_template == nil then
    if displaying_technology == true then
      active_list_box = requires_tech_list_box
      inactive_list_box = requires_building_list_box
      list_template = UIComponent(requires_tech_list_box:Find("template_row"))
      UIComponent(list_template:Parent()):Divorce(list_template:Address())
    else
      active_list_box = requires_building_list_box
      inactive_list_box = requires_tech_list_box
      list_template = UIComponent(requires_building_list_box:Find("template_row"))
      UIComponent(list_template:Parent()):Divorce(list_template:Address())
    end
  end
  active_list_box:SetVisible(true)
  inactive_list_box:SetVisible(false)
  longest_text_end = -9999
  local this_x, this_y = this:Position()
  name_component:SetStateText(unit_name)
  name_component:MoveTo(this_x + margin, this_y + margin)
  UpdateLongestTextEnd(name_component)
  local bottom_component = name_component
  if 0 < #requirements then
    requires_component:MoveTo(this_x + margin, this_y + margin + name_component:Height())
    requires_component:SetVisible(true)
    bottom_component = requires_component
    UpdateLongestTextEnd(requires_component)
    requires_tech_list_box:MoveTo(this_x + margin, this_y + margin + name_component:Height() + requires_component:Height())
    local template_height = list_template:Height()
    for i = 1, #requirements do
      bottom_component = UIComponent(Component.CreateFromComponent(list_template:Address(), unit_name .. "_requirement" .. i, active_list_box:Address(), 0, (i - 1) * template_height, {}, {}))
      row_templates[#row_templates + 1] = bottom_component
      local image = UIImage(requirements[i].IconFilename)
      image:SetComponentTexture(bottom_component:Find("icon"), 0)
      local text_field = UIComponent(bottom_component:Find("text"))
      text_field:SetStateText(requirements[i].Name)
      UpdateLongestTextEnd(text_field, text_field:Position() - this:Position())
    end
  end
  Resize(bottom_component)
end

function UpdateLongestTextEnd(component, offset)
  if offset == nil then
    offset = 0
  end
  local details, width = component:GetStateText()
  if width == nil then
    width = 0
  end
  local x, y = component:Position()
  longest_text_end = utilities.Max(longest_text_end, x + width + offset)
  ShaneOutput("longest_text_end = " .. tostring(longest_text_end) .. ", after examining string: " .. tostring(details))
end

function Resize(bottom_component)
  local this_x, this_y = this:Position()
  local new_width = longest_text_end + margin - this_x
  local bottom_x, bottom_y = bottom_component:Position()
  local new_height = bottom_y + bottom_component:Height() + margin - this_y
  ShaneOutput("Resizing tooltip: this_x = " .. tostring(this_x) .. ", longest_text_end = " .. tostring(longest_text_end) .. ", width = " .. tostring(new_width) .. ", height = " .. tostring(new_height))
  if new_width ~= this:Width() or new_height ~= this:Height() then
    this:Resize(new_width, new_height, false)
    longest_text_end = longest_text_end - this_x
    utilities.PositionTooltip(Address)
    this_x, this_y = this:Position()
    longest_text_end = longest_text_end + this_x
  end
end

function OnDestroyed()
  for i = 1, #row_templates do
    Component.Destroy(row_templates[i]:Address(), true)
  end
  row_templates = {}
end

function OnUpdatePulse(time)
  local this_x, this_y = this:Position()
  longest_text_end = longest_text_end - this_x
  utilities.PositionTooltip(Address)
  this_x, this_y = this:Position()
  longest_text_end = longest_text_end + this_x
end
