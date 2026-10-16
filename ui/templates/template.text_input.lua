local utilities = require("Utilities")
local this = UIComponent(Address)
local highlight = this:Find("highlight", false)
local value = ""
local caret_pos = 0
local input_hidden = this:GetProperty("HideInput", true)
input_hidden = input_hidden ~= nil and 0 < input_hidden
local has_focus = false
local x_offset = this:GetStateTextDetails().XOffset
local text_shifted_off_width = 0
this:SetEventCallback("OnInputFocusGain", "FocusGain")
this:SetEventCallback("OnInputFocusLose", "FocusLose")
this:SetEventCallback("OnMouseLClickUp", "OnSelect")
this:SetEventCallback("OnMouseLClickDown", "OnLClickDown")
this:SetEventCallback("OnMouseMove", "OnMouseMove")
this:SetStateText(value)
local highlight_height, highlight_ypos
if highlight ~= nil then
  highlight = UIComponent(highlight)
  highlight:SetVisible(false)
  local _, this_y = this:Position()
  local this_height = this:Height()
  highlight_ypos = this_y + this_height / 8
  highlight_height = this_height - this_height / 4
end
g_escapeable = true
g_notify_func = nil
local lclick_down = false
local highlight_startpos = 0
local highlight_endpos = 0
local highlight_threshold = 5
local caret_pos_end = 0
local clipboard = ClipboardInterface()
local prev_key = "a"
local highlight_tweak = 0

function GetValue()
  if not input_hidden then
    return value
  else
    return string.rep("*", string.length(value))
  end
end

function DefaultCharacterInput(ch, value)
  if CharacterValidator == nil then
    if this:HasInterface() then
      return this:InterfaceFunction("CharacterValidator", ch, value)
    else
      return true
    end
  else
    return CharacterValidator(ch, value)
  end
end

function CharacterInput(ch)
  if highlight ~= nil and highlight:Visible() and caret_pos_end ~= nil and this:IsCharPrintable(ch) and DefaultCharacterInput(ch, value) == true then
    DeleteUnderHighlight()
  end
  if ch == "\r" then
    if g_escapeable then
      this:StealInputFocus(false)
    end
    OnEnterPressed()
  elseif this:IsCharPrintable(ch) and DefaultCharacterInput(ch, value) == true and (string.length(value) > 0 or ch ~= " ") then
    if string.length(value) > 0 then
      local begin = string.sub(value, 1, caret_pos)
      local _end = ""
      if caret_pos < string.length(value) then
        _end = string.sub(value, caret_pos + 1, -1)
      end
      value = begin .. ch .. _end
    else
      value = value .. ch
    end
    caret_pos = caret_pos + 1
    this:InterfaceFunction("TextChanged", value)
  end
  SetDisplayString()
  ClearHighlight()
end

function DeleteUnderHighlight()
  if 0 < caret_pos or 0 < caret_pos_end then
    local old_value = value
    if caret_pos < caret_pos_end then
      if caret_pos ~= 0 then
        local begin = string.sub(value, 0, caret_pos)
        local _end = string.sub(value, caret_pos_end + 1, -1)
        value = begin .. _end
        caret_pos = string.length(begin)
      else
        value = string.sub(value, caret_pos_end + 1, -1)
        caret_pos = 0
      end
    elseif 0 < caret_pos_end then
      local begin = string.sub(value, 1, caret_pos_end)
      local _end = string.sub(value, caret_pos + 1, -1)
      value = begin .. _end
      caret_pos = string.length(begin)
    else
      value = string.sub(value, caret_pos + 1, -1)
      caret_pos = 0
    end
    if value ~= old_value then
      this:InterfaceFunction("TextChanged", value)
    end
  end
end

function ClearHighlight()
  if highlight ~= nil then
    highlight:SetVisible(false)
    caret_pos_end = nil
  end
end

function Copy()
  if not input_hidden then
    if caret_pos_end ~= nil and caret_pos < caret_pos_end then
      local copy_text = string.sub(value, caret_pos + 1, caret_pos_end)
      clipboard:Copy(copy_text)
    else
      local copy_text = string.sub(value, caret_pos_end + 1, caret_pos)
      clipboard:Copy(copy_text)
    end
  end
end

function Cut()
  Copy()
  if highlight ~= nil and highlight:Visible() and caret_pos_end ~= nil then
    DeleteUnderHighlight()
  end
end

