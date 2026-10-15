local utils = require("Utilities")
local panel_manager = PanelManager
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local m_text = UIComponent(this:Find("DY_text"))
local ok_group = UIComponent(this:Find("ok_group"))
local both_group = UIComponent(this:Find("both_group"))
local ok_tick = UIComponent(ok_group:Find("button_tick"))
local both_tick = UIComponent(both_group:Find("button_tick"))
local both_cancel = UIComponent(both_group:Find("button_cancel"))
local m_message, m_ok_callback, m_cancel_callback, m_mp_timer, m_mp_default, m_default_button, m_button_timer_txt_ptr
local TimeString = utils.TimeString
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function CallTimerFunc(timer_func)
  return timer_func()
end

function Initialise(txt, ok_callback, cancel_callback, no_default_close, mp_timer, mp_default)
  ShaneOutput("dialog_box initialise")
  ShaneOutput("txt = " .. tostring(txt))
  ShaneOutput("ok_callback = " .. tostring(ok_callback))
  ShaneOutput("cancel_callback = " .. tostring(cancel_callback))
  ShaneOutput("no_default_close = " .. tostring(no_default_close))
  ShaneOutput("mp_timer = " .. tostring(mp_timer))
  ShaneOutput("mp_default = " .. tostring(mp_default))
  m_message = txt
  m_ok_callback = ok_callback
  m_cancel_callback = cancel_callback
  m_mp_timer = mp_timer
  m_mp_default = mp_default
  local show_both = ok_callback ~= nil and cancel_callback ~= nil
  local text_box = UIComponent(this:Find("DY_text"))
  text_box:SetStateText(txt)
  MultiplayerRemoveTimerFromDialogButton(ok_tick:Address())
  MultiplayerRemoveTimerFromDialogButton(both_tick:Address())
  MultiplayerRemoveTimerFromDialogButton(both_cancel:Address())
  local show_tick = (no_default_close ~= true or ok_callback ~= nil) and show_both == false
  ShaneOutput("show_tick = " .. tostring(show_tick))
  ok_group:SetVisible(show_tick)
  both_group:SetVisible(show_both)
  if m_mp_timer ~= nil then
    m_default_button = nil
    if show_both == true then
      if m_mp_default == true then
        m_default_button = UIComponent(both_group:Find("button_tick"))
      else
        m_default_button = UIComponent(both_group:Find("button_cancel"))
      end
    else
      m_default_button = UIComponent(ok_group:Find("button_tick"))
    end
    m_button_timer_txt_ptr = MultiplayerAddTimerToDialogButton(m_default_button:Address())
  end
  this:StealShortcutKey("ESCAPE")
  this:StealShortcutKey("RETURN")
  this:StealShortcutKey("NUMPADENTER")
  this:InterfaceFunction("InitialiseDialogue", m_mp_timer, m_message, m_button_timer_txt_ptr, m_mp_default == true, m_cancel_callback == nil)
end

function OnKey(key, v, ended)
  if ended then
    if key == "ESCAPE" then
      if m_cancel_callback then
        OnCancel()
      else
        OnAccept()
      end
    elseif key == "RETURN" or key == "NUMPADENTER" then
      OnAccept()
    end
  end
end

function OnShortcut()
end

function OnAccept()
  panel_manager.ClosePanel(this:Id())
  if m_ok_callback then
    m_ok_callback()
  end
end

function OnCancel()
  panel_manager.ClosePanel(this:Id())
  if m_cancel_callback then
    m_cancel_callback()
  end
end

function MultiplayerAddTimerToDialogButton(dialog_button_ptr)
  local timer = UIComponent(Component.CreateFromLayout("ui/Common UI/button_timer", "button_timer", dialog_button_ptr, 0, 0))
  timer:Resize(UIComponent(dialog_button_ptr):Dimensions())
  UIComponent(timer:Find("halo")):ShaderTechniqueSet("highlight_circumference_t0", true, false)
  return timer:Find("time_label")
end

function MultiplayerRemoveTimerFromDialogButton(dialog_button_ptr)
  local timer_ptr = UIComponent(dialog_button_ptr):Find("button_timer", false)
  if timer_ptr then
    Component.Destroy(timer_ptr)
    return true
  end
  return false
end

UIComponent(both_group:Find("button_tick")):SetGlobal("OnSelect", OnAccept)
UIComponent(both_group:Find("button_cancel")):SetGlobal("OnCancel", OnCancel)
UIComponent(ok_group:Find("button_tick")):SetGlobal("OnSelect", OnAccept)
