local utilities = require("Utilities")
local this = UIComponent(Address)
local creation_time
local expanded = false
local g_effects
local functionality_text = UIComponent(this:Find("txt_functionality"))
local functionality_text2 = UIComponent(this:Find("txt_functionality2"))
local upgrade_pips = UIComponent(this:Find("upgrade_pips"))
local effects_list_box, effect_template
local techs_header = UIComponent(this:Find("tx_header_tech"))
local techs_list_box, tech_template, techs_list_box_offset
local recruitments_header = UIComponent(this:Find("tx_header_recruitment"))
local recruitments_list_box, recruitment_template, recruitments_list_box_offset, bottom_margin
local g_max_level_display = 7
local expand_time = 1000

function Initialise(details, effects, constructable)
  creation_time = nil
  expanded = false
  g_effects = effects
  local this_x, this_y = this:Position()
  if effect_template == nil then
    effect_template = this:Find("row_effect")
    effects_list_box = UIComponent(effect_template):Parent()
    UIComponent(effects_list_box):Divorce(effect_template)
  end
  if tech_template == nil then
    tech_template = this:Find("row_tech")
    techs_list_box = UIComponent(tech_template):Parent()
    UIComponent(techs_list_box):Divorce(tech_template)
    local techs_list_box_x, techs_list_box_y = UIComponent(techs_list_box):Position()
    local techs_header_x, techs_header_y = techs_header:Position()
    techs_list_box_offset = techs_list_box_y - techs_header_y
  end
  if recruitment_template == nil then
    recruitment_template = this:Find("row_recruitment")
    recruitments_list_box = UIComponent(recruitment_template):Parent()
    UIComponent(recruitments_list_box):Divorce(recruitment_template)
    local recruitments_list_box_x, recruitments_list_box_y = UIComponent(recruitments_list_box):Position()
    local recruitments_header_x, recruitments_header_y = recruitments_header:Position()
    recruitments_list_box_offset = recruitments_list_box_y - recruitments_header_y
    bottom_margin = this_y + this:Height() - recruitments_list_box_y - UIComponent(recruitments_list_box):Height()
  end
  UIComponent(this:Find("dy_building_name")):SetStateText(details.Name)
  for i = 1, g_max_level_display do
    UIComponent(this:Find("Level Pip " .. i)):SetVisible(false)
  end
  for i = 1, details.MaxLevel + 1 do
    local pip = UIComponent(this:Find("Level Pip " .. i))
    pip:SetState("empty")
    pip:SetVisible(true)
  end
  for i = 1, details.Level + 1 do
    UIComponent(this:Find("Level Pip " .. i)):SetState("filled")
  end
  functionality_text:SetVisible(true)
  if constructable then
    functionality_text:SetState("functions_upgrade")
  else
    functionality_text:SetState("functions_owned")
  end
  functionality_text2:SetVisible(false)
  functionality_text2:SetStateText(details.ShortDescription)
  UIComponent(effects_list_box):SetVisible(false)
  techs_header:SetVisible(false)
  UIComponent(techs_list_box):SetVisible(false)
  recruitments_header:SetVisible(false)
  UIComponent(recruitments_list_box):SetVisible(false)
  local x, y = functionality_text:Position()
  local h = functionality_text:Height()
  this:Resize(this:Width(), y - this_y + h + bottom_margin, false)
  utilities.PositionTooltip(Address)
end

function Expand(effects)
  expanded = true
  local x, y = UIComponent(effects_list_box):Position()
  local longest_text = GetTextEndPosition(this, "txt_functionality")
  functionality_text:SetVisible(false)
  functionality_text2:SetVisible(true)
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
    UIComponent(effects_list_box):MoveTo(x, y)
    UIComponent(effects_list_box):SetVisible(true)
    y = y + next_child_y
  else
    UIComponent(effects_list_box):SetVisible(false)
  end
  if 0 < #effects.technology then
    UIComponent(techs_list_box):DestroyChildren()
    local next_child_y = 0
    for i = 1, #effects.technology do
      local c = UIComponent(Component.CreateFromComponent(tech_template, "general_tech_" .. i, techs_list_box, 0, next_child_y, {
        "{icon:1}" .. effects.technology[i].IconFilename
      }, {
        tx_tech = effects.technology[i].Name
      }))
      next_child_y = next_child_y + c:Height()
      longest_text = utilities.Max(longest_text, GetTextEndPosition(c, "tx_tech"))
    end
    techs_header:MoveTo(x, y)
    techs_header:SetVisible(true)
    UIComponent(techs_list_box):MoveTo(x, y + techs_list_box_offset)
    UIComponent(techs_list_box):SetVisible(true)
    y = y + techs_list_box_offset + next_child_y
  else
    techs_header:SetVisible(false)
    UIComponent(techs_list_box):SetVisible(false)
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
      local c = UIComponent(Component.CreateFromComponent(recruitment_template, "general_recruitment_" .. i, recruitments_list_box, 0, next_child_y, {
        "{icon:1}" .. effects.recruitment[i].Icon .. ".tga"
      }, {
        tx_tech = effects.recruitment[i].Name
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
  local this_x, this_y = this:Position()
  local new_width = longest_text - this_x + 10
  if new_width > this:Width() then
    local upgrade_pips_x, upgrade_pips_y = upgrade_pips:Position()
    local upgrade_pips_offset = this_x + this:Width() - upgrade_pips_x
    upgrade_pips:MoveTo(this_x + new_width - upgrade_pips_offset, upgrade_pips_y)
    functionality_text2_x, functionality_text2_y = functionality_text2:Position()
    functionality_text2:Resize(new_width - functionality_text2_x + this_x - 10, functionality_text2:Height())
  else
    new_width = this:Width()
  end
  local details, text_width, text_height = functionality_text2:GetStateText()
  local offset = text_height - functionality_text2:Height() + 16
  functionality_text2:Resize(text_width, text_height + 16)
  if UIComponent(effects_list_box):Visible() then
    local lx, ly = UIComponent(effects_list_box):Position()
    UIComponent(effects_list_box):MoveTo(lx, ly + offset)
  end
  if UIComponent(techs_list_box):Visible() then
    local lx, ly = techs_header:Position()
    techs_header:MoveTo(lx, ly + offset)
    lx, ly = UIComponent(techs_list_box):Position()
    UIComponent(techs_list_box):MoveTo(lx, ly + offset)
  end
  if UIComponent(recruitments_list_box):Visible() then
    local lx, ly = recruitments_header:Position()
    recruitments_header:MoveTo(lx, ly + offset)
    lx, ly = UIComponent(recruitments_list_box):Position()
    UIComponent(recruitments_list_box):MoveTo(lx, ly + offset)
  end
  local new_height = y + offset - this_y + bottom_margin
  this:Resize(new_width, new_height, false)
  utilities.PositionTooltip(Address)
end

function GetTextEndPosition(parent_component, component_name)
  local text_component = UIComponent(parent_component:Find(component_name))
  local details, text_width = text_component:GetStateText()
  local text_x, text_y = text_component:Position()
  return text_x + text_width
end

function OnUpdatePulse(time)
  if creation_time == nil then
    creation_time = time
  elseif not expanded and time - creation_time >= expand_time then
    Expand(g_effects)
  end
end

function OnDestroyed()
  Component.Destroy(effect_template, true)
  Component.Destroy(tech_template, true)
  Component.Destroy(recruitment_template, true)
end
