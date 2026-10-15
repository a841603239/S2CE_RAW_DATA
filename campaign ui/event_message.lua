local utils = require("Utilities")
local this = UIComponent(Address)
local m_details
local m_position = {}
local m_current_layout
local m_old_pri = 0
local panel_manager = PanelManager
local message_handler = MessageManager
local needs_ally_decision = false
local ally_decision_made = false
this:SetEventCallback("OnDestroyed", OnDestroyed)
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function IconDestroyed()
  m_details.Parent = nil
end

function InitStandardDetails(root, details)
  if #details.Image == 0 then
    image = UIImage("data/ui/eventpics/" .. CampaignUI.PlayersCulture() .. "/envelope.tga")
  else
    image = UIImage(details.Image)
  end
  if root:Find("event_pic") ~= nil then
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  local title = UIComponent(root:Find("dy_title"))
  title:SetStateText(details.Title, true, 1)
  if details.Data.SubTitle == nil or 1 >= #details.Data.SubTitle then
    details.Data.SubTitle = ""
    UIComponent(root:Find("dy_fields")):SetVisible(false)
    UIComponent(root:Find("subheader_frame")):SetVisible(false)
  else
    UIComponent(root:Find("dy_fields")):SetVisible(true)
    UIComponent(root:Find("subheader_frame")):SetVisible(true)
  end
  UIComponent(root:Find("dy_fields")):SetStateText(details.Data.SubTitle, true, 1)
end

function InitialiseStandard(root, details)
  InitStandardDetails(root, details)
  local textview = UIComponent(root:Find("TextView"))
  local txt = details.Data.Text ~= nil and details.Data.Text or details.Text
  if details.Data.ExtraText ~= nil then
    txt = txt .. details.Data.ExtraText
  end
  if details.Data.MoviePath ~= nil and string.length(details.Data.MoviePath) > 0 and root:Find("event_pic") ~= nil then
    CampaignUI.AttachMovieToComponent(root:Find("event_pic"), details.Data.MoviePath)
  end
  textview:LuaCall("SetText", txt)
  textview:LuaCall("MessageEventResize")
  local slider = UIComponent(root:Find("vslider"))
  slider:LuaCall("Reset")
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY,
    Z = details.Data.PosZ
  }
end

function InitialiseIncident(root, details)
  image = UIImage(details.Data.Image)
  if root:Find("event_pic") ~= nil then
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  local title = UIComponent(root:Find("dy_title"))
  UIComponent(root:Find("dy_title")):SetStateText(details.Data.Title, true, 1)
  UIComponent(root:Find("dy_fields")):SetVisible(false)
  local subtitle = UIComponent(root:Find("dy_subheader_target"))
  subtitle:SetStateText(details.Data.Target, true, 1)
  if 1 >= #details.Data.Target then
    subtitle:SetVisible(false)
  else
    subtitle:SetVisible(true)
  end
  local txt = details.Data.Text ~= nil and details.Data.Text or details.Text
  if details.Data.ExtraText ~= nil then
    txt = txt .. details.Data.ExtraText
  end
  local text_comp = UIComponent(root:Find("dy_details_text")):SetStateText(txt)
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY,
    Z = details.Data.PosZ
  }
end

function InitialiseMission(root, details)
  image = UIImage(details.Data.Image)
  if root:Find("event_pic") ~= nil then
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  UIComponent(root:Find("dy_title")):SetStateText(details.Data.MainTitle, true, 1)
  UIComponent(root:Find("dy_fields")):SetStateText(details.Data.Title, true, 1)
  local txt = details.Data.Text ~= nil and details.Data.Text or details.Text
  if details.Data.ExtraText ~= nil then
    txt = txt .. details.Data.ExtraText
  end
  local text_comp = UIComponent(root:Find("Text")):SetStateText("\n" .. txt)
  local objectives = UIComponent(root:Find("mission_objectives"))
  if details.Data.ObjectivesText ~= nil then
    objectives:SetVisible(true)
    UIComponent(root:Find("dy_choice_text")):SetStateText(details.Data.ObjectivesText)
  else
    objectives:SetVisible(false)
  end
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY,
    Z = details.Data.PosZ
  }
  UIComponent(root:Find("reward_window")):SetVisible(details.Data.HideReward == nil)
end

