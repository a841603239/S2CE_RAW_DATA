dofile("data/ui/vertical_mousewheel_script.lua")
local utils = require("CoreUtils")
local this = UIComponent(Address)
local vslider = UIComponent(Component.Call("vslider.Address"))
local list = UIComponent(this:Find("list_box"))
local margin = 0
Component.SetProperty("vslider.Notify", Address)
g_notify_func = nil

function Notify(notifier)
  local x, y = this:Position()
  local value = vslider:GetProperty("Value")
  list:MoveTo(x, y - value + margin)
end

function SetSliderValue(val)
  vslider:SetProperty("maxValue", val)
  if list:ChildCount() > 0 then
    vslider:LuaCall("Reset")
  end
end

function ResetSlider()
  if list:ChildCount() > 0 then
    local min = vslider:GetProperty("minValue")
    vslider:LuaCall("ValueSet", min)
    vslider:LuaCall("Reset")
  end
end

function ScrollTo(value)
  value = utils.Max(vslider:GetProperty("minValue"), utils.Min(vslider:GetProperty("maxValue"), value))
  vslider:LuaCall("ValueSet", value)
  local x, y = UIComponent(list:Parent()):Position()
  list:MoveTo(x, y - value)
end

function ListAddress()
  return list:Address()
end

function ListChildren()
  return list:LuaCall("ChildList")
end

local m_headers = {}
local m_sort_column
local current_sort_greater = false
oldNotify = Notify

function Sorter(a, b)
  if UIComponent(a):HasInterface() then
    if current_sort_greater then
      return UIComponent(a):InterfaceFunction("LessThan", b, m_sort_column)
    else
      return UIComponent(b):InterfaceFunction("LessThan", a, m_sort_column)
    end
  elseif current_sort_greater then
    return Component.CallByAddress(a, "LuaCall", "LessThan", b, m_sort_column)
  else
    return Component.CallByAddress(b, "LuaCall", "LessThan", a, m_sort_column)
  end
end

function Initialise()
  local h = UIComponent(this:Find("headers"))
  for n = 1, h:ChildCount() do
    m_headers[n] = {}
    m_headers[n].Component = UIComponent(h:Find(n - 1))
    m_headers[n].Component:SetProperty("Column", n - 1)
    m_headers[n].LastSortGreater = true
  end
  margin = h:Height()
end

function InitialSort(column, greater)
  if column == nil then
    column = 0
  end
  if greater == nil then
    greater = false
  end
  m_headers[column + 1].Component:SetState(greater == false and "selected_down" or "selected_up")
  m_headers[column + 1].LastSortGreater = greater
  Notify(m_headers[column + 1].Component:Address(), true)
end

function LastSorted()
  return m_sort_column, not current_sort_greater
end

function SortAgain()
  if m_sort_column ~= nil then
    SortByColumn(m_sort_column, true)
  end
end

function CurrentSortGreater(column)
  return m_headers[column + 1].LastSortGreater
end

function SortByColumn(column, initial)
  if initial ~= true then
    m_headers[column + 1].LastSortGreater = not m_headers[column + 1].LastSortGreater
  end
  m_sort_column = column
  current_sort_greater = m_headers[column + 1].LastSortGreater
  m_headers[column + 1].Component:SetState(current_sort_greater == false and "selected_down" or "selected_up")
  local children = ListChildren()
  table.sort(children, Sorter)
  list:ReorderChildren(children)
  list:Layout()
  ResetSlider()
  if g_notify_func ~= nil then
    g_notify_func(Address)
  end
end

function Notify(notifier, initial)
  local found = false
  if notifier ~= vslider:Address() then
    for i, v in ipairs(m_headers) do
      local column = v.Component:GetProperty("Column")
      if notifier == v.Component:Address() then
        SortByColumn(column, initial)
        found = true
      elseif v.Component:SetState("unselected") == false then
        m_headers[column + 1].LastSortGreater = true
        v.Component:SetState("normal")
      end
    end
  end
  if found == false then
    oldNotify(notifier)
  end
end

Initialise()
