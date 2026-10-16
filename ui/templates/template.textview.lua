dofile("data/ui/vertical_mousewheel_script.lua")
local utilities = require("Utilities")
local this = UIComponent(Address)
local vslider = UIComponent(this:Find("vslider"))
local m_Text = UIComponent(this:Find("Text"))
local ourHeight = this:Height()
local slider_visible = vslider:Visible()

function InitState(state)
  vslider:SetProperty("Notify", Address)
  vslider:LuaCall("Reset")
end

function SetTextExtents(w, h)
  local diff = utilities.Max(0, h - ourHeight)
  vslider:LuaCall("MaxValueSet", diff)
end

function Notify()
  local value = vslider:LuaCall("ValueGet")
  local ourX, ourY = Component.Call("Position")
  m_Text:MoveTo(m_Text:Position(), ourY - value)
end

function SetText(text)
  local w, h = m_Text:SetStateText(text)
  m_Text:Resize(m_Text:Width(), utilities.Max(h, ourHeight))
  SetTextExtents(m_Text:Dimensions())
  vslider:LuaCall("Reset")
  vslider:LuaCall("ValueSet", 0)
end

function MoveToBottom()
  vslider:LuaCall("Reset")
  vslider:LuaCall("MoveToBottom")
end

function MessageEventResize()
  m_Text:SetStateText(m_Text:GetStateText(), true, 6)
end
