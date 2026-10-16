local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local panel_root = UIComponent(parent:Parent())

function ResetDeploymentPanel()
  this:SetState("normal")
end

function DeployDismiss()
  if not BattleUI.SteamOverlayOpen() then
    this:SetState("inactive")
    parent:LuaCall("DeployDismissed")
  end
end
