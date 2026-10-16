local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local button = UIComponent(this:Find("button_battle_start"))

function DeployDismissed()
  parent:LuaCall("DeployDismissed")
end

function ResetDeploymentPanel()
  button:LuaCall("ResetDeploymentPanel")
end

function ChangeButtonActivate(is_inactive)
  if is_inactive == true then
    button:SetState("inactive")
  else
    button:SetState("normal")
  end
end
