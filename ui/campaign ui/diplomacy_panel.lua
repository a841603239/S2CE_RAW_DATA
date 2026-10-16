dofile("ui/campaign ui/theatre_map_selector.lua")
local utils = require("Utilities")
local theatre = CampaignUI.HomeTheatre(CampaignUI.PlayerFactionId())
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local sub_panel_group = UIComponent(this:Find("subpanel_group"))
local main_panel_timer = UIComponent(this:Find("time_label"))
local dip_rel = UIComponent(this:Find("diplomatic_relations"))
local map_panel = UIComponent(this:Find("map_panel"))
local opposing_faction, player_faction, negotiation
local current_action = {}
local in_session = true
local initialised_from_pending_move, initialised_from_quick_deal_action, technology_template, faction_list_template, diplomacy_button_template
local player_initialised = false
local ready_to_close = true
local safe_to_propose = false
local first_open = true
local negotiation_ended = false
local MP_ACTION_TIMER_NONE = 1
local MP_ACTION_TIMER_MAIN = 2
local MP_ACTION_TIMER_COUNTEROFFER = 3
local MP_ACTION_TIMER_CONFIRM = 4
local mp_action_times = {
  -1,
  30,
  30,
  10
}
local mp_action_timer = {type = MP_ACTION_TIMER_NONE, timeout = -1}
local mp_timed_button, mp_pre_submenu_timers_button
local TimeString = utils.TimeString
Component.SetProperty("diplomatic_relations.button_cancel.ParentPopup", Address)
local tech_categories = {
  CampaignUI.LocalisationString("tech_category_military"),
  CampaignUI.LocalisationString("tech_category_industrial"),
  CampaignUI.LocalisationString("tech_category_enlightenment")
}
local tech_offer = UIComponent(this:Find("tech_offer"))
local tech_offer_list = UIComponent(tech_offer:Find("listview"))
local tech_offer_tabs = {}
for i = 0, 2 do
  local tech_offer_tab_group_ptr = tech_offer:Find("TabGroup", false)
  if tech_offer_tab_group_ptr then
    table.insert(tech_offer_tabs, UIComponent(UIComponent(tech_offer_tab_group_ptr):Find(i)))
  end
end
local tech_demand = UIComponent(this:Find("tech_demand"))
local tech_demand_list = UIComponent(tech_demand:Find("listview"))
local tech_demand_tabs = {}
for i = 0, 2 do
  local tech_demand_tab_group_ptr = tech_demand:Find("TabGroup", false)
  if tech_demand_tab_group_ptr then
    table.insert(tech_demand_tabs, UIComponent(UIComponent(tech_demand_tab_group_ptr):Find(i)))
  end
end
local show_shane_output = false

function ShaneOutput(string)
  if defined.debug and show_shane_output then
    out.shane(string)
  end
end

function SelectNextTheatre()
  theatre = MapSelectNextTheatre()
end

function SelectPrevTheatre()
  theatre = MapSelectPrevTheatre()
end

function OnExit()
  out.shane("diplomacy_panel: OnExit()")
  EndNegotiation()
  this:InterfaceFunction("Exited")
  if initialised_from_pending_move ~= nil then
    CampaignUI.FinalisePendingAction()
    initialised_from_pending_move = nil
  end
end

function OnDestroyed()
  out.shane("diplomacy_panel: OnDestroyed()")
  if technology_template ~= nil then
    Component.Destroy(technology_template, true)
  end
  if faction_list_template ~= nil then
    Component.Destroy(faction_list_template, true)
  end
  EndNegotiation()
end

function SetCloseable(closeable)
  g_closeable = closeable
  local dip_rel = UIComponent(this:Find("diplomatic_relations"))
  UIComponent(dip_rel:Find("button_cancel")):SetVisible(closeable)
end

function OverrideCurrentAction(state, from_unilateral)
  local list
  if from_unilateral then
    list = UIComponent(this:Find("menu_1"))
  else
    list = UIComponent(this:Find("menu_1"))
  end
  for i = 0, list:ChildCount() - 1 do
    local child = UIComponent(list:Find(i))
    local txt = UIComponent(child:Find(0))
    if txt:CurrentState() == state then
      current_action.Action = child:LuaCall("Action")
      current_action.State = state
      current_action.Text = txt:GetStateText()
      break
    end
  end
end

function AddToNegotiation(reason)
  initialised_from_pending_move = reason
end

function EnterQuickDeal()
  out.shane("entering quick deal")
  ClearDiplomaticOptions()
  ClearOffersDemands()
  local button_qd = UIComponent(dip_rel:Find("button_enter_quick_deal"))
  button_qd:SetState("selected")
  local faction_left = UIComponent(this:Find("faction_left"))
  local menu_addr = faction_left:Find("menu_1")
  local menu = UIComponent(menu_addr)
  local player_faction = CampaignUI.PlayerFactionId()
  CreateButtons({
    {
      State = "trade",
      Active = DiplomacyUI_CheckGeneralActionAvailability(player_faction, "DIPLOMATIC_ACTION_ACTION_TYPE_TRADE_AGREEMENT"),
      Unilateral = false
    },
    {
      State = "access",
      Active = DiplomacyUI_CheckGeneralActionAvailability(player_faction, "DIPLOMATIC_ACTION_ACTION_TYPE_MILITARY_ACCESS"),
      Unilateral = false
    },
    {
      State = "alliance",
      Active = DiplomacyUI_CheckGeneralActionAvailability(player_faction, "DIPLOMATIC_ACTION_ACTION_TYPE_ALLIANCE"),
      Unilateral = false
    },
    {
      State = "protector",
      Active = DiplomacyUI_CheckGeneralActionAvailability(player_faction, "DIPLOMATIC_ACTION_ACTION_TYPE_PROTECTORATE"),
      Unilateral = false
    },
    {
      State = "peace",
      Active = DiplomacyUI_CheckGeneralActionAvailability(player_faction, "DIPLOMATIC_ACTION_ACTION_TYPE_PEACE"),
      Unilateral = false
    }
  }, menu_addr, 1)
  for i = 0, menu:ChildCount() - 1 do
    local comp = UIComponent(menu:Find(i))
    if comp:CurrentState() ~= "inactive" then
      Notify(comp:Find(0))
      break
    end
  end
  out.shane("entered quick deal")
end

function ShowDiplomaticRelationsLists()
  dip_rel:SetVisible(true)
  dip_rel:LuaCall("Initialise")
  this:InterfaceFunction("ShowMap")
  UIComponent(this:Find("offers_demands")):SetVisible(false)
  local button_qd = UIComponent(dip_rel:Find("button_enter_quick_deal"))
  button_qd:SetState("active")
  ClearDiplomaticOptions()
  ClearOffersDemands()
  EndNegotiation()
end

function HideDiplomaticRelationsLists()
  dip_rel:SetVisible(false)
  UIComponent(this:Find("offers_demands")):SetVisible(true)
end

