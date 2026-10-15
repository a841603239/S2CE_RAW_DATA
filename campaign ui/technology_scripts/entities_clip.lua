local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local g_entities = {}
local g_max_visible_entities = 4
local g_entity_width = 0
local g_selected_entity
local g_card_scroll = 0
local g_scroll_start_time
local g_scroll_time = 0.5
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

function Initialise(entities, selected_entity, template_name)
  ShaneOutput("Initialising entities_clip with " .. #entities .. " entities")
  this:DestroyChildren()
  g_card_scroll = 0
  g_entities = entities
  g_selected_entity = nil
  if 0 < #g_entities then
    for i = 1, #entities do
      local entity = entities[i]
      entity.Component = {}
      entity.Component = UIComponent(Component.CreateComponentFromTemplate(template_name, "entity" .. i, Address, 0, 0))
      entity.Component:LuaCall("Initialise", entity)
      g_entity_width = entity.Component:Width()
      local x, y = Position(i - 1, entity.Component, #entities)
      entity.TargetPosition = {}
      entity.TargetPosition.x = x
      entity.TargetPosition.y = y
      entity.Component:MoveTo(x, y)
    end
    if SelectEntity(selected_entity) == false then
      for i = 1, #g_entities do
        if entities[i] ~= selected_entity and SelectEntity(entities[i]) == true then
          break
        end
      end
    end
  end
  return #g_entities * g_entity_width > this:Width()
end

function ScrollCardsLeft()
  ShaneOutput("Scrolling entity cards left")
  if g_card_scroll > g_max_visible_entities - #g_entities then
    g_card_scroll = g_card_scroll - 1
    UpdateTargetPositions()
  end
end

function ScrollCardsRight()
  ShaneOutput("Scrolling entity cards right")
  if g_card_scroll < 0 then
    g_card_scroll = g_card_scroll + 1
    UpdateTargetPositions()
  end
end

function UpdateTargetPositions()
  g_scroll_start_time = CampaignUI.Time()
  for i = 1, #g_entities do
    local x, y = Position(i - 1, g_entities[i].Component)
    g_entities[i].TargetPosition = {}
    g_entities[i].TargetPosition.x = x
    g_entities[i].TargetPosition.y = y
  end
end

function Position(index, card)
  local pane_width = this:Width()
  local pane_height = this:Height()
  local x, y = this:Position()
  y = y + (pane_height - card:Height()) / 2
  local cards_width = g_entity_width * #g_entities
  if pane_width >= cards_width then
    x = x + index * g_entity_width + (pane_width - cards_width) / 2
  else
    x = x + (index + g_card_scroll) * g_entity_width
  end
  return x, y
end

function SelectEntity(entity)
  local selectable = entity.Component:LuaCall("Selectable")
  if selectable == true then
    assert(entity ~= nil)
    ShaneOutput("SelectEntity called with " .. tostring(entity))
    for i = 1, #g_entities do
      if g_entities[i] ~= entity then
        ShaneOutput("Deselecting entity at index " .. i)
        g_entities[i].Component:LuaCall("SetSelected", false)
      else
        ShaneOutput("Selecting entity at index " .. i)
      end
    end
    g_selected_entity = entity
    g_selected_entity.Component:LuaCall("SetSelected", true)
  end
  return selectable
end

function ActiveEntities()
  local active = {}
  for i = 1, #g_entities do
    if g_entities[i].Activity ~= nil then
      active[#active + 1] = g_entities[i]
    end
  end
  return active
end
