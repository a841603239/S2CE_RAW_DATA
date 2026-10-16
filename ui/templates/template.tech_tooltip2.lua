local utilities = require("Utilities")
local this = UIComponent(Address)
local creation_time
local expanded = false
local g_details
local turns_component = UIComponent(this:Find("Turns"))
local turns_offset
local requires_header = UIComponent(this:Find("txt_requires"))
local requires_list_box, require_template, requires_list_box_offset
local effects_header = UIComponent(this:Find("tx_header_effects"))
local effects_list_box, effect_template, effects_list_box_offset
local recruitments_header = UIComponent(this:Find("tx_header_recruitment"))
local recruitments_list_box, recruitment_template, recruitments_list_box_offset
local constructions_header = UIComponent(this:Find("tx_header_construction"))
local constructions_list_box, construction_template, constructions_list_box_offset, bottom_margin, longest_text
local expand_time = 1000

function Initialise(details)
  creation_time = nil
  expanded = false
  g_details = details
  longest_text = GetTextEndPosition(this, "txt_function") + turns_component:Width()
  local this_x, this_y = this:Position()
  if require_template == nil then
    require_template = this:Find("template_row")
    requires_list_box = UIComponent(require_template):Parent()
    UIComponent(requires_list_box):Divorce(require_template)
    local requires_list_box_x, requires_list_box_y = UIComponent(requires_list_box):Position()
    local requires_header_x, requires_header_y = requires_header:Position()
    requires_list_box_offset = requires_list_box_y - requires_header_y
  end
  if effect_template == nil then
    effect_template = this:Find("template_row")
    effects_list_box = UIComponent(effect_template):Parent()
    UIComponent(effects_list_box):Divorce(effect_template)
    local effects_list_box_x, effects_list_box_y = UIComponent(effects_list_box):Position()
    local effects_header_x, effects_header_y = effects_header:Position()
    effects_list_box_offset = effects_list_box_y - effects_header_y
  end
  if recruitment_template == nil then
    recruitment_template = this:Find("template_row")
    recruitments_list_box = UIComponent(recruitment_template):Parent()
    UIComponent(recruitments_list_box):Divorce(recruitment_template)
    local recruitments_list_box_x, recruitments_list_box_y = UIComponent(recruitments_list_box):Position()
    local recruitments_header_x, recruitments_header_y = recruitments_header:Position()
    recruitments_list_box_offset = recruitments_list_box_y - recruitments_header_y
  end
  if construction_template == nil then
    construction_template = this:Find("template_row")
    constructions_list_box = UIComponent(construction_template):Parent()
    UIComponent(constructions_list_box):Divorce(construction_template)
    local constructions_list_box_x, constructions_list_box_y = UIComponent(constructions_list_box):Position()
    local constructions_header_x, constructions_header_y = constructions_header:Position()
    constructions_list_box_offset = constructions_list_box_y - constructions_header_y
    bottom_margin = this_y + this:Height() - constructions_list_box_y - UIComponent(constructions_list_box):Height()
  end
  UIComponent(this:Find("dy_Name")):SetStateText(details.Name)
  local turns_x, turns_y = turns_component:Position()
  turns_offset = this_x + this:Width() - turns_x
  local x, y
  if #details.dependancies > 0 then
    UIComponent(requires_list_box):DestroyChildren()
    local next_child_y = 0
    for i = 1, #details.dependancies do
      local c = UIComponent(Component.CreateFromComponent(require_template, "require_" .. i, requires_list_box, 0, next_child_y, {
        "{tech_icon1:1}" .. details.dependancies[i].IconFilename
      }, {
        req_item = details.dependancies[i].Name
      }))
      next_child_y = next_child_y + c:Height()
      longest_text = utilities.Max(longest_text, GetTextEndPosition(c, "req_item"))
    end
    requires_header:SetVisible(true)
    UIComponent(requires_list_box):SetVisible(true)
    x, y = UIComponent(requires_list_box):Position()
    y = y + next_child_y
  else
    requires_header:SetVisible(false)
    UIComponent(requires_list_box):SetVisible(false)
    local functionality_text = UIComponent(this:Find("txt_function"))
    x, y = functionality_text:Position()
    y = y + functionality_text:Height()
  end
  effects_header:SetVisible(false)
  UIComponent(effects_list_box):SetVisible(false)
  recruitments_header:SetVisible(false)
  UIComponent(recruitments_list_box):SetVisible(false)
  constructions_header:SetVisible(false)
  UIComponent(constructions_list_box):SetVisible(false)
  local new_width = longest_text - this_x + 10
  turns_component:MoveTo(this_x + new_width - turns_offset, turns_y)
  this:Resize(new_width, y - this_y + bottom_margin, false)
  utilities.PositionTooltip(Address)
  longest_text = longest_text - this_x
end