function Initialise(faction, quick_deal_action)
  out.dylan("Initialising diplomacy panel with faction: " .. tostring(faction))
  current_action = {}
  opposing_faction = faction
  player_faction = CampaignUI.PlayerFactionId()
  theatre = CampaignUI.HomeTheatre(player_faction)
  in_session = true
  map_panel:SetVisible(true)
  InitialiseMapHolders(map_panel, CampaignUI.TheatreList(), player_faction, "diplomacy_attitude_faction")
  SetMapAttitudes("diplomacy_attitude_faction")
  SetMapFaction(player_faction)
  this:InterfaceFunction("InitNegotiation", tostring(opposing_faction))
  this:InterfaceFunction("InitPanel", tostring(player_faction), "faction_left")
  this:InterfaceFunction("InitPanel", tostring(opposing_faction), "faction_right")
  ClearSubPopups()
  ClearDiplomaticOptions()
  ClearOffersDemands()
  if quick_deal_action ~= nil then
    initialised_from_quick_deal_action = quick_deal_action
  end
  if opposing_faction ~= nil then
    if first_open == true then
      dip_rel:LuaCall("Initialise")
    end
    HideDiplomaticRelationsLists()
    this:InterfaceFunction("HideMap")
    SetTreatyStrings(opposing_faction)
    out.dylan("Creating negotiation with factions: " .. tostring(player_faction) .. " and " .. tostring(opposing_faction))
    out.shane("diplomacy_panel: Initialise(), negotiation = " .. tostring(negotiation))
    negotiation_ended = false
    negotiation = UIDiplomacyNegotiation(player_faction, opposing_faction)
    if first_open == false then
      SetMapFaction(opposing_faction)
    end
  else
    ShowDiplomaticRelationsLists()
  end
  if diplomacy_button_template == nil then
    diplomacy_button_template = UIComponent(UIComponent(this:Find("faction_left")):Find("diplomacy_button"))
  end
  diplomacy_button_template:SetVisible(false)
  SetOfferButtonStatus()
  local button_set = UIComponent(this:Find("button_set2"))
  UIComponent(button_set:Find("button_cancel")):SetState("active")
  UIComponent(button_set:Find("button_counteroffer")):SetState("active")
  local continue_string = CampaignUI.UILocalisationString("button_accept_Tooltip_100031")
  local cancel_string = CampaignUI.UILocalisationString("button_cancel_Tooltip_570010")
  UIComponent(button_set:Find("button_accept")):SetTooltipText(continue_string, true)
  UIComponent(button_set:Find("button_cancel")):SetTooltipText(cancel_string, true)
  SetCloseable(true)
  this:InterfaceFunction("Opened")
  first_open = false
end

function RequestDiplomacy(incoming_negotiation, greeting)
  player_faction = CampaignUI.PlayerFactionId()
  theatre = CampaignUI.HomeTheatre(player_faction)
  InitialiseMapHolders(map_panel, CampaignUI.TheatreList(), player_faction, "diplomacy_attitude_faction")
  current_action = {}
  out.shane("diplomacy_panel: RequestDiplomacy(), negotiation = " .. tostring(negotiation))
  negotiation_ended = false
  negotiation = UIDiplomacyNegotiation(incoming_negotiation)
  in_session = true
  opposing_faction = negotiation:ProposerId()
  this:InterfaceFunction("InitNegotiation", tostring(opposing_faction))
  this:InterfaceFunction("InitPanel", tostring(player_faction), "faction_left")
  this:InterfaceFunction("InitPanel", tostring(opposing_faction), "faction_right")
  ClearSubPopups()
  UIComponent(this:Find("button_set1")):SetVisible(false)
  UIComponent(this:Find("button_set2")):SetVisible(true)
  UIComponent(this:Find("button_set3")):SetVisible(false)
  SetTreatyStrings(opposing_faction)
  ClearDiplomaticOptions()
  ClearOffersDemands()
  AIResponse(greeting)
  SetOfferButtonStatus()
  local button_set = UIComponent(this:Find("button_set2"))
  UIComponent(button_set:Find("button_accept")):SetState("inactive")
  UIComponent(button_set:Find("button_cancel")):SetState("inactive")
  UIComponent(button_set:Find("button_counteroffer")):SetState("inactive")
  SetCloseable(false)
end

function SetTreatyStrings(faction)
  this:InterfaceFunction("SetTreatyStrings", tostring(faction))
end

function ClearSubPopups(clear_button_set)
  ShaneOutput("ClearSubPopups : clear_button_set = " .. tostring(clear_button_set))
  UIComponent(this:Find("speechbox")):PropagateVisibility(false)
  for i = 0, sub_panel_group:ChildCount() - 1 do
    UIComponent(sub_panel_group:Find(i)):SetVisible(false)
  end
  sub_panel_group:SetVisible(true)
  if clear_button_set ~= false then
    UIComponent(this:Find("button_set1")):SetVisible(true)
    UIComponent(this:Find("button_set2")):SetVisible(false)
    UIComponent(this:Find("button_set3")):SetVisible(false)
  end
  local declare_war_popup = UIComponent(this:Find("declare_war"))
  declare_war_popup:UnLockPriority()
  current_subpopup = nil
end

function ShowSubPopup(popup)
  ShaneOutput("++ShowSubPopup: popup = " .. tostring(popup))
  if mp_timed_button ~= nil then
    ShaneOutput("Pre submenu timer is on: " .. tostring(UIComponent(mp_timed_button):Id()))
  else
    ShaneOutput("No pre submenu timer active")
  end
  if mp_pre_submenu_timers_button ~= nil then
    ShaneOutput("Saved button timer is on: " .. tostring(UIComponent(UIComponent(mp_pre_submenu_timers_button):Parent()):Id()))
  end
  UIComponent(this:Find("speechbox")):PropagateVisibility(false)
  sub_panel_group:SetVisible(true)
  for i = 0, sub_panel_group:ChildCount() - 1 do
    UIComponent(sub_panel_group:Find(i)):SetVisible(false)
  end
  local submenu_to_submenu = current_subpopup ~= nil
  ShaneOutput("submenu_to_submenu = " .. tostring(submenu_to_submenu))
  current_subpopup = UIComponent(this:Find(popup))
  current_subpopup:SetVisible(true)
  if not submenu_to_submenu and mp_timed_button ~= nil and mp_pre_submenu_timers_button == nil then
    mp_pre_submenu_timers_button = mp_timed_button
  end
end

function CreateButtons(table, parent, y)
  ShaneOutput("::CreateButtons " .. #table .. " entries")
  for i, v in ipairs(table) do
    ShaneOutput("Creating button " .. i)
    if diplomacy_button_template == nil then
      diplomacy_button_template = UIComponent(UIComponent(this:Find("faction_left")):Find("diplomacy_button"))
    end
    local child = UIComponent(Component.CreateFromComponent(diplomacy_button_template:Address(), "diplomacy_button_" .. v.State, parent, 1, y, {}, {}))
    out.dylan("diplomacy_button_" .. v.State)
    local txt = UIComponent(child:Find(0))
    child:SetProperty("Notify", Address)
    child:SetVisible(true)
    child:SetGlobal("Active", v.Active)
    child:SetGlobal("Unilateral", v.Unilateral == true)
    if v.Active then
      child:SetState("active")
    else
      child:SetState("inactive")
    end
    if txt:SetState(v.State) then
      if v.Tooltip then
        txt:SetTooltipText(v.Tooltip)
      end
      local tt = txt:GetTooltipText()
      child:SetTooltipText(tt, true)
      if v.Address ~= nil then
        child:LuaCall("SetAction", v.Address)
      end
      y = y + child:Height()
    else
      ShaneOutput("Destroying button " .. i)
      Component.Destroy(child:Address())
    end
  end
  return y
end

function RefreshButtonStates()
  local offers_demands = UIComponent(this:Find("offers_demands"))
  local offers_list = UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("list_box"))
  local demands_list = UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("list_box"))
  local total_offers_demands = offers_list:ChildCount() + demands_list:ChildCount()
  local faction_list = UIComponent(this:Find("faction_left"))
  local menu = UIComponent(faction_list:Find("menu_1"))
  local child_count = menu:ChildCount()
  for i = 0, child_count - 1 do
    local child = UIComponent(menu:Find(i))
    if child:GlobalExists("Active") and (not child:GlobalExists("Unilateral") or total_offers_demands == 0) then
      child:SetState("active")
    else
      child:SetState("inactive")
    end
  end
