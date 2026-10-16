local utilities = require("Utilities")
local this = UIComponent(Address)
local creation_time
local expanded = false
local name_component = UIComponent(this:Find("dy_name"))
local function_component = UIComponent(this:Find("txt_function"))
local description_component = UIComponent(this:Find("dy_description"))
local level_component = UIComponent(this:Find("upgrade_pips"))
local turns_component = UIComponent(this:Find("Turns"))
local categories = {
  "require",
  "generic",
  "technology",
  "recruitment",
  "construction"
}
local header_template, list_boxes, row_templates, longest_text_end
local margin = 8
local expand_time = 2000
local effect_lists, unlocks_recruitment
local max_level_display = 7
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

function InitialiseBuilding(details, effects, constructable, constructing, is_tribal_restricted, affordable)
  turns_component:SetVisible(false)
  effect_lists = effects
  unlocks_recruitment = constructable
  if constructable then
    function_component:SetState("building_upgrade")
  elseif constructing then
    function_component:SetState("cancel_construction")
  else
    function_component:SetState("building_owned")
  end
  function_component:SetVisible(true)
  local additional_description = ""
  if affordable == false then
    additional_description = additional_description .. "\n" .. CampaignUI.LocalisationString("unaffordable")
  end
  local description = details.ChainTooltip
  if description == nil then
    description = details.ShortDescription
  end
  Initialise(details.Name, description .. additional_description)
  SetBuildingLevel(details.Level, details.MaxLevel)
  Resize(function_component)
end

function InitialiseTechnology(details, func, description)
  effect_lists = CampaignUI.TechEffects(details.Key, details.region_key, CampaignUI.PlayersFactionKey(), details.slot_key)
  unlocks_recruitment = true
  level_component:SetVisible(false)
  function_component:SetState("technology")
  local bottom_component
  if func ~= nil then
    function_component:SetStateText(func)
    function_component:SetVisible(true)
    bottom_component = function_component
  else
    function_component:SetVisible(false)
    bottom_component = name_component
  end
  Initialise(details.Name, description)
  longest_text_end = longest_text_end + turns_component:Width() + 10
  if details.dependancies ~= nil and #details.dependancies > 0 then
    AddCategory("require", details.dependancies, "IconFilename", "", "", "Name")
    local this_x, this_y = this:Position()
    local bottom_x, bottom_y = bottom_component:Position()
    list_boxes.require:MoveTo(this_x + margin, bottom_y + bottom_component:Height() + 10)
    Resize(list_boxes.require)
  else
    Resize(bottom_component)
  end
  if func == nil then
    Expand()
  end
end

function CollectTemplates()
  if header_template == nil then
    header_template = this:Find("txt_header")
    UIComponent(UIComponent(header_template):Parent()):Divorce(header_template)
    list_boxes = {}
    row_templates = {}
    for i = 1, #categories do
      list_boxes[categories[i]] = UIComponent(this:Find(categories[i] .. "_list_box"))
      row_templates[categories[i]] = list_boxes[categories[i]]:Find(0)
      list_boxes[categories[i]]:Divorce(row_templates[categories[i]])
    end
  end
end

function Initialise(name, description)
  CollectTemplates()
  creation_time = nil
  expanded = false
  longest_text_end = -9999
  local this_x, this_y = this:Position()
  name_component:SetStateText(name)
  name_component:MoveTo(this_x + margin, this_y + margin)
  UpdateLongestTextEnd(name_component)
  function_component:MoveTo(this_x + margin, this_y + margin + name_component:Height())
  if function_component:Visible() then
    UpdateLongestTextEnd(function_component)
  end
  description_component:SetStateText(description)
  description_component:MoveTo(this_x + margin, this_y + margin + name_component:Height())
  description_component:SetVisible(false)
  turns_component:SetVisible(false)
end

function SetBuildingLevel(level, max_level)
  for i = 1, max_level_display do
    UIComponent(this:Find("Level Pip " .. i)):SetVisible(false)
  end
  for i = 1, max_level + 1 do
    local pip = UIComponent(this:Find("Level Pip " .. i))
    pip:SetVisible(true)
    pip:SetState("empty")
  end
  for i = 1, level + 1 do
    UIComponent(this:Find("Level Pip " .. i)):SetState("filled")
  end
  UpdateLongestTextEnd(name_component, level_component:Width() + 10)
end

function UpdateTurns(turns_state, turns)
  ShaneOutputFocused("UpdateTurns:")
  ShaneOutputFocused("turns = " .. tostring(turns))
  ShaneOutputFocused("turns_state = " .. tostring(turns_state))
  if turns_state == nil then
    turns_component:SetVisible(false)
  else
    turns_component:SetVisible(true)
    turns_component:SetState(turns_state)
    if turns == nil then
      turns_component:SetStateText("")
    else
      turns_component:SetStateText(turns)
    end
  end
end

