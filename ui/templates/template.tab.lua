local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
padding = 10
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function SetPadding(p)
  padding = p
  this:SetState("selected")
  this:SetState("selected_roll")
  this:SetState("unselected_roll")
  if this:SetState("unselected") == false then
    this:SetState("active")
  end
end

function InitState(state)
  local textWidth = state.Text.DisplayWidth
  local new_w, h
  if textWidth == 0 and this:ChildCount() > 1 then
    local c = this:Find(1, false)
    local x, y = this:Position()
    if c ~= nil then
      c = UIComponent(c)
      local s, w = c:GetStateText()
      h = c:Height()
      local c_x, c_y = c:Position()
      if w ~= nil then
        new_w = w + state.Images[1].Width + state.Images[3].Width + padding
        c:Resize(utils.Max(this:Width(), new_w), h)
        c:MoveTo(x, c_y)
      end
      textWidth = w
    end
  end
  if this:CanResizeWidth() and textWidth ~= nil and textWidth ~= 0 and textWidth + padding > state.Images[2].Width then
    state.Images[2].Width = textWidth + padding
    state.Images[3].X = textWidth + padding + state.Images[1].Width
    for i, v in ipairs(state.Images) do
      v.Height = nil
    end
  end
  return state
end

function LClick()
  parent:LuaCall("Notify", Component.Messages.LClickUp, Address)
end

function OnTexturePopulate(visible)
  ShaneOutput("tab: OnTexturePopulate - " .. tostring(visible))
  parent:LuaCall("Notify", Component.Messages.Move, Address)
end