end

function ClearDiplomaticOptions()
  local faction_list = UIComponent(this:Find("faction_left"))
  UIComponent(faction_list:Find("menu_1")):DestroyChildren()
end

function ClearOffersDemands()
  local offers_demands = UIComponent(this:Find("offers_demands"))
  offers_list = UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("list_box"))
  demands_list = UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("list_box"))
  offers_list:DestroyChildren()
  demands_list:DestroyChildren()
  UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("vslider")):SetVisible(false)
  UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("vslider")):SetVisible(false)
end

function InitialiseNegotiation(greeting, player_init_negotation, proposal_made, likelihood)
  ShaneOutput("InitialiseNegotiation: player_init_negotation = " .. tostring(player_init_negotation) .. ", proposal_made = " .. tostring(proposal_made))
  ClearSubPopups()
  player_initialised = player_init_negotation
  if player_init_negotation == false then
    this:InterfaceFunction("InitNegotiation", tostring(opposing_faction))
  end
  if likelihood ~= nil then
    this:InterfaceFunction("UpdateChanceOfAccept", likelihood)
  end
  UIComponent(this:Find("tx_likelihood of success")):SetVisible(false)
  ShaneOutput("1")
  current_action = {}
  local faction_list = UIComponent(this:Find("faction_left"))
  local menu1 = faction_list:Find("menu_1")
  ClearDiplomaticOptions()
  ShaneOutput("2")
  local details = negotiation:BuildPossibleActions()
  if player_init_negotation == true then
    local y = CreateButtons(details.Unilaterals, menu1, 1)
    CreateButtons(details.OffersAndDemands, menu1, y)
  end
  ShaneOutput("3")
  local offers_demands = UIComponent(this:Find("offers_demands"))
  local left_list, right_list
  if player_init_negotation then
    UIComponent(offers_demands:Find("offers_title")):SetState("faction_left")
    UIComponent(offers_demands:Find("demands_title")):SetState("faction_left")
    left_list = UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("list_box"))
    right_list = UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("list_box"))
  else
    UIComponent(offers_demands:Find("offers_title")):SetState("faction_right")
    UIComponent(offers_demands:Find("demands_title")):SetState("faction_right")
    left_list = UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("list_box"))
    right_list = UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("list_box"))
  end
  ShaneOutput("4")
  left_list:DestroyChildren()
  right_list:DestroyChildren()
  local offers_slider = UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("vslider"))
  local demands_slider = UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("vslider"))
  offers_slider:SetVisible(false)
  demands_slider:SetVisible(false)
  offers_slider:LuaCall("ValueSet", 0)
  demands_slider:LuaCall("ValueSet", 0)
  local offers, demands = negotiation:BuildOfferAndDemandStrings()
  for i, v in ipairs(offers) do
    AddToOffersDemandsList(left_list:Address(), v.Action, v.Text, v.Hostage, v.HostagePortrait, player_init_negotation)
  end
  for i, v in ipairs(demands) do
    AddToOffersDemandsList(right_list:Address(), v.Action, v.Text, v.Hostage, v.HostagePortrait, player_init_negotation)
  end
  if player_init_negotation ~= true or safe_to_propose == false then
    out.dylan("Setting offers/demands non-interactive")
    for i = 0, left_list:ChildCount() - 1 do
      UIComponent(left_list:Find(i)):SetInteractive(false)
    end
    for i = 0, right_list:ChildCount() - 1 do
      UIComponent(right_list:Find(i)):SetInteractive(false)
    end
  else
    out.dylan("Not setting offers/demands non-interactive")
  end
  ShaneOutput("5")
  RefreshButtonStates()
  ShaneOutput("6")
  if greeting ~= nil and 0 < #greeting then
    AIResponse(greeting)
  else
    UIComponent(this:Find("speechbox")):PropagateVisibility(false)
  end
  ShaneOutput("7")
  if player_init_negotation ~= nil then
    ShaneOutput("8")
    local send_offer_buttons = UIComponent(this:Find("button_set1"))
    local respond_offer_buttons = UIComponent(this:Find("button_set2"))
    local players_turn = CampaignUI.IsPlayersTurn()
    local local_player_preparing_proposal = players_turn and player_init_negotation and not proposal_made
    local local_player_sent_proposal = players_turn and player_init_negotation and proposal_made
    local local_player_recieved_proposal = players_turn and not player_init_negotation and proposal_made
    local out_of_turn_player_preparing_proposal = not players_turn and player_init_negotation and not proposal_made
    local out_of_turn_player_sent_proposal = not players_turn and player_init_negotation and proposal_made
    local out_of_turn_player_recieved_proposal = not players_turn and not player_init_negotation and proposal_made
    send_offer_buttons:PropagateVisibility(local_player_preparing_proposal or out_of_turn_player_preparing_proposal)
    respond_offer_buttons:PropagateVisibility(not player_init_negotation or proposal_made)
    ShaneOutput("9")
    if not player_init_negotation and proposal_made then
      UIComponent(respond_offer_buttons:Find("button_accept")):SetState("active")
      UIComponent(respond_offer_buttons:Find("button_cancel")):SetState("active")
      UIComponent(respond_offer_buttons:Find("button_counteroffer")):SetState("active")
      local accept_string = CampaignUI.UILocalisationString("button_accept_Tooltip_90071")
      local decline_string = CampaignUI.UILocalisationString("option2_text_tx_decline_Text_67002b")
      UIComponent(respond_offer_buttons:Find("button_accept")):SetTooltipText(accept_string, true)
      UIComponent(respond_offer_buttons:Find("button_cancel")):SetTooltipText(decline_string, true)
    else
      UIComponent(respond_offer_buttons:Find("button_accept")):SetState("inactive")
      UIComponent(respond_offer_buttons:Find("button_cancel")):SetState("inactive")
      UIComponent(respond_offer_buttons:Find("button_counteroffer")):SetState("inactive")
    end
    SetCloseable(player_init_negotation == true)
  end
  if initialised_from_pending_move ~= nil then
    if initialised_from_pending_move == "DeclareWar" then
      OverrideCurrentAction("war", true)
      if negotiation ~= nil then
        InitialiseDeclareWar(false, negotiation:TreatyWarningTurns(), negotiation:ShowWarningTurns())
      else
        InitialiseDeclareWar(nil, 0, false)
      end
    elseif initialised_from_pending_move == "RequestAccess" then
      OverrideCurrentAction("access", false)
      InitialiseMilitaryAccess()
      local access = UIComponent(this:Find("offer_access"))
      local grp = UIComponent(access:Find("ButtonGroup"))
      grp:LuaCall("SelectButton", grp:Find("5"))
      access = UIComponent(this:Find("demand_access"))
      grp = UIComponent(access:Find("ButtonGroup"))
      grp:LuaCall("SelectButton", grp:Find("5"))
    end
    initialised_from_pending_move = true
  end
  safe_to_propose = true
  SetOfferButtonStatus()
  if initialised_from_quick_deal_action ~= nil then
    local qd_act = initialised_from_quick_deal_action
    initialised_from_quick_deal_action = nil
    local act_btn_names = {
      DIPLOMATIC_ACTION_ACTION_TYPE_ALLIANCE = "alliance",
      DIPLOMATIC_ACTION_ACTION_TYPE_MILITARY_ACCESS = "access",
      DIPLOMATIC_ACTION_ACTION_TYPE_TRADE_AGREEMENT = "trade",
      DIPLOMATIC_ACTION_ACTION_TYPE_PEACE = "peace",
      DIPLOMATIC_ACTION_ACTION_TYPE_PROTECTORATE = "protector"
    }
    local faction_list = UIComponent(this:Find("faction_left"))
    local menu1 = UIComponent(faction_list:Find("menu_1"))
    local act_btn = menu1:Find("diplomacy_button_" .. act_btn_names[qd_act])
    if act_btn ~= nil then
      local action = UIComponent(act_btn):LuaCall("Action")
      if qd_act == "DIPLOMATIC_ACTION_ACTION_TYPE_MILITARY_ACCESS" then
        negotiation:Propose(4, 4, action)
        RebuildActionButtons()
      else
        Notify(UIComponent(act_btn):Find(0))
      end
    end
  end