function InitialiseFame(root, details)
  InitStandardDetails(root, details)
  local textview = UIComponent(root:Find("TextView"))
  local txt = details.Data.Text ~= nil and details.Data.Text or details.Text
  if details.Data.ExtraText ~= nil then
    txt = txt .. details.Data.ExtraText
  end
  textview:LuaCall("SetText", txt)
  local slider = UIComponent(root:Find("vslider"))
  slider:LuaCall("Reset")
  local int_fame, prestige, is_shogun, max_prestige = CampaignUI.GetFameDetails()
  local fame_field = UIComponent(root:Find("clan_fame_value"))
  fame_field:SetState("fame_" .. tostring(int_fame))
  if is_shogun then
    fame_field:SetTooltipText("", true)
  end
  if CampaignUI.IsGempei() then
    if 0 <= int_fame and int_fame <= 4 then
      fame_field:SetTooltipText(CampaignUI.LocalisationString("clan_fame_tooltip_" .. tostring(int_fame)), false)
    end
    local clan_fame_parent = UIComponent(root:Find("clan_fame"))
    UIComponent(clan_fame_parent:Find("tooltip_box")):SetTooltipText(CampaignUI.LocalisationString("clan_fame_tooltip_general"), true)
    UIComponent(clan_fame_parent:Find("fame_bar")):SetTooltipText(CampaignUI.LocalisationString("clan_fame_tooltip_general"), true)
    UIComponent(clan_fame_parent:Find("fame_bar_fill")):SetTooltipText(CampaignUI.LocalisationString("clan_fame_tooltip_general"), true)
  elseif CampaignUI.IsBoshin() then
    local title = UIComponent(root:Find("dy_title"))
    local title_text = ""
    if int_fame <= 0 then
      fame_field:SetTooltipText(CampaignUI.LocalisationString("bos_fame_tooltip_level_0_both"), false)
      title_text = CampaignUI.LocalisationString("bos_fame_title_level_0_both")
    else
      local religion_key = CampaignUI.PlayerReligionKey()
      if religion_key == "inf_bos_imperial" then
        fame_field:SetTooltipText(CampaignUI.LocalisationString("bos_fame_tooltip_level_" .. tostring(int_fame) .. "_imperial"), false)
        title_text = CampaignUI.LocalisationString("bos_fame_title_level_" .. tostring(int_fame) .. "_imperial")
      elseif religion_key == "inf_bos_shogunate" then
        fame_field:SetTooltipText(CampaignUI.LocalisationString("bos_fame_tooltip_level_" .. tostring(int_fame) .. "_shogun"), false)
        title_text = CampaignUI.LocalisationString("bos_fame_title_level_" .. tostring(int_fame) .. "_shogun")
      else
        fame_field:SetTooltipText(CampaignUI.LocalisationString("bos_fame_tooltip_level_4_self"), false)
        title_text = CampaignUI.LocalisationString("bos_fame_title_level_4_self")
      end
    end
    fame_field:SetStateText(title_text)
    title:SetStateText(title_text)
  end
  local bar = UIComponent(root:Find("fame_bar"))
  local bar_fill = UIComponent(root:Find("fame_bar_fill"))
  local max_width = bar:Width()
  local progression = 0
  if max_prestige ~= 0 then
    progression = prestige / max_prestige
  end
  local final_width = progression * max_width
  if final_width < 1 then
    final_width = 1
  end
  if max_width < final_width then
    final_width = max_width
  end
  bar_fill:Resize(final_width, bar_fill:Height())
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY,
    Z = details.Data.PosZ
  }
end

function InitialiseUnitRouts(root, details)
  local image = UIImage(details.Image)
  local portrait = root:Find("unit_portrait")
  image:SetComponentTexture(portrait, 0)
  UIComponent(root:Find("dy_title")):SetStateText(details.Title)
  UIComponent(root:Find("dy_fields")):SetStateText(details.Data.SubTitle)
  UIComponent(root:Find("TextView")):LuaCall("SetText", details.Text)
  UIComponent(root:Find("vslider")):LuaCall("Reset")
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY,
    Z = details.Data.PosZ,
    Facing = details.Data.Facing
  }
end

function InitialiseUnitRecruited(root, details)
  UIComponent(root:Find("dy_title")):SetStateText(details.Title, true, 1)
  UIComponent(root:Find("dy_fields")):SetStateText(details.Data.SubTitle, true, 1)
  local textview = UIComponent(root:Find("TextView"))
  textview:LuaCall("SetText", details.Data.Unit.Description)
  if #details.Data.OrderedBy > 0 then
    UIComponent(root:Find("DY_ordered_by")):SetStateText(details.Data.OrderedBy)
    UIComponent(root:Find("DY_location")):SetStateText(details.Data.OrderedByLocation)
    UIComponent(root:Find("TX_ordered_by")):SetVisible(true)
    UIComponent(root:Find("TX_location")):SetVisible(true)
  else
    local ordered = UIComponent(root:Find("TX_ordered_by"))
    local pos_x, pos_y = ordered:Position()
    pos_x = textview:Position()
    UIComponent(root:Find("TX_ordered_by")):SetVisible(false)
    UIComponent(root:Find("TX_location")):SetVisible(false)
    local panel = UIComponent(root:Find("textpanel"))
  end
  local info_pic = root:Find("unit_portrait")
  if details.Data.Unit.IsNaval == true then
    info_pic = root:Find("ship_portrait")
  end
  image = UIImage(details.Data.Unit.InfoPic .. ".tga")
  image:SetComponentTexture(info_pic, 0)
  local slider = UIComponent(root:Find("vslider"))
  slider:LuaCall("Reset")
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
end

