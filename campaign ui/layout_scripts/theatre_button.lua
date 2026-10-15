local this = UIComponent(Address)

function NotifySelected()
  UIComponent(this:Parent()):LuaCall("Notify", Component.Messages.StateChange, this:CurrentState(), Address)
end

function SetState(state)
  this:SetState(state)
end
