local utils = require("Utilities")
local this = UIComponent(Address)
local g_tech_parent = UIComponent(this:Parent("technology"))
local g_Key
this:SetTooltipText(CampaignUI.LocalisationString("technology_status_being_researched"))
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function SetActiveTechnology(technology)
  this:SetState("researching")
  image = UIImage(technology.IconFilename)
  image:SetComponentTexture(Address, 0)
  g_Key = technology.Key
end

function OnMouseRClickUp()
end

function ShowInfo()
  ShaneOutput("University tech icon right clicked")
  g_tech_parent:LuaCall("TechRightClicked", g_Key)
end

function CloseInfo()
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", ShowInfo)
this:SetEventCallback("OnMouseOff", CloseInfo)
