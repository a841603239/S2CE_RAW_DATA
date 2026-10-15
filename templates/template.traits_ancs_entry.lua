local this = UIComponent(Address)
local utils = require("utilities")
local m_zoom_func

function Initialise(details, type_a_bg, zoom_func)
  m_zoom_func = zoom_func
  m_position = {
    X = details.PosX,
    Y = details.PosY
  }
  if type_a_bg then
    this:SetState("A_normal")
  else
    this:SetState("B_normal")
  end
  local card = UIComponent(this:Find("CampaignCharacterCard"))
  local w, h = card:Dimensions()
  local x, y = utils.OffsetFrom(this, card)
  card:SetInteractive(false)
  if details.EntityType == "unit" then
    image = UIImage(details.Entity.IconSquare)
    image:SetComponentTexture(card:Address(), 0)
  elseif details.EntityType == "character" then
    image = UIImage(details.Entity.CardImage)
    image:SetComponentTexture(card:Address(), 0)
  else
    Component.Destroy(card:Address())
    card = nil
  end
  if card ~= nil then
    card:SetMoveable(false)
    card:SetInteractive(false)
    card:Resize(w, h)
  end
  x, y = this:Position()
  UIComponent(this:Find("dy_name")):SetStateText(details.SubTitle)
  UIComponent(this:Find("trait_name_dy")):SetStateText(details.Name)
  UIComponent(this:Find("trait_effect_dy")):SetStateText(details.Effect)
  UIComponent(this:Find("trait_effect_dy")):Resize(190, 68)
  local tt = details.Text
  tt = string.gsub(tt, [[


]], "||")
  this:SetTooltipText(tt, true)
  this:SetEventCallback("OnMouseLDblClick", OnLeftDblClick)
end

function OnLeftDblClick()
  if m_zoom_func ~= nil then
    m_zoom_func(m_position)
  end
end

function OnLeftClickUp()
end

function OnRightClickUp()
end
