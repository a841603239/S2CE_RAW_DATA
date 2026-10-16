package.path = ";?.lua;data/ui/templates/?.lua;data/ui/?.lua"
local utils = require("Utilities")
local message_handler = MessageManager
local huds = HudManager
CampaignUI.ID = "CampaignUI"
local this = UIComponent(Address)
local cursor = Cursor()
local season_states = {
  "summer",
  "winter",
  "spring",
  "autumn"
}
local SECONDS_BEFORE_WAITING_DIALOG = 10
local MP_RECONNECT_MSG = 0
local MP_SAVE_CONFIRM_MSG = 1
local MP_PREBATTLE_SELECTION_MSG = 2
local mp_waiting_for_load = false
local g_multiplayer_timer_active = false
local g_end_turn_timer = UIComponent(this:Find("end_turn_timer"))
local g_orders_layout = UIComponent(this:Find("orders layout"))
local tabgroup = UIComponent(this:Find("TabGroup"))
local last_priority
local panel_manager = PanelManager
g_current_manager = nil
local g_campaign_result_component, g_character_ptr_for_info
g_hud = nil
g_selected_entity = nil
g_tab_selection = nil
local g_layouts_path = "data/ui/campaign ui/"
local g_common_layouts_path = "data/ui/common UI/"
local g_advice_and_options_panel_name = "advice_interface"
local g_advice_and_options_panel
local g_menu_bar_name = "menu_bar"
local g_last_diplomatic_negotiation, g_tooltip_obj
local g_tooltip_methods = {
  standard = {
    name = "data/ui/common ui/Tooltip",
    func = function(addr, text)
      UIComponent(g_tooltip_obj):LuaCall("SetText", addr, text, CampaignUI)
    end
  },
  unitcard = {
    name = "data/ui/common ui/unitcard_tooltip",
    func = nil
  },
  technology = {
    name = "data/ui/campaign ui/TechTreeItem_Tooltip",
    func = nil
  },
  minister = {
    name = "data/ui/campaign ui/Minister_tooltip",
    func = nil
  },
  building = {
    name = "data/ui/campaign ui/TechTreeItem_Tooltip",
    func = nil
  },
  dipl_region = {
    name = "data/ui/campaign ui/Diplomacy_region_tooltip",
    func = nil
  },
  tax_income = {
    name = "data/ui/campaign ui/tax_breakdown_tooltip",
    func = nil
  },
  map_piece = {
    name = "data/ui/campaign ui/campaign_map_tooltip",
    func = nil
  },
  recruitment_effects = {
    name = "data/ui/campaign ui/recruitment_effects_tooltip",
    func = nil
  },
  trade_route = {
    name = "data/ui/campaign ui/trade_route_tooltip",
    func = nil
  }
}
local g_tooltip_method
local g_log_hud_position = false
local g_refresh_functions = {}
local g_previous_refresh_tick, g_building_key_for_info, g_mp_message_box, g_disconnection_dialog
local TimeString = utils.TimeString
local can_open_diplomacy = true
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShaneOutputFocused(output)
  out.shane(output)
end

function SettlementLootingOptions(info)
  if not panel_manager.IsPanelOpen("settlement_captured") then
    ClearPopUpPreBattle()
    ClearMoviePanel()
    panel_manager.OpenPanel("settlement_captured", nil, "Initialise", info)
  end
end

function ClearSettlementLootingOptions(info)
  if panel_manager.IsPanelOpen("settlement_captured") then
    panel_manager.ClosePanel("settlement_captured")
  end
end

function ClearMoviePanel()
  if panel_manager.IsPanelOpen("event_movie_panel") then
    panel_manager.ClosePanel("event_movie_panel")
  end
end

function NotifyDropInMatchCandidateFound()
  local c = UIComponent(Component.CreateFromLayout("ui/common ui/panel_dropin_requester", "panel_dropin_requester", Address, 0, 0))
  c:LuaCall("Initialise")
  huds.MoveRelativeToHUD(c:Address(), huds.g_centre, huds.g_centre)
end

function SetUIForRebellions(enable)
  local buttons_to_disable = {
    UIComponent(this:Find("button_missions")),
    UIComponent(this:Find("button_diplomacy")),
    UIComponent(this:Find("button_missions")),
    UIComponent(this:Find("button_finance")),
    UIComponent(this:Find("button_tech")),
    UIComponent(this:Find("build_browser"))
  }
  for i, v in ipairs(buttons_to_disable) do
    v:SetState(enable and "Unselected" or "Inactive")
  end
  UIComponent(g_hud):LuaCall("ReassignHudFlags")
end

function ShowEnlistGeneral(military_force)
  panel_manager.OpenPanel("enlist_commander", nil, "InitEnlistCommander", false, military_force)
end

function ShowEnlistAdmiral(military_force)
  panel_manager.OpenPanel("enlist_commander", nil, "InitEnlistCommander", true, military_force)
end

function ShowEnterRevolutionaryRegionPopup(data)
  local dialog = panel_manager.OpenPanel("dialogue_box", nil, "Initialise", CampaignUI.LocalisationString("enter_contested_region_warning"), function()
    CampaignUI.EnterRevolutionaryRegion(data)
  end, function()
  end)
end

function TooltipMethod()
  return g_tooltip_method
end

