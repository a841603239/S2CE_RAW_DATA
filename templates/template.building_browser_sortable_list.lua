dofile("data/ui/vertical_mousewheel_script.lua")
dofile("data/ui/templates/template.sortable_list.lua")
local utils = require("CoreUtils")
local this = UIComponent(Address)
local vslider = UIComponent(this:Find("vslider"))
local list = UIComponent(this:Find("list_box"))
local clip = UIComponent(this:Find("list_clip"))
local m_margin = 0
local m_original_child_order = {}
vslider:SetProperty("Notify", Address)
g_notify_func = nil
local shane_output = true

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ScrollTo(value)
  value = utils.Max(vslider:GetProperty("minValue"), utils.Min(vslider:GetProperty("maxValue"), value))
  vslider:LuaCall("ValueSet", value)
  local x, y = clip:Position()
  list:MoveTo(x, y - value)
end

function Reset()
  local x, y = this:Position()
  local value = 0
  list:MoveTo(x, y - value + m_margin)
  vslider:LuaCall("ValueSet", 0)
end

function Notify(notifier)
  local x, y = this:Position()
  local value = vslider:GetProperty("Value")
  list:MoveTo(x, y - value + m_margin)
end

function SetSliderValue(val)
  vslider:SetProperty("maxValue", val)
  vslider:LuaCall("Reset")
end

function ListAddress()
  return list:Address()
end

function ListChildren()
  return list:LuaCall("ChildList")
end

local m_headers = {}
local m_sort_column
oldNotify = Notify

function Sorter(a, b)
  if m_headers[m_sort_column + 1].Component:CurrentState() == "selected_up" then
    return Component.CallByAddress(b, "LuaCall", "LessThan", a, m_sort_column)
  end
  return Component.CallByAddress(a, "LuaCall", "LessThan", b, m_sort_column)
end

function Initialise(entries, start_column)
  local h = UIComponent(this:Find("headers"))
  for n = 1, h:ChildCount() do
    m_headers[n] = {}
    m_headers[n].Component = UIComponent(h:Find(n - 1))
    m_headers[n].Component:SetProperty("Column", n - 1)
    if not m_headers[n].Component:SetState("unselected") then
      m_headers[n].Component:SetState("normal")
    end
  end
  m_margin = h:Height()
  for i, v in ipairs(entries) do
    list:Adopt(v)
  end
  list:Layout()
  m_original_child_order = list:LuaCall("ChildList")
  if start_column == nil then
    start_column = 1
  end
  ShaneOutput("Initial sort")
  SortByColumn(start_column - 1)
  ScrollTo(0)
end

function SortByColumn(column)
  ShaneOutput("SortByColumn: column = " .. tostring(column))
  m_sort_column = column
  local children = {}
  for i, v in ipairs(m_original_child_order) do
    children[#children + 1] = v
  end
  table.sort(children, Sorter)
  list:ReorderChildren(children)
  ShaneOutput("#children = " .. #children)
  for i, v in ipairs(children) do
    ShaneOutput(UIComponent(UIComponent(v):Find("dy_name")):GetStateText())
  end
  for i, v in ipairs(children) do
    local entry = UIComponent(v)
    local state = i % 2 == 1 and "B_normal" or "A_normal"
    entry:SetState(state)
  end
  list:Layout()
  if g_notify_func ~= nil then
    g_notify_func(Address)
  end
end

function Notify(notifier, column)
  local found = false
  for i, v in ipairs(m_headers) do
    if notifier == v.Component:Address() then
      SortByColumn(column)
      found = true
    end
  end
  if found == false then
    oldNotify(notifier)
  else
    for i, v in ipairs(m_headers) do
      if notifier ~= v.Component:Address() and v.Component:SetState("unselected") == false then
        v.Component:SetState("normal")
      end
    end
  end
end