function Expand(details)
  expanded = true
  local x, y
  if requires_header:Visible() then
    x, y = UIComponent(requires_list_box):Position()
    y = y + UIComponent(requires_list_box):Height()
  else
    x, y = requires_header:Position()
  end
  local this_x, this_y = this:Position()
  longest_text = this_x + longest_text
  local effects = CampaignUI.TechEffects(details.Key, details.region_key, CampaignUI.PlayersFactionKey(), details.slot_key)
  local genericEffects2Display = {}
  for i = 1, #effects.generic do
    if effects.generic[i].Priority > 0 then
      table.insert(genericEffects2Display, effects.generic[i])
    end
  end
  for i = 1, #genericEffects2Display - 1 do
    for j = i + 1, #genericEffects2Display do
      if genericEffects2Display[i].Priority < genericEffects2Display[j].Priority then
        local swap = genericEffects2Display[i]
        genericEffects2Display[i] = genericEffects2Display[j]
        genericEffects2Display[j] = swap
      end
    end
  end
  if 0 < #genericEffects2Display then
    UIComponent(effects_list_box):DestroyChildren()
    local next_child_y = 0
    for i = 1, #genericEffects2Display do
      local c = UIComponent(Component.CreateFromComponent(effect_template, "general_effect_" .. i, effects_list_box, 0, next_child_y, {
        "{icon:1}" .. genericEffects2Display[i].IconFilename
      }, {
        tx_effect = genericEffects2Display[i].Description
      }))
      next_child_y = next_child_y + c:Height()
      longest_text = utilities.Max(longest_text, GetTextEndPosition(c, "tx_effect"))
    end
    effects_header:MoveTo(x, y)
    effects_header:SetVisible(true)
    UIComponent(effects_list_box):MoveTo(x, y + effects_list_box_offset)
    UIComponent(effects_list_box):SetVisible(true)
    y = y + effects_list_box_offset + next_child_y
  else
    effects_header:SetVisible(false)
    UIComponent(effects_list_box):SetVisible(false)
  end
  if 0 < #effects.recruitment then
    UIComponent(recruitments_list_box):DestroyChildren()
    local next_child_y = 0
    for i = 1, #effects.recruitment do
      local colour
      if effects.recruitment[i].IsNaval then
        colour = effects.FactionColour
      else
        colour = effects.UniformColour
      end
      local c = UIComponent(Component.CreateFromComponent(recruitment_template, "recruitment_" .. i, recruitments_list_box, 0, next_child_y, {
        "{icon:1}" .. effects.recruitment[i].Icon .. ".tga"
      }))
      next_child_y = next_child_y + c:Height()
      longest_text = utilities.Max(longest_text, GetTextEndPosition(c, "tx_tech"))
    end
    recruitments_header:MoveTo(x, y)
    recruitments_header:SetVisible(true)
    UIComponent(recruitments_list_box):MoveTo(x, y + recruitments_list_box_offset)
    UIComponent(recruitments_list_box):SetVisible(true)
    y = y + recruitments_list_box_offset + next_child_y
  else
    recruitments_header:SetVisible(false)
    UIComponent(recruitments_list_box):SetVisible(false)
  end
  if 0 < #effects.construction then
    UIComponent(constructions_list_box):DestroyChildren()
    local next_child_y = 0
    for i = 1, #effects.construction do
      local c = UIComponent(Component.CreateFromComponent(construction_template, "construction_" .. i, constructions_list_box, 0, next_child_y, {
        "{icon:1}" .. effects.construction[i].IconFilename
      }, {
        tx_building = effects.construction[i].Name
      }))
      next_child_y = next_child_y + c:Height()
      longest_text = utilities.Max(longest_text, GetTextEndPosition(c, "tx_building"))
    end
    constructions_header:MoveTo(x, y)
    constructions_header:SetVisible(true)
    UIComponent(constructions_list_box):MoveTo(x, y + constructions_list_box_offset)
    UIComponent(constructions_list_box):SetVisible(true)
    y = y + constructions_list_box_offset + next_child_y
  else
    constructions_header:SetVisible(false)
    UIComponent(constructions_list_box):SetVisible(false)
  end
  if effects_header:Visible() or recruitments_header:Visible() or constructions_header:Visible() then
    local new_width = longest_text - this_x + 15
    local turns_x, turns_y = turns_component:Position()
    turns_component:MoveTo(this_x + new_width - turns_offset, turns_y)
    this:Resize(new_width, y - this_y + bottom_margin, false)
    utilities.PositionTooltip(Address)
  end
end

function GetTextEndPosition(parent_component, component_name)
  local text_component = UIComponent(parent_component:Find(component_name))
  local details, text_width = text_component:GetStateText()
  local text_x, text_y = text_component:Position()
  return text_x + text_width
end

function UpdateTurns(turns_state, turns)
  turns_component:SetState(turns_state)
  if turns == nil then
    turns = ""
  end
  turns_component:SetStateText(turns)
end

function OnUpdatePulse(time)
  if creation_time == nil then
    creation_time = time
  elseif not expanded and time - creation_time >= expand_time then
    Expand(g_details)
  end
end

function OnDestroyed()
  Component.Destroy(require_template, true)
  Component.Destroy(effect_template, true)
  Component.Destroy(recruitment_template, true)
  Component.Destroy(construction_template, true)
end