function SetTooltipMethod(method)
  if g_tooltip_method ~= method then
    ShaneOutput("Changing tooltip method to: " .. tostring(method))
  end
  if g_tooltip_method == nil or g_tooltip_method ~= method then
    if g_tooltip_obj ~= nil then
      local tmp_tooltip_obj = g_tooltip_obj
      g_tooltip_obj = nil
      g_tooltip_method = nil
      Component.Destroy(tmp_tooltip_obj)
      if g_tooltip_obj ~= nil then
        return nil
      end
    end
    g_tooltip_obj = Component.CreateFromLayout(g_tooltip_methods[method].name, g_tooltip_methods[method].name, Address, 0, 0)
    Component.RegisterTooltipObject(g_tooltip_obj)
    utils.PositionTooltip(g_tooltip_obj)
    g_tooltip_method = method
  end
  return g_tooltip_obj
end

function SetTooltip(text)
  g_tooltip:LuaCall("SetText", text, CampaignUI)
end

local last_tooltip_text

function SetTooltipText(addr, text)
  local report = false
  if last_tooltip_text ~= text then
    report = true
    ShaneOutput([[
>> Tooltip change <<

]])
    ShaneOutput("SetTooltipText: " .. tostring(addr) .. ", " .. tostring(text))
    ShaneOutput("g_tooltip_method = " .. tostring(g_tooltip_method))
    last_tooltip_text = text
  end
  if g_tooltip_method == nil and 0 < #text then
    if report then
      ShaneOutput("Setting tooltip method to standard")
    end
    SetTooltipMethod("standard")
  end
  if g_tooltip_method ~= nil and g_tooltip_obj ~= nil then
    local method = g_tooltip_methods[g_tooltip_method].func
    if report then
      ShaneOutput("Using tooltip method = " .. tostring(method))
    end
    if method ~= nil then
      if report then
        ShaneOutput("g_tooltip_obj = " .. tostring(g_tooltip_obj))
      end
      method(addr, text)
    end
  else
    ShaneOutput("Can't set tooltip because there is no tooltip object set.")
  end
  if report then
    ShaneOutput([[


>> Tooltip change end <<

]])
  end
end

function GetTooltipComponent()
  return g_tooltip_obj
end

function UpdateMapCursor(faction_details, line1, line2, line3, force_above, trade_routes)
  if 0 < #line1 then
    if trade_routes and 0 < #trade_routes then
      SetTooltipMethod("trade_route")
      return g_tooltip_obj
    else
      SetTooltipMethod("map_piece")
      UIComponent(g_tooltip_obj):LuaCall("SetText", Address, CampaignUI, faction_details, line1, line2, line3, force_above, trade_routes)
    end
  elseif g_tooltip_method == "map_piece" or g_tooltip_method == "trade_route" then
    g_tooltip_method = nil
    UIComponent(g_tooltip_obj):SetVisible(false)
  end
end

function RemoveMapCursor()
  if g_tooltip_method == "map_piece" then
    ShaneOutput("Removing map piece tooltip")
    g_tooltip_method = nil
    if g_tooltip_obj ~= nil then
      UIComponent(g_tooltip_obj):SetVisible(false)
    end
  end
end

function DockHudRelative(x, y, docking)
  return huds.HudDockOriginAndOffset(x, y, this:Width(), this:Height())
end

function StoreMessages()
  message_handler.StoreMessages()
end

function RestoreMessages()
  message_handler.RestoreMessages()
end

function CheckForAutoOpenMessages(force_reopen)
  message_handler.CheckForAutoOpen(force_reopen)
end

function ShownMessage()
  return message_handler.ShownMessage()
end

function StoreMessages()
  message_handler.StoreMessages()
end

function PendingAutoShowMessage()
  return message_handler.PendingAutoShowMessage()
end

function OnDestroyed()
  panel_manager.Reset()
  if message_handler.HasMessagesStored() == false then
    message_handler.DestroyAllMessages()
  end
  utils.UnRequire("Utilities")
  utils.UnRequire("Recruitment")
  utils.UnRequire("Construction")
  utils.UnRequire("Huds")
  utils.UnRequire("Agents")
  utils.UnRequire("Army")
  utils.UnRequire("Labels")
  utils.UnRequire("PanelManager")
end

function TaxLevelsChanged(details)
  local region_info_panel = this:Find("region_info", false)
  if region_info_panel ~= nil then
    UIComponent(region_info_panel):LuaCall("Reinitialise")
  end
end

function OnPlayerStartTurn()
  Component.CallByAddress(g_hud, "LuaCall", "OnStartTurn")
end

function ContinueSiege()
  ShaneOutput("..Continuing siege..")
  ClearPopUpPreBattle()
end

function InitState(state)
  ShaneOutput("<><><><><><><><><><><><><><><><><><><><><><><><><>")
  ShaneOutput("<><><><><> InitState called for root! <><><><><><>")
  ShaneOutput("<><><><><><><><><><><><><><><><><><><><><><><><><>")
  g_hud = this:Find("layout")
  mp_waiting_for_load = false
  g_disconnection_dialog = nil
  CampaignUI.DebugViewLuaComponentPtr(g_hud)
  huds.RegisterHud(g_hud, true)
  message_handler.ReInitialiseStackbase(0)
end

function ShowPreBattlePopup(pending_battle)
  if not panel_manager.IsPanelOpen("popup_pre_battle") then
    g_log_hud_position = true
    panel_manager.OpenPanel("popup_pre_battle", nil, "Initialise", pending_battle)
    CampaignUI.DismissHud()
    message_handler.HideAllMessages(true)
  end
end

