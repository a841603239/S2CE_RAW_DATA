dofile("data/ui/vertical_mousewheel_script.lua")
local utils = require("CoreUtils")
local this = UIComponent(Address)
local vslider = UIComponent(this:Find("vslider"))
local list = UIComponent(this:Find("list_box"))
local clip = UIComponent(this:Find("list_clip"))
Component.SetProperty("vslider.Notify", Address)

function InitState(state)
  vslider:LuaCall("Reset")
end

function MoveToBottom()
  vslider:LuaCall("Reset")
  vslider:LuaCall("MoveToBottom")
end

function Notify(notifier, value)
  local x, y = clip:Position()
  out.shane("Notify: clip_pos = " .. tostring(x) .. ", " .. tostring(y) .. ", value = " .. tostring(value))
  list:MoveTo(x, y - value)
end

function SetListExtents()
  local list_w, list_h = list:Bounds()
  local diff = utils.Max(0, list_h - this:Height())
  vslider:LuaCall("MaxValueSet", diff)
end

function SetSliderValue(val)
  vslider:LuaCall("MaxValueSet", val)
end

function ScrollTo(value)
  vslider:LuaCall("ValueSet", value)
  local x, y = clip:Position()
  list:MoveTo(x, y - value)
end

function ListAddress()
  return list:Address()
end

function ListChildren()
  return list:LuaCall("ChildList")
end

function SetMargin(m)
end
