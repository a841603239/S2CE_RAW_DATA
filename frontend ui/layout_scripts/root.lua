system.ClearRequiredFiles()
package.path = ";?.lua;data/ui/templates/?.lua;data/ui/?.lua"
local utils = require("Utilities")
local this = UIComponent(Address)
local g_tooltip_obj, g_tooltip_template, mp_frame
local bg = UIComponent(this:Find("layout"))
bg:SetImageColour(0, 0, 0, 0, 255)
bg:SetImageMetrics(0, 0, 0, FrontEnd.ScreenSize())

function OnAdoptChild(child)
  if child ~= g_tooltip_obj and g_tooltip_obj ~= nil then
    Component.Adopt(g_tooltip_obj)
  end
end

function SetTooltipText(addr, text)
  if g_tooltip_obj == nil and 0 < #text then
    SetTooltip("Tooltip")
  end
  if g_tooltip_obj and g_tooltip_template == "Tooltip" then
    UIComponent(g_tooltip_obj):LuaCall("SetText", addr, text)
    Component.Adopt(g_tooltip_obj)
  end
  return g_tooltip_obj
end

local tooltip_paths = {
  Tooltip = "data/ui/common ui/Tooltip",
  unitcard_tooltip = "data/ui/common ui/unitcard_tooltip",
  TechTreeItem_Tooltip = "data/ui/campaign ui/TechTreeItem_Tooltip",
  Minister_tooltip = "data/ui/campaign ui/Minister_tooltip",
  TechTreeItem_Tooltip = "data/ui/campaign ui/TechTreeItem_Tooltip",
  Diplomacy_region_tooltip = "data/ui/campaign ui/Diplomacy_region_tooltip",
  tax_breakdown_tooltip = "data/ui/campaign ui/tax_breakdown_tooltip",
  campaign_map_tooltip = "data/ui/campaign ui/campaign_map_tooltip",
  recruitment_effects_tooltip = "data/ui/campaign ui/recruitment_effects_tooltip"
}

function SetTooltip(template)
  if g_tooltip_template ~= template then
    if g_tooltip_obj ~= nil then
      local tmp_tooltip_obj = g_tooltip_obj
      g_tooltip_obj = nil
      g_tooltip_template = nil
      Component.Destroy(tmp_tooltip_obj)
      if g_tooltip_obj ~= nil then
        return nil
      end
    end
    g_tooltip_obj = Component.CreateFromLayout(tooltip_paths[template], template, Address, 0, 0)
    Component.RegisterTooltipObject(g_tooltip_obj)
    utils.PositionTooltip(g_tooltip_obj)
    g_tooltip_template = template
  end
  return g_tooltip_obj
end

function OnDestroyed()
  utils.UnRequire("Utilities")
  utils.UnRequire("CoreUtils")
end

function Quit()
  if defined.demo == true then
    TransitionTo("demo_movies", nil, "quit")
  else
    FrontEnd.Quit()
  end
end

function CentreMenu(menu)
  local sw, sh = FrontEnd.ScreenSize()
  local w, h = menu:Dimensions()
  this:MoveTo((sw - w) / 2, (sh - h) / 2)
end

function OnShortcut(func, ended)
  if func == "voice_chat" then
    FrontEnd.EnableVoiceChat(not ended)
  end
end

function OnKey(key, v, ended)
end

function TransitionBack()
  this:InterfaceFunction("TransitionBack")
end

function TransitionTo(menu, transitioning_back, ...)
  this:InterfaceFunction("TransitionTo", menu, ...)
end

function TransitionToMP(menu, transitioning_back, ...)
  this:InterfaceFunction("TransitionToMP", menu, ...)
end

function StartDefaultCampaign()
  FrontEnd.StartDefaultCampaign()
end

function StartDefaultLand()
  FrontEnd.StartDefaultLandBattle()
end

function StartDefaultNaval()
  FrontEnd.StartDefaultSeaBattle()
end

function StartDefaultFort()
  FrontEnd.StartDefaultFortBattle()
end

local m_msg_box

function ShowMessageBox(title, msg, ok_callback, cancel_callback)
  HideMessageBox()
  FrontEnd.TriggerMessageBoxOpenedEvent()
  local panel = UIComponent(Component.CreateFromLayout("data/ui/frontend ui/message_box", "message_box", Address))
  if ok_callback == nil and cancel_callback == nil then
    ok_callback = HideMessageBox
  end
  panel:LuaCall("Initialise", title, msg, ok_callback, cancel_callback)
  local tw, th = this:Dimensions()
  local w, h = panel:Dimensions()
  panel:MoveTo((tw - w) / 2, (th - h) / 2)
  this:LockPriority(panel:Priority())
  m_msg_box = panel
end