function Paste()
  paste_text = clipboard:Paste()
  if type(paste_text) == "string" then
    local old_value = value
    if string.length(paste_text) > 100 then
      paste_text = string.sub(paste_text, 1, 100)
    end
    local valid_text = true
    local temp_value = value
    if string.length(temp_value) > 0 then
      local begin = string.sub(temp_value, 1, caret_pos)
      local _end = ""
      if caret_pos < string.length(temp_value) then
        _end = string.sub(temp_value, caret_pos + 1, -1)
      end
      temp_value = begin .. paste_text .. _end
    else
      temp_value = temp_value .. paste_text
    end
    out.scott_b(temp_value)
    local validated_temp_value = ""
    for i = 1, string.length(temp_value) do
      local temp_char = string.sub(temp_value, i, i)
      if not this:IsCharPrintable(temp_char) or not DefaultCharacterInput(temp_char, validated_temp_value) then
        valid_text = false
        break
      end
      validated_temp_value = validated_temp_value .. temp_char
    end
    if valid_text then
      value = temp_value
      if highlight ~= nil and highlight:Visible() and caret_pos_end ~= nil then
        DeleteUnderHighlight()
      end
      caret_pos = caret_pos + string.length(paste_text)
      SetDisplayString()
    end
    if value ~= old_value then
      this:InterfaceFunction("TextChanged", value)
    end
  end
end

function SelectAll()
  if string.length(value) > 0 and highlight ~= nil then
    local parent_x = this:Position()
    highlight_startpos = this:FindTextSnapPosition(GetValue(), 0)
    local parent_x = this:Position()
    local snap_pos = this:FindTextSnapPosition(GetValue(), string.length(value))
    highlight_endpos = snap_pos
    highlight:Resize(snap_pos - highlight_startpos, highlight_height)
    caret_pos = string.length(value)
    caret_pos_val = highlight_startpos - parent_x
    caret_pos_end = this:FindPositionIntoCurrentText(GetValue(), 0)
    local this_x, this_y = this:Position()
    local this_height = this:Height()
    highlight_ypos = this_y + this_height / 8
    highlight:SetOpacity(true, 64)
    highlight:MoveTo(highlight_startpos + highlight_tweak, highlight_ypos)
    SetDisplayString()
    highlight:SetVisible(true)
  end
end

function SetEscapeable(can_escape)
  g_escapeable = can_escape
end

function OnKeyEvent(k, v, key_up)
  lclick_down = false
  if g_escapeable and key_up == true and k == "ESCAPE" then
    this:StealInputFocus(false)
    return
  end
  if prev_key == "LCONTROL" and k == "V" then
    Paste()
    ClearHighlight()
  end
  if prev_key == "LCONTROL" and k == "A" then
    ClearHighlight()
    SelectAll()
    return
  end
  if string.length(value) > 0 and key_up == false then
    local old_value = value
    if k == "BACK" then
      if highlight ~= nil and highlight:Visible() and caret_pos_end ~= nil then
        DeleteUnderHighlight()
      elseif 0 < caret_pos then
        out.scott_b("DELETE IN TEXT INPUT CALLED")
        out.scott_b("original value:" .. value .. ";caret_post:" .. tostring(caret_pos))
        local begin = string.sub(value, 1, caret_pos - 1)
        local _end = string.sub(value, caret_pos + 1, -1)
        value = begin .. _end
        caret_pos = caret_pos - 1
        out.scott_b("new value:" .. value .. ";caret_post:" .. tostring(caret_pos))
      end
      ClearHighlight()
    elseif k == "DELETE" then
      if highlight ~= nil and highlight:Visible() and caret_pos_end ~= nil then
        DeleteUnderHighlight()
      elseif caret_pos < string.length(value) then
        local begin = string.sub(value, 1, caret_pos)
        local _end = string.sub(value, caret_pos + 2, -1)
        value = begin .. _end
      end
      ClearHighlight()
    elseif k == "LEFT" and 0 < caret_pos then
      caret_pos = caret_pos - 1
      ClearHighlight()
    elseif k == "RIGHT" and caret_pos < string.length(value) then
      caret_pos = caret_pos + 1
      ClearHighlight()
    elseif k == "END" then
      caret_pos = string.length(value)
      ClearHighlight()
    elseif k == "HOME" then
      caret_pos = 0
      ClearHighlight()
    elseif prev_key == "LCONTROL" and k == "X" then
      Cut()
      ClearHighlight()
    elseif prev_key == "LCONTROL" and k == "C" then
      Copy()
    end
    SetDisplayString()
    if value ~= old_value then
      this:InterfaceFunction("TextChanged", value)
    end
  end
  prev_key = k