end

function SetOfferButtonStatus()
  if negotiation ~= nil and negotiation:CanPropose() then
    UIComponent(this:Find("button_send")):SetState("active")
    UIComponent(this:Find("button_threat_of_force")):SetState(negotiation:CanThreaten() and "active" or "inactive")
  else
    UIComponent(this:Find("button_send")):SetState("inactive")
    UIComponent(this:Find("button_threat_of_force")):SetState("inactive")
  end
  local respond_offer_buttons = UIComponent(this:Find("button_set2"))
  local accept_button = UIComponent(respond_offer_buttons:Find("button_accept"))
  if negotiation ~= nil and accept_button:CurrentState() == "active" and negotiation:CanAccept() == false then
    accept_button:SetState("inactive")
  end
end

function AIEndedDiplomacy(msg, verdict)
  ShaneOutput("AIEndedDiplomacy: msg = " .. tostring(msg))
  ClearSubPopups(true)
  local button_set2 = UIComponent(this:Find("button_set2"))
  button_set2:PropagateVisibility(false)
  local button_set3 = UIComponent(this:Find("button_set3"))
  button_set3:PropagateVisibility(true)
  UIComponent(button_set3:Find("button_accept")):SetState("active")
  SetCloseable(true)
  in_session = false
  this:InterfaceFunction("InitPanel", tostring(player_faction), "faction_left")
  this:InterfaceFunction("InitPanel", tostring(opposing_faction), "faction_right")
  ClearDiplomaticOptions()
  ClearOffersDemands()
  AIResponse(msg)
  if verdict == nil then
    verdict = "message"
  end
  out.dylan("AI response: " .. verdict)
  this:InterfaceFunction("NotifyAIResponse", verdict)
end

function AIResponse(msg)
  ShaneOutput("AIResponse: msg = " .. tostring(msg))
  local diplomat = UIComponent(this:Find("diplomat"))
  UIComponent(diplomat:Find("speechbox")):SetStateText(msg)
  UIComponent(diplomat:Find("speechbox")):SetVisible(true)
  SetTreatyStrings()
end

function SendOffer()
  if negotiation ~= nil then
    negotiation:ProposeDeal(false)
    safe_to_propose = false
  end
end

function EndNegotiation()
  out.shane("diplomacy_panel: EndNegotiation(), negotiation_ended = " .. tostring(negotiation_ended) .. ", negotiation = " .. tostring(negotiation))
  if negotiation_ended ~= true then
    negotiation_ended = true
    if negotiation ~= nil then
      negotiation:End()
      negotiation = nil
    end
  end
end

function CancelOffer()
  out.shane("diplomacy_panel: CancelOffer()")
  if negotiation:CanPropose() then
    out.shane("diplomacy_panel: negotiation:Cancel()")
    negotiation:Cancel()
  else
    EndNegotiation()
    if player_initialised == true and CampaignUI.IsPlayersTurn() then
      ShowDiplomaticRelationsLists()
    else
      ClosePopup()
    end
  end
  UIComponent(this:Find("button_set1")):SetVisible(true)
  UIComponent(this:Find("button_set2")):SetVisible(false)
  UIComponent(this:Find("button_set3")):SetVisible(false)
  map_panel:SetVisible(true)
end

function Notify(notifier)
  local button = UIComponent(notifier)
  local state = button:CurrentState()
  local parent = UIComponent(button:Parent())
  if negotiation == nil then
    local button_list = UIComponent(parent:Parent())
    for i = 0, button_list:ChildCount() - 1 do
      local button_to_clear = UIComponent(button_list:Find(i))
      if button_to_clear:GlobalExists("Active") then
        button_to_clear:SetState("active")
      else
        button_to_clear:SetState("inactive")
      end
    end
    parent:SetState("selected")
    if state == "alliance" then
      dip_rel:LuaCall("Initialise", "DIPLOMATIC_ACTION_ACTION_TYPE_ALLIANCE")
    elseif state == "access" then
      dip_rel:LuaCall("Initialise", "DIPLOMATIC_ACTION_ACTION_TYPE_MILITARY_ACCESS")
    elseif state == "trade" then
      dip_rel:LuaCall("Initialise", "DIPLOMATIC_ACTION_ACTION_TYPE_TRADE_AGREEMENT")
    elseif state == "peace" then
      dip_rel:LuaCall("Initialise", "DIPLOMATIC_ACTION_ACTION_TYPE_PEACE")
    elseif state == "protector" then
      dip_rel:LuaCall("Initialise", "DIPLOMATIC_ACTION_ACTION_TYPE_PROTECTORATE")
    end
  else
    current_action.Action = parent:LuaCall("Action")
    current_action.State = state
    current_action.Text = button:GetStateText()
    if state == "war" then
      if negotiation ~= nil then
        InitialiseDeclareWar(false, negotiation:TreatyWarningTurns(), negotiation:ShowWarningTurns())
      else
        InitialiseDeclareWar(nil, 0, false)
      end
    elseif state == "access" then
      InitialiseMilitaryAccess()
      RebuildActionButtons()
    elseif state == "payments" then
      InitialisePayments()
      RebuildActionButtons()
    elseif state == "trade" or state == "alliance" or state == "peace" then
      if safe_to_propose then
        negotiation:Propose(current_action.Action)
      end
      RebuildActionButtons()
    elseif state == "access_cancel" then
      if safe_to_propose then
        negotiation:Propose(current_action.Action)
      end
    elseif state == "trade_cancel" then
      InitialiseTradeCancel()
    elseif state == "alliance_cancel" then
      InitialiseAllianceCancel()
    elseif state == "protector" then
      if safe_to_propose then
        negotiation:Propose(current_action.Action)
      end
    elseif state == "state_gift" then
      InitialiseStateGift()
    elseif state == "request_join_war" or state == "break_trade" or state == "break_alliance" then
      InitialiseFactionLists(state)
    elseif state == "marriage" then
      InitialiseMarriage()
    elseif state == "hostage" then
      InitialiseHostages()
    end
  end
end

function InitialiseFactionLists(state)
  ShowSubPopup("request_join_war")
  local subpanel = UIComponent(this:Find("request_join_war"))
  UIComponent(subpanel:Find("ok_request")):SetGlobal("stance", state)
  local offered, demanded = negotiation:FactionListsForStanceDeclarations(state)
  if faction_list_template == nil then
    faction_list_template = this:Find("faction_list_item")
    UIComponent(UIComponent(faction_list_template):Parent()):Divorce(faction_list_template)
  end
  local title = UIComponent(this:Find("deal_type_title_left"))
  title:SetState(state)
  local offers_list = UIComponent(UIComponent(subpanel:Find("list_offers")):Find("list_box"))
  offers_list:DestroyChildren()
  for i, v in ipairs(offered) do
    local item_name = "offer" .. tostring(i)
    local c = UIComponent(Component.CreateFromComponent(faction_list_template, item_name, offers_list:Address(), 0, 0, {
      "{miniflag_dy:1}" .. v.FlagPath
    }, {
      [item_name] = v.Name
    }))
    c:SetGlobal("FactionKey", v.Key)
    if v.Selected then
      UIComponent(c:Find("checkbox")):LuaCall("SetSelected", true)
    end
  end
  offers_list:Layout()
  title = UIComponent(this:Find("deal_type_title_right"))
  title:SetState(state)
  local demanded_list = UIComponent(UIComponent(subpanel:Find("list_demands")):Find("list_box"))
  demanded_list:DestroyChildren()
  for i, v in ipairs(demanded) do
    out.tom(v.Name)
    local item_name = "demand" .. tostring(i)
    local c = UIComponent(Component.CreateFromComponent(faction_list_template, item_name, demanded_list:Address(), 0, 0, {
      "{miniflag_dy:1}" .. v.FlagPath
    }, {
      [item_name] = v.Name
    }))
    c:SetGlobal("FactionKey", v.Key)
    if v.Selected then
      UIComponent(c:Find("checkbox")):LuaCall("SetSelected", true)
    end
  end
  demanded_list:Layout()
