local utils = require("Utilities")
local this = UIComponent(Address)
local g_position_map, g_components_table, g_players_side
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Clear()
  this:DestroyChildren()
end

function Initialise(units, position_map, players_side, player_reinforcing, character_ptr)
  Clear()
  ShaneOutput(">> Initialising reinforcements window:")
  ShaneOutput(">> Player = " .. tostring(players_side))
  ShaneOutput(">> Num units = " .. #units)
  g_components_table = {}
  g_players_side = players_side
  g_position_map = position_map
  local expose_units = not players_side and (not player_reinforcing or not CampaignUI.IsCharacterPlayerControlled(character_ptr))
  for u = 1, #units do
    g_components_table[u] = utils.CreateUnitCard(units[u], units[u].Id, Address, 0, 0, true, true, false, expose_units)
    local card = UIComponent(g_components_table[u])
    card:Resize(60, 80)
    if units[u].IsFixedArtillery == true then
      card:LuaCall("SetTooltipFunctionState", "strat_reinforcement_invalid")
      card:SetState("Inactive")
    else
      card:LuaCall("SetTooltipFunctionState", "strat_reinforcement")
    end
    if g_players_side == false or player_reinforcing == true then
      card:SetState("NonInteractive")
      card:SetDisabled(true)
    end
    card:SetEventCallback("OnMouseLClickUp", "")
    card:SetEventCallback("OnMouseRClickUp", "")
    card:SetEventCallback("OnStartDrag", "")
    card:SetEventCallback("OnMove", "")
  end
  OrderAndPositionCards()
end

function OrderAndPositionCards()
  local px, py = this:Position()
  for i = 1, #g_components_table do
    local x, y = CardPosition(g_position_map[i])
    UIComponent(g_components_table[i]):MoveTo(px + x, py + y)
  end
end

function SwitchCards(card_index1, card_index2)
  ShaneOutput("Switching " .. card_index1 .. " with " .. card_index2)
  ShaneOutput("Map entries are " .. g_position_map[card_index1] .. " and " .. g_position_map[card_index2])
  local saved_position = g_position_map[card_index1]
  g_position_map[card_index1] = g_position_map[card_index2]
  g_position_map[card_index2] = saved_position
  OrderAndPositionCards()
end

function CardPosition(pos)
  local columns = 7
  local x_spacing = 60
  local y_spacing = 80
  local x = utils.TruncToInt((pos - 1) % columns) * x_spacing
  local y = utils.TruncToInt((pos - 1) / columns) * y_spacing
  return x, y
end

function HandleDrop(dropped_items)
  ShaneOutput("*** PreBattle HandleDrop ***")
  if g_players_side == true then
    local dropped_card = UIComponent(dropped_items[1].Address)
    if dropped_card:Id() ~= "dy_portrait" then
      local dropped_card_index
      for i = 1, #g_components_table do
        if g_components_table[i] == dropped_card:Address() then
          ShaneOutput("Dropped card found in g_components_table at index " .. i)
          dropped_card_index = i
          break
        end
      end
      local handled = false
      for i = 1, #g_components_table do
        local card = UIComponent(g_components_table[i])
        if card:Address() ~= dropped_card:Address() and IsMouseOver(card, dropped_items.X, dropped_items.Y) then
          ShaneOutput("Recieving card found in g_components_table at index " .. i)
          SwitchCards(i, dropped_card_index)
          handled = true
          break
        end
      end
      if handled == false then
        ShaneOutput("Not handled")
        local px, py = this:Position()
        local x, y = CardPosition(g_position_map[dropped_card_index])
        ShaneOutput("Drop not handled, repositioning for original index " .. g_position_map[dropped_card_index])
        dropped_card:MoveTo(px + x, py + y)
      end
      dropped_items[1].Handled = true
    end
  end
  return dropped_items
end

function IsMouseOver(component, dx, dy)
  local x, y = component:Position()
  if dx > x and dx < x + component:Width() and dy > y and dy < y + component:Height() then
    return true
  end
  return false
end
