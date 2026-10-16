package.path = ";?.lua;data/ui/templates/?.lua;data/ui/?.lua;data/ui/battle ui/?.lua"
local utils = require("Utilities")
local message_handler = MessageManager
local hud_manager = HudManager
local panel_manager = PanelManager
local visibility_manager = utils.Require("battle_HUD_visibility_manager")
BattleUI.ID = "BattleUI"
local this = UIComponent(Address)
local g_hud
local UI_MODE_LAND = 0
local UI_MODE_SEA = 1
local g_menu_bar_name = "menu_bar"
local g_player_list_panel_name = "multiplayer_player_list"
local g_chat_panel_name = "multiplayer_chat"
local g_battle_summary_popup_name = "in_battle_results_popup"
local g_battle_results_popup_name = "mp_postbattle"
local g_battle_results_popup
local g_layouts_path = "data/ui/battle ui/"
local g_common_layouts_path = "data/ui/common UI/"
local g_paused_panel, g_post_battle_details
local g_post_battle_details_name = "mp_postbattle"
local g_picture_in_picture_display, is_battle_multiplayer, g_deployment_start_time
max_deployment_time = 60

function InitState(state)
  details = BattleUI.BattleDetails()
  is_battle_multiplayer = details.IsMultiplayer
  this:LockPriority(-50)
  g_hud = this:Find("layout")
  assert(g_hud, "LuaScript: Hud not found")
  visibility_manager.InitialiseHUDVisibilityManager()
end

function OnDestroyed()
  panel_manager.ClearCachedComponent()
  utils.UnRequire("PanelManager")
  utils.UnRequire("Utilities")
end

this:SetEventCallback("OnDestroyed", OnDestroyed)

function CallSpeedVotingFunction(functionName, param1)
  out.dylan("called CallSpeedVotingFunction with: " .. tostring(functionName) .. ". param: " .. tostring(param1))
  local mp_speed_voting = this:Find("mp_speed_voting", false)
  if mp_speed_voting ~= nil then
    UIComponent(mp_speed_voting):LuaCall(functionName, param1)
  else
    out.dylan("speed voting component was not found")
  end
end

function GetReviewPanelComponent()
  return this:Find("review_DY")
end

function ShowMessage(details)
end

function OnShortcut(f, ended)
end

function ChangeVisibilityBasedOnSettings(RadarSetting)
  SetRadarVisibility(RadarSetting)
end

function SetRadarVisibility(visible)
  print("root")
  print(invisible)
  visibility_manager.SetRadarVisibility(visible)
end

function SetTooltipText(addr, text)
  this:InterfaceFunction("SetTooltipText", addr, text)
end

function HudDockOriginAndOffset(x, y)
  return hud_manager.HudDockOriginAndOffset(x, y, this:Width(), this:Height())
end

function ResetReviewPanel()
  out.dylan("ResetReviewPanel")
  UIComponent(g_hud):DestroyChildren()
end

function DockHudRelative(x, y, docking)
  return hud_manager.HudDockOriginAndOffset(x, y, this:Width(), this:Height())
end

function CheckDeploymentUpdate(current_time)
  if BattleUI.IsSpectator() then
    return
  end
  if is_battle_multiplayer and BattleUI.HasEnteredDeployment() == true then
    local num_ready = CheckMultiplayerReadyPlayers()
    local time_since_clicked = 0
    if g_deployment_start_time then
      time_since_clicked = current_time / 1000 - g_deployment_start_time
      if time_since_clicked > max_deployment_time then
        BattleUI.InformOfDeploymentFinished()
      end
    end
    local deployment_panel = panel_manager.IsPanelOpen("finish_deployment")
    if deployment_panel ~= nil then
      UIComponent(deployment_panel):LuaCall("UpdateMultiplayerDeploymentInformation", num_ready, time_since_clicked / max_deployment_time)
    end
  end
end

