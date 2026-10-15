local utils = require("Utilities")
local this = UIComponent(Address)
local panels = {
  UIComponent(this:Find("panel left")),
  UIComponent(this:Find("panel right"))
}
local exchange_cost = 0
local time_label = UIComponent(this:Find("time_label"))
local button_cancel = UIComponent(this:Find("button_cancel"))
local mp_button_timer_txt_ptr
local swap = {}
local lhs = {}
local rhs = {}

function ClearSwaps()
  swap = {}
  lhs = {}
  rhs = {}
  swap[1] = {
    Units = {
      Initial = {},
      Final = {}
    },
    Ships = {
      Initial = {},
      Final = {}
    },
    Agents = {
      Initial = {},
      Final = {}
    }
  }
  swap[2] = {
    Units = {
      Initial = {},
      Final = {}
    },
    Ships = {
      Initial = {},
      Final = {}
    },
    Agents = {
      Initial = {},
      Final = {}
    }
  }
end

function Reinitialise(lhs_character, rhs_character, lhs_garrison, rhs_garrison, cost)
  Initialise(lhs_character, rhs_character, lhs_garrison, rhs_garrison, cost)
end

function Initialise(lhs_character, rhs_character, lhs_garrison, rhs_garrison, cost, max_units_per_navy)
  ClearSwaps()
  lhs.Character = lhs_character
  lhs.Garrison = lhs_garrison
  rhs.Character = rhs_character
  rhs.Garrison = rhs_garrison
  exchange_cost = cost
  panels[1]:LuaCall("Initialise", lhs_character, rhs_character, lhs_garrison, rhs_garrison, cost, rhs_character ~= nil and rhs_character or rhs_garrison, panels[2], max_units_per_navy)
  panels[2]:LuaCall("Initialise", rhs_character, lhs_character, rhs_garrison, lhs_garrison, cost, lhs_character ~= nil and lhs_character or lhs_garrison, panels[1], max_units_per_navy)
  swap[1].Units.Initial, swap[1].Ships.Initial, swap[1].Agents.Initial = panels[1]:LuaCall("Cards")
  swap[2].Units.Initial, swap[2].Ships.Initial, swap[2].Agents.Initial = panels[2]:LuaCall("Cards")
  this:StealShortcutKey("ESCAPE")
  this:SetGlobal("OnKey", function(key, v, ended)
    if key == "ESCAPE" and ended then
      CancelExchange()
    end
  end)
  this:SetGlobal("OnShortcut", function()
  end)
  time_label:SetInteractive(false)
  this:InterfaceFunction("Initialise")
end

function ExchangeSelected()
  local lhs, lhs_tab = panels[1]:LuaCall("Selected")
  local rhs, rhs_tab = panels[2]:LuaCall("Selected")
  local lhs_left, rhs_left
  out.shane("ExchangeSelected: lhs selected = " .. #lhs)
  out.shane("ExchangeSelected: rhs selected = " .. #rhs)
  local is_swapping = 0 < #lhs and 0 < #rhs
  if 0 < #lhs then
    panels[2]:LuaCall("RemoveCards", rhs, rhs_tab, is_swapping)
    rhs_left = panels[2]:LuaCall("RecieveCards", lhs, lhs_tab, is_swapping)
  end
  if 0 < #rhs then
    lhs_left = panels[1]:LuaCall("RecieveCards", rhs, rhs_tab, is_swapping)
  end
  out.shane("ExchangeSelected: lhs_left = " .. (lhs_left ~= nil and #lhs_left or "nil"))
  out.shane("ExchangeSelected: rhs_left = " .. (rhs_left ~= nil and #rhs_left or "nil"))
  if rhs_left ~= nil then
    panels[1]:LuaCall("RecieveCards", rhs_left, lhs_tab)
  end
  if lhs_left ~= nil then
    panels[2]:LuaCall("RecieveCards", lhs_left, rhs_tab)
  end
  panels[1]:LuaCall("DeselectAll")
  panels[2]:LuaCall("DeselectAll")
end

function CalculateItemsToTransfer(initial, final)
  local results = {}
  local found = false
  local i = 1
  while final[i] and found == false do
    for j, w in ipairs(initial) do
      if w == final[i] then
        found = true
        break
      end
    end
    if found == false then
      results[#results + 1] = UIComponent(final[i]):InterfaceFunction("ItemAddress")
    else
      found = false
    end
    i = i + 1
  end
  return results
end

function FinaliseExchange()
  Component.Call("Root.LuaCall", "ClosePopup", Address)
  swap[1].Units.Final, swap[1].Ships.Final, swap[1].Agents.Final = panels[1]:LuaCall("Cards")
  swap[2].Units.Final, swap[2].Ships.Final, swap[2].Agents.Final = panels[2]:LuaCall("Cards")
  lhs.Results = {
    Units = CalculateItemsToTransfer(swap[1].Units.Initial, swap[1].Units.Final),
    Ships = CalculateItemsToTransfer(swap[1].Ships.Initial, swap[1].Ships.Final),
    Agents = CalculateItemsToTransfer(swap[1].Agents.Initial, swap[1].Agents.Final)
  }
  rhs.Results = {
    Units = CalculateItemsToTransfer(swap[2].Units.Initial, swap[2].Units.Final),
    Ships = CalculateItemsToTransfer(swap[2].Ships.Initial, swap[2].Ships.Final),
    Agents = CalculateItemsToTransfer(swap[2].Agents.Initial, swap[2].Agents.Final)
  }
  CampaignUI.FinaliseExchange(lhs, rhs, exchange_cost)
end

function CancelExchange()
  CampaignUI.FinaliseExchange()
  Component.Call("Root.LuaCall", "ClosePopup", Address)
end

function HasValidSelection()
  return not ((not panels[1]:LuaCall("HasValidSelection", #panels[2]:LuaCall("Selected")) or not panels[2]:LuaCall("HasSpace") and not panels[2]:LuaCall("HasValidSelection", #panels[1]:LuaCall("Selected"))) and panels[2]:LuaCall("HasValidSelection", #panels[1]:LuaCall("Selected"))) or panels[1]:LuaCall("HasSpace") or panels[1]:LuaCall("HasValidSelection", #panels[2]:LuaCall("Selected"))
end