function InitialiseAgentRecruited(root, details)
  UIComponent(root:Find("dy_title")):SetStateText(details.Title, true, 1)
  UIComponent(root:Find("dy_fields")):SetStateText(details.Data.SubTitle, true, 1)
  image = UIImage(details.Data.Portrait)
  image:SetComponentTexture(root:Find("char_portrait"), 0)
  local textview = UIComponent(root:Find("TextView"))
  textview:LuaCall("SetText", details.Text .. details.Data.ExtraText)
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
end

function InitialiseBuildingConstructed(root, details)
  if details.Title ~= nil then
    UIComponent(root:Find("dy_title")):SetStateText(details.Title, true, 1)
  end
  if details.Data.SubTitle ~= nil then
    UIComponent(root:Find("dy_fields")):SetStateText(details.Data.SubTitle, true, 1)
  end
  if details.Data.ShortDescription ~= nil then
    UIComponent(root:Find("Text")):SetStateText(details.Data.ShortDescription)
  elseif details.ExtraText ~= nil then
    UIComponent(root:Find("Text")):SetStateText(details.ExtraText)
  end
  if details.Data.Location ~= nil then
    UIComponent(root:Find("DY_location")):SetStateText(details.Data.Location)
    UIComponent(root:Find("TX_location")):SetVisible(true)
  else
    UIComponent(root:Find("TX_location")):SetVisible(false)
  end
  out.dylan("Building constructed icon: " .. details.Data.InfoPic)
  image = UIImage(details.Data.InfoPic)
  image:SetComponentTexture(root:Find("info_pic"), 0)
  out.dylan("Building constructed image: " .. details.Image)
  image2 = UIImage(details.Image)
  image2:SetComponentTexture(root:Find("event_pic"), 0)
  local slider = UIComponent(root:Find("vslider"))
  slider:LuaCall("Reset")
  slider:SetVisible(true)
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
end

function InitialiseBuildList(root, details)
  local list = root:Find("list_box")
  UIComponent(list):DestroyChildren()
  local bg_type = true
  if details.Data.Event == "summary_recruitment" then
    UIComponent(root:Find("dy_title")):SetState("units")
    for i, v in ipairs(details.Data) do
      local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/unit_trained_entry", "entry" .. i, list, 0, 0))
      entry:LuaCall("Initialise", v, bg_type, OnZoomTo)
      bg_type = not bg_type
    end
  elseif details.Data.Event == "summary_recruitment_ships" then
    UIComponent(root:Find("dy_title")):SetState("ships")
    for i, v in ipairs(details.Data) do
      local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/unit_trained_entry", "entry" .. i, list, 0, 0))
      entry:LuaCall("Initialise", v, bg_type, OnZoomTo)
      bg_type = not bg_type
    end
  elseif details.Data.Event == "summary_construction" then
    UIComponent(root:Find("dy_title")):SetState("buildings")
    for i, v in ipairs(details.Data) do
      local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/building_constructed_entry", "entry" .. i, list, 0, 0))
      entry:LuaCall("Initialise", v, bg_type, OnZoomTo)
      bg_type = not bg_type
    end
  elseif details.Data.Event == "boshin_distract_garrison" then
    UIComponent(root:Find("dy_title")):SetStateText(details.Title)
    for i = 1, details.Data.NumUnits do
      local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/unit_trained_entry", "entry" .. i, list, 0, 0))
      local unit_id = "Unit_" .. tostring(i)
      entry:LuaCall("InitialiseFromRecord", details, details.Data[unit_id], bg_type, OnZoomTo)
      bg_type = not bg_type
    end
  end
  UIComponent(list):Layout()
end

