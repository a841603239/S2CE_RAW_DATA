local utils = require("Utilities")
local this = UIComponent(Address)
local g_tab_width = 52
local g_reinforcements_window, g_reinforcements, g_selected_tab, g_players_side, g_player_reinforcing
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ReinforcementDetails()
  local reinforcing_armies = {}
  ShaneOutput("* Getting reinforcement details:")
  ShaneOutput("* Childcount = " .. this:ChildCount())
  for i = 1, this:ChildCount() do
    reinforcing_armies[i] = {}
    local character_ptr = UIComponent(this:Find(i - 1)):LuaCall("CharacterPtr")
    reinforcing_armies[i].commander = character_ptr
    local units = g_reinforcements[i].commander.units
    local map = g_reinforcements[i].position_map
    reinforcing_armies[i].units = {}
    ShaneOutput("* reinforcing_armies size = " .. #reinforcing_armies)
    ShaneOutput("* units size = " .. #units)
    ShaneOutput("* map size = " .. #map)
    for u = 1, #units do
      reinforcing_armies[i].units[u] = units[map[u]].Address
    end
  end
  return reinforcing_armies
end

function Initialise(reinforcements, cards_window, players_side, player_reinforcing)
  this:DestroyChildren()
  g_players_side = players_side
  g_player_reinforcing = player_reinforcing
  g_reinforcements_window = cards_window
  g_reinforcements = reinforcements
  ShaneOutput("Generating cards for " .. #reinforcements .. " reinforcements")
  local first
  if 0 < #reinforcements then
    for r = 1, #reinforcements do
      local commander = reinforcements[r].commander
      local images = {
        "{" .. "dy_portrait" .. ":1}" .. commander.CardImage,
        "{" .. "small_flag" .. ":1}" .. commander.SmallFlag
      }
      local x = (r - 1) * g_tab_width
      local component = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/prebattle_portrait_tab", "reinforcement_tab" .. r, this:Address(), x, 0, images))
      component:LuaCall("Initialise", this, r, commander.Address)
      if g_players_side == false or g_player_reinforcing == true then
        UIComponent(component:Find(0)):SetMoveable(false)
      end
      if first == nil then
        first = component
      end
    end
    SelectTab(first)
  else
    g_reinforcements_window:LuaCall("Clear")
  end
end

function SelectTab(tab, character_ptr)
  ShaneOutput("Selecting pre battle screen tab " .. tab:Id() .. " of " .. this:ChildCount())
  g_selected_tab = tab
  for i = 0, this:ChildCount() - 1 do
    UIComponent(this:Find(i)):SetState("unselect")
  end
  tab:SetState("select")
  local data_index = tab:LuaCall("GetIndex")
  g_reinforcements_window:LuaCall("Initialise", g_reinforcements[data_index].commander.units, g_reinforcements[data_index].position_map, g_players_side, g_player_reinforcing, character_ptr)
end

function HandleDrop(dropped_items)
  if g_players_side == true then
    ShaneOutput("Handle drop called for pre battle screen!")
    local dropped_item = UIComponent(dropped_items[1].Address)
    if dropped_item:Id() == "dy_portrait" then
      ShaneOutput("Handling drop for component with address " .. tostring(dropped_item:Address()))
      for i = 0, this:ChildCount() - 1 do
        local tab = UIComponent(this:Find(i))
        if IsMouseOver(tab, dropped_items.X, dropped_items.Y) then
          ShaneOutput("Whos parent tab is " .. tostring(dropped_item:Parent()))
          ShaneOutput("Which was dropped onto tab " .. tostring(tab:Address()))
          local dropped_items_tab = UIComponent(dropped_item:Parent())
          local px, py = dropped_items_tab:Position()
          dropped_item:MoveTo(px + 3, py - 1)
          SwitchTabs(tab, dropped_items_tab)
          dropped_items[1].Handled = true
          break
        end
      end
    end
  end
  return dropped_items
end

function MoveTabLeft()
  for i = 0, this:ChildCount() - 1 do
    if this:Find(i) == g_selected_tab:Address() then
      if 0 < i then
        SwitchTabs(UIComponent(this:Find(i - 1)), g_selected_tab)
      end
      break
    end
  end
end

function MoveTabRight()
  for i = 0, this:ChildCount() - 1 do
    if this:Find(i) == g_selected_tab:Address() then
      if i < this:ChildCount() - 1 then
        SwitchTabs(UIComponent(this:Find(i + 1)), g_selected_tab)
      end
      break
    end
  end
end

function SwitchTabs(tab1, tab2)
  local new_order = {}
  local original_order = {}
  for c = 0, this:ChildCount() - 1 do
    local child = this:Find(c)
    original_order[#original_order + 1] = child
    if child == tab2:Address() then
      new_order[#new_order + 1] = tab1:Address()
    elseif child == tab1:Address() then
      new_order[#new_order + 1] = tab2:Address()
    else
      new_order[#new_order + 1] = child
    end
  end
  ShaneOutput("New order for pre battle tabs:")
  local order_string = ""
  for i = 1, #original_order do
    order_string = order_string .. UIComponent(original_order[i]):Id() .. ", "
  end
  ShaneOutput("Switching pre battle tabs, old order = " .. order_string)
  order_string = ""
  for i = 1, #new_order do
    order_string = order_string .. UIComponent(new_order[i]):Id() .. ", "
  end
  ShaneOutput("Switching pre battle tabs, new order = " .. order_string)
  this:ReorderChildren(new_order)
  PositionTabs()
  SelectTab(tab2)
end

function IsMouseOver(component, dx, dy)
  local x, y = component:Position()
  if dx > x and dx < x + component:Width() and dy > y and dy < y + component:Height() then
    return true
  end
  return false
end

function PositionTabs()
  for i = 0, this:ChildCount() - 1 do
    local tab = UIComponent(this:Find(i))
    local px, py = UIComponent(tab:Parent()):Position()
    tab:MoveTo(px + i * g_tab_width, py)
  end
end
