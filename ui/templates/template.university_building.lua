local this = UIComponent(Address)
local tech_parent = UIComponent(this:Parent("technology"))
local g_university
local g_localised_tooltip = CampaignUI.LocalisationString("technology_entity_tooltip")
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(university)
  g_university = university
  this:SetTooltipText(university.Name .. ", " .. university.SlotName .. "||" .. g_localised_tooltip, true)
end

function OnMouseLClickUp()
  ShaneOutput("Mouse left click up on university building")
  tech_parent:LuaCall("OnEntityLClickUp", g_university)
end

function OnMouseRClickUp()
  ShaneOutput("Mouse right click up on university building")
  tech_parent:LuaCall("OnEntityRClickUp", g_university)
end
