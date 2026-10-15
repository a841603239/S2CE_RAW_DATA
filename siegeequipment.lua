module((...), package.seeall)
local utils = require("Utilities")
local g_siege_equipment_selection = 1
local g_enqueued_siege_equipment_cards = {}
local g_activated_with_selected_entity
local g_siege_equipment_card_width = 76
local g_siege_equipment_cards = {}
local g_siege_equipment_card_tables = {}
local g_state_shader_tables = {}
local g_max_siege_equipment_capacity = 8
local g_target_state_completed = false
local g_build_points
local g_siege_equipment_details = {}

function OnTransitionComplete()
  SetStateShaders()
end

function TargetStateCompleted()
  g_target_state_completed = true
end

function HasTargetStateCompleted()
  return g_target_state_completed
end

function SetStateShaders()
  local time = CampaignUI.Time()
  for i = 1, #g_state_shader_tables do
    local table = g_state_shader_tables[i]
    local var1 = table.var1
    local var2 = table.var2
    local var3 = table.var3
    local var4 = table.var4
    if var3 == "time" then
      var3 = time
      var4 = time + var4
    end
    utils.PropagateShader(table.component, table.technique, var1, var2, var3, var4)
  end
end

function GenerateSiegeEquipmentPanel(table_of_siege_equipment, table_of_enqueued_units, faction_colours, build_points, controlable)
  g_build_points = build_points
  local siege_equipment_capacity = g_max_siege_equipment_capacity
  g_state_shader_tables = {}
  local root = UIComponent(Component.Root())
  local cardgroup = UIComponent(root:Find("SiegeEquipmentCardGroup"))
  local buttons_siege = UIComponent(root:Find("buttons_siege"))
  buttons_siege:PropagateVisibility(true)
  local build_points_text = UIComponent(buttons_siege:Find("build_points"))
  build_points_text:SetStateText(build_points)
  local time = CampaignUI.Time()
  if siege_equipment_capacity == 0 then
    for i = 0, g_max_siege_equipment_capacity - 1 do
      local entry = UIComponent(buttons_siege:Find("queue_" .. i))
      local state_shader_table = {}
      state_shader_table.component = entry:Address()
      state_shader_table.technique = "alpha_over_time_t0"
      state_shader_table.var1 = 0.5
      state_shader_table.var2 = 0.5
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    end
  elseif 0 < siege_equipment_capacity then
    for i = 0, siege_equipment_capacity - 1 do
      local entry = UIComponent(buttons_siege:Find("queue_" .. i))
      local state_shader_table = {}
      state_shader_table.component = entry:Address()
      state_shader_table.technique = "alpha_over_time_t0"
      state_shader_table.var1 = 1
      state_shader_table.var2 = 1
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    end
    for i = siege_equipment_capacity, g_max_siege_equipment_capacity - 1 do
      local entry = UIComponent(buttons_siege:Find("queue_" .. i))
      local state_shader_table = {}
      state_shader_table.component = entry:Address()
      state_shader_table.technique = "alpha_over_time_t0"
      state_shader_table.var1 = 0.5
      state_shader_table.var2 = 0.5
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    end
  else
    for i = 0, g_max_siege_equipment_capacity - 1 do
      local entry = UIComponent(buttons_siege:Find("queue_" .. i))
      local state_shader_table = {}
      state_shader_table.component = entry:Address()
      state_shader_table.technique = "alpha_over_time_t0"
      state_shader_table.var1 = 1
      state_shader_table.var2 = 1
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    end
  end
  GenerateSiegeEquipmentCards(table_of_siege_equipment, table_of_enqueued_units, faction_colours, siege_equipment_capacity, controlable)
  SetStateShaders()
end