function ClearPopUpPreBattle()
  g_log_hud_position = false
  if panel_manager.IsPanelOpen("popup_pre_battle") then
    panel_manager.ClosePanel("popup_pre_battle")
  end
  message_handler.HideAllMessages(false)
end

function ShowPostBattlePopup(battle_results)
  if not panel_manager.IsPanelOpen("popup_battle_results") then
    panel_manager.OpenPanel("popup_battle_results", nil, "Initialise", battle_results)
  end
end

function ClearPopUpPostBattle()
  panel_manager.ClosePanel("popup_battle_results")
  if CampaignUI.IsMultiplayer() then
    EnableHUD()
  end
  CampaignUI.RecallHud()
end

function ShowPersistentPanels(is_multiplayer)
  is_multiplayer = is_multiplayer or false
  out.dylan("showing menu bar")
  local menu_bar_panel = Component.CreateFromLayout(g_common_layouts_path .. g_menu_bar_name, g_menu_bar_name, Address, 0, 0)
  return UIComponent(menu_bar_panel):LuaCall("InitialiseMenuBar", CampaignUI, is_multiplayer)
end

function ChangeOptionsMenuButtonActive(enabled)
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangeMenuButtonActive", enabled)
end

function ChangeAdvicePanelDisplay(show_not_hide)
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangeAdvicePanelDisplay", show_not_hide)
end

function ChangeChatPanelDisplay(show_not_hide, requesting_component)
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangeChatPanelDisplay", show_not_hide, requesting_component)
end

function ChangePlayerListDisplay(show_not_hide, requesting_component)
  out.dylan("showing players list. show_not_hide is: " .. tostring(show_not_hide))
  local menu_bar_panel = UIComponent(this:Find(g_menu_bar_name))
  menu_bar_panel:LuaCall("ChangePlayerListDisplay", show_not_hide, requesting_component)
end

function ShowCampaignResultPopup(is_victory, can_continue)
  local result_string = CampaignUI.LocalisationString("defeat")
  if is_victory == true then
    result_string = CampaignUI.LocalisationString("victory")
  end
  if g_campaign_result_component == nil then
    g_campaign_result_component = panel_manager.OpenPanel("campaign_victory", nil, "Initialise", result_string, is_victory, can_continue)
  else
    UIComponent(g_campaign_result_component):LuaCall("Initialise", result_string, is_victory, can_continue)
  end
end

function RemoveCampaignResultPopup()
  panel_manager.ClosePanel("campaign_result")
end

function DismissCurrentAdvice(from_end_turn)
  CampaignUI.DismissCurrentAdvice(from_end_turn)
end

function InitialiseMoviePanel(details)
  out.dylan("InitialiseMoviePanel called - " .. tostring(movie_panel_component))
  message_handler.SetCurrentMessageUnread()
  local movie_panel_component = panel_manager.IsPanelOpen("event_movie_panel")
  if movie_panel_component == nil then
    movie_panel_component = panel_manager.OpenPanel("event_movie_panel", nil, "ShowMovieType", details)
  else
    UIComponent(movie_panel_component):LuaCall("ShowMovieType", details)
  end
  return movie_panel_component
end

function ShowTravelDestinationsPopup(details)
  panel_manager.OpenPanel("travel_destinations", nil, "Initialise", details)
end

function ShowCampaignLostMessage()
  out.dylan("ShowCampaignLostMessage")
  panel_manager.OpenPanel("dialogue_box", nil, "Initialise", CampaignUI.LocalisationString("quit_warning"), function()
    CampaignUI.QuitToMainScreen()
  end)
end

function ShowMoveOptionsPopup(details)
  panel_manager.OpenPanel("move_options", nil, "Initialise", details)
end

function HideMoveOptionsPopup(faction, reason)
  panel_manager.ClosePanel("move_options")
  if reason == nil then
    CampaignUI.FinalisePendingAction()
  elseif reason == "DeclareWar" and CampaignUI.NumberOfAllies(faction) == 0 and CampaignUI.NumberOfAllies(CampaignUI.PlayersFactionKey()) == 0 and CampaignUI.BothHuman(CampaignUI.PlayersFactionKey(), faction) == false then
    CampaignUI.QuickDeclareWar(faction)
    CampaignUI.FinalisePendingAction()
  else
    ToggleDiplomacyPopup(faction)
    local panel = panel_manager.IsPanelOpen("diplomacy_panel")
    UIComponent(panel):LuaCall("AddToNegotiation", reason)
  end
end

function OpenTaxes()
  local region_info = panel_manager.IsPanelOpen("region_info")
  if region_info ~= nil then
    local region_shown = UIComponent(region_info):LuaCall("RegionShown")
    if region_shown ~= nil then
      local finance_panel = panel_manager.IsPanelOpen("finance_screen")
      if finance_panel == nil then
        finance_panel = ShowFinancePopup()
      end
    end
  end
end

function RefreshRegionInfo(addr)
  local component, _, at_top = panel_manager.IsPanelOpen("region_info")
  if component ~= nil and at_top == true then
    panel_manager.ClosePanel("region_info")
    ShowRegionInfo(addr)
  end
end

function ShowRegionInfo(region_ptr)
  if not CampaignUI.RegionInfoDisabled() then
    local region_info_panel, _, at_top = panel_manager.IsPanelOpen("region_info")
    if region_info_panel == nil or not at_top then
      region_info_panel = panel_manager.OpenPanel("region_info", region_ptr, "InitialiseFromDetails", CampaignUI.InitialiseRegionInfoDetails(region_ptr))
    end
    if region_info_panel ~= nil then
      UIComponent(region_info_panel):InterfaceFunction("Initialise", region_ptr)
    end
  end