function InitialiseAttrition(root, details)
  ShaneOutput("** InitialiseAttrition ** #details.Data = " .. tostring(#details.Data))
  local list = root:Find("list_box")
  UIComponent(list):DestroyChildren()
  local bg_type = true
  if details.Data.Event == "summary_attrition" then
    UIComponent(root:Find("dy_title")):SetState("attrition")
  elseif details.Data.Event == "summary_bombardment" then
    UIComponent(root:Find("dy_title")):SetState("bombardment")
  elseif details.Data.Event == "summary_trade_raiding" then
    UIComponent(root:Find("dy_title")):SetState("raided")
  end
  for i, v in ipairs(details.Data) do
    local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/attrition_entry", "entry" .. i, list, 0, 0))
    entry:LuaCall("Initialise", v, bg_type)
    bg_type = not bg_type
  end
  UIComponent(list):Layout()
end

function InitialiseTraitsAncList(root, details)
  ShaneOutput("** InitialiseTraitsAncList **")
  local list = root:Find("list_box")
  UIComponent(list):DestroyChildren()
  local bg_type = true
  UIComponent(root:Find("dy_title")):SetStateText(details.Title)
  for i, v in ipairs(details.Data) do
    local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/traits_ancs_entry", "entry" .. i, list, 0, 0))
    entry:LuaCall("Initialise", v, bg_type, OnZoomTo)
    bg_type = not bg_type
  end
  UIComponent(list):Layout()
end

function InitialiseSabotage(root, details)
  UIComponent(root:Find("dy_title")):SetStateText(details.Title)
  UIComponent(root:Find("DY_target_location")):SetStateText(details.Data.Location)
  UIComponent(root:Find("DY_target_faction")):SetStateText(details.Data.Faction)
  UIComponent(root:Find("DY_saboteur")):SetStateText(details.Data.AgentName)
  UIComponent(root:Find("main_text")):SetStateText(details.Text)
  if #details.Image > 0 and root:Find("event_pic") ~= nil then
    image = UIImage(details.Image)
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  if 0 < #details.Data.Mon and root:Find("mon") ~= nil then
    mon_image = UIImage(details.Data.Mon)
    mon_image:SetComponentTexture(root:Find("mon"), 0)
  end
  local target_txt = UIComponent(root:Find("dy_fields"))
  target_txt:SetStateText(details.Data.Target)
  if #details.Data.Target <= 1 then
    UIComponent(root:Find("TX_target")):SetVisible(false)
    target_txt:SetVisible(false)
  else
    UIComponent(root:Find("TX_target")):SetVisible(true)
    target_txt:SetVisible(true)
  end
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
end

function InitialiseMarriageProposal(root, details)
  UIComponent(root:Find("dy_title")):SetStateText(details.Title)
  UIComponent(root:Find("TextView")):LuaCall("SetText", details.Text)
  UIComponent(root:Find("dy_fields")):SetVisible(false)
  if #details.Image > 0 and root:Find("event_pic") ~= nil then
    image = UIImage(details.Image)
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  local bride = UIComponent(root:Find("portrait1_frame"))
  if 0 < #details.Data.PortraitBride then
    image = UIImage(details.Data.PortraitBride)
    image:SetComponentTexture(bride:Find("image"), 0)
  end
  local bride_name = UIComponent(bride:Find("dy_title"))
  bride_name:SetStateText(details.Data.NameBride)
  UIComponent(root:Find("dy_trait")):SetStateText(details.Data.TraitName)
  UIComponent(root:Find("trait_icon")):SetTooltipText(details.Data.TraitTooltip)
  if #details.Data.TraitName <= 1 then
    UIComponent(root:Find("trait_icon")):SetVisible(false)
  else
    UIComponent(root:Find("trait_icon")):SetVisible(true)
  end
  UIComponent(root:Find("tx_brides_trait")):SetVisible(false)
  local son = UIComponent(root:Find("portrait2_frame"))
  if 0 < #details.Data.PortraitSon then
    image = UIImage(details.Data.PortraitSon)
    image:SetComponentTexture(son:Find("image"), 0)
  end
  local son_name = UIComponent(son:Find("dy_title"))
  son_name:SetStateText(details.Data.NameSon)
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
  msg_layout = UIComponent(this:Find(1))
  msg_layout:InterfaceFunction("Initialise", details.Data.Bride, details.Data.Son)
end

function InitialiseAssassination(root, details)
  UIComponent(root:Find("DY_target_location")):SetStateText(details.Data.Location)
  UIComponent(root:Find("DY_target_faction")):SetStateText(details.Data.Faction)
  UIComponent(root:Find("DY_saboteur")):SetStateText(details.Data.AgentName)
  UIComponent(root:Find("main_text")):SetStateText(details.Text)
  if #details.Title > 0 then
    UIComponent(root:Find("dy_title")):SetStateText(details.Title)
  end
  if 0 < #details.Image and root:Find("event_pic") ~= nil then
    image = UIImage(details.Image)
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  if 0 < #details.Data.Mon and root:Find("mon") ~= nil then
    mon_image = UIImage(details.Data.Mon)
    mon_image:SetComponentTexture(root:Find("mon"), 0)
  end
  local target_txt = UIComponent(root:Find("DY_target"))
  target_txt:SetStateText(details.Data.Target)
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY
  }
end

function InitialiseDisaster(root, details)
end

function InitialiseMarriage(root, details)
end

function InitialiseBlockade(root, details)
  UIComponent(root:Find("DY_faction")):SetStateText(details.Data.Faction)
  UIComponent(root:Find("DY_region")):SetStateText(details.Data.Region)
  UIComponent(root:Find("DY_theatre")):SetStateText(details.Data.Theatre)
  InitialiseStandard(root, details)
  UIComponent(root:Find("TX_port")):SetStateText(CampaignUI.UILocalisationString("TX_port_NewState_Text_3b0018"))
end

function InitialiseTechAdvances(root, details)
  details.Image = details.Data.Image
  InitialiseStandard(root, details)
  if details.Data.Next ~= nil then
    local next_tech = UIComponent(root:Find("DY_next_technology"))
    local x, y = UIComponent(root:Find("TX_next_technology")):Position()
    next_tech:SetStateText(details.Data.Next.Name)
    details.Data.Next.FactionKey = details.Data.FactionKey
    local c = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/technology_card", "tech", root:Find("tech_icon_placeholder"), 0, 0, {
      "{tech:1}" .. details.Data.Next.IconFilename
    }))
    c:InterfaceFunction("InitialiseFromLua", details.Data.CampaignTech)
    UIComponent(root:Find("DY_next_technology")):SetVisible(true)
    UIComponent(root:Find("tech_icon_placeholder")):SetVisible(true)
    UIComponent(root:Find("tx_research_halted")):SetVisible(false)
  else
    UIComponent(root:Find("DY_next_technology")):SetVisible(false)
    UIComponent(root:Find("tech_icon_placeholder")):SetVisible(false)
    UIComponent(root:Find("tx_research_halted")):SetVisible(true)
  end
