local utils = require("Utilities")
local core = require("CoreUtils")
local CampaignUI, Localisation
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local stealing = core.NamespaceFile("technology_stealing")
local researching = core.NamespaceFile("technology_researching")
local techmode
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

function ZoomToEntity()
  techmode.ZoomToEntity()
end

function ResearchingMode()
  return techmode == researching
end

function Refresh(residence, character)
  ShaneOutput("* technology.lua - Refresh: residence = " .. tostring(residence) .. ", character = " .. tostring(character))
  if techmode == stealing then
    local details = CampaignUI.TechnologyStealingDetails(character, residence)
    if details ~= nil then
      Initialise(details, CampaignUI, Localisation, true)
    else
      panel_manager.ClosePanel("technology")
    end
  else
    local details = CampaignUI.TechnologyResearchingDetails(character, residence)
    if details ~= nil then
      Initialise(details, CampaignUI, Localisation, false)
    else
      panel_manager.ClosePanel("technology")
    end
  end
end

function Reinitialise(details, steal)
  ShaneOutput("* Reinitialising technology *")
  Initialise(details, CampaignUI, Localisation, steal)
end

function Initialise(details, ui_interface, localisation_interface, steal)
  ShaneOutput("* Initialising technology *")
  CampaignUI = ui_interface
  Localisation = localisation_interface
  if steal == true then
    techmode = stealing
  else
    techmode = researching
  end
  techmode.Initialise(details, Address, Component.Root(), CampaignUI, Localisation)
end

function OnEntityLClickUp(entity)
  techmode.SelectEntity(entity)
end

function OnEntityRClickUp(entity)
  techmode.ShowEntityDetails(entity)
end

function TechLeftClicked(key)
  techmode.TechLeftClicked(key)
end

function TechRightClicked(key)
  techmode.TechRightClicked(key)
end

function TurnsToResearchOrChanceToSteal(tech_key)
  return techmode.TurnsToResearchOrChanceToSteal(tech_key)
end

function SelectedEntityProgessingTech(tech_key)
  return techmode.SelectedEntityProgessingTech(Key)
end

function SelectedEntityIncapacitated()
  return techmode.SelectedEntityIncapacitated()
end

function HasFacilities()
  return techmode.HasFacilities()
end

function CreateTechEntry(item_name, tech_box, image_list)
  return Component.CreateFromLayout("data/ui/campaign ui/tech_entry", item_name, tech_box, 0, 0, image_list)
end

function SelectTab(address)
  ShaneOutput("SelectTab called with " .. tostring(address))
  techmode.SelectTab(address)
end

function TechAvailable(tech_entry)
  return techmode.TechAvailable(tech_entry)
end

function TechCompleted(tech_entry)
  return techmode.TechCompleted(tech_entry)
end

function TechInProgress(tech_entry)
  return techmode.TechInProgress(tech_entry)
end

function TechProgressStalled(tech_entry)
  return techmode.TechProgressStalled(tech_entry)
end

function OnExit()
  this:InterfaceFunction("OnExit")
end