end

function OnLDblClick()
end

function ClosePopup(which)
  ShaneOutput("Closing popup", which)
  panel_manager.ClosePanel(which)
end

function EnableDiplomacy()
  can_open_diplomacy = true
end

function ToggleDiplomacyPopup(opponent_faction)
  if CampaignUI.IsPlayersTurn() then
    g_log_hud_position = true
    panel_manager.OpenPanel("diplomacy_panel", nil, "Initialise", opponent_faction)
    local dip_panel = UIComponent(this:Find("diplomacy_panel"))
    dip_panel:InterfaceFunction("Opened")
  end
end

function ShowDiplomacyRelationsPopup()
  ToggleDiplomacyRelationsPopup()
end

function SetLastDiplomacyNegotiation(neg)
  if neg ~= nil then
    g_last_diplomatic_negotiation = neg
  end
end

function ShowUnitExchangePopup(show, lhs_character, rhs_character, lhs_garrison, rhs_garrison, cost, max_units_per_navy)
  if show then
    panel_manager.OpenPanel("unit_exchange", nil, "Initialise", lhs_character, rhs_character, lhs_garrison, rhs_garrison, cost, max_units_per_navy)
  else
    panel_manager.ClosePanel("unit_exchange")
  end
end

function ClearUnitExchange()
  if panel_manager.IsPanelOpen("unit_exchange") then
    panel_manager.ClosePanel("unit_exchange")
  end
end

function AIRequestDiplomacy(negotiation, greeting, faction)
  if panel_manager.IsPanelOpen("diplomacy_panel") == nil then
    out.shane("diplomacy_panel (layout.root): AIRequestDiplomacy(), DiplomacyPanel was not open, faction = " .. tostring(faction))
    panel_manager.OpenPanel("diplomacy_panel", nil, "RequestDiplomacy", negotiation, greeting)
    local dip_panel = UIComponent(this:Find("diplomacy_panel"))
    dip_panel:LuaCall("HideDiplomaticRelationsLists")
    dip_panel:InterfaceFunction("Opened")
  else
    out.shane("diplomacy_panel (layout.root): AIRequestDiplomacy(), DiplomacyPanel was already open, faction = " .. tostring(faction))
    local dip_panel = UIComponent(this:Find("diplomacy_panel"))
    dip_panel:LuaCall("RequestDiplomacy", negotiation, greeting)
    dip_panel:LuaCall("HideDiplomaticRelationsLists")
    dip_panel:InterfaceFunction("Opened")
  end
end

function OpenDuelPopup(issued, attacker, targets)
  if issued then
    panel_manager.OpenPanel("agent_action", nil, "Initialise", "duel", attacker, targets)
  else
    panel_manager.OpenPanel("duel_recieved", nil, "InitDetails", attacker, targets)
  end
end

function OpenAgentActionPopup(mode, attacker, targets)
  panel_manager.OpenPanel("agent_action", nil, "Initialise", mode, attacker, targets)
end

function OpenAgentOptionsPopup(attacker, target, actions_bitfield, infiltrate_chance, sabotage_chance)
  panel_manager.OpenPanel("agent_options", nil, "Initialise", attacker, target, actions_bitfield, infiltrate_chance, sabotage_chance)
end

function ShowFinancePopup()
  return panel_manager.OpenPanel("finance_screen", nil, "Initialise")
end

function ShowMissionsPopup()
  panel_manager.OpenPanel("missions", nil, "Initialise")
end

function RefreshMissionsPopup()
  if panel_manager.IsPanelOpen("missions") ~= nil then
    panel_manager.OpenPanel("missions", nil, "Initialise")
  end
end

function OnEndTurnClearPanels()
  if message_handler.DismissAllMessages() then
    panel_manager.CloseAllPanels()
    ClearUnitExchange()
    DismissCurrentAdvice(true)
    if g_tooltip_obj ~= nil then
      Component.Destroy(g_tooltip_obj)
      g_tooltip_obj = nil
      g_tooltip_method = nil
    end
    return true
  end
  return false
end

function ShowPrestige()
  panel_manager.OpenPanel("Prestige", nil, "Initialise")
end

function ShowTechnologies(residence)
  local details = CampaignUI.TechnologyPlayerDetails(residence)
  if details ~= nil then
    panel_manager.OpenPanel("technology", nil, "Initialise", details, CampaignUI, Localisation, false)
  end
end

function ShowResearchingTechnologies(residence, character)
  if ResearchPanelOpen() == true then
    RefreshResearchPanel(residence, character)
  else
    local details = CampaignUI.TechnologyResearchingDetails(character, residence)
    if details ~= nil then
      panel_manager.OpenPanel("technology", character, "Initialise", details, CampaignUI, Localisation, false)
    end
  end
end

function ShowStealingTechnologies(residence, character)
  if StealingPanelOpen() == true then
    RefreshStealingPanel(residence, character)
  else
    local details = CampaignUI.TechnologyStealingDetails(character, residence)
    if details ~= nil then
      panel_manager.OpenPanel("technology", tostring(residence) .. tostring(character), "Initialise", details, CampaignUI, Localisation, true)
    end
  end
end

