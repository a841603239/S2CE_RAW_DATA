local this = UIComponent(Address)
local multiplayer_panel = UIComponent(this:Find("deployment_end_mp"))
local singleplayer_panel = UIComponent(this:Find("deployment_end_sp"))
local is_multiplayer, mp_waiting_for_others

function InitDeploymentPanel(player_mode, make_inactive)
  local make_inactive = make_inactive or false
  is_multiplayer = player_mode
  if is_multiplayer == true then
    ShowWaitingForPlayers()
  else
    ShowNoPanel()
  end
end

function ShowStartDeployment()
  if is_multiplayer then
    ShowMultiplayerPanel()
  else
    ShowSingleplayerPanel()
    singleplayer_panel:LuaCall("ResetDeploymentPanel")
  end
end

function ShowNoPanel()
  SetSingleplayerPanelVisible(false)
  SetMultiplayerPanelVisible(false)
  SetWaitingPanelVisible(false)
end

function ShowWaitingForPlayers()
  SetSingleplayerPanelVisible(false)
  SetMultiplayerPanelVisible(false)
  SetWaitingPanelVisible(true)
end

function ShowSingleplayerPanel()
  local is_skipping_deployment = BattleUI.IsSkippingDeployment()
  SetSingleplayerPanelVisible(not is_skipping_deployment)
  SetMultiplayerPanelVisible(false)
  SetWaitingPanelVisible(false)
end

function ShowMultiplayerPanel()
  SetSingleplayerPanelVisible(false)
  SetMultiplayerPanelVisible(true)
  SetWaitingPanelVisible(false)
end

function SetMultiplayerPanelVisible(visible)
  multiplayer_panel:SetVisible(visible)
end

function SetSingleplayerPanelVisible(visible)
  singleplayer_panel:SetVisible(visible)
end

function SetWaitingPanelVisible(visible)
  if visible == true and mp_waiting_for_others == nil then
    mp_waiting_for_others = UIComponent(Component.CreateFromLayout("data/ui/common ui/waiting_for_players", "waiting_for_players", Address))
    local x, y = multiplayer_panel:Position()
    mp_waiting_for_others:MoveTo(x, y)
  end
  if mp_waiting_for_others ~= nil then
    mp_waiting_for_others:SetVisible(visible)
  end
end

function DeployDismissed()
  out.dylan("DeployDismissed")
  BattleUI.InformOfDeploymentFinished()
end

function UpdateEndDeployment()
end