function HideMessageBox()
  if m_msg_box ~= nil then
    Component.Destroy(m_msg_box:Address())
    m_msg_box = nil
    this:UnLockPriority()
  end
end

function NetworkError(msg, transition_back, is_error)
  if is_error == nil then
    is_error = true
  end
  if transition_back == true then
    out.tom("Transitioning back")
    TransitionBack()
  end
  out.tom("Showing error box")
  this:UnLockPriority()
  ShowMessageBox(is_error and FrontEnd.LocalisationString("network_error_title") or " ", msg, HideMessageBox)
end

function StartCurrentCampaign()
  FrontEnd.StartCurrentCampaign()
  HideMessageBox()
end

function LegendarySaveOverwriteWarning(title, message)
  ShowMessageBox(title, message, StartCurrentCampaign, HideMessageBox)
end

function AcceptEndTutorials()
  FrontEnd.CancelFrontendTutorial()
  HideMessageBox()
end

function EndFrontendTutorial(title, message)
  ShowMessageBox(title, message, AcceptEndTutorials, HideMessageBox)
end

function CallClearSkillTree()
  FrontEnd.ClearSkillTree()
  HideMessageBox()
end

function ConfirmAvatarReset()
  FrontEnd.ResetAvatar()
  HideMessageBox()
end

function RequestAvatarReset(title, msg)
  ShowMessageBox(title, msg, ConfirmAvatarReset, HideMessageBox)
  local txt = UIComponent(m_msg_box:Find("txt"))
  local txt_details = {}
  txt_details.HAlign = "left"
  txt_details.XOffset = 10
  txt:SetStateTextDetails(txt_details)
end

function ClearSkillTreeMessageBox(title, message)
  ShowMessageBox(title, message, CallClearSkillTree, HideMessageBox)
end

function ConfirmBattleTypeChange()
  HideMessageBox()
  local setup = UIComponent(this:Find("mp_battle_setup"))
  setup:InterfaceFunction("ConfirmBattleTypeChange")
end

function DeclineBattleTypeChange()
  HideMessageBox()
  local setup = UIComponent(this:Find("mp_battle_setup"))
  setup:InterfaceFunction("DeclineBattleTypeChange")
end

function RequestBattleTypeChange(title, msg)
  ShowMessageBox(title, msg, ConfirmBattleTypeChange, DeclineBattleTypeChange)
end

this:StealShortcutKey("ESCAPE")

function GainPasswordForInvitedGame(invite_for_battle)
  local pwd = UIComponent(Component.CreateFromLayout("data/ui/frontend ui/password_entry", "password_entry", Address))
  pwd:LuaCall("Initialise", nil, false, 0)
  this:LockPriority(pwd:Priority())
end

function InitState()
end

function CheckOnlineStatus(is_battle)
  local current_game_type = FrontEnd.MPCurrentGameType()
  if current_game_type ~= nil then
    if current_game_type ~= "quick_battle" then
      TransitionToMP("mp_avatar_general")
    elseif is_battle then
      TransitionToMP("mp_matchmaking")
    end
  end
end

function InviteJoinSuccess(invite_for_battle)
  local online_mode = FrontEnd.MPIsOnline()
  out.tom("Join success result recieved, battle = ", tostring(invite_for_battle))
  if online_mode == true then
    TransitionTo("multiplayer_online", nil, false, true, invite_for_battle == false)
  elseif online_mode == false then
    TransitionTo("multiplayer_lan", nil, true, true, invite_for_battle == false)
  end
end

function LoggedOut(reason)
  if m_msg_box ~= nil then
    this:Adopt(m_msg_box:Address())
  end
  if reason == 1 then
    ShowMessageBox(FrontEnd.LocalisationString("network_error_title"), FrontEnd.LocalisationString("network_error_internal_controller_disconnection"))
  end
end

function ClosePopup(address)
  if g_unit_info_panel and address == g_unit_info_panel.Component then
    Component.Destroy(g_unit_info_panel.Component)
    g_unit_info_panel = nil
    this:UnLockPriority()
  end
end

function ChangeChatPanelDisplay(show_not_hide, x_offset, y_offset)
end

function OrderChildrenByPriority()
  local child_list = {}
  for i = 0, this:ChildCount() - 1 do
    child_list[#child_list + 1] = this:Find(i)
  end
  for i = 1, #child_list do
    if UIComponent(child_list[i]):Id() == "tutorial_halo_group" then
      local tutorial_halo_group = table.remove(child_list, i)
      child_list[#child_list + 1] = tutorial_halo_group
      break
    end
  end
  for i = 1, #child_list do
    if UIComponent(child_list[i]):Id() == "browser" then
      local browser = table.remove(child_list, i)
      child_list[#child_list + 1] = browser
      break
    end
  end
  this:ReorderChildren(child_list)
end