function RefreshResearchPanel(residence, character)
  ShaneOutput("* RefreshResearchPanel: residence = " .. tostring(residence) .. ", character = " .. tostring(character))
  local technology_panel = panel_manager.IsPanelOpen("technology")
  if technology_panel ~= nil and UIComponent(technology_panel):LuaCall("ResearchingMode") == true then
    UIComponent(technology_panel):LuaCall("Refresh", residence, character)
  end
end

function CloseStealingPanel()
  ShaneOutput("* CloseStealingPanel")
  local technology_panel = panel_manager.IsPanelOpen("technology")
  if technology_panel ~= nil and UIComponent(technology_panel):LuaCall("ResearchingMode") == false then
    panel_manager.ClosePanel("technology")
  end
end

function RefreshStealingPanel(residence, character)
  ShaneOutput("* RefreshStealingPanel: residence = " .. tostring(residence) .. ", character = " .. tostring(character))
  local technology_panel = panel_manager.IsPanelOpen("technology")
  if technology_panel ~= nil and UIComponent(technology_panel):LuaCall("ResearchingMode") == false then
    UIComponent(technology_panel):LuaCall("Refresh", residence, character)
  end
end

function ResearchPanelOpen()
  local panel = panel_manager.IsPanelOpen("technology")
  return panel ~= nil and UIComponent(panel):LuaCall("ResearchingMode") == true
end

function StealingPanelOpen()
  local panel = panel_manager.IsPanelOpen("technology")
  return panel ~= nil and UIComponent(panel):LuaCall("ResearchingMode") == false
end

function ShowBuildingBrowser()
  panel_manager.OpenPanel("building_browser", nil, "Initialise")
end

function ShowCharacterInfoUnitInfo(unit_ptr)
  UIComponent(this:Find("CharacterInfoPopup")):LuaCall("Initialise", character_ptr)
end

function CloseFullCharacterInfo()
  local char_panel = panel_manager.IsPanelOpen("CharacterInfoPopup_Full")
  if char_panel ~= nil then
    panel_manager.ClosePanel("CharacterInfoPopup_Full")
  end
end

function CloseCharacterInfoUnitInfo()
end

function RefreshCharacterInfo(character_ptr)
  local panel, _, is_top = panel_manager.IsPanelOpen("CharacterInfoPopup_Full")
  if panel ~= nil and is_top == true then
    UIComponent(panel):LuaCall("Initialise", character_ptr)
  end
end

function ShowFullCharacterInfo(character_ptr)
  panel_manager.OpenPanel("CharacterInfoPopup_Full", character_ptr, "Initialise", character_ptr)
  g_character_ptr_for_info = character_ptr
end

function CloseCharacterInfo()
end

function ShowCharacterInfo(character_ptr)
  ShaneOutput("Showing character info with address " .. tostring(character_ptr))
  UIComponent(this:Find("CharacterInfoPopup")):LuaCall("Initialise", character_ptr)
  g_character_ptr_for_info = character_ptr
  CampaignUI.OpenInfoPanel("CharacterInfoPopup")
end

function ShowFullUnitInfoCharacterInfo(character_ptr)
  panel_manager.OpenPanel("CharacterInfoPopup_Full", character_ptr, "Initialise", CampaignUI.InitialiseCharacterDetails(character_ptr))
end

function ShowUnitInfoCharacterInfo(character_ptr)
  UIComponent(this:Find("CharacterInfoPopup")):LuaCall("Initialise", character_ptr)
  CampaignUI.OpenInfoPanel("CharacterInfoPopup")
end

function CloseUnitInfoCharacterInfo()
end

function RefreshFortInfo(fort_ptr, building_key)
end

function ShowFullFortInfo(fort_ptr, building_key, fort_details_table)
end

function ShowFortInfo(fort_ptr, building_key, fort_details_table)
  local panel_id = fort_ptr
  if building_key ~= nil then
    panel_id = building_key
  end
  ShaneOutput("ShowFortInfo with fort_ptr " .. tostring(fort_ptr) .. " and building_key " .. tostring(building_key))
  g_building_key_for_info = building_key
  if fort_ptr ~= nil then
    local effects = CampaignUI.FortEffects(fort_ptr, building_key)
    local fort_details = CampaignUI.FortDetails(fort_ptr, building_key)
    UIComponent(this:Find("BuildingInfoPopup")):LuaCall("InitialiseBuildingInfoPanel", true, fort_details.building_key, fort_details.faction_key, fort_details.region_key, fort_details.slot_key, fort_details.Name, fort_details.ShortDescription, "", effects)
  elseif fort_details_table ~= nil then
    local effects = fort_details_table.Effects
    UIComponent(this:Find("BuildingInfoPopup")):LuaCall("InitialiseBuildingInfoPanel", true, fort_details_table.building_key, fort_details_table.faction_key, fort_details_table.region_key, fort_details_table.slot_key, fort_details.Name, fort_details.ShortDescription, "", effects)
  end
  CampaignUI.OpenInfoPanel("BuildingInfoPopup")
end

function RefreshBuildingInfo(building_key, region_key, faction_key, slot_key)
end

function CloseFullBuildingInfo()
end

function CloseBuildingInfo()
end

function ShowFullRecruitableUnitInfo(record_key, faction_key, cost, experience)
end

function ShowRecruitableUnitInfo(record_key, faction_key, cost, experience)
end

function InfoPanelNotUsed()
  CampaignUI.StartInfoPanelCountdown()
end

function ShowFullUnitInfo(unit)
  if unit ~= nil then
    CampaignUI.OpenUnitEncyclopaediaEntry(unit)
  end