end

function TechAvailable(tech_entry)
  return true
end

function TechDisplayOnly(tech_entry)
  return true
end

function InitialiseTechList(root, details)
  if #details.Image == 0 then
    image = UIImage("data/ui/eventpics/" .. CampaignUI.PlayersCulture() .. "/envelope.tga")
  else
    image = UIImage(details.Image)
  end
  if root:Find("event_pic") ~= nil then
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  local list = root:Find("list_box")
  UIComponent(list):DestroyChildren()
  local bg_type = true
  for i, v in ipairs(details.Data) do
    local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/tech_advances_entry", "entry" .. i, list, 0, 0))
    entry:LuaCall("Initialise", v, bg_type)
    bg_type = not bg_type
  end
  UIComponent(list):Layout()
end

function InitialiseCapitalLost(root, details)
  InitStandardDetails(root, details)
  local txt = details.Data.Text ~= nil and details.Data.Text or details.Text
  local textview = UIComponent(root:Find("TextView"))
  textview:LuaCall("SetText", txt)
  local slider = UIComponent(root:Find("vslider"))
  slider:LuaCall("Reset")
  if details.Data.ExtraText ~= nil then
    UIComponent(root:Find("DY_new capital")):SetStateText(details.Data.ExtraText)
  end
  m_position = {
    X = details.Data.PosX,
    Y = details.Data.PosY,
    Z = details.Data.PosZ
  }
end

function InitialiseRiots(root, details)
  InitialiseStandard(root, details)
  UIComponent(root:Find("DY_pop_killed")):SetStateText(details.Data.Population)
  UIComponent(root:Find("DY_buildings_damaged")):SetStateText(details.Data.Buildings)
end

function InitialiseRevolution(root, details)
  UIComponent(root:Find("dy_title")):SetStateText(details.Title)
  if details.Data.SubTitle == nil then
    details.Data.SubTitle = ""
  end
  UIComponent(root:Find("TextView")):LuaCall("SetText", details.Text)
  if #details.Image == 0 then
    image = UIImage("data/ui/eventpics/" .. CampaignUI.PlayersCulture() .. "/envelope.tga")
  else
    image = UIImage(details.Image)
  end
  if root:Find("event_pic") ~= nil then
    image:SetComponentTexture(root:Find("event_pic"), 0)
    CampaignUI.AttachMovieToComponent(root:Find("event_pic"), details.Data.MoviePath)
  end
  local revolution_panel = UIComponent(root:Find("Layout_revolution"))
  revolution_panel:LuaCall("InitialiseRevolutionPanel", details)
end

function DestroyMovie(root)
  if m_details ~= nil and m_details.Data.MoviePath ~= nil and m_details.Data.MoviePath ~= "" then
    out.tom("Destroying movie with path " .. m_details.Data.MoviePath)
    CampaignUI.StopMovieInComponent(nil)
  end
end

function InitialiseElectionResults(root, details)
  local bg_type = true
  UIComponent(root:Find("text_window")):SetStateText(details.Text)
  local list = root:Find("list_box")
  UIComponent(list):DestroyChildren()
  local player_faction = CampaignUI.PlayerFactionId()
  local home_theatre = CampaignUI.HomeTheatre(player_faction)
  local governorships = CampaignUI.GovernorshipList(player_faction)
  local home_governorship
  for i = 1, #governorships do
    if governorships[i].TheatreKey == home_theatre then
      home_governorship = governorships[i].Key
      break
    end
  end
  for i, v in ipairs(details.Data.Ministers) do
    if v.Post ~= "governor_" .. home_governorship then
      local entry = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/election_results_entry", "entry" .. i, list, 0, 0))
      entry:LuaCall("Initialise", v, bg_type)
      bg_type = not bg_type
    end
  end
  UIComponent(list):Layout()
end

local function InitAlliesList(list_address, allies, protectorates, protectors)
  local list = UIComponent(list_address)
  local bg = UIComponent(list:Find("list_box"))
  bg:DestroyChildren()
  for i, v in pairs(allies) do
    images = {
      "{miniflag:1}" .. v.Flag
    }
    text = {}
    text.faction_name = v.Name
    local icon = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_allies_list_item", "ally", bg:Address(), 0, 0, images, text))
  end
  for i, v in pairs(protectorates) do
    images = {
      "{miniflag:1}" .. v.Flag
    }
    text = {}
    text.faction_name = v.Name
    local icon = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_allies_list_item", "ally", bg:Address(), 0, 0, images, text))
  end
  for i, v in pairs(protectors) do
    images = {
      "{miniflag:1}" .. v.Flag
    }
    text = {}
    text.faction_name = v.Name
    local icon = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/diplomacy_allies_list_item", "ally", bg:Address(), 0, 0, images, text))
  end
  bg:Layout()
end