end

function OkStanceDeclaration(stance)
  local subpanel = UIComponent(this:Find("request_join_war"))
  local offered = {}
  local demanded = {}
  local offers_list = UIComponent(subpanel:Find("list_offers"))
  local contained_list = UIComponent(offers_list:Find("list_box"))
  for i = 0, contained_list:ChildCount() - 1 do
    local c = UIComponent(contained_list:Find(i))
    if UIComponent(c:Find("checkbox")):LuaCall("Selected") then
      offered[#offered + 1] = c:GlobalExists("FactionKey")
    end
  end
  local demanded_list = UIComponent(subpanel:Find("list_demands"))
  contained_list = UIComponent(demanded_list:Find("list_box"))
  for i = 0, contained_list:ChildCount() - 1 do
    local c = UIComponent(contained_list:Find(i))
    if UIComponent(c:Find("checkbox")):LuaCall("Selected") then
      demanded[#demanded + 1] = c:GlobalExists("FactionKey")
    end
  end
  out.dylan("Request join war, offered = " .. #offered .. ", demanded = " .. #demanded .. ", stance = " .. stance)
  local proposal_made = false
  if safe_to_propose and (0 < #offered or 0 < #demanded) then
    negotiation:Propose(offered, demanded, current_action.Action)
    proposal_made = true
  end
  ClearSubPopups(proposal_made)
end

local diplomacy_gift_values = CampaignUI.StateGiftValues()

function InitialiseStateGift()
  ShowSubPopup("state_gift")
  local state_gift = UIComponent(this:Find("state_gift"))
  local bg = UIComponent(state_gift:Find("ButtonGroup"))
  local available_cash = negotiation:MaxPlayerPaymentAllowed()
  for i, v in ipairs(diplomacy_gift_values) do
    local tx = UIComponent(state_gift:Find(i .. "_tx"))
    tx:SetStateText(v)
    local c = UIComponent(bg:Find(i - 1))
    if v > available_cash then
      c:SetState("inactive")
    else
      c:SetState("normal")
    end
  end
end

function OkStateGift()
  local proposal_made = false
  if negotiation ~= nil then
    local state_gift = UIComponent(this:Find("state_gift"))
    local bg = UIComponent(state_gift:Find("ButtonGroup"))
    local option = bg:LuaCall("SelectedButton")
    if option ~= -1 and safe_to_propose then
      negotiation:Propose(diplomacy_gift_values[option + 1], current_action.Action)
      proposal_made = true
    end
  end
  ClearSubPopups(proposal_made)
end

function InitialiseTradeCancel()
  ShowSubPopup("end_trade")
end

function InitialiseAllianceCancel()
  ShowSubPopup("end_alliance")
end

function OkTradeOrAllianceCancel()
  local proposal_made = false
  if negotiation ~= nil and safe_to_propose then
    negotiation:Propose(current_action.Action)
    proposal_made = true
  end
  ClearSubPopups(true)
end

function InitialiseDeclareWar(declared_by_ai, treaty_warning_turns, show_turn_number)
  ShaneOutput("InitialiseDeclareWar: declared_by_ai = " .. tostring(declared_by_ai))
  ShaneOutput("                      treaty_warning = " .. tostring(treaty_warning_turns))
  ShowSubPopup("declare_war")
  local declare_war_popup = UIComponent(this:Find("declare_war"))
  declare_war_popup:LockPriority(50)
  local faction_details = CampaignUI.FactionDetails(opposing_faction)
  local declare_war = UIComponent(this:Find("declare_war"))
  local faction_name = UIComponent(declare_war:Find("enemy_faction_name"))
  local your_allies = declare_war:Find("your_allies_list")
  local thier_allies = declare_war:Find("their_allies_list")
  local checkbox = UIComponent(declare_war:Find("checkbox"))
  local checkbox_text = UIComponent(declare_war:Find("call_help_tx"))
  local treaty_warning = UIComponent(declare_war:Find("tx_treaty_cooldown_warning"))
  local cooldown_text = UIComponent(treaty_warning:Find("tx_treaty_cooldown_turns"))
  local cooldown_turns = UIComponent(treaty_warning:Find("dy_turns"))
  if declared_by_ai == true then
    UIComponent(declare_war:Find("button_ok_declare")):SetVisible(false)
    UIComponent(declare_war:Find("button_cancel_declare")):SetVisible(false)
    UIComponent(declare_war:Find("button_ok_declared")):SetVisible(true)
    UIComponent(declare_war:Find("button_ok_declared")):SetState("active")
    UIComponent(declare_war:Find("declare_war_tx")):SetState("war_declared")
    UIComponent(declare_war:Find("descr_tx")):SetState("they")
    SetCloseable(false)
  else
    UIComponent(declare_war:Find("button_ok_declare")):SetVisible(true)
    UIComponent(declare_war:Find("button_cancel_declare")):SetVisible(true)
    UIComponent(declare_war:Find("button_ok_declared")):SetVisible(false)
    UIComponent(declare_war:Find("declare_war_tx")):SetState("declared_war")
    UIComponent(declare_war:Find("descr_tx")):SetState("you")
  end
  treaty_warning:SetVisible(0 < treaty_warning_turns and declared_by_ai == false)
  cooldown_text:SetVisible(show_turn_number)
  cooldown_turns:SetStateText(treaty_warning_turns)
  faction_name:SetStateText(faction_details.Name)
  local num_your_allies = InitAlliesList(your_allies, CampaignUI.RetrieveDiplomacyDetails(player_faction).Allies, opposing_faction, CampaignUI.RetrieveDiplomacyDetails(player_faction).Protectorates, CampaignUI.RetrieveDiplomacyDetails(player_faction).ProtectorOf)
  InitAlliesList(thier_allies, CampaignUI.RetrieveDiplomacyDetails(opposing_faction).Allies, player_faction, CampaignUI.RetrieveDiplomacyDetails(opposing_faction).Protectorates, CampaignUI.RetrieveDiplomacyDetails(opposing_faction).ProtectorOf)
  checkbox:SetState("selected")
  if num_your_allies <= 0 then
    checkbox:SetVisible(false)
    checkbox_text:SetVisible(false)
  else
    checkbox:SetVisible(true)
    checkbox_text:SetVisible(true)
  end
end

function InitAlliesList(list_address, allies, ignore_faction, protectorates, protectors)
  local list = UIComponent(list_address)
  local bg = UIComponent(list:Find("list_box"))
  bg:DestroyChildren()
  local allies_count = 0
  for i, v in pairs(allies) do
    if v.Label == nil or v.Label ~= ignore_faction then
      images = {
        "{miniflag:1}" .. v.Flag
      }
      text = {}
      text.faction_name = v.Name
      local icon = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_allies_list_item", "ally", bg:Address(), 0, 0, images, text))
      icon:Resize(icon:Width(), icon:Height() + 1, false)
      allies_count = allies_count + 1
    end
  end
  if protectorates ~= nil then
    for i, v in pairs(protectorates) do
      if v.Label == nil or v.Label ~= ignore_faction then
        images = {
          "{miniflag:1}" .. v.Flag
        }
        text = {}
        text.faction_name = v.Name
        local icon = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_allies_list_item", "ally", bg:Address(), 0, 0, images, text))
        icon:Resize(icon:Width(), icon:Height() + 1, false)
      end
    end
  end
  if protectors ~= nil then
    for i, v in pairs(protectors) do
      if v.Label == nil or v.Label ~= ignore_faction then
        images = {
          "{miniflag:1}" .. v.Flag
        }
        text = {}
        text.faction_name = v.Name
        local icon = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_allies_list_item", "ally", bg:Address(), 0, 0, images, text))
        icon:Resize(icon:Width(), icon:Height() + 1, false)
      end
    end
  end
  bg:Layout()
  local no_allies_text = UIComponent(list:Find("tx_no_allies_available"))
  if bg:ChildCount() == 0 then
    no_allies_text:SetVisible(true)
  else
    no_allies_text:SetVisible(false)
  end
  return allies_count
end

local old_pri_lock

function ConfirmWarDeclared(msg, details)
  SetCloseable(true)
  this:UnLockPriority()
  local players_joining_allies, opponents_joining_allies, players_refusing_allies
  local proposers_version = player_faction == negotiation:ProposerId()
  if proposers_version then
    players_joining_allies = details.AttackersJoiningAllies
    opponents_joining_allies = details.DefendersJoiningAllies
    players_refusing_allies = details.AttackersRefusingAllies
  else
    players_joining_allies = details.DefendersJoiningAllies
    opponents_joining_allies = details.AttackersJoiningAllies
    players_refusing_allies = details.DefendersRefusingAllies
  end
  ShowSubPopup("war_declared")
  AIResponse(msg)
  local war_declared = UIComponent(sub_panel_group:Find("war_declared"))
  local your_allies = war_declared:Find("your_allies_list")
  local their_allies = war_declared:Find("their_allies_list")
  local players_allies_count = InitAlliesList(your_allies, players_joining_allies)
  local opponents_allies_count = InitAlliesList(their_allies, opponents_joining_allies)
  UIComponent(war_declared:Find("vline")):SetVisible(0 < players_allies_count and 0 < opponents_allies_count)
  if g_your_joined_tx == nil then
    g_your_joined_tx = UIComponent(war_declared:Find("joined_tx"))
    g_their_joined_tx = UIComponent(g_your_joined_tx:Find(0))
    local x, y = g_their_joined_tx:Position()
    war_declared:Adopt(g_their_joined_tx:Address())
    g_their_joined_tx:MoveTo(x, y)
  end
  if 0 < players_allies_count then
    UIComponent(your_allies):SetVisible(true)
    g_your_joined_tx:SetVisible(true)
  else
    UIComponent(your_allies):SetVisible(false)
    g_your_joined_tx:SetVisible(false)
  end
  if 0 < opponents_allies_count then
    UIComponent(their_allies):SetVisible(true)
    g_their_joined_tx:SetVisible(true)
  else
    UIComponent(their_allies):SetVisible(false)
    g_their_joined_tx:SetVisible(false)
  end
  UIComponent(war_declared:Find("faction_left_name")):SetStateText(CampaignUI.FactionDetails(player_faction).Name)
  UIComponent(war_declared:Find("faction_right_name")):SetStateText(CampaignUI.FactionDetails(opposing_faction).Name)
  local x = 0
  local parent = war_declared:Find("refused_allies_group")
  Component.CallByAddress(parent, "DestroyChildren")
  for k, v in pairs(players_refusing_allies) do
    local icon = Component.CreateFromLayout("data/ui/campaign ui/faction_flag_small", "flag" .. k, parent, x, 0, {
      v.Flag
    })
    UIComponent(icon):SetTooltipText(v.Name)
    x = x + Component.CallByAddress(icon, "Width")
  end
  UIComponent(war_declared:Find("refused_tx")):PropagateVisibility(0 < x)
  in_session = false
  this:InterfaceFunction("InitPanel", tostring(player_faction), "faction_left")
  this:InterfaceFunction("InitPanel", tostring(opposing_faction), "faction_right")
  ClearDiplomaticOptions()
end

function OkDeclareWar(declared_by_ai)
  if negotiation ~= nil then
    local declare_war = UIComponent(sub_panel_group:Find("declare_war"))
    call_allies = UIComponent(declare_war:Find("checkbox")):CurrentState() == "selected"
    if declared_by_ai == true then
      this:LockPriority(50)
      CampaignUI.InviteAlliesIntoWar(call_allies)
    elseif safe_to_propose then
      negotiation:Propose(call_allies, current_action.Action)
      UIComponent(declare_war:Find("button_ok_declare")):SetVisible(false)
      UIComponent(declare_war:Find("button_cancel_declare")):SetVisible(false)
      MultiplayerClearButtonExtras(true)
    end
  end
end

function OkWarDeclared()
  out.shane("diplomacy_panel: OkWarDeclared()")
  ClearSubPopups()
  out.shane("diplomacy_panel: negotiation:Cancel()")
  negotiation:Cancel()
  ClosePopup()
end

function RemoveDiplomacyItem(item)
  local c = UIComponent(item)
  local diplomacy_item = c:GlobalExists("DiplomacyItem")
  Component.Destroy(item)
  RefreshButtonStates()
  negotiation:RemoveAction(diplomacy_item)
end

function RemoveHostage(item)
  local c = UIComponent(item)
  local diplomacy_item = c:GlobalExists("DiplomacyItem")
  RefreshButtonStates()
  negotiation:RemoveHostages(diplomacy_item)
end

function AddToOffersDemandsList(list_address, item, text, hostage_name_and_age, hostage_portrait_path, player_initialised)
  local list = UIComponent(list_address)
  local diplomacy_item
  local delete_button_visible = player_initialised == true and negotiation:CanPropose()
  local resized_for_hostage = false
  diplomacy_item = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_item_text", tostring(item), list_address, 0, 0, {}, {}))
  diplomacy_item:SetGlobal("DiplomacyItem", item)
  UIComponent(diplomacy_item:Find("text_field")):SetStateText(tostring(text))
  if hostage_name_and_age == "Hostage Demanded" then
    local top_hostage = UIComponent(diplomacy_item:Find("hostage"))
    top_hostage:SetVisible(true)
    UIComponent(top_hostage:Find("hostage_details")):SetVisible(false)
    diplomacy_item:Resize(diplomacy_item:Width(), diplomacy_item:Height() + 40, false)
    resized_for_hostage = true
  elseif hostage_name_and_age ~= nil then
    UIComponent(diplomacy_item:Find("hostage")):SetVisible(true)
    local name_and_age = UIComponent(diplomacy_item:Find("dy_hostage_name_and_age"))
    name_and_age:SetStateText(tostring(hostage_name_and_age))
    if hostage_portrait_path ~= nil then
      local portrait_image = UIImage(hostage_portrait_path)
      portrait_image:SetComponentTexture(diplomacy_item:Find("hostage_details"), 0)
    end
    diplomacy_item:Resize(diplomacy_item:Width(), diplomacy_item:Height() + 40, false)
    resized_for_hostage = true
  else
    UIComponent(diplomacy_item:Find("hostage")):SetVisible(false)
  end
  local text_field = UIComponent(diplomacy_item:Find("text_field"))
  local details, width, height = text_field:GetStateText()
  if height ~= nil and height > text_field:Height() then
    text_field:Resize(text_field:Width(), height + 12, false)
    UIComponent(diplomacy_item:Find("hostage")):SetVisible(false)
    if resized_for_hostage then
      diplomacy_item:Resize(diplomacy_item:Width(), diplomacy_item:Height() - 40, false)
    end
    if diplomacy_item:Height() < text_field:Height() then
      diplomacy_item:Resize(diplomacy_item:Width(), diplomacy_item:Height() + height + 12, false)
    end
  end
  list:Layout()
  local slider = UIComponent(UIComponent(UIComponent(list:Parent()):Parent()):Find("vslider"))
  slider:SetVisible(0 < slider:GetProperty("maxValue"))
end

local highlighted_region

function ShowRegion(region)
  theatre = region.Theatre
  ShowMap(region, false)
end

function HideMap()
  UIComponent(map_panel:Find("japan")):SetVisible(false)
  UIComponent(map_panel:Find("jap_tut")):SetVisible(false)
  UIComponent(map_panel:Find("jap_bos")):SetVisible(false)
end

function ShowMap(region, mouseon_highlighting)
  UIComponent(this:Find("speechbox")):PropagateVisibility(false)
  map_panel:SetVisible(true)
  SetMapTheatreByKey(theatre)
  out.dylan("ShowMap called, theatre = " .. theatre)
  local map = GetTheatreMapComponentByKey(theatre)
  map:SetVisible(true)
  local internal_map = UIComponent(UIComponent(map:Find("Blank")):Find("map"))
  if mouseon_highlighting then
    internal_map:LuaCall("SetHighlightQueryFunction", HighlightRegion)
  else
    internal_map:LuaCall("SetHighlightQueryFunction", nil)
  end
  highlighted_region = region
  if region ~= nil then
    internal_map:LuaCall("SetHighlightedRegionByAddress", region.Address)
  end
end

function RebuildActionButtons()
  if negotiation ~= nil then
    ClearDiplomaticOptions()
    local details = negotiation:BuildPossibleActions()
    local faction_list = UIComponent(this:Find("faction_left"))
    local menu1 = faction_list:Find("menu_1")
    local y = CreateButtons(details.Unilaterals, menu1, 1)
    CreateButtons(details.OffersAndDemands, menu1, y)
  end
end

function InitialiseMilitaryAccess()
  ShowSubPopup("access")
  local access = UIComponent(sub_panel_group:Find("access"))
  local offer_access = UIComponent(access:Find("offer_access"))
  local demand_access = UIComponent(access:Find("demand_access"))
  local offer_default, demand_default = CampaignUI.RetrieveRemainingMilitaryAccessTurns(player_faction, opposing_faction)
  InitialiseMilitaryAccessButtons(offer_access, offer_default)
  InitialiseMilitaryAccessButtons(demand_access, demand_default)
end

function InitialiseMilitaryAccessButtons(component, default)
  local button_group = UIComponent(component:Find("ButtonGroup"))
  local buttons = {
    UIComponent(button_group:Find("0")),
    UIComponent(button_group:Find("5")),
    UIComponent(button_group:Find("10")),
    UIComponent(button_group:Find("20")),
    UIComponent(button_group:Find("indefinite"))
  }
  local texts = {
    UIComponent(component:Find("0_tx")),
    UIComponent(component:Find("5_tx")),
    UIComponent(component:Find("10_tx")),
    UIComponent(component:Find("20_tx"))
  }
  local values = {
    0,
    5,
    10,
    20
  }
  for i = 1, 4 do
    buttons[i]:SetState("normal")
    texts[i]:SetStateText(values[i])
  end
  local selected
  if default < 0 then
    for i = 1, 4 do
      buttons[i]:SetState("inactive")
    end
    selected = 5
  else
    for i = 1, 3 do
      if default < values[i + 1] then
        texts[i]:SetStateText(default)
        selected = i
        break
      else
        buttons[i]:SetState("inactive")
      end
    end
    if selected == nil then
      texts[4]:SetStateText(default)
      selected = 4
    end
  end
  button_group:LuaCall("SelectButton", buttons[selected]:Address())
end

function InitialiseMarriage()
  ShowSubPopup("marriage")
  this:InterfaceFunction("PopulateMarriageLists")
end

function OkMarriage()
  local proposal_made = false
  if negotiation ~= nil then
    local marriage = UIComponent(this:Find("marriage"))
    local princess_tag = UIComponent(marriage:Find("tx_no_princess"))
    local list_view = UIComponent(princess_tag:Parent())
    local list_box = UIComponent(list_view:Find("list_box"))
    local wife_offered
    for i = 0, list_box:ChildCount() - 1 do
      local child = UIComponent(list_box:Find(i))
      if child:GetStateText() ~= "row_example" and (child:CurrentState() == "selected" or child:CurrentState() == "selected_roll") then
        local wife_name = UIComponent(child:Find("dy_name")):GetStateText()
        wife_offered = wife_name
      end
    end
    local prince_tag = UIComponent(marriage:Find("tx_no_prince"))
    list_view = UIComponent(prince_tag:Parent())
    list_box = UIComponent(list_view:Find("list_box"))
    local wife_demanded_for
    for i = 0, list_box:ChildCount() - 1 do
      local child = UIComponent(list_box:Find(i))
      if child:GetStateText() ~= "row_example" and (child:CurrentState() == "selected" or child:CurrentState() == "selected_roll") then
        local prince_name = UIComponent(child:Find("dy_name")):GetStateText()
        wife_demanded_for = prince_name
      end
    end
    if safe_to_propose then
      if wife_offered ~= nil then
        negotiation:Propose("no_faction", wife_offered, current_action.Action)
        proposal_made = true
      elseif wife_demanded_for ~= nil then
        negotiation:Propose(opposing_faction, wife_demanded_for, current_action.Action)
        proposal_made = true
      end
    end
  end
  ClearSubPopups(proposal_made)
end

function InitialiseHostages()
  ShowSubPopup("hostages")
  this:InterfaceFunction("PopulateHostageLists")
end

function OkHostage()
  local proposal_made = false
  if negotiation ~= nil then
    local hostages = UIComponent(this:Find("hostages"))
    local list_view = UIComponent(hostages:Find("listview"))
    local list_box = UIComponent(list_view:Find("list_box"))
    local hostage_offered, hostage_offered_uid, hostage_demanded_for
    for i = 0, list_box:ChildCount() - 1 do
      local child = UIComponent(list_box:Find(i))
      if child:GetStateText() ~= "row_example" and (child:CurrentState() == "selected" or child:CurrentState() == "selected_roll") then
        local hostage_name = UIComponent(child:Find("dy_name")):GetStateText()
        hostage_offered = hostage_name
        hostage_offered_uid = child:GetProperty("uid")
      end
    end
    local checkbox = UIComponent(hostages:Find("checkbox_demand_hostage"))
    hostage_demanded_for = string.sub(checkbox:GetStateText(), 8, -1) == "selected"
    if safe_to_propose then
      if hostage_offered ~= nil then
        negotiation:Propose(hostage_offered_uid, current_action.Action)
        proposal_made = true
      elseif hostage_demanded_for ~= nil then
        negotiation:Propose("demand_hostage", current_action.Action)
        proposal_made = true
      end
    end
  end
  ClearSubPopups(proposal_made)
end

function AcceptMilitaryAccess()
  local access = UIComponent(sub_panel_group:Find("access"))
  local offer_access = UIComponent(access:Find("offer_access"))
  local demand_access = UIComponent(access:Find("demand_access"))
  local offer = UIComponent(offer_access:Find("ButtonGroup")):LuaCall("SelectedButton")
  local demand = UIComponent(demand_access:Find("ButtonGroup")):LuaCall("SelectedButton")
  local proposal_made = false
  if safe_to_propose and (0 < offer or 0 < demand) then
    negotiation:Propose(offer, demand, current_action.Action)
    proposal_made = true
  end
  ClearSubPopups(proposal_made)
end

function InitialisePayments()
  ShowSubPopup("payments")
  local payments = UIComponent(this:Find("payments"))
  local amount = UIComponent(payments:Find("amount"))
  local turns = UIComponent(payments:Find("turns"))
  local bg = UIComponent(payments:Find("ButtonGroup"))
  local offer_demand = UIComponent(payments:Find("ButtonGroup_offer_demand"))
  bg:LuaCall("SelectButton", bg:Find(1))
  offer_demand:LuaCall("SelectButton", offer_demand:Find(0))
  amount:LuaCall("SetValue", 0)
  turns:LuaCall("SetValue", 0)
  turns:SetGlobal("g_notify_func", CheckMaxTurns)
end

function CheckMaxTurns(turns)
  if g_checking_max_turns ~= true then
    g_checking_max_turns = true
    local turns_component = UIComponent(UIComponent(this:Find("payments")):Find("turns"))
    turns_component:LuaCall("SetValue", turns_component:LuaCall("CheckMax", turns))
    g_checking_max_turns = false
  end
end

function AcceptOffer()
  out.shane("diplomacy_panel: AcceptOffer()")
  if in_session == true then
    negotiation:AcceptOffer()
    local button_set = UIComponent(this:Find("button_set2"))
    UIComponent(button_set:Find("button_accept")):SetState("inactive")
  elseif CampaignUI.IsPlayersTurn() then
    ready_to_close = false
    EndNegotiation()
    Initialise(opposing_faction)
  else
    EndNegotiation()
    ClosePopup()
  end
end

function DeclineOffer()
  ShaneOutput("DeclineOffer")
  if in_session == true then
    negotiation:DeclineOffer()
  elseif CampaignUI.IsPlayersTurn() then
    ShowDiplomaticRelationsLists()
  else
    ClosePopup()
  end
end

function CounterOffer()
  negotiation:PrepareCounterOffer()
  out.dylan("Setting offers/demands interactive")
  local offers_demands = UIComponent(this:Find("offers_demands"))
  local offers_list = UIComponent(UIComponent(offers_demands:Find("list_offers")):Find("list_box"))
  local demands_list = UIComponent(UIComponent(offers_demands:Find("list_demands")):Find("list_box"))
  for i = 0, offers_list:ChildCount() - 1 do
    UIComponent(offers_list:Find(i)):SetInteractive(true)
  end
  for i = 0, demands_list:ChildCount() - 1 do
    UIComponent(demands_list:Find(i)):SetInteractive(true)
  end
end

function ThreatOfForce()
  if negotiation ~= nil then
    negotiation:ProposeDeal(true)
    safe_to_propose = false
  end
end

function OkPayments()
  local payments = UIComponent(this:Find("payments"))
  local amount = UIComponent(payments:Find("amount"))
  local turns = UIComponent(payments:Find("turns"))
  local button_group = UIComponent(payments:Find("ButtonGroup"))
  local button_group_offer_demand = UIComponent(payments:Find("ButtonGroup_offer_demand"))
  local payments_value = tonumber(amount:LuaCall("CurrentValue"))
  local turns_value = tonumber(turns:LuaCall("CurrentValue"))
  local pay_once = button_group:LuaCall("SelectedButton") == 1
  local offered = button_group_offer_demand:LuaCall("SelectedButton") == 0
  if payments_value == nil then
    payments_value = 0
  end
  if turns_value == nil then
    turns_value = 0
  end
  local proposal_made = false
  if safe_to_propose and 0 < payments_value and (pay_once == true or 0 < turns_value) then
    negotiation:Propose(offered, payments_value, turns_value, pay_once == false, current_action.Action)
    proposal_made = true
  end
  ClearSubPopups(proposal_made)
end

function ClosedByCloseButton()
  if g_closeable ~= false then
    out.shane("diplomacy_panel: closed by close button, negotiation = " .. tostring(negotiation))
    if negotiation ~= nil then
      if CampaignUI.IsPlayersTurn() or negotiation:Finished() then
        EndNegotiation()
      else
        out.shane("diplomacy_panel: negotiation:DeclineOffer()")
        negotiation:DeclineOffer()
      end
    end
    ClosePopup()
  end
end

function ClosePopup()
  out.shane("diplomacy_panel: ClosePopup()")
  UIComponent(Component.Root()):LuaCall("ClosePopup", this:Address())
  EndNegotiation()
end

function ClosePopupSoftly()
  out.shane("diplomacy_panel: ClosePopupSoftly()")
  safe_to_propose = false
  if ready_to_close == true then
    ClearSubPopups()
    SetCloseable(true)
    ClosePopup()
  else
    ready_to_close = true
  end
end

function HighlightRegion(ownerKey, regionAddress)
  if proposer_regions ~= nil then
    for i = 1, #proposer_regions do
      if proposer_regions[i].Address == regionAddress then
        return true
      end
    end
  end
  if recipient_regions ~= nil then
    for i = 1, #recipient_regions do
      if recipient_regions[i].Address == regionAddress then
        return true
      end
    end
  end
  return false
end

function RegionClicked(region)
  if not UIComponent(this:Find("regions")):Visible() then
    return
  end
  local r
  if proposer_regions ~= nil then
    for i = 1, #proposer_regions do
      if proposer_regions[i].Address == region.Address then
        r = proposer_regions[i]
        break
      end
    end
  end
  if r == nil and recipient_regions ~= nil then
    for i = 1, #recipient_regions do
      if recipient_regions[i].Address == region.Address then
        r = recipient_regions[i]
        break
      end
    end
  end
  if r ~= nil then
    r.Selected = not r.Selected
    if r.Selected then
      UIComponent(r.Item:Find("checkbox")):SetState("Selected")
    else
      UIComponent(r.Item:Find("checkbox")):SetState("Normal")
    end
    MapShowRegion(r.Address, r.Selected)
  end
end

function MultiplayerTimeRemaining()
  return utils.Max(0, mp_action_timer.timeout - CampaignUI.Time())
end

function MultiplayerTimerSet(type)
  if mp_timed_button ~= nil and (type == MP_ACTION_TIMER_NONE or MultiplayerTimeRemaining() < mp_action_times[type]) then
    mp_action_timer.type = type
    mp_action_timer.timeout = CampaignUI.Time() + mp_action_times[type]
    CampaignUI.AddOrRefreshButtonTimer(mp_timed_button, mp_action_times[type])
  end
end

function MultiplayerClearButtonExtras(clear_action_time)
  if clear_action_time then
    MultiplayerTimerSet(MP_ACTION_TIMER_NONE)
  end
  main_panel_timer:PropagateVisibility(false)
  if mp_timed_button ~= nil then
    CampaignUI.RemoveButtonTimer(mp_timed_button)
    mp_timed_button = nil
  end
end

function MultiplayerSetButtonTimer(button_ptr, timer_type)
  MultiplayerClearButtonExtras(false)
  main_panel_timer:SetVisible(button_ptr ~= nil)
  if button_ptr ~= nil then
    CampaignUI.AddOrRefreshButtonTimer(button_ptr, timer_type ~= nil and mp_action_times[timer_type] or 0)
    mp_timed_button = button_ptr
  end
end

function MultiplayerTimerRunOutEvent()
  local subpanel_open = current_subpopup ~= nil
  if mp_timed_button ~= nil then
    UIComponent(mp_timed_button):ForceEvent("OnMouseLClickUp")
  end
  if not subpanel_open then
    MultiplayerClearButtonExtras(false)
  end
end