function Expand()
  expanded = true
  function_component:SetVisible(false)
  description_component:SetVisible(true)
  AddCategory("generic", effect_lists.generic, "IconFilename", "", "", "Description")
  AddCategory("technology", effect_lists.technology, "IconFilename", "", "", "Name")
  AddCategory("recruitment", effect_lists.recruitment, "Icon", "", ".tga", "Name")
  AddCategory("construction", effect_lists.construction, "IconFilename", "", "", "Name")
  local this_x, this_y = this:Position()
  local desc_x, desc_y = description_component:Position()
  local desc_width = longest_text_end - desc_x
  if turns_component:Visible() then
    desc_width = desc_width - turns_component:Width() - 10
  end
  description_component:Resize(desc_width, 300)
  local desc_details, desc_width, desc_height = description_component:GetStateText()
  if desc_width == nil then
    desc_width = 0
  end
  if desc_height == nil then
    desc_height = 0
  end
  description_component:Resize(desc_width, desc_height)
  local y = desc_y + desc_height + 10
  local bottom_component = description_component
  for i = 1, #categories do
    local category = categories[i]
    if 0 < list_boxes[category]:ChildCount() then
      list_boxes[category]:MoveTo(this_x + margin, y)
      y = y + list_boxes[category]:Height()
      bottom_component = list_boxes[category]
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
end

function AddCategory(name, effects, icon_field, icon_prefix, icon_postfix, text_field)
  if effects ~= nil and name == "generic" then
    local sorted_effects = {}
    for i = 1, #effects do
      if effects[i].Priority > 0 then
        table.insert(sorted_effects, effects[i])
      end
    end
    for i = 1, #sorted_effects - 1 do
      for j = i + 1, #sorted_effects do
        local swap = false
        if sorted_effects[i].New == false and sorted_effects[j].New == true then
          swap = true
        elseif sorted_effects[i].Priority < sorted_effects[j].Priority and sorted_effects[i].New == sorted_effects[j].New then
          swap = true
        end
        if swap then
          local tmp = sorted_effects[i]
          sorted_effects[i] = sorted_effects[j]
          sorted_effects[j] = tmp
        end
      end
    end
    effects = sorted_effects
  end
  if effects ~= nil and 0 < #effects then
    list_boxes[name]:DestroyChildren()
    local header = UIComponent(Component.CreateFromComponent(header_template, name .. "_header", list_boxes[name]:Address(), 0, 0, {}, {}))
    if name == "recruitment" then
      if unlocks_recruitment == true then
        header:SetState("recruitment_unlock")
      else
        header:SetState("recruitment_enable")
      end
    else
      header:SetState(name)
    end
    UpdateLongestTextEnd(header)
    local next_child_y = header:Height()
    for i = 1, #effects do
      local icon_def
      if name == "recruitment" then
        icon_def = {
          "{icon:2}" .. icon_prefix .. effects[i][icon_field] .. icon_postfix
        }
      else
        icon_def = {
          "{icon:1}" .. icon_prefix .. effects[i][icon_field] .. icon_postfix
        }
      end
      local c = UIComponent(Component.CreateFromComponent(row_templates[name], name .. "_" .. i, list_boxes[name]:Address(), 0, next_child_y, icon_def, {
        text = effects[i][text_field]
      }))
      if name == "recruitment" then
        local red_frame = false
        if effects[i].TechnologyRequirements ~= nil then
          for j = 1, #effects[i].TechnologyRequirements do
            if effects[i].TechnologyRequirements[j].Status ~= utilities.TECHNOLOGY_STATUS_RESEARCHED then
              red_frame = true
              break
            end
          end
        end
        if effects[i].BuildingRequirements ~= nil and not red_frame then
          for j = 1, #effects[i].BuildingRequirements do
            if effects[i].BuildingRequirements[j].Constructed == false then
              red_frame = true
              break
            end
          end
        end
        UIComponent(c:Find("frame_red")):SetVisible(red_frame)
        UIComponent(c:Find("Experience")):SetState(effects[i].Experience)
      end
      if name == "require" and effects[i].Status == utilities.TECHNOLOGY_STATUS_RESEARCHED then
        UIComponent(c:Find("icon")):SetImageColour(0, 255, 255, 255, 255)
      end
      next_child_y = next_child_y + c:Height()
      UpdateLongestTextEnd(UIComponent(c:Find("text")))
    end
    list_boxes[name]:Resize(300, next_child_y, false)
  else
    list_boxes[name]:Resize(300, 0, false)
  end
end

function Resize(bottom_component)
  local this_x, this_y = this:Position()
  local new_width = longest_text_end + margin - this_x
  local bottom_x, bottom_y = bottom_component:Position()
  local new_height = bottom_y + bottom_component:Height() + margin - this_y
  if new_width ~= this:Width() or new_height ~= this:Height() then
    this:Resize(new_width, new_height, false)
    level_component:MoveTo(this_x + this:Width() - margin - level_component:Width(), this_y + margin)
    turns_component:MoveTo(this_x + this:Width() - margin - turns_component:Width(), this_y + margin)
    longest_text_end = longest_text_end - this_x
    utilities.PositionTooltip(Address)
    this_x, this_y = this:Position()
    longest_text_end = longest_text_end + this_x
  end
end

function OnUpdatePulse(time)
  if creation_time == nil then
    creation_time = time
  elseif not expanded and time - creation_time >= expand_time then
    Expand()
  end
  local this_x, this_y = this:Position()
  longest_text_end = longest_text_end - this_x
  utilities.PositionTooltip(Address)
  this_x, this_y = this:Position()
  longest_text_end = longest_text_end + this_x
end

function OnDestroyed()
  if header_template ~= nil then
    Component.Destroy(header_template, true)
    for i = 1, #categories do
      Component.Destroy(list_boxes[categories[i]]:Address(), true)
      Component.Destroy(row_templates[categories[i]], true)
    end
    header_template = nil
    list_boxes = nil
    row_templates = nil
  end
end