end

function CloseFullUnitInfoPopup()
  if panel_manager.IsPanelOpen("UnitInfoPopup_Full") ~= nil then
    panel_manager.ClosePanel("UnitInfoPopup_Full")
  end
end

function CloseUnitInfoPopup()
end

function ShowFullBuildingInfo(building_key, region_key, faction_key, slot_key)
  if building_key ~= nil then
    CampaignUI.OpenBuildingEncyclopaediaEntry(building_key)
  end
end

function ShowBuildingInfo(building_key, region_key, faction_key, slot_key)
  ShaneOutput("ShowBuildingInfo: ")
  ShaneOutput("building_key = " .. tostring(building_key))
  ShaneOutput("faction_key = " .. tostring(faction_key))
  ShaneOutput("region_key = " .. tostring(region_key))
  ShaneOutput("slot_key = " .. tostring(slot_key))
  g_building_key_for_info = building_key
  local panel
  local details = CampaignUI.BuildingRecordDetails(building_key, region_key, faction_key, slot_key)
  if slot_key == nil then
    UIComponent(this:Find("BuildingInfoPopup")):LuaCall("InitialiseBuildingInfoPanel", true, building_key, region_key, faction_key, slot_key, details.Name, details.ShortDescription, "")
  else
    UIComponent(this:Find("BuildingInfoPopup")):LuaCall("InitialiseBuildingInfoPanel", true, building_key, region_key, faction_key, slot_key, details.Name, details.ShortDescription, "")
  end
  if panel ~= nil then
    CampaignUI.TriggerBuildingInfoPanelOpenEvent(UIComponent(panel):Id(), UIComponent(panel):Address())
  end
  CampaignUI.OpenInfoPanel("BuildingInfoPopup")
end

function ShowFullTechInfo(tech_key, region_key, faction_key, slot_key)
end

function ShowTechInfo(tech_key, region_key, faction_key, slot_key)
  ShaneOutput("ShowTechInfo: ")
  ShaneOutput("tech_key = " .. tostring(tech_key))
  ShaneOutput("region_key = " .. tostring(region_key))
  ShaneOutput("faction_key = " .. tostring(faction_key))
  ShaneOutput("slot_key = " .. tostring(slot_key))
  local details = CampaignUI.InitialiseTechDetails(tech_key, region_key, faction_key, slot_key)
  local panel = this:Find("BuildingInfoPopup")
  UIComponent(panel):LuaCall("InitialiseBuildingInfoPanel", false, tech_key, region_key, faction_key, slot_key, details.Name, details.ShortDescription, "")
  if panel ~= nil then
    CampaignUI.TriggerTechnologyInfoPanelOpenEvent(UIComponent(panel):Id(), UIComponent(panel):Address())
  end
  CampaignUI.OpenInfoPanel("BuildingInfoPopup")
end

function addSmallFlagToComponent(flag_path, destinationComponent, x, y)
  images = {}
  images[1] = flag_path
  Component.CreateFromLayout("data/ui/campaign ui/faction_flag_small", "FactionFlag", destinationComponent, x, y, images)
end

local function SetCameraControlPriorities(pri)
  local camera_control_elements = {
    "world_theatres_ButtonGroup",
    "radar arrow L",
    "radar arrow R",
    "radar",
    "globe",
    "zoom_holder"
  }
  for i, v in ipairs(camera_control_elements) do
    UIComponent(this:Find(v)):PropagatePriority(pri)
  end
end

function CreateEndTurnFlagsDisplay(info)
  CloseEndTurnFlagsDisplay(true)
  flags_display = Component.CreateFromLayout("data/ui/campaign ui/ai_turns", "ai_turns", Address, 0, 0)
  UIComponent(flags_display):LuaCall("Initialise", info)
  huds.MoveRelativeToHUD(flags_display, huds.g_top, huds.g_top)
end

function CloseEndTurnFlagsDisplay(dont_close_panels)
  if flags_display ~= nil then
    Component.Destroy(flags_display)
    flags_display = nil
  end
  if dont_close_panels ~= true then
    OnEndTurn()
  end
end

function OnEndTurn()
  panel_manager.CloseAllPanels()
  ClearUnitExchange()
  DismissCurrentAdvice(true)
  if g_tooltip_obj ~= nil then
    Component.Destroy(g_tooltip_obj)
    g_tooltip_obj = nil
    g_tooltip_method = nil
  end
end

function HideEscapeMenu()
  ShowEscapeMenu()
end

function OnShortcut(func, ended)
  out.dylan("reached onShortcut with: " .. tostring(func))
  if func == "voice_chat" then
    CampaignUI.EnableVoiceChat(not ended)
  elseif ended == true then
    if func == "toggle_move_speed" then
      CampaignUI.ToggleMoveSpeed()
    elseif func == "home_zoom" then
      CampaignUI.ZoomToCapital()
    elseif func == "current_selection_order_cancel" then
      CampaignUI.CancelOrderForSelectedCharacter()
    elseif func == "quick_save" and CampaignUI.CanSave() then
      CampaignUI.QuickSave()
    elseif func == "quick_load" then
      CampaignUI.QuickLoad()
    elseif func == "toggle_labels" then
      CampaignUI.ToggleLabels()
    elseif func == "select_next" then
      CampaignUI.NextAutoEntitySelection()
    elseif func == "select_prev" then
      CampaignUI.PreviousAutoEntitySelection()
    elseif func == "toggle_flag_display" then
      CampaignUI.ToggleFlagDisplay()
    elseif func == "auto_merge_units" then
      MergeSelection()
    elseif func == "toggle_sfx" then
      CampaignUI.ToggleSFX()
    end
  end
