local this = UIComponent(Address)
local utils = require("Utilities")
local ok_group = UIComponent(this:Find("ok_group"))
local both_group = UIComponent(this:Find("both_group"))
local text_box = UIComponent(this:Find("DY_text"))
local button_tick = UIComponent(this:Find("button_tick"))
local m_text, m_message_type, m_initial_time, m_ok_callback, m_cancel_callback, m_update_callback

function Initialise(message_type, message, ok_callback, cancel_callback, update_callback)
  m_message_type = message_type
  m_text = message
  m_initial_time = CampaignUI.Time()
  m_ok_callback = ok_callback
  m_cancel_callback = cancel_callback
  m_update_callback = update_callback
  text_box:SetStateText(m_text)
  ok_group:SetVisible(m_ok_callback ~= nil and cancel_callback == nil)
  both_group:SetVisible(cancel_callback ~= nil)
end

function MessageType()
  return m_message_type
end

function OnUpdatePulse(time)
  if m_update_callback ~= nil then
    UIComponent(Component.Root()):LuaCall(m_update_callback, Address, m_text, time * 0.001)
  end
end

function OnKey(key, v, ended)
  if ended then
    if key == "RETURN" then
      OnAccept()
    elseif key == "ESCAPE" then
      OnCancel()
    end
  end
end

function OnShortcut()
end

function OnAccept()
  if m_ok_callback then
    m_ok_callback()
  end
end

function OnCancel()
  if m_cancel_callback then
    m_cancel_callback()
  end
end

UIComponent(ok_group:Find("button_tick")):SetGlobal("OnSelect", OnAccept)
UIComponent(both_group:Find("button_tick")):SetGlobal("OnSelect", OnAccept)
UIComponent(both_group:Find("button_cancel")):SetGlobal("OnSelect", OnCancel)
