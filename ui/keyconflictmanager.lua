module((...), package.seeall)
local keyboard_definitions, prefs_manager

local function KeysUsed(descr, key, mod)
  return descr.Keys[1].Key == key and prefs_manager:ModifierUsed(mod, descr.Keys[1].Modifier) or descr.Keys[2].Key == key and prefs_manager:ModifierUsed(mod, descr.Keys[2].Modifier)
end

local function CheckDuplicate(mapping_table, current_mode, descr, key, mod)
  for dk, dv in pairs(mapping_table) do
    if (dv.Mode == current_mode or dv.Mode == "universal" or current_mode == "universal") and descr.Address ~= dv.Address and KeysUsed(dv, key, mod) == true then
      return true, dv.Name
    end
  end
  return false
end

function OnAssignOld(key_details)
end

function OnAssignNew(key_details)
end

function SetPrefsManager(manager)
  prefs_manager = manager
  keyboard_definitions = manager:GetKeyboardDefinitions()
end

function SetShortcutKey(mapping_table, current_mode, descr, key, mod, slot, key_name, key, conflict_panel)
  local keys = mapping_table[descr]
  local result, msg = CheckDuplicate(mapping_table, current_mode, keys, key, mod)
  if result == false then
    local slot_alt = {2, 1}
    if slot ~= 0 and keys.Keys[slot_alt[slot]].Key ~= key and keys.Keys[slot].Key ~= key then
      keys.Keys[slot].Key = key
      keys.Keys[slot].Modifier = mod
    else
      keys.Keys[1].Key = key
      keys.Keys[1].Modifier = mod
      keys.Keys[2].Key = keyboard_definitions.Keys.NumKeys
      keys.Keys[2].Modifier = keyboard_definitions.Modifiers.None
    end
    keys.Changed = true
    msg = prefs_manager:LocalisedKeyString(keys.Keys)
    keys.KeyString = msg
  else
    local conflict_panel = UIComponent(conflict_panel)
    key_name = prefs_manager:LocalisedKeyString({
      {Key = key, Modifier = mod},
      {
        Key = keyboard_definitions.Keys.NumKeys,
        Modifier = keyboard_definitions.Modifiers.None
      }
    })
    conflict_panel:LuaCall("Initialise", {
      descr = descr,
      mod = mod,
      slot = slot,
      key_name = key_name,
      key = key
    }, msg, OnAssignOld, OnAssignNew)
  end
  return result == false, msg
end