local function SetAllyButtonText(button, name)
  UIComponent(button:Find(0)):SetVisible(false)
  txt = UIComponent(button:Find(1))
  txt:SetVisible(true)
  local state_txt = CampaignUI.UILocalisationString("option2_text_normal_Text_260075")
  txt:SetStateText(CampaignUI.FormatString(state_txt, name))
end

local button_positions

function InitialiseAllyAttacked(root, details)
  local image = UIImage(details.Image)
  if root:Find("event_pic") ~= nil then
    image:SetComponentTexture(root:Find("event_pic"), 0)
  end
  local txt = UIComponent(root:Find("dy_aggressor"))
  txt:SetStateText(details.Data.Aggressor.Name)
  local txt = UIComponent(root:Find("dy_defender"))
  txt:SetStateText(details.Data.Defender.Name)
  InitAlliesList(root:Find("allies_list1"), details.Data.Aggressor.Allies, details.Data.Aggressor.Protectorates, details.Data.Aggressor.ProtectorOf)
  InitAlliesList(root:Find("allies_list2"), details.Data.Defender.Allies, details.Data.Defender.Protectorates, details.Data.Defender.ProtectorOf)
  local title = UIComponent(root:Find("dy_title"))
  local buttons = {
    top = UIComponent(root:Find("assist_button1")),
    mid = UIComponent(root:Find("assist_button2")),
    bot = UIComponent(root:Find("decline_button"))
  }
  if button_positions == nil then
    button_positions = {
      top = {
        buttons.top:Position()
      },
      mid = {
        buttons.mid:Position()
      },
      bot = {
        buttons.bot:Position()
      }
    }
  end
  if details.Data.AlliedWithAggressor and details.Data.AlliedWithDefender then
    title:SetState("tx_ally_declares_war_on_ally")
  end
  if details.Data.InvitedByAggressor and details.Data.InvitedByDefender then
    SetAllyButtonText(buttons.top, details.Data.Aggressor.Name)
    buttons.top:SetVisible(true)
    buttons.mid:SetVisible(true)
    txt = UIComponent(buttons.mid:Find(0))
    local state_txt = CampaignUI.UILocalisationString("option2_text_normal_Text_260075")
    txt:SetStateText(CampaignUI.FormatString(state_txt, details.Data.Defender.Name))
    buttons.top:SetGlobal("OnSelect", function()
      CampaignUI.SideWithAlly(details.Data.Aggressor.Key)
      OnOk()
    end)
    buttons.mid:SetGlobal("OnSelect", function()
      CampaignUI.SideWithAlly(details.Data.Defender.Key)
      OnOk()
    end)
    buttons.bot:SetGlobal("OnSelect", function()
      CampaignUI.DeclineSidingWithAlly()
      OnOk()
    end)
  elseif details.Data.InvitedByDefender then
    if details.Data.AlliedWithAggressor then
      SetAllyButtonText(buttons.top, details.Data.Defender.Name)
    else
      title:SetState("tx_ally_attacked")
      UIComponent(buttons.top:Find(0)):SetVisible(true)
      UIComponent(buttons.top:Find(1)):SetVisible(false)
    end
    buttons.mid:SetVisible(true)
    txt = UIComponent(buttons.mid:Find(0))
    local state_txt = CampaignUI.UILocalisationString("option2_text_normal_Text_260075")
    txt:SetStateText(CampaignUI.FormatString(state_txt, details.Data.Aggressor.Name))
    buttons.mid:SetState("inactive")
    if details.Data.AlliedWithAggressor then
      buttons.mid:SetTooltipText(CampaignUI.LocalisationString("declare_war_ally_not_requested_help"))
    end
    UIComponent(buttons.bot:Find(0)):SetState("tx_decline(breaks_alliance)")
    UIComponent(buttons.bot:Find(0)):SetStateText(CampaignUI.LocalisationString("decline_breaks_alliance_defender"))
    buttons.top:SetGlobal("OnSelect", function()
      CampaignUI.SideWithAlly(details.Data.Defender.Key)
      OnOk()
    end)
    buttons.bot:SetGlobal("OnSelect", function()
      CampaignUI.DeclineSidingWithAlly(details.Data.Defender.Key)
      OnOk()
    end)
  elseif details.Data.InvitedByAggressor then
    if details.Data.AlliedWithDefender then
      SetAllyButtonText(buttons.top, details.Data.Aggressor.Name)
    else
      title:SetState("tx_ally_declares_war")
      UIComponent(buttons.top:Find(0)):SetVisible(true)
      UIComponent(buttons.top:Find(1)):SetVisible(false)
    end
    buttons.mid:SetVisible(false)
    txt = UIComponent(buttons.mid:Find(0))
    local state_txt = CampaignUI.UILocalisationString("option2_text_normal_Text_260075")
    txt:SetStateText(CampaignUI.FormatString(state_txt, details.Data.Defender.Name))
    buttons.mid:SetState("inactive")
    if details.Data.AlliedWithDefender then
      buttons.mid:SetTooltipText(CampaignUI.LocalisationString("declare_war_ally_not_requested_help"))
    end
    UIComponent(buttons.bot:Find(0)):SetState("tx_decline")
    UIComponent(buttons.bot:Find(0)):SetStateText(CampaignUI.LocalisationString("decline_breaks_alliance_defender"))
    buttons.top:SetGlobal("OnSelect", function()
      CampaignUI.SideWithAlly(details.Data.Aggressor.Key)
      OnOk()
    end)
    buttons.bot:SetGlobal("OnSelect", function()
      CampaignUI.DeclineSidingWithAlly(details.Data.Aggressor.Key)
      OnOk()
    end)
  end
  if buttons.mid:Visible() == false then
    buttons.bot:MoveTo(button_positions.mid[1], button_positions.mid[2])
  else
    buttons.bot:MoveTo(button_positions.bot[1], button_positions.bot[2])
  end
  if details.Data.CanDeclineToJoin == false then
    buttons.bot:SetState("inactive")
  end
  UIComponent(buttons.bot:Find("button_default_selection")):SetVisible(false)
  UIComponent(buttons.mid:Find("button_default_selection")):SetVisible(false)
  UIComponent(buttons.top:Find("button_default_selection")):SetVisible(false)
  local highlighted_button = buttons.bot:Address()
  if CampaignUI.IsTimedMultiplayerGame() then
    if details.Data.CanDeclineToJoin then
      UIComponent(buttons.bot:Find("button_default_selection")):SetVisible(true)
    elseif buttons.mid:CurrentState() == "active" then
      UIComponent(buttons.mid:Find("button_default_selection")):SetVisible(true)
      UIComponent(buttons.top:Find("button_default_selection")):SetVisible(false)
      highlighted_button = buttons.mid:Address()
    else
      UIComponent(buttons.mid:Find("button_default_selection")):SetVisible(false)
      UIComponent(buttons.top:Find("button_default_selection")):SetVisible(true)
      highlighted_button = buttons.top:Address()
    end
  end
  local event_panel = UIComponent(this:Parent("events"))
  event_panel:InterfaceFunction("InitTempTimer", highlighted_button)
  needs_ally_decision = CampaignUI.IsTimedMultiplayerGame()
  ally_decision_made = false
