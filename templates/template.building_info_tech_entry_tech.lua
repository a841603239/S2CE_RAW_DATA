local utils = require("Utilities")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local tech_key, region_key, faction_key, slot_key
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(tech, region, faction, slot)
  tech_key = tech
  region_key = region
  faction_key = faction
  slot_key = slot
  ShaneOutput("ShowTechInfo Initialise:")
  ShaneOutput("tech_key = " .. tostring(tech_key))
  ShaneOutput("region_key = " .. tostring(region_key))
  ShaneOutput("faction_key = " .. tostring(faction_key))
  ShaneOutput("slot_key = " .. tostring(slot_key))
end

function OnMouseRClickUp()
  root:LuaCall("ShowFullTechInfo", tech_key, region_key, faction_key, slot_key)
end

function ShowInfoPanel()
  ShaneOutput("ShowTechInfo RightClickUp:")
  ShaneOutput("tech_key = " .. tostring(tech_key))
  ShaneOutput("region_key = " .. tostring(region_key))
  ShaneOutput("faction_key = " .. tostring(faction_key))
  ShaneOutput("slot_key = " .. tostring(slot_key))
  root:LuaCall("ShowTechInfo", tech_key, region_key, faction_key, slot_key)
end

function CloseInfoPanel()
  root:LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", ShowInfoPanel)
this:SetEventCallback("OnMouseOff", CloseInfoPanel)
