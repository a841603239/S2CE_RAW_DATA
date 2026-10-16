local this = UIComponent(Address)
local utils = require("utilities")
local m_pos_x, m_pos_y
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(details, type_a_bg)
  ShaneOutput("** attrition_entry:Initialise **")
  if type_a_bg then
    this:SetState("A_normal")
  else
    this:SetState("B_normal")
  end
  UIComponent(this:Find("dy_name")):SetStateText(details.CharacterName)
  if details.MenLost ~= nil then
    UIComponent(this:Find("men_lost_dy")):SetStateText(CampaignUI.LocalisationString("player_stats_men_lost") .. ": " .. details.MenLost)
  elseif details.Region ~= nil then
    UIComponent(this:Find("men_lost_dy")):SetStateText(details.Region)
  else
    UIComponent(this:Find("men_lost_dy")):SetVisible(false)
  end
  m_pos_x = details.PosX
  m_pos_y = details.PosY
  if details.PortraitPath ~= nil and #details.PortraitPath > 0 then
    image = UIImage(details.PortraitPath)
    image:SetComponentTexture(this:Find("image"), 0)
    UIComponent(this:Find("portrait_clip")):SetVisible(true)
    UIComponent(this:Find("unit_frame")):SetVisible(true)
    UIComponent(this:Find("icon_raiding")):SetVisible(false)
    UIComponent(this:Find("building_window")):SetVisible(false)
  elseif details.BuildingImage ~= nil and 0 < #details.BuildingImage then
    image = UIImage(details.BuildingImage)
    image:SetComponentTexture(this:Find("building_window"), 0)
    UIComponent(this:Find("portrait_clip")):SetVisible(false)
    UIComponent(this:Find("unit_frame")):SetVisible(false)
    UIComponent(this:Find("icon_raiding")):SetVisible(false)
    UIComponent(this:Find("building_window")):SetVisible(true)
  else
    UIComponent(this:Find("portrait_clip")):SetVisible(false)
    UIComponent(this:Find("unit_frame")):SetVisible(false)
    UIComponent(this:Find("icon_raiding")):SetVisible(true)
    UIComponent(this:Find("building_window")):SetVisible(false)
  end
end

function OnLeftClickUp()
  CampaignUI.SetCameraTarget(m_pos_x, m_pos_y)
end

function OnRightClickUp()
  CampaignUI.SetCameraTarget(m_pos_x, m_pos_y)
end