end

function InitialiseDilemma(root, details)
end

function ReInitialise(details)
  if details ~= nil then
    OnDestroyed()
  end
  out.tom("Reinitialising with layout " .. details.Layout)
  SelectLayout(details ~= nil and details or m_details)
end

local layout_map = {
  standard = {Layout = InitialiseStandard, OnDestroy = DestroyMovie},
  unit_recruited = {Layout = InitialiseUnitRecruited},
  agent_recruited = {Layout = InitialiseAgentRecruited},
  building_constructed = {Layout = InitialiseBuildingConstructed},
  build_list = {Layout = InitialiseBuildList},
  sabotage = {Layout = InitialiseSabotage},
  assassination = {Layout = InitialiseAssassination},
  disaster = {Layout = InitialiseDisaster},
  blockade = {Layout = InitialiseBlockade},
  marriage = {Layout = InitialiseMarriage},
  traits_anc_list = {Layout = InitialiseTraitsAncList},
  election_results = {Layout = InitialiseElectionResults},
  unit_routs = {Layout = InitialiseUnitRouts},
  revolution = {
    Layout = InitialiseRevolution,
    NoButtons = true,
    OnDestroy = DestroyMovie
  },
  riots = {Layout = InitialiseRiots},
  technology_advances = {Layout = InitialiseTechAdvances},
  tech_advances_list = {Layout = InitialiseTechList},
  capital_lost = {Layout = InitialiseCapitalLost},
  ally_attacked = {Layout = InitialiseAllyAttacked, NoButtons = true},
  attrition_list = {Layout = InitialiseAttrition},
  dilemma = {Layout = InitialiseDilemma, NoButtons = true},
  incident = {Layout = InitialiseIncident},
  standard_vertical = {Layout = InitialiseStandard, OnDestroy = DestroyMovie},
  mission = {Layout = InitialiseMission},
  marriage_proposal = {Layout = InitialiseMarriageProposal, NoButtons = true},
  fame = {Layout = InitialiseFame}
}

function OnDestroyed()
  out.tom("Event message OnDestroyed()")
  DestroyMovie()
  this:UnLockPriority()
end

