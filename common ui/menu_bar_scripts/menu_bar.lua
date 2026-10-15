local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local button_chat = UIComponent(UIComponent(Component.Root()):Find("button_hud_chat"))
local button_advisor_male = UIComponent(this:Find("button_show_advice_male"))
local button_advisor_female = UIComponent(this:Find("button_show_advice_female"))
local dist_from_hud = 50
local g_common_layouts_path = "data/ui/common UI/"
local g_advice_and_options_panel_name = "advice_interface"
local g_player_list_panel_name = "multiplayer_player_list"
local g_chat_panel_name = "multiplayer_chat"
local g_advice_and_options_panel, g_player_list_panel, g_chat_panel
local online = true
local m_UIAccess
local utilities = require("Utilities")
local hud_manager = HudManager
local g_is_tutorial = false

function InitialiseMenuBar(UIAccess, is_multiplayer, is_tutorial)
  out.dylan("InitialiseMenuBar. is_multiplayer is: " .. tostring(is_multiplayer))
  m_UIAccess = UIAccess
  online = m_UIAccess.IsOnline()
  g_is_tutorial = UIAccess.IsTutorial()
  SetButtonsVisibility(is_multiplayer)
  AlignMenuBar()
  local x_offset_from_screen_edge = 15
  if online then
    ChangeChatPanelDisplay(true, this, x_offset_from_screen_edge, -dist_from_hud)
    ChangePlayerListDisplay(true, this, x_offset_from_screen_edge, this:Height())
  end
  if not is_multiplayer then
    return ChangeAdvicePanelDisplay(false, this, x_offset_from_screen_edge, this:Height(), true)
  end
end

function AlignMenuBar()
end

function SetButtonsVisibility(is_multiplayer)
  out.dylan("SetButtonsVisibility")
  button_chat:SetVisible(online and m_UIAccess.IsTutorial() == false)
  if is_multiplayer or g_is_tutorial then
    button_advisor_male:SetVisible(false)
    button_advisor_female:SetVisible(false)
  else
    button_advisor_female:SetState("inactive")
    button_advisor_male:SetState("inactive")
  end
end

function ChangeAdvicePanelDisplay(show_not_hide, requesting_component, x_offset, y_offset, set_inactive)
  if nil == g_advice_and_options_panel then
    g_advice_and_options_panel = Component.CreateFromLayout(g_common_layouts_path .. g_advice_and_options_panel_name, g_advice_and_options_panel_name, Component.Root(), 0, 0)
    UIComponent(g_advice_and_options_panel):LuaCall("InitialiseAdvisorPanel", is_multiplayer, m_UIAccess.MultiplayerBaseInterface(), m_UIAccess.RetrieveGameCore())
  end
  UIComponent(g_advice_and_options_panel):LuaCall("ChangeFadingPanelVisibility", show_not_hide)
  return g_advice_and_options_panel
end

function ChangeChatPanelDisplay(show_not_hide, requesting_component, x_offset, y_offset)
  if g_chat_panel == nil then
    g_chat_panel = Component.CreateFromLayout(g_common_layouts_path .. g_chat_panel_name, g_chat_panel_name, Component.Root(), 0, 0)
    UIComponent(g_chat_panel):InterfaceFunction("InitialiseChatWindowFromLua", false, false, false, false)
    hud_manager.MoveRelativeToHUD(g_chat_panel, hud_manager.g_left, hud_manager.g_bottom)
    MoveComponentByOffset(g_chat_panel, x_offset, y_offset)
  end
  UIComponent(g_chat_panel):InterfaceFunction("ChangeFadingPanelVisibilityFromLua", show_not_hide)
end

function ChangePlayerListDisplay(show_not_hide, requesting_component, x_offset, y_offset)
  if g_player_list_panel == nil then
    g_player_list_panel = Component.CreateFromLayout(g_common_layouts_path .. g_player_list_panel_name, g_player_list_panel_name, Component.Root(), 0, 0)
    UIComponent(g_player_list_panel):InterfaceFunction("InitialiseMultiplayerPlayerList")
    hud_manager.MoveRelativeToHUD(g_player_list_panel, hud_manager.g_left, hud_manager.g_centre)
    MoveComponentByOffset(g_player_list_panel, x_offset, y_offset)
  end
  UIComponent(g_player_list_panel):InterfaceFunction("ChangeFadingPanelVisibilityFromLua", show_not_hide)
end

function MoveComponentByOffset(component_address, x_offset, y_offset)
  local x_offset = x_offset or 0
  local y_offset = y_offset or 0
  local current_posx, current_posy = UIComponent(component_address):Position()
  UIComponent(component_address):MoveTo(current_posx + x_offset, current_posy + y_offset)
end

function ChangeVisibilityButtonState(button, is_highlighted, requesting_component, is_inactive)
  local set_inactive = is_inactive or nil
  if button ~= nil then
    if set_inactive ~= nil then
      button:LuaCall("ChangeInactiveState", set_inactive)
    else
      button:LuaCall("ChangeHighlightState", is_highlighted, requesting_component)
    end
  else
    out.dylan("we looked for a button, couldn't find it. Searched for: " .. button_lookup)
  end
end

function HidePersistentPanels()
  out.dylan("HidePersistentPanels " .. tostring(show_not_hide))
  if g_advice_and_options_panel ~= nil then
    UIComponent(g_advice_and_options_panel):SetVisible(false)
  end
  if g_player_list_panel ~= nil then
    UIComponent(g_player_list_panel):SetVisible(false)
  end
  if g_chat_panel ~= nil then
    UIComponent(g_chat_panel):SetVisible(false)
  end
end

function ChangeMenuButtonActive(enabled)
  local menu_button = UIComponent(this:Find("button_menu"))
  if enabled == false then
    menu_button:SetState("inactive")
  else
    menu_button:SetState("unselected")
  end
end

function DisplayOptionsMenu()
  out.dylan("displaying options menu")
  UIComponent(Component.Root()):LuaCall("ShowEscapeMenu", parent)
end

function DisplayAdvice()
  out.dylan("toggling advice")
  if g_advice_and_options_panel then
    local is_visible = UIComponent(g_advice_and_options_panel):Visible()
    UIComponent(g_advice_and_options_panel):LuaCall("ChangeFadingPanelVisibility", not is_visible)
  end
end