end

function ShowEscapeMenu()
  CampaignUI.OpenEscapeMenu()
end

function MissionUpdate(mission_details)
  local panel = panel_manager.IsPanelOpen("missions")
  if panel ~= nil then
    UIComponent(panel):LuaCall("UpdateMissions", mission_details)
  end
end

function DialogOpponentDemandsSurrender(title, message, location)
  local timer
  local TIME_TO_MAKE_SURRENDER_DECISION = 10
  if CampaignUI.IsTimedMultiplayerGame() then
    timer = CampaignUI.Time() + TIME_TO_MAKE_SURRENDER_DECISION
  end
  panel_manager.OpenPanel("surrender_dialogue_box", nil, "Initialise", title .. "\n" .. location .. [[


]] .. message, function()
    CampaignUI.PlayerSurrenderDecision(true)
  end, function()
    CampaignUI.PlayerSurrenderDecision(false)
  end, false, timer)
end

function DialogWillGoBankrupt(timer)
  local title = CampaignUI.LocalisationString("will_go_bankrupt_title")
  local message = CampaignUI.LocalisationString("will_go_bankrupt")
  panel_manager.OpenPanel("dialogue_box", nil, "Initialise", title .. [[


]] .. message, function()
    CampaignUI.PlayerIgnoresBankruptcy(true)
  end, function()
    CampaignUI.PlayerIgnoresBankruptcy(false)
  end, false, timer)
end

function SetHudVisible()
  UIComponent(g_hud):SetVisible(true)
end

function ConfirmSave(success)
  if success ~= nil then
    if is_load == true then
      panel_manager.OpenPanel("dialogue_box", nil, "Initialise", success == true and CampaignUI.LocalisationString("load_success") or CampaignUI.LocalisationString("load_fail"))
    elseif not CampaignUI.IsMultiplayer() or CampaignUI.MultiplayerPlayerOutOfTurn() then
      local name = CampaignUI.MultiplayerPlayersName()
      if success == true and name ~= nil then
        MultiplayerMessagePlayerSaved(name .. ": " .. CampaignUI.LocalisationString("save_success"))
      end
    elseif panel_manager.IsPanelOpen("popup_pre_battle") == nil then
      panel_manager.OpenPanel("dialogue_box", nil, "Initialise", success == true and CampaignUI.LocalisationString("save_success") or CampaignUI.LocalisationString("save_fail"), function()
        CampaignUI.MultiplayerSaveConfirm()
      end)
    end
  end
end

function OnUpdatePulse(time)
  local time_seconds = time * 0.001
  if CampaignUI.IsMultiplayer() then
    ProcessMultiplayerMessagePanels(time_seconds)
  end
end

function MultiplayerClearMessageBox(message_type)
  ShaneOutput("** MultiplayerClearMessageBox, message_type = " .. tostring(message_type))
  if g_mp_message_box ~= nil and UIComponent(g_mp_message_box):InterfaceFunction("MessageType") == message_type then
    Component.Destroy(g_mp_message_box)
    g_mp_message_box = nil
  end
end

function MultiplayerMessagePlayerSaved(message)
  if g_mp_message_box == nil then
    g_mp_message_box = Component.CreateFromLayout("ui/Common UI/mp_message_box", "mp_message_box", Address, 0, 0)
    huds.MoveRelativeToHUD(g_mp_message_box, huds.g_right, huds.g_bottom, 0)
    UIComponent(g_mp_message_box):InterfaceFunction("Initialise", MP_SAVE_CONFIRM_MSG, message)
  end
end

function MultiplayerMessageWaitingReconnectUpdate(mp_dialog_ptr, text, time)
  local dialog_text = UIComponent(UIComponent(mp_dialog_ptr):Find("DY_text"))
  local time_to_drop = utils.Max(0, utils.TruncToInt(CampaignUI.RemainingTimeToDrop()))
  dialog_text:SetStateText(text .. [[


]] .. TimeString(time_to_drop))
  return time_to_drop == 0
end

function ProcessMultiplayerMessagePanels(time_seconds)
  if CampaignUI.IsMultiplayer() == true then
    local time_since_tick = CampaignUI.TimeSinceTick()
    if time_since_tick > SECONDS_BEFORE_WAITING_DIALOG then
      if not mp_waiting_for_load and g_mp_message_box == nil then
        local message = CampaignUI.LocalisationString("multiplayer_waiting_reconnect")
        g_mp_message_box = Component.CreateFromLayout("ui/Common UI/mp_message_box", "mp_message_box", Address, 0, 0)
        huds.MoveRelativeToHUD(g_mp_message_box, huds.g_right, huds.g_bottom, 0)
        UIComponent(g_mp_message_box):InterfaceFunction("Initialise", MP_RECONNECT_MSG, message, true)
      end
    else
      MultiplayerClearMessageBox(MP_RECONNECT_MSG)
    end
  end
end

function TurnTimeExpired()
  panel_manager.CloseAllPanels()
  ClearUnitExchange()
  DismissCurrentAdvice(true)
  DialogMultiplayerTimeIsUp()
end

function MultiplayerTimeIsUp()
  OnEndTurnClearPanels()
  CampaignUI.MultiplayerTimeIsUp()