function SelectLayout(details)
  DestroyMovie()
  m_position = {}
  m_destroy_func = nil
  out.tom("Initialised message with layout: " .. tostring(details.Layout) .. ". Title: " .. tostring(details.Title))
  ShaneOutput("Requires response: " .. tostring(details.RequiresResponse))
  m_details = utils.CopyTable(details)
  local layout
  if m_current_layout ~= details.Layout then
    if m_current_layout ~= nil then
      Component.Destroy(this:Find("Layout_" .. m_current_layout))
    end
    local event_panel = UIComponent(this:Parent("events"))
    if event_panel ~= nil then
      event_panel:InterfaceFunction("ClearEventWindow")
    end
    layout = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/Layout_" .. details.Layout, "Layout_" .. details.Layout, Address, 0, 0))
    layout:PropagateVisibility(true)
    local px, py = this:Position()
    local shift_x = (layout:Width() - this:Width()) / 2
    layout:MoveTo(px - shift_x, py)
  else
    layout = UIComponent(this:Find("Layout_" .. m_current_layout))
  end
  m_details.Root = layout
  local buttons_group = UIComponent(this:Find("Buttons"))
  buttons_group:PropagateVisibility(false)
  layout_map[details.Layout].Layout(layout, details)
  if layout_map[details.Layout].NoButtons == nil then
    buttons_group:SetVisible(true)
    if m_position.X ~= nil then
      UIComponent(this:Find("OK_zoom")):PropagateVisibility(true)
    else
      UIComponent(this:Find("OK")):PropagateVisibility(true)
    end
  end
  m_current_layout = details.Layout
  this:StealShortcutKey("ESCAPE")
  this:SetEventCallback("OnKey", OnKey)
  out.tom("Selecting Layout " .. details.Layout .. " req response = " .. tostring(m_details.RequiresResponse))
  if m_details.RequiresResponse == true then
    layout:PropagatePriority(40)
    layout:LockPriority(39)
  end
  UpdateReviewButtonCounts()
end

function OnShortcut()
end

function OnKey(key, v, ended)
  if ended then
    if key == "RETURN" then
      if m_details ~= nil and m_details.RequiresResponse == false then
        OnOk()
      end
    elseif key == "ESCAPE" and m_details ~= nil and m_details.RequiresResponse == false then
      OnCancel()
    end
  end
end

function ShowMessageFromReviewType(type)
  if tostring(type) == "button_recruitment" then
    message_handler.ShowRecruitmentMessageFromReviewButton()
  elseif tostring(type) == "button_construction" then
    message_handler.ShowConstructionMessageFromReviewButton()
  elseif tostring(type) == "button_character" then
    message_handler.ShowCharacterMessageFromReviewButton()
  end
end

function NotifyCurrentLayoutCleared()
  m_current_layout = nil
end

function CloseDialog()
  DestroyMovie()
  local buttons_group = UIComponent(this:Find("Buttons"))
  buttons_group:SetVisible(true)
  UIComponent(buttons_group:Find("OK")):PropagateVisibility(false)
  UIComponent(buttons_group:Find("OK_zoom")):PropagateVisibility(false)
  UIComponent(buttons_group:Find("yes_no")):PropagateVisibility(false)
  UIComponent(buttons_group:Find("OK_view_research")):PropagateVisibility(false)
  if needs_ally_decision and not ally_decision_made then
    CampaignUI.DeclineSidingWithAlly()
  end
  ally_decision_made = false
  needs_ally_decision = false
  UpdateReviewButtonCounts()
  if m_details ~= nil then
    if m_details.RequiresResponse == true then
      this:UnLockPriority()
      this:PropagatePriority(10)
      m_details.RequiresResponse = false
    end
    if CampaignUI == nil then
      message_handler.HideMessage(Address)
    elseif m_details.Layout ~= nil and this:ChildCount() > 1 then
      msg_layout = UIComponent(this:Find(1))
      out.tom("Hiding and destroying " .. msg_layout:Id())
      msg_layout:UnLockPriority()
      message_handler.HideMessage(this:Find(1))
    end
  end
  message_handler.ClosePanelIfNoMessage()
end

function Hide()
  m_details.Parent:LuaCall("Hide")
end

function OnOk()
  if needs_ally_decision then
    ally_decision_made = true
  end
  CloseDialog()
end

function OnCancel()
  CloseDialog()
end

function OnZoomTo(pos)
  m_details.Parent:LuaCall("Hide")
  if BattleUI then
    BattleUI.CameraZoomTo(m_position.X, m_position.Y, m_position.Z, m_position.Facing)
  elseif pos == nil and m_position ~= nil then
    CampaignUI.SetCameraTarget(m_position.X, m_position.Y)
    CloseDialog()
  else
    CampaignUI.SetCameraTarget(pos.X, pos.Y)
    CloseDialog()
  end
end

function UpdateReviewButtonCounts()
  local mc1 = message_handler.GetRecruitmentMessageCount()
  local mc2 = message_handler.GetConstructionMessageCount()
  local mc3 = message_handler.GetCharacterMessageCount()
  local reports = UIComponent(UIComponent(this:Parent()):Find("reports_window"))
  local mc1_txt = UIComponent(reports:Find("button_recruitment")):Find("dy_txt")
  local mc2_txt = UIComponent(reports:Find("button_construction")):Find("dy_txt")
  local mc3_txt = UIComponent(reports:Find("button_character")):Find("dy_txt")
  local mc4_txt = UIComponent(reports:Find("button_finance")):Find("dy_txt")
  local mc5_txt = UIComponent(reports:Find("button_diplomacy")):Find("dy_txt")
  UIComponent(mc1_txt):SetStateText(tostring(mc1))
  UIComponent(mc2_txt):SetStateText(tostring(mc2))
  UIComponent(mc3_txt):SetStateText(tostring(mc3))
  UIComponent(mc4_txt):SetVisible(false)
  UIComponent(mc5_txt):SetVisible(false)
end
