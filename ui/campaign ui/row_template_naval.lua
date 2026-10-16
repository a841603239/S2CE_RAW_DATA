local utils = require("Utilities")
local this = UIComponent(Address)
local m_character, m_character_interface
sort_columns = {}

function LessThan(c, column)
  local rhs_value = UIComponent(c):GlobalExists("sort_columns")[column + 1]
  return column ~= 0 and sort_columns[column + 1] == rhs_value and sort_columns[1] < UIComponent(c):GlobalExists("sort_columns")[1] or rhs_value > sort_columns[column + 1]
end

function Character()
  return m_character
end

function OnDestroyed()
  if m_character_interface ~= nil then
    m_character_interface:Release()
    m_character_interface = nil
  end
end

function Initialise(char, skill, loyalty, name, soldiers, ap, apt)
  this:SetEventCallback("OnDestroyed", OnDestroyed)
  m_character = char
  local mp = tonumber(apt) > 0 and tonumber(ap) / tonumber(apt) or 0
  sort_columns = {
    tonumber(skill),
    tonumber(loyalty),
    name,
    tonumber(soldiers),
    mp
  }
  local name_comp = UIComponent(this:Find("name"))
  name_comp:SetStateText(name)
  if this:Find("ap", false) then
    SetMovePoints(mp)
  end
  local skill_comp = UIComponent(this:Find("skill_level"))
  skill_comp:SetState(tostring(skill))
  local loyalty_comp = UIComponent(this:Find("loyalty_level"))
  loyalty_comp:SetState(tostring(loyalty))
  if this:Find("ships", false) then
    local ships_comp = UIComponent(this:Find("ships"))
    ships_comp:SetStateText(soldiers)
  end
end

function OnRClickUp()
end

function ShowInfoPanel()
  if m_unit == nil then
  end
end

function SetMovePoints(mp_ratio)
  local mp_bar = UIComponent(this:Find("ap"))
  local mp = UIComponent(this:Find("ap_bar"))
  local new_height = (mp:Height() - 2) * mp_ratio
  if 1 <= new_height then
    mp_bar:SetVisible(true)
    mp_bar:Resize(mp:Width() - 1, new_height, false)
  else
    mp_bar:SetVisible(false)
  end
  local mx, my = mp:Position()
  mp_bar:MoveTo(mx + 1, my + (mp:Height() - mp_bar:Height()))
end

function SetLocation(location)
  local region = UIComponent(this:Find("region_dy"))
  if location == nil then
    region:SetStateText("")
  else
    region:SetStateText(location)
  end
end

function OnSelect()
  this:InterfaceFunction("SelectItem")
end

function Select(temp)
end

function CloseInfo()
  Component.CallByAddress(Component.Root(), "LuaCall", "InfoPanelNotUsed")
end

this:SetEventCallback("OnMouseOn", ShowInfoPanel)
this:SetEventCallback("OnMouseOff", CloseInfo)
