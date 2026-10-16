local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
padding = 10

function SetPadding(p)
  padding = p
  this:SetState("selected")
  this:SetState("active")
  this:SetState("hover")
  this:SetState("inactive")
end

function InitState(state)
  return state
end

function LClick()
  parent:LuaCall("Notify", Component.Messages.LClickUp, Address)
end

function OnTexturePopulate(visible)
  ShaneOutput("tab: OnTexturePopulate - " .. tostring(visible))
  parent:LuaCall("Notify", Component.Messages.Move, Address)
end
