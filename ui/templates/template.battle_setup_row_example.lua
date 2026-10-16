local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
m_name = nil
m_players = nil

function Initialise(name, players)
  m_name = name
  m_players = players
  FullName = name
  this:PropagateVisibility(true)
  this:SetState("unselected")
  local delete_button = this:Find("button_delete", false)
  if delete_button ~= nil then
    UIComponent(delete_button):SetVisible(false)
  end
  if utils.FitTextToComponent(this, "name", name) == true then
    this:SetTooltipText(name, true)
  end
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
    local rhs_players = rhs:GlobalExists("m_players")
    if m_players == rhs_players then
      return LessThan(rhs:Address(), 0)
    else
      return rhs_players > m_players
    end
  end
end

this:SetEventCallback("OnMouseLClickDown", LClickDown)
