dofile("data/ui/templates/template.text_input.lua")
local generalisedOnKeyEvent = OnKeyEvent
local generalisedOnSelect = OnSelect
local max_input = 200
local this = UIComponent(Address)
local parent = UIComponent(this:Parent("multiplayer_chat"))

function ValidateTextInput(ch, current_value)
  if max_input == nil then
    return true
  else
    return string.length(current_value) < max_input
  end
end

this:SetGlobal("CharacterValidator", ValidateTextInput)

function OnSelect(offset_x)
  this:StealInputFocus(true)
  generalisedOnSelect(offset_x)
  parent:InterfaceFunction("ChatInputFocusGained")
end

function ChatInputFocusLost()
  parent:InterfaceFunction("ChatInputFocusLost")
  ClearHighlight()
end

this:SetEventCallback("OnInputFocusLose", "ChatInputFocusLost")

function OnSendChat()
  parent:InterfaceFunction("OnSendChat")
end

function OnKeyEvent(k, v, key_up)
  if k == "RETURN" and key_up == true then
    local value = Value()
    if 0 < #value then
      OnSendChat()
    end
  else
    generalisedOnKeyEvent(k, v, key_up)
  end
end

function SetMaxInput(new_value)
  max_input = new_value
end
