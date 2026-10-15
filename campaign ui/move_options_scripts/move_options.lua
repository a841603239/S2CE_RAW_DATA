local root = UIComponent(Component.Root())
local this = UIComponent(Address)
local m_faction, m_layout_text_title, m_layout_text_box, m_layout_text_button
local m_altered_for_allegiance = false

function Initialise(details)
  if details ~= nil then
    m_faction = details.Faction.Key
    UIComponent(this:Find("options_bar2")):SetVisible(not details.IsAttack and not details.WarOnlyOption)
    if details.WarOnlyOption then
      UIComponent(this:Find("title_frame")):SetState("WarRequired")
      UIComponent(this:Find("text_box")):SetState("war_required")
    end
    if details.WarNotAnOption == true then
      UIComponent(this:Find("options_bar1")):SetState("inactive")
    else
      UIComponent(this:Find("options_bar1")):SetState("unselected")
    end
    if details.WarNotAllowedDueToVassal == true then
      UIComponent(this:Find("options_bar1")):SetTooltipText(CampaignUI.LocalisationString("move_options_vassal_cannot_declare_war"))
    end
  end
  local cancel_disabled = CampaignUI.MoveOptionsCancelDisabled()
  local cancel_button_text = UIComponent(UIComponent(this:Find("options_bar3")):Find("button_txt"))
  if cancel_button_text:GetStateText() ~= CampaignUI.LocalisationString("bribe_nonhostile_cancel") and cancel_button_text:GetStateText() ~= CampaignUI.LocalisationString("allegiance_nonhostile_cancel") then
    m_layout_text_title = UIComponent(this:Find("title_frame")):GetStateText()
    m_layout_text_box = UIComponent(this:Find("text_box")):GetStateText()
    m_layout_text_button = cancel_button_text:GetStateText()
  end
  UIComponent(this:Find("options_bar3")):SetState(cancel_disabled and "inactive" or "unselected")
  if cancel_disabled == false then
    this:StealShortcutKey("ESCAPE")
  end
  if m_altered_for_allegiance == true then
    local bar1 = UIComponent(this:Find("options_bar1"))
    local bx, by = bar1:Position()
    bar1:MoveTo(bx, by - 50)
    local text_box = UIComponent(UIComponent(this:Find("panel")):Find("text_box"))
    text_box:Resize(text_box:Width(), text_box:Height() - 50)
    m_altered_for_allegiance = false
  end
  if details ~= nil then
    if details.IsFromBribe then
      UIComponent(this:Find("options_bar2")):SetVisible(false)
      UIComponent(this:Find("title_frame")):SetStateText(CampaignUI.LocalisationString("bribe_nonhostile_panel_title"))
      UIComponent(this:Find("text_box")):SetStateText(CampaignUI.LocalisationString("bribe_nonhostile_description"))
      cancel_button_text:SetStateText(CampaignUI.LocalisationString("bribe_nonhostile_cancel"))
    elseif details.IsFromAllegiance then
      if m_altered_for_allegiance == false then
        local bar1 = UIComponent(this:Find("options_bar1"))
        local bx, by = bar1:Position()
        bar1:MoveTo(bx, by + 50)
        local text_box = UIComponent(UIComponent(this:Find("panel")):Find("text_box"))
        text_box:Resize(text_box:Width(), text_box:Height() + 50)
        m_altered_for_allegiance = true
      end
      UIComponent(this:Find("options_bar2")):SetVisible(false)
      UIComponent(this:Find("title_frame")):SetStateText(CampaignUI.LocalisationString("allegiance_nonhostile_panel_title"))
      UIComponent(this:Find("text_box")):SetStateText(CampaignUI.LocalisationString("allegiance_nonhostile_description"))
      cancel_button_text:SetStateText(CampaignUI.LocalisationString("allegiance_nonhostile_cancel"))
    elseif details.IsFromSeduction then
      UIComponent(this:Find("options_bar2")):SetVisible(false)
      UIComponent(this:Find("title_frame")):SetStateText(CampaignUI.LocalisationString("seduce_nonhostile_panel_title"))
      UIComponent(this:Find("text_box")):SetStateText(CampaignUI.LocalisationString("seduce_nonhostile_description"))
      cancel_button_text:SetStateText(CampaignUI.LocalisationString("allegiance_nonhostile_cancel"))
    elseif details.IsFromCoerce then
      UIComponent(this:Find("options_bar2")):SetVisible(false)
      UIComponent(this:Find("title_frame")):SetStateText(CampaignUI.LocalisationString("bos_bribe_coerce_panel_title"))
      UIComponent(this:Find("text_box")):SetStateText(CampaignUI.LocalisationString("bos_bribe_coerce_description"))
      cancel_button_text:SetStateText(CampaignUI.LocalisationString("bos_bribe_nonhostile_cancel"))
    elseif details.IsFromPersuade then
      UIComponent(this:Find("options_bar2")):SetVisible(false)
      UIComponent(this:Find("title_frame")):SetStateText(CampaignUI.LocalisationString("bos_bribe_persuade_panel_title"))
      UIComponent(this:Find("text_box")):SetStateText(CampaignUI.LocalisationString("bos_bribe_persuade_description"))
      cancel_button_text:SetStateText(CampaignUI.LocalisationString("bos_bribe_nonhostile_cancel"))
    elseif details.IsFromEnchant then
      UIComponent(this:Find("options_bar2")):SetVisible(false)
      UIComponent(this:Find("title_frame")):SetStateText(CampaignUI.LocalisationString("bos_bribe_enchant_panel_title"))
      UIComponent(this:Find("text_box")):SetStateText(CampaignUI.LocalisationString("bos_bribe_enchant_description"))
      cancel_button_text:SetStateText(CampaignUI.LocalisationString("bos_bribe_nonhostile_cancel"))
    elseif m_layout_text_title ~= nil and m_layout_text_box ~= nil and m_layout_text_button ~= nil then
      UIComponent(this:Find("title_frame")):SetStateText(m_layout_text_title)
      UIComponent(this:Find("text_box")):SetStateText(m_layout_text_box)
      cancel_button_text:SetStateText(m_layout_text_button)
    end
  end
  if details ~= nil then
    local tx_box = UIComponent(UIComponent(this:Find("panel")):Find("text_box"))
    local treaty_text = UIComponent(this:Find("tx_treaty_cooldown_warning"))
    local treaty_turns = UIComponent(treaty_text:Find("dy_turns"))
    local cooldown = UIComponent(treaty_text:Find("tx_treaty_cooldown_turns"))
    local bx, by = tx_box:Position()
    local tx, ty = treaty_text:Position()
    treaty_text:MoveTo(tx, by + tx_box:Height())
    treaty_text:SetVisible(details.TreatyWarningTurns ~= nil and details.TreatyWarningTurns > 0)
    treaty_turns:SetStateText(details.TreatyWarningTurns)
    cooldown:SetVisible(details.ShowWarningTurns)
  end
end

function OnExit()
end

function OnKey(key, v, ended)
  if key == "ESCAPE" and ended then
    CancelMove()
  end
end

function OnShortcut()
end

function DeclareWar()
  root:LuaCall("HideMoveOptionsPopup", m_faction, "DeclareWar")
end

function RequestAccess()
  root:LuaCall("HideMoveOptionsPopup", m_faction, "RequestAccess")
end

function CancelMove()
  root:LuaCall("HideMoveOptionsPopup")
end
