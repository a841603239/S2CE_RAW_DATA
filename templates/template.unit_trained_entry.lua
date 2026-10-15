local this = UIComponent(Address)
local utils = require("utilities")
local m_unit, m_unit_ptr, m_zoom_func

function Initialise(details, type_a_bg, zoom_func)
  m_unit = details.Unit
  m_unit_ptr = details.UnitPtr
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
  local card = UIComponent(this:Find("card_placeholder"))
  local w, h = card:Dimensions()
  local x, y = utils.OffsetFrom(this, card)
  image = UIImage(details.Unit.IconSquare)
  image:SetComponentTexture(this:Find("card_placeholder"), 0)
  local name_field = UIComponent(this:Find("dy_name"))
  name_field:SetStateText(details.Unit.Name)
  UIComponent(this:Find("DY_location")):SetStateText(details.Location)
  if details.OrderedBy ~= nil and 0 < #details.OrderedBy then
    UIComponent(this:Find("DY_ordered_by")):SetStateText(details.OrderedBy .. " - " .. details.OrderedByLocation)
  else
    UIComponent(this:Find("TX_ordered_by")):SetVisible(false)
  end
  this:SetEventCallback("OnMouseLDblClick", OnLeftDblClick)
  this:SetTooltipText(CampaignUI.LocalisationString("lists_tooltip"), true)
end

function InitialiseFromRecord(details, unit, type_a_bg, zoom_func)
  m_unit = nil
  m_unit_ptr = nil
  m_zoom_func = zoom_func
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
  if type_a_bg then
    this:SetState("A_normal")
  else
    this:SetState("B_normal")
  end
  image = UIImage(unit.IconSquare)
  image:SetComponentTexture(this:Find("card_placeholder"), 0)
  local name_field = UIComponent(this:Find("dy_name"))
  name_field:SetStateText(unit.Name)
  UIComponent(this:Find("DY_location")):SetStateText(details.Data.Location)
  UIComponent(this:Find("TX_ordered_by")):SetVisible(false)
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
  UIComponent(Component.Root()):LuaCall("ShowFullUnitInfo", m_unit_ptr)
end

function ShowInfoPanel()
end

function CloseInfoPanel()
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", ShowInfoPanel)
this:SetEventCallback("OnMouseOff", CloseInfoPanel)
