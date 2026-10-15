local this = UIComponent(Address)
g_notify_func = nil

function NotifySelected()
  if g_notify_func == nil then
    UIComponent(this:Parent()):LuaCall("Notify", Component.Messages.StateChange, this:CurrentState(), Address)
  else
    g_notify_func(Address, this:CurrentState() == "down")
  end
end

function SetSelected(select)
  if select then
    this:SetState("selected")
  else
    this:SetState("normal")
  end
end

function SetState(state)
  Component.SetState(state)
end

function Selected()
  local current_state = this:CurrentState()
  return current_state == "selected" or current_state == "down" or current_state == "selected_down_off" or current_state == "selected_roll"
end
