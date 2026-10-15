local utilities = require("Utilities")
local this = UIComponent(Address)
local currentComponent
local lines = {}
local last_update_time = 0
local current_line = 1
local delay_until_update = 2000
local environment
local advice_triggered = false
local current_text

function ShaneOutputFocused(output)
  out.shane(output)
end

local function SetLine(txt)
  this:InterfaceFunction("SetLine", txt)
end

function InitState(details)
  if details.Text.DisplayWidth ~= 0 then
    this:Resize(details.Text.DisplayWidth + 16, details.Text.DisplayHeight + 16)
  end
end

function ReportError(msg)
  if environment ~= nil and environment.DebugMessage ~= nil then
    environment.DebugMessage()
  end
end

function SetText(addr, text, env)
  if text == nil then
    ReportError("Tooltip being set with nil text")
    return
  end
  if #text ~= 0 then
    if addr ~= currentComponent or text ~= current_text then
      current_text = text
      last_update_time = 0
      lines = {}
      local i
      local last_i = 1
      while true do
        i = string.find(text, "||", last_i)
        if i == nil then
          lines[#lines + 1] = string.sub(text, last_i, -1)
          break
        end
        lines[#lines + 1] = string.sub(text, last_i, i - 1)
        last_i = i + 2
      end
      environment = env
      currentComponent = addr
      advice_triggered = false
      current_line = 1
      this:SetVisible(true)
      this:InterfaceFunction("SetText", currentComponent, environment ~= nil, lines)
    end
  elseif addr == currentComponent or currentComponent == nil then
    currentComponent = nil
    this:SetVisible(false)
    this:InterfaceFunction("SetText", currentComponent)
  else
    this:InterfaceFunction("SetText")
  end
end