end

function OnEnterPressed()
  this:InterfaceFunction("OnEnterPressed")
end

function SetDisplayString()
  local v
  if input_hidden then
    v = string.rep("*", string.length(value))
  else
    v = value
  end
  if has_focus == true then
    local begin = string.sub(v, 1, caret_pos)
    local _end = string.sub(v, caret_pos + 1, -1)
    local w
    if highlight == nil or caret_pos_end == nil then
      w = this:SetStateText(begin .. "|" .. _end)
    else
      w = this:SetStateText(begin .. _end)
    end
    if w > this:Width() then
      text_shifted_off_width = this:Width() - w
      this:SetStateTextXOffset(text_shifted_off_width)
    else
      this:SetStateTextXOffset(x_offset)
    end
  else
    this:SetStateText(v)
  end
end

function FocusGain()
  caret_pos = string.length(value)
  caret_pos_end = nil
  has_focus = true
  SetDisplayString()
end

function FocusLose()
  has_focus = false
  SetDisplayString()
  if highlight ~= nil then
    highlight:SetVisible(false)
  end
  if g_notify_func then
    g_notify_func(Value())
  end
  lclick_down = false
end

function OnSelect(offset_x)
  lclick_down = false
  offset_x = offset_x - text_shifted_off_width
  caret_pos = string.length(value)
  caret_pos = this:FindPositionIntoCurrentText(GetValue(), offset_x)
  if caret_pos > string.length(value) then
    caret_pos = string.length(value)
  end
  SetDisplayString()
  if highlight ~= nil then
    local parent_x = this:Position()
    local snap_pos = this:FindTextSnapPosition(GetValue(), caret_pos)
    highlight_endpos = snap_pos
    local difference = highlight_endpos - highlight_startpos
    if difference < 0 then
      difference = -difference
    end
    if difference > highlight_threshold then
      caret_pos_val = highlight_startpos - parent_x
      caret_pos_end = this:FindPositionIntoCurrentText(GetValue(), caret_pos_val)
    else
      caret_pos_end = nil
    end
  end
  SetDisplayString()
end

function SetValue(v)
  local old_value = value
  value = v
  caret_pos = utilities.Min(caret_pos, string.length(value))
  SetDisplayString()
  if value ~= old_value then
    this:InterfaceFunction("TextChanged", value)
  end
end

function MoveCaretToEnd()
  caret_pos = string.length(value)
  SetDisplayString()
end

function Value()
  return value
end

function OnLClickDown(x, y)
  if highlight ~= nil then
    local parent_x = this:Position()
    local this_x, this_y = this:Position()
    local this_height = this:Height()
    highlight_ypos = this_y + this_height / 8
    highlight_height = this_height - this_height / 4
    highlight:SetOpacity(true, 64)
    highlight:SetVisible(false)
    offset_x = x
    caret_pos = this:FindPositionIntoCurrentText(GetValue(), offset_x)
    SetDisplayString()
    local snap_pos = this:FindTextSnapPosition(GetValue(), caret_pos)
    highlight:MoveTo(snap_pos + highlight_tweak, highlight_ypos)
    highlight_startpos = snap_pos
  end
  lclick_down = true
end

function UpdateHighlight(xpos)
  local parent_x = this:Position()
  offset_x = xpos
  caret_pos = this:FindPositionIntoCurrentText(GetValue(), offset_x)
  SetDisplayString()
  local snap_pos = this:FindTextSnapPosition(GetValue(), caret_pos)
  out.scott_b(caret_pos)
  out.scott_b(snap_pos)
  if snap_pos > highlight_startpos then
    highlight:Resize(snap_pos - highlight_startpos, highlight_height)
  else
    highlight:MoveTo(snap_pos + highlight_tweak, highlight_ypos)
    highlight:Resize(highlight_startpos - snap_pos, highlight_height)
  end
  if highlight:Width() > highlight_threshold and snap_pos ~= highlight_startpos then
    highlight:SetVisible(true)
  else
    highlight:SetVisible(false)
  end
end

function IsOutOfRange(x, y)
  local textbox_x, textbox_y = this:Position()
  if x <= 0 or x >= this:Width() or y <= 0 or y >= this:Height() then
    return true
  else
    return false
  end
end

function OnMouseMove(x, y)
  if highlight ~= nil and lclick_down == true then
    UpdateHighlight(x)
    if IsOutOfRange(x, y) then
      OnSelect(x)
    end
  end
end

function SetInputHidden(value)
  input_hidden = value
  SetDisplayString()
end