function UpdateSiegeEquipmentCardTables(table_of_siege_equipment)
  for c = 1, #table_of_siege_equipment do
    local found = false
    local new_id = table_of_siege_equipment[c].card_id
    for i = 1, #g_siege_equipment_card_tables do
      local existing_id = g_siege_equipment_card_tables[i].card_id
      if existing_id == new_id then
        found = true
        g_siege_equipment_card_tables[i].status = table_of_siege_equipment[c].status
        g_siege_equipment_card_tables[i].slot = table_of_siege_equipment[c].slot
        g_siege_equipment_card_tables[i].turns = table_of_siege_equipment[c].turns
        break
      end
    end
    if false == found then
      out.shane("")
      out.shane("Previous:")
      for i = 1, #g_siege_equipment_card_tables do
        out.shane(g_siege_equipment_card_tables[i].card_id)
      end
      out.shane("")
      out.shane("Current:")
      for i = 1, #table_of_siege_equipment do
        out.shane(table_of_siege_equipment[i].card_id)
      end
      out.shane("")
    end
    assert(found, "Couldnt find siege_equipment card " .. table_of_siege_equipment[c].card_id)
  end
  return g_siege_equipment_card_tables
end

function SiegeEquipmentOptionsUnchanged(table_of_siege_equipment)
  if #g_siege_equipment_card_tables ~= #table_of_siege_equipment then
    return false
  else
    for i = 1, #table_of_siege_equipment do
      local found = false
      for n = 1, #g_siege_equipment_card_tables do
        if table_of_siege_equipment[i].card_id == g_siege_equipment_card_tables[n].card_id then
          found = true
          break
        end
      end
      if found == false then
        return false
      end
    end
  end
  return true
end

function GenerateSiegeEquipmentCards(table_of_siege_equipment, table_of_enqueued_units, faction_colours, siege_equipment_capacity, controlable)
  local entry_time = 0
  local entry_time_scalar = 1
  local initial_entry_time = 2
  local root = UIComponent(Component.Root())
  local selected_entity = root:LuaCall("SelectedEntity")
  local preferr_refresh = nil ~= g_activated_with_selected_entity and selected_entity == g_activated_with_selected_entity
  if preferr_refresh == true and SiegeEquipmentOptionsUnchanged(table_of_siege_equipment) then
    table_of_siege_equipment = UpdateSiegeEquipmentCardTables(table_of_siege_equipment)
    entry_time_scalar = 0
  else
    g_siege_equipment_card_tables = table_of_siege_equipment
    g_siege_equipment_selection = 1
  end
  entry_time = initial_entry_time * entry_time_scalar
  g_siege_equipment_cards = {}
  g_enqueued_siege_equipment_cards = {}
  for r = 1, #table_of_siege_equipment do
    g_siege_equipment_cards[r] = GenerateSiegeEquipmentCard(table_of_siege_equipment[r], 0, 0, 1, r, faction_colours, entry_time_scalar)
    g_siege_equipment_details[r] = {}
    g_siege_equipment_details[r] = table_of_siege_equipment[r]
  end
  SelectSiegeEquipmentCard(g_siege_equipment_selection, entry_time_scalar)
  for e = 1, #table_of_enqueued_units do
    table_of_enqueued_units[e].future_order = siege_equipment_capacity < e
    g_enqueued_siege_equipment_cards[e] = GenerateSiegeEquipmentCard(table_of_enqueued_units[e], 0, 80, 1, e, faction_colours, entry_time)
  end
  SetEnqueuedSiegeEquipmentCards(table_of_enqueued_units, entry_time)
  g_state = g_siege_equipment
  g_activated_with_selected_entity = selected_entity
end

