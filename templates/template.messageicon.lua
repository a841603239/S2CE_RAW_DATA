local utils = require("utilities")
local message_handler = MessageManager
local panel_manager = PanelManager
local events_logs_panel, details, shown_message, root_address
local this = UIComponent(Address)
local environment
local requires_response = false
local ui_in_use
if CampaignUI ~= nil then
  ui_in_use = CampaignUI
elseif BattleUI then
  ui_in_use = BattleUI
else
  ui_in_use = FrontEnd
end

function SetTooltip()
end

function Initialise(d, root, env)
  details = d
  root_address = root
  environment = env
  SetTooltip()
end

function EventPanelDestroyed(panel)
  if panel == shown_message then
    shown_message = nil
  end
end

function SetResponseStatus(req)
  requires_response = req
end

function ShowMessage()
  details.Parent = this
  if ui_in_use ~= CampaignUI then
    shown_message = panel_manager.OpenPanel("event_message", Address, "SelectLayout", details)
  else
    local events
    if not panel_manager.IsPanelOpen("events") then
      events = UIComponent(panel_manager.OpenPanel("events", Address, "Initialise"))
    else
      events = UIComponent(UIComponent(Component.Root()):Find("events"))
    end
    local event_msg = UIComponent(UIComponent(events:Find("TabGroup")):Find("new_events")):Find("event_window")
    UIComponent(event_msg):LuaCall("SelectLayout", details)
    shown_message = event_msg
  end
  if shown_message ~= nil then
    UIComponent(shown_message):InterfaceFunction("MultiplayerTimerReset")
    message_handler.ShowingMessage(this:Parent())
    SetTooltip()
    if details.Event ~= "HistoricEvent" and details.Event ~= "Dilemma" then
      environment.TriggerMessageOpenedEvent(details.Data, details.Event)
    else
      environment.TriggerMessageOpenedEvent(details.Data, nil)
    end
    message_handler.InitMessageCallback(this:Parent())
  else
    message_handler.HidingMessage(this:Parent())
  end
end

function RequiresResponse()
  return details.RequiresResponse
end

function OnMouseOn()
  UIComponent(this:Parent()):LuaCall("SetMouseOver", true)
end

function OnMouseOff()
  UIComponent(this:Parent()):LuaCall("SetMouseOver", false)
end

function DismissMessage()
  if details.RequiresResponse == false then
    message_handler.HideMessage(this:Parent())
  end
end

function Hide()
  if shown_message ~= nil then
    panel_manager.ClosePanel(shown_message)
    message_handler.HidingMessage(this:Parent())
  end
end

function Destroy(msg)
  local p = this:Parent()
  if msg == shown_message or msg == p then
    if shown_message ~= nil then
      if ui_in_use ~= CampaignUI then
        panel_manager.ClosePanel(shown_message)
        message_handler.HidingMessage(p)
      else
        message_handler.HidingMessage(p)
      end
    end
    Component.Destroy(p)
    return true
  end
  return false
end
