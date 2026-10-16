module((...), package.seeall)
local utils = require("Utilities")
local VERTICAL_DOWN = 0
local VERTICAL_UP = 1
local HORIZONTAL_LEFT = 2
local HORIZONTAL_RIGHT = 3
local orders_table = {}
local minimap_table = {}
local cards_table = {}
local balance_of_power_table = {}
local root
local m_is_replay = BattleUI.IsReplay()
local m_is_spectator = BattleUI.IsSpectator()
local m_hud_x = 0
local m_hud_y = 0

function InitialiseHUDVisibilityManager()
  root = UIComponent(Component.Root())
  if BattleUI.IsLandBattle() then
    InitialiseComponentTable(orders_table, "land_battle_orders")
  else
    InitialiseComponentTable(orders_table, "naval_battle_orders")
  end
  InitialiseComponentTable(minimap_table, "radar")
  InitialiseComponentTable(cards_table, "cards_panel")
  InitialiseComponentTable(balance_of_power_table, "kill_ratio_PH")
  AddEffected(cards_table.effected_components, orders_table, VERTICAL_DOWN)
  AddEffected(cards_table.effected_components, balance_of_power_table, VERTICAL_DOWN)
  if m_is_spectator == true then
    SetTimerVisibility(true)
  end
end

function InitialiseComponentTable(table, component_name)
  table.component = UIComponent(root:Find(component_name))
  table.component_name = component_name
  table.original_position = {}
  table.x, table.y = table.component:Position()
  table.effected_components = {}
end

function AddEffected(table, effected_table, type_of_transition)
  effected_table.transition_type = type_of_transition
  table[#table + 1] = effected_table
end

function ChangeTableVisibility(table, invisible)
  out.dylan("ChangeTableVisibility; table is: " .. table.component_name .. ". Invisible is: " .. tostring(invisible))
  local visible = not invisible
  table.component:SetVisible(visible)
  for s, v in ipairs(table.effected_components) do
    RepositionEffectedComponent(visible, table.component:Width(), table.component:Height(), v)
  end
end

function RepositionEffectedComponent(visibility_change, width_change, height_change, effected_table)
  if visibility_change == true then
    effected_table.component:MoveTo(effected_table.x, effected_table.y)
  elseif effected_table.transition_type == VERTICAL_DOWN then
    effected_table.component:MoveTo(effected_table.x, effected_table.y + height_change)
  end
end

function SetOrdersVisibility(invisible)
  ChangeTableVisibility(orders_table, invisible)
end

function SetRadarVisibility(visible)
  print("in visi manager")
  print(visible)
  print(not visible)
  minimap_table.component:InterfaceFunction("ToggleMap", visible)
end

function SetTimerVisibility(invisible)
  ChangeTableVisibility(timer_table, invisible)
end