function GenerateSiegeEquipmentCard(table, x, y, size, position_index, faction_colours, entry_time_scalar)
  if nil ~= g_review_panel then
    local root = UIComponent(Component.Root())
    local enqueued = table.status == "Enqueued" or table.status == "Paused"
    out.shane("Siege card image path = " .. table.image_path .. ".tga")
    local image_list = {
      "{" .. table.card_id .. ":3}" .. table.image_path .. ".tga"
    }
    local parent = root:Find("SiegeEquipmentCardGroup")
    local componentAddress = Component.CreateComponentFromTemplate("SiegeEquipmentCard", table.card_id, parent, x, y, image_list)
    assert(componentAddress ~= nil)
    local component = UIComponent(componentAddress)
    local siege_equipment_cost_component = UIComponent(component:Find("SiegeEquipmentCost"))
    siege_equipment_cost_component:PropagateVisibility(enqueued == false)
    if mask_exists == true then
      component:SetImageColour(1, faction_colours.primary_red, faction_colours.primary_green, faction_colours.primary_blue, 255)
    end
    component:SetTooltipText(table.name, true)
    component:SetProperty("ChildIndex", position_index)
    component:SetProperty("ImagePath", table.image_path)
    component:SetProperty("status", table.status)
    component:SetProperty("Turns", table.turns)
    component:SetProperty("Cost", table.cost)
    component:LuaCall("SetItemAddress", table.item_ptr)
    component:SetProperty("Enqueued", enqueued)
    local time = CampaignUI.Time()
    local turns_component = UIComponent(component:Find("Turns"))
    local text_component = UIComponent(component:Find("Cost"))
    text_component:SetStateText(table.cost)
    turns_component:SetVisible(true)
    turns_component:SetState("not queued")
    if table.status == "Available" then
      turns_component:SetState("not queued")
      turns_component:SetStateText(table.turns)
      text_component:SetState("Normal")
      local state_shader_table = {}
      state_shader_table.component = component:Address()
      state_shader_table.technique = "grey_over_time_t0"
      state_shader_table.var1 = 0
      state_shader_table.var2 = 0
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    elseif table.status == "Enqueued" then
      component:SetState("queue_unselected")
      component:SetProperty("SlotIndex", table.slot)
      text_component:SetState("Normal")
      if table.future_order == true then
        turns_component:SetState("not queued")
      else
        turns_component:SetState("queued")
      end
      turns_component:SetStateText(table.turns)
      local state_shader_table = {}
      state_shader_table.component = component:Address()
      state_shader_table.technique = "grey_over_time_t0"
      state_shader_table.var1 = 0
      state_shader_table.var2 = 0
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    elseif table.status == "Paused" then
      component:SetState("queue_unselected")
      component:SetProperty("SlotIndex", table.slot)
      text_component:SetState("Normal")
      turns_component:SetState("not queued")
      turns_component:SetStateText(table.turns)
      local state_shader_table = {}
      state_shader_table.component = component:Address()
      state_shader_table.technique = "grey_over_time_t0"
      state_shader_table.var1 = 1
      state_shader_table.var2 = 1
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    elseif table.status == "Unaffordable" then
      text_component:SetState("Red")
      turns_component:SetVisible(false)
      local state_shader_table = {}
      state_shader_table.component = component:Address()
      state_shader_table.technique = "grey_over_time_t0"
      state_shader_table.var1 = 1
      state_shader_table.var2 = 1
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    elseif table.status == "NoSiegeEquipmentSlot" then
      text_component:SetState("Red")
      turns_component:SetVisible(false)
      local state_shader_table = {}
      state_shader_table.component = component:Address()
      state_shader_table.technique = "grey_over_time_t0"
      state_shader_table.var1 = 1
      state_shader_table.var2 = 1
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    else
      text_component:SetState("Normal")
      turns_component:SetVisible(false)
      local state_shader_table = {}
      state_shader_table.component = component:Address()
      state_shader_table.technique = "grey_over_time_t0"
      state_shader_table.var1 = 1
      state_shader_table.var2 = 1
      state_shader_table.var3 = "time"
      state_shader_table.var4 = 0
      g_state_shader_tables[#g_state_shader_tables + 1] = state_shader_table
    end
    text_component:SetStateText(table.cost)
    return componentAddress
  end
  return nil
end

function SetEnqueuedSiegeEquipmentCards(table_of_enqueued_units, time)
  local enqueued_card_spacing = 0
  local cardgroup = UIComponent(UIComponent(Component.Root()):Find("SiegeEquipmentCardGroup"))
  local buttons_siege = UIComponent(UIComponent(Component.Root()):Find("buttons_siege"))
  for c = 1, #g_enqueued_siege_equipment_cards do
    assert(g_enqueued_siege_equipment_cards[c] ~= nil)
    local px, py = UIComponent(UIComponent(buttons_siege:Find("queue_" .. c - 1)):Parent()):Position()
    local x, y = UIComponent(buttons_siege:Find("queue_" .. c - 1)):Position()
    local target_width = UIComponent(buttons_siege:Find("queue_" .. c - 1)):Width()
    local target_height = UIComponent(buttons_siege:Find("queue_" .. c - 1)):Height()
    assert(g_enqueued_siege_equipment_cards[c] ~= nil)
    UIComponent(g_enqueued_siege_equipment_cards[c]):MoveTo(x, y)
    UIComponent(g_enqueued_siege_equipment_cards[c]):Resize(target_width, target_height)
    local target_greyscale = 0
    if table_of_enqueued_units[c].status ~= "Enqueued" then
      target_greyscale = 1
    end
    out.shane("Setting target state with target width of " .. target_width)
    Component.CallByAddress(g_enqueued_siege_equipment_cards[c], "LuaCall", "TargetStateSet", time, 0, x - px, y - py, target_width, target_greyscale)
  end
end

function SiegeEquipmentCardSelected(component)
  local selected = g_siege_equipment_cards[g_siege_equipment_selection] == component
  return selected
end

function SelectSiegeEquipmentCard(position_index, entry_time_scalar)
  g_siege_equipment_selection = position_index
  if 0 < #g_siege_equipment_cards then
    local positions, sizes = SiegeCardPositions_OSX(#g_siege_equipment_cards, g_siege_equipment_selection)
    for c = 1, #g_siege_equipment_cards do
      assert(g_siege_equipment_cards[c] ~= nil)
      local component = UIComponent(g_siege_equipment_cards[c])
      local status = component:GetProperty("status")
      local target_greyscale_unary = 0
      if status ~= "Available" then
        target_greyscale_unary = 1
      end
      local siege_equipment_cost_component = UIComponent(component:Find("SiegeEquipmentCost"))
      local cost_component = UIComponent(component:Find("Cost"))
      local turns_component = UIComponent(component:Find("Turns"))
      local turns = component:GetProperty("Turns")
      local cost = component:GetProperty("Cost")
      if c == g_siege_equipment_selection then
        turns_component:SetState("not queued")
        turns_component:SetStateText(turns)
        siege_equipment_cost_component:PropagateVisibility(true)
        cost_component:SetStateText(cost)
      else
        siege_equipment_cost_component:PropagateVisibility(false)
        turns_component:SetState("0")
      end
      assert(g_siege_equipment_cards[c] ~= nil)
      local time = 0.2 * entry_time_scalar
      local greytime = 3 * entry_time_scalar
      local target_xoffs = positions[c]
      local target_yoffs = 0
      local target_width = sizes[c]
      out.shane("Setting target state with target width of " .. target_width)
      Component.CallByAddress(g_siege_equipment_cards[c], "LuaCall", "TargetStateSet", time, greytime, target_xoffs, target_yoffs, target_width, target_greyscale_unary)
      local root = UIComponent(Component.Root())
      local cardgroup = UIComponent(root:Find("SiegeEquipmentCardGroup"))
      local card = UIComponent(g_siege_equipment_cards[c])
      local counter
      local counter_component = cardgroup:Find("Counter" .. c, false)
      if counter_component == nil then
        counter = UIComponent(Component.CreateComponentFromTemplate("siege_equipment_counter", "Counter" .. c, cardgroup:Address(), 0, 0))
        local group_x, group_y = cardgroup:Position()
        counter:MoveTo(group_x + target_xoffs + (card:Width() / 2 - counter:Width() / 2), group_y + 83)
        counter:SetStateText(g_siege_equipment_details[c].stock)
      end
    end
  end
end

function SiegeEquipmentCardPosition(position_index, total_cards)
  return card_positions[position_index]
end

function SiegeCardPositions_OSX(total_cards, selected_card)
  local card_positions = {}
  local card_sizes = {}
  local card_width = utils.TruncToInt(g_siege_equipment_card_width * 0.9)
  local selected_card_width = card_width - card_width % 2
  local unselected_card_width = utils.TruncToInt(card_width * 0.9)
  unselected_card_width = unselected_card_width - unselected_card_width % 2
  local review_panel_width = UIComponent(g_review_panel):Width()
  local x_spacing = card_width
  local total_width = card_width * 2 * total_cards - card_width
  local position = utils.TruncToInt((review_panel_width - total_width) * 0.5)
  out.shane("Positioning " .. total_cards .. " siege cards")
  for i = 1, total_cards do
    if i == selected_card then
      card_sizes[i] = selected_card_width
      card_positions[i] = position
    else
      card_sizes[i] = unselected_card_width
      card_positions[i] = position
    end
    position = position + card_width * 2
  end
  return card_positions, card_sizes
end
