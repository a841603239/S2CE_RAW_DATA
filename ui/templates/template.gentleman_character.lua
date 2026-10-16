local this = UIComponent(Address)
local tech_parent = UIComponent(this:Parent("technology"))
local g_gentleman
local g_localised_tooltip = CampaignUI.LocalisationString("technology_entity_tooltip")
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(gentleman)
  g_gentleman = gentleman
  this:SetTooltipText(gentleman.Name .. ", " .. gentleman.SlotName .. "||" .. g_localised_tooltip, true)
end

function OnMouseLClickUp()
  ShaneOutput("Mouse left click up on gentleman character")
  tech_parent:LuaCall("OnEntityLClickUp", g_gentleman)
end

function OnMouseRClickUp()
  ShaneOutput("Mouse right click up on gentleman character")
  tech_parent:LuaCall("OnEntityRClickUp", g_gentleman)
end