function CheckMultiplayerReadyPlayers()
  local num_ready = BattleUI.NumHumansRequestingNextPhase()
  if g_deployment_start_time == nil and num_ready ~= 0 then
    g_deployment_start_time = BattleUI.InformOfDeploymentCountdownBegun()
  end
  return num_ready
end

function ShowPersistentPanels(is_multiplayer, is_tutorial)
  out.dylan("showing menu bar")
  local l_menu_bar_panel = Component.CreateFromLayout(g_common_layouts_path .. g_menu_bar_name, g_menu_bar_name, Address, 0, 0)
  return UIComponent(l_menu_bar_panel):LuaCall("InitialiseMenuBar", BattleUI, is_multiplayer, is_tutorial)
end

function ChangeAdvicePanelDisplay(show_not_hide, requesting_component)
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangeAdvicePanelDisplay", show_not_hide, requesting_component)
end

function ChangeChatPanelDisplay(show_not_hide, requesting_component)
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangeChatPanelDisplay", show_not_hide, requesting_component)
end

function ChangePlayerListDisplay(show_not_hide, requesting_component)
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangePlayerListDisplay", show_not_hide, requesting_component)
end

function HidePersistentPanel(hide_menu_bar_too)
  out.dylan("HidePersistentPanel called")
  if this:Find(g_menu_bar_name, false) ~= nil then
    local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name, false))
    menu_bar_panel:LuaCall("HidePersistentPanels", BattleUI, false)
    if hide_menu_bar_too == true then
      menu_bar_panel:SetVisible(false)
    else
      menu_bar_panel:SetVisible(true)
    end
  end
end

function HideSelectionBox()
  local selection = this:Find("box_selection")
  if selection ~= nil then
    selection = UIComponent(selection)
    selection:SetVisible(false)
  end
end

function HidePausePanel()
  if g_paused_panel ~= nil then
    Component.Destroy(g_paused_panel)
    g_paused_panel = nil
  end
end

function ClearDeploymentPanels()
  local deployment_panel = panel_manager.IsPanelOpen("finish_deployment")
  if deployment_panel ~= nil then
    panel_manager.ClosePanel("finish_deployment")
  end
end

function ClearConflictPanels()
  panel_manager.CloseAllPanels()
end

function ShowPostBattleDetails()
  if g_post_battle_details == nil then
    g_post_battle_details = Component.CreateFromLayout(g_common_layouts_path .. g_post_battle_details_name, g_post_battle_details_name, Address, 0, 0)
  else
    print("ShowPostBattleDetails already exists!")
  end
end

function ShowBattleMultiplayerDisconnect(localised_message, fatal)
  out.dylan("showing battle disconnect panel")
  if fatal then
    ClearConflictPanels()
    panel_manager.OpenPanel("dialogue_box", nil, "Initialise", localised_message, function()
      BattleUI.ExitBattle()
    end)
  else
    panel_manager.OpenPanel("dialogue_box", nil, "Initialise", localised_message)
  end
end

function ShowDeploymentPopup(is_multiplayer, is_spectator)
  local deployment_panel = panel_manager.IsPanelOpen("finish_deployment")
  if deployment_panel == nil then
    out.dylan("++create deployment++")
    panel_manager.OpenPanel("finish_deployment", nil, "InitDeploymentPanel", is_multiplayer, is_spectator)
  end
end

function SetDeploymentPopupAsDeploymentStart()
  local deployment_panel = panel_manager.IsPanelOpen("finish_deployment")
  if deployment_panel ~= nil then
    UIComponent(deployment_panel):LuaCall("ShowStartDeployment")
  end
end

function ShowPostBattleResultsPopup(PostBattleInfo)
  HidePersistentPanel(true)
  if g_battle_results_popup == nil then
    print("Showing battle results popup")
    g_battle_results_popup = Component.CreateFromLayout(g_layouts_path .. g_battle_results_popup_name, g_battle_results_popup_name, Address, 0, 0)
    UIComponent(g_battle_results_popup):LuaCall("InitialisePostbattle", PostBattleInfo)
  end
