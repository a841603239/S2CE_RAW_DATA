local utils = require("Utilities")
local this = UIComponent(Address)
local g_left_arrow = UIComponent(this:Find("arrow_L"))
local g_right_arrow = UIComponent(this:Find("arrow_R"))
local g_entities_clip = UIComponent(this:Find("entities_clip"))
local g_display_area_width = g_entities_clip:Width()
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
  ShaneOutput("Initialising entities_pane with " .. #entities .. " entities")
  SetArrowsVisibility(g_entities_clip:LuaCall("Initialise", entities, selected_entity, template_name))
end

function SetArrowsVisibility(visible)
  g_left_arrow:SetVisible(visible)
  g_right_arrow:SetVisible(visible)
end

function EntitiesForward()
  g_entities_clip:LuaCall("ScrollCardsLeft")
end

function EntitiesBack()
  g_entities_clip:LuaCall("ScrollCardsRight")
end
