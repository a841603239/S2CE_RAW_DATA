local utils = require("Utilities")
local this = UIComponent(Address)
local advice_text_panel = UIComponent(this:Find("advice_text_panel"))
local portrait_parent = UIComponent(this:Find("advisor_portrait_parent"))
local panel_mode = "advice_mode"
local current_advice_mode = "both"
local shader_cleared = false
local UIAccess = {}
local can_access_main_menu_function

function InitialiseAdvisorPanel(is_multiplayer, multiplayer_base_interface, game_core)
  is_multiplayer = is_multiplayer or false
  if BattleUI ~= nil then
    SetAsBattlePanel()
  else
    SetAsCampaignPanel()
  end
  SetAsAdvicePanel()
end

function AdvicePanelAddress()
  return advice_text_panel:Address()
end

function SetPanelMode(mode_to_set)
  if mode_to_set == "advice_mode" then
    SetAsAdvicePanel()
  else
    out.dylan("ERROR! trying to set the advice panel to an invalid mode.")
    SetAsAdvicePanel()
  end
end

function SetAsAdvicePanel()
  panel_mode = "advice_mode"
  advice_text_panel:SetVisible(true)
end

function SetAsBattlePanel()
  out.dylan("setting advisor as battle panel")
  UIAccess = BattleUI
end

function SetAsCampaignPanel()
  out.dylan("setting advisor as campaign panel")
  UIAccess = CampaignUI
  
  function can_access_main_menu_function()
    CampaignUI.PlayerInControl()
  end
end

function IsInChatMode()
  out.dylan("advice panel mode: " .. panel_mode)
  if panel_mode == "chat_mode" then
    return true
  else
    return false
  end
end

function ChangeAdviceSettings(new_advice_setting)
  if current_advice_mode ~= new_advice_setting then
    out.dylan("New advice setting: " .. new_advice_setting)
    current_advice_mode = new_advice_setting
    UIAccess.ChangeAdviceMode(current_advice_mode)
  end
end

function AdviceHasBeenDismissed()
  if not UIAccess.IsTutorial() then
    this:StealShortcutKey("ESCAPE", false)
  end
  UIComponent(Component.Root()):LuaCall("ChangeAdvicePanelDisplay", false)
end

function DismissCurrentAdvice(from_end_turn)
  out.dylan("DismissCurrentAdvice.")
  UIAccess.DismissCurrentAdvice(from_end_turn)
end

function ShowPanelIsUpdated()
  utils.PropagateShader(portrait_parent:Address(), "glow_pulse_t0", 1, 2, 1)
  shader_cleared = false
end

function ClearPanelShader()
  if shader_cleared == false then
    utils.PropagateShader(portrait_parent:Address(), "normal_t0")
    shader_cleared = true
  end
end

function ChangeAdvisorButtonState(button_name, state)
  local button_to_change = UIComponent(this:Find(button_name))
  button_to_change:SetState(state)
end

function ChangeFadingPanelVisibility(visible)
  if visible == true and not UIAccess.IsTutorial() then
    this:StealShortcutKey("ESCAPE")
  end
  this:SetVisible(visible)
end

this:SetGlobal("OnKey", function(key, v, ended)
  if key == "ESCAPE" and ended then
    DismissCurrentAdvice(false)
  end
end)
