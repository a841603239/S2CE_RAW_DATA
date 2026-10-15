local utils = require("Utilities")
local this = UIComponent(Address)
local panel = this:Parent("main_panel", false)
local STATUS_OPEN = 1
local STATUS_OPEN_LOCKED = 3
local STATUS_CLOSED = 2
local STATUS_CLOSED_LOCKED = 4
column_data = {}

function Select(s)
  if panel ~= nil then
    if s then
      this:SetState("selected")
      UIComponent(panel):LuaCall("NotifySelectionChanged", Address)
    else
      this:SetState("unselected")
    end
  end
end

function OnSelect()
  if m_is_compatible == true then
    local p = UIComponent(this:Parent())
    p:LuaCall("SelectItem", Address)
  end
end

function OnDblClick()
  if m_is_compatible == true then
    local p = UIComponent(this:Parent("custom_battle_script"))
    p:LuaCall("MPJoin", false)
  end
end

function GameIndex()
  return m_game_index
end

function Passworded()
  return m_passworded
end

function Compatible()
  return m_is_compatible
end

function LessThan(rhs, column)
  rhs = UIComponent(rhs)
  local rhs_compatible = rhs:LuaCall("Compatible")
  if m_is_compatible and rhs_compatible == false then
    return true
  end
  return column_data[column + 1] < rhs:GlobalExists("column_data")[column + 1]
end
