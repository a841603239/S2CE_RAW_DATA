local this = UIComponent(Address)
local current_key
local last_slot = 1
local slot_alt = {2, 1}
local prefs_manager
g_Description = nil
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local keys = UIComponent(this:Find("keys"))
local controls = this:Parent("controls", false)
if controls == nil then
  controls = this:Parent("options_controls")
else
  controls = UIComponent(controls):Find(0)
end
controls = UIComponent(controls)

function Initialise(manager, descr)
  g_Description = descr
  prefs_manager = manager
  if FrontEnd == nil then
    for i = 0, this:ChildCount() - 1 do
      local child = UIComponent(this:Find(i))
      child:SetStateTextDetails({
        Colour = {
          r = 0,
          g = 0,
          b = 0,
          a = 255
        }
      })
    end
    this:Resize(UIComponent(this:Parent()):Width(), this:Height())
  end
  this:SetState("unselected")
  current_key = keys:GetStateText()
  OnFocusLose()
end

function Select(s)
  if s == true then
    this:SetState("selected")
    this:StealShortcutKey(true)
  else
    this:SetState("unselected")
    this:StealShortcutKey(false)
  end
end

function OnLClickUp()
  parent:LuaCall("SelectItem", Address)
end

function OnKey(key_string, key)
  if prefs_manager:IsModifier(key) == false then
    if 0 < #current_key then
      last_slot = slot_alt[last_slot]
    end
    local result, msg = controls:LuaCall("SetShortcutKey", g_Description, key, prefs_manager:ModifierHeld(), last_slot, key_string, key)
    if result == true then
      current_key = msg
    else
      out.tom("Key " .. key_string .. " already assigned to function " .. msg)
    end
    this:StealShortcutKey(false)
    parent:LuaCall("SelectItem", nil)
  end
end

function OnFocusGain()
  current_key = keys:GetStateText()
  keys:SetStateText("...  ")
end

function OnFocusLose()
  keys:SetStateText(current_key, true, 1)
end