end

function ClearBattleResultsPopup()
  out.dylan("ClearBattleResultsPopup")
  print("Clearing the post battle results pop up " .. g_battle_results_popup_name)
  g_battle_results_popup:LuaCall("ClearResultPopup")
  Component.Destroy(g_battle_results_popup)
  g_battle_results_popup = nil
  BattleUI.DestroyBattleChat()
end

function DismissBattleResult(goto_frontend)
  message_handler.ClearMessagesFromEnv()
  out.dylan("DismissBattleResult")
  panel_manager.ClosePanel(g_battle_summary_popup_name)
  if goto_frontend == nil then
    goto_frontend = true
  end
  BattleUI.InformOfBattleSummaryDismiss(goto_frontend)
end

function ClosePopup(which)
  print("Closing pop-up " .. tostring(which))
  if which ~= nil then
    if which == g_battle_results_popup then
      Component.Destroy(g_battle_results_popup)
      g_battle_results_popup = nil
      BattleUI.InformOfBattleSummaryDismiss()
      if BattleUI.IsE3DemoReplay() then
        BattleUI.ExitBattle()
      end
    else
      out.dylan("closing results via: panel manager")
      panel_manager.ClosePanel(which)
    end
  end
end

function HideEscapeMenu()
  ShowEscapeMenu()
end

function ShowEscapeMenu()
  out.dylan("ShowEscapeMenu")
  local panel
  if BattleUI.IsDeploymentOrConflict() then
    HideSelectionBox()
    BattleUI.ExplicitlyCancelMouseHeld()
    panel = panel_manager.OpenPanel("esc_menu_battle")
    if panel ~= nil then
      BattleUI.Pause()
      UIComponent(panel):InterfaceFunction("InitializeMenu")
      UIComponent(panel):StealShortcutKey("ESCAPE")
    end
  end
  return panel
end

function ReturnToBattleFromEscapeMenu()
  HideEscapeMenu()
end

function ForceEscapeMenuShow()
  if BattleUI.IsDeploymentOrConflict() then
    HideSelectionBox()
    BattleUI.ExplicitlyCancelMouseHeld()
    if not panel_manager.IsPanelOpen("esc_menu_battle") then
      local panel = panel_manager.OpenPanel("esc_menu_battle")
      UIComponent(panel):InterfaceFunction("InitializeMenu")
      UIComponent(panel):StealShortcutKey("ESCAPE")
    end
  end
end

function ForceEscapeMenuHide()
  if BattleUI.IsDeploymentOrConflict() and panel_manager.IsPanelOpen("esc_menu_battle") then
    panel_manager.ClosePanel("esc_menu_battle")
  end
end

function ExitBattle()
  BattleUI.ExitBattle()
  ClearDeploymentPanels()
end

function HandleDrop(handle_drop_table)
  local draggable_elements = {
    this:Find(g_chat_panel_name, false),
    this:Find(g_player_list_panel_name, false),
    this:Find("radar")
  }
  for i, v in ipairs(handle_drop_table) do
    for index, element in ipairs(draggable_elements) do
      if element == v.Address then
        v.Handled = true
      end
    end
  end
  return handle_drop_table
end

function SaveCurrentModules()
  out.dylan("SaveCurrentModules")
  message_handler.StoreMessages()
end

function RestoreSavedModules()
  out.dylan("RestoreSavedModules")
  local minimal_hud = BattleUI.IsMinimisedHUD()
  hud_manager.RegisterHud(g_hud, false)
  message_handler.ReInitialiseStackbase(minimal_hud and 38 or 0)
  message_handler.RestoreMessages()
end

function RegisterBattleHud(hud_component)
  hud_manager.RegisterHud(hud_component, false)
end
