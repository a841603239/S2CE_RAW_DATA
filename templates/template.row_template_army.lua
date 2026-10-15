local utils = require("Utilities")
local m_unit, m_character, m_character_interface
local this = UIComponent(Address)
sort_columns = {}

function LessThan(c, column)
  local rhs_value = UIComponent(c):GlobalExists("sort_columns")[column + 1]
  return column ~= 0 and sort_columns[column + 1] == rhs_value and sort_columns[1] < UIComponent(c):GlobalExists("sort_columns")[1] or rhs_value > sort_columns[column + 1]
end

function OnDestroyed()
  if m_character_interface ~= nil then
    m_character_interface:Release()
    m_character_interface = nil
  end
end

function Character()
  return m_character
end

function NotifyCharacterDestroyed()
  local parent = UIComponent(this:Parent())
  Component.Destroy(Address)
  parent:Layout()
end

function NotifyCharacterContainedChanged(ch, contained)
  if contained == true then
    NotifyCharacterDestroyed()
  end
end

function NotifyCharacterMoved(mp_ratio)
  sort_columns[2] = mp_ratio
  sort_columns[3] = location
  SetMovePoints(mp_ratio)
  SetLocation(location)
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
  local soldiers_comp = UIComponent(this:Find("soldiers"))
  soldiers_comp:SetStateText(soldiers)
  local skill_comp = UIComponent(this:Find("skill_level"))
  skill_comp:SetState(tostring(skill))
  local loyalty_comp = UIComponent(this:Find("loyalty_level"))
  loyalty_comp:SetState(tostring(loyalty))
  SetMovePoints(mp)
end

function SetMovePoints(mp_ratio)
  local mp_bar = UIComponent(this:Find("ap"))
  local mp = UIComponent(this:Find("ap_bar"))
  mp_bar:SetVisible(0 < mp_ratio)
  mp_bar:Resize(mp:Width() - 1, (mp:Height() - 2) * mp_ratio, false)
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

function OnRClickUp()
  if m_unit == nil then
    Component.CallByAddress(Component.Root(), "LuaCall", "ShowFullCharacterInfo", m_character)
  else
    Component.CallByAddress(Component.Root(), "LuaCall", "ShowFullUnitInfo", m_unit)
  end
end

function ShowInfoPanel()
  if m_unit == nil then
    Component.CallByAddress(Component.Root(), "LuaCall", "ShowCharacterInfo", m_character)
  else
    Component.CallByAddress(Component.Root(), "LuaCall", "ShowUnitInfo", m_unit)
  end
end

function NotifyMilitaryForceChanged(soldiers_count)
  local soldiers = UIComponent(this:Find("soldiers_dy"))
  soldiers:SetStateText(soldiers_count)
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
