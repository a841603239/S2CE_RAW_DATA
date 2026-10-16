local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local requester
m_name = nil
m_date = nil
m_hours_played = 0

function Initialise(name, date, time, req)
  requester = UIComponent(req)
  m_name = name
  m_date = date
  m_hours_played = time
  utils.FitTextToComponent(this, 0, name)
  local tt = UIComponent(this:Find(0)):GetTooltipText()
  this:SetTooltipText(tt, true)
end

function OnSelect()
  parent:LuaCall("SelectItem", Address, true)
end

function LClickDown()
  parent:LuaCall("SelectItem", Address, false)
end

function Select(s)
  if s then
    this:SetState("selected")
  else
    this:SetState("unselected")
  end
end

function OnDblClick()
end

function LessThan(rhs, column)
  rhs = UIComponent(rhs)
  if column == 0 then
    return m_name < rhs:GlobalExists("m_name")
  elseif column == 1 then
    return m_hours_played < rhs:GlobalExists("m_hours_played")
  elseif column == 2 then
    return m_date < rhs:GlobalExists("m_date")
  end
end

this:SetEventCallback("OnMouseLClickDown", LClickDown)