end

function DialogMultiplayerTimeIsUp()
  if panel_manager.IsPanelOpen("dialogue_box") == nil then
    local title = CampaignUI.LocalisationString("multiplayer_time_up_title")
    local message = CampaignUI.LocalisationString("multiplayer_time_up")
    panel_manager.OpenPanel("dialogue_box", nil, "Initialise", title .. [[


]] .. message, MultiplayerTimeIsUp, nil, true, CampaignUI.Time() + 6, true)
  end
end

function MultiplayerUnlimitedTurnBegin(last_player_name)
  local message = CampaignUI.LocalisationString("multiplayer_turn_begin1") .. " " .. last_player_name .. [[


]] .. CampaignUI.LocalisationString("multiplayer_turn_begin2")
  panel_manager.OpenPanel("dialogue_box", nil, "Initialise", message, function()
    CampaignUI.MultiplayerUnlimitedTurnBeginConfirm()
  end)
end

function MultiplayerUnlimitedTurnEnd(next_player_name)
  local message = CampaignUI.LocalisationString("multiplayer_turn_end") .. " " .. next_player_name
  panel_manager.OpenPanel("dialogue_box", nil, "Initialise", message, nil, nil, true)
end

function MultiplayerUnlimitedDismissEndTurnDialog()
  panel_manager.ClosePanel("dialogue_box")
end

function MultiplayerDisconnect(msg)
  if g_disconnection_dialog == nil then
    if panel_manager.IsPanelOpen("dialogue_box") ~= nil then
      panel_manager.ClosePanel("dialogue_box")
    end
    g_disconnection_dialog = panel_manager.OpenPanel("dialogue_box", nil, "Initialise", msg, function()
      CampaignUI.QuitToMainScreen()
    end)
  end
end

function MultiplayerAddTimerToButton(button_ptr, only_show_highlight, green)
  local timer = UIComponent(Component.CreateFromLayout("ui/Common UI/button_timer", "button_timer", button_ptr, 0, 0))
  local parent_name = ""
  if UIComponent(button_ptr):Parent() ~= nil then
    parent_name = UIComponent(UIComponent(button_ptr):Parent()):Id()
  end
  ShaneOutput("Added timer to button: " .. parent_name .. ":" .. UIComponent(button_ptr):Id())
  timer:Resize(UIComponent(button_ptr):Dimensions())
  UIComponent(timer:Find("time_label")):SetVisible(not only_show_highlight)
  local halo = UIComponent(timer:Find("halo"))
  if only_show_highlight and green then
    halo:SetState("green")
  else
    halo:SetState("red")
  end
  halo:ShaderTechniqueSet("highlight_circumference_t0", true, false)
  return timer:Address()
end

function MultiplayerRemoveTimerFromButton(button_ptr)
  local timer_ptr = UIComponent(button_ptr):Find("button_timer", false)
  if timer_ptr then
    Component.Destroy(timer_ptr)
    ShaneOutput("Removed timer from button: " .. UIComponent(button_ptr):Id())
    return true
  else
    ShaneOutput("No timer to remove from button: " .. UIComponent(button_ptr):Id())
  end
  return false
end

function MultiplayerAddSelectedHighlightToButton(button_ptr, green)
  local highlight = UIComponent(Component.CreateFromLayout("ui/Common UI/button_timer", "button_selection_highlight", button_ptr, 0, 0))
  local parent_name = ""
  if UIComponent(button_ptr):Parent() ~= nil then
    parent_name = UIComponent(UIComponent(button_ptr):Parent()):Id()
  end
  ShaneOutput("Added selected highlight to button: " .. parent_name .. ":" .. UIComponent(button_ptr):Id())
  highlight:Resize(UIComponent(button_ptr):Dimensions())
  local halo = UIComponent(highlight:Find("halo"))
  if green then
    halo:SetState("green")
  else
    halo:SetState("red")
  end
  halo:ShaderTechniqueSet("highlight_circumference_t0", true, false)
  UIComponent(highlight:Find("time_label")):SetVisible(false)
  return highlight:Address()
end

function MultiplayerRemoveSelectionHighlightFromButton(button_ptr)
  local highlight_ptr = UIComponent(button_ptr):Find("button_selection_highlight", false)
  if highlight_ptr then
    Component.Destroy(highlight_ptr)
    ShaneOutput("Removed highlight from button: " .. UIComponent(button_ptr):Id())
    return true
  else
    ShaneOutput("No highlight to remove from button: " .. UIComponent(button_ptr):Id())
  end
  return false
end

function MultiplayerOpponentsPreBattleSelection(selection)
  local panel = panel_manager.IsPanelOpen("popup_pre_battle")
  if panel then
    UIComponent(panel):LuaCall("MultiplayerOpponentsSelection", selection)
  end
end

function MultiplayerOpponentsPostBattleDismissed(time)
  local panel = panel_manager.IsPanelOpen("popup_battle_results")
  if panel then
    UIComponent(panel):LuaCall("MultiplayerOpponentsPostBattleDismissed", time)
  end
end

function MultiplayerSetWaitingForLoad(waiting)
  mp_waiting_for_load = waiting
  if waiting then
    if panel_manager.IsPanelOpen("waiting_for_players") == nil then
      panel_manager.OpenPanel("waiting_for_players")
    end
  elseif panel_manager.IsPanelOpen("waiting_for_players") ~= nil then
    panel_manager.ClosePanel("waiting_for_players")
  end
end
