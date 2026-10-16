local utils = require("Utilities")
local this = UIComponent(Address)
local g_index, g_parent, g_character_ptr

function Initialise(parent, index, character_ptr)
  g_parent = parent
  g_index = index
  g_character_ptr = character_ptr
end

function OnMouseLClickUp()
  g_parent:LuaCall("SelectTab", this, g_character_ptr)
end

function GetIndex()
  return g_index
end

function SetIndex(index)
  g_index = index
end

function HandleDrop(dropped_items)
  return g_parent:LuaCall("HandleDrop", dropped_items)
end

function CharacterPtr()
  return g_character_ptr
end
