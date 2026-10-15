local utils = require("Utilities")
local this = UIComponent(Address)
local tech_parent = UIComponent(this:Parent("technology"))
local g_character = UIComponent(this:Find("gentleman_character"))
local g_attribute = UIComponent(this:Find("CharacterAttribute"))
local g_attribute_level = UIComponent(g_attribute:Find("Level"))
local g_name = UIComponent(this:Find("name"))
local g_tech_icon = UIComponent(this:Find("tech_icon"))
local g_turns_icon = UIComponent(this:Find(" Turns"))
local g_gentleman
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function ShowTableVars(table, table_name)
  for h, v in pairs(table) do
    if type(v) == "table" then
      local pre_appended = table_name
      table_name = table_name .. "." .. tostring(h)
      ShowTableVars(v, tostring(h))
      table_name = pre_appended
    end
    ShaneOutput(table_name .. "." .. h .. " = " .. tostring(v))
  end
end

function Initialise(gentleman)
  ShaneOutput("**Initialising gentleman: " .. tostring(gentleman.Name) .. " with image: " .. tostring(gentleman.Portrait))
  g_gentleman = gentleman
  local image = UIImage(gentleman.CardImage)
  image:SetComponentTexture(g_character:Address(), 0)
  image = UIImage(gentleman.Attributes.PrimaryAttributePath)
  image:SetComponentTexture(g_attribute:Address(), 0)
  g_attribute_level:SetState(tostring(gentleman.Attributes.PrimaryLevel))
  g_name:SetStateText(gentleman.Name)
  g_character:LuaCall("Initialise", gentleman)
  UpdateStatus(gentleman)
end

function UpdateStatus(gentleman)
  ShaneOutput("Updating gentleman, stealing = " .. tostring(gentleman.Activity ~= nil))
  if gentleman.Activity ~= nil then
    g_tech_icon:LuaCall("SetActiveTechnology", gentleman.Activity.Technology)
    g_turns_icon:SetStateText(gentleman.Activity.ChanceToSteal .. "%")
  end
  g_tech_icon:PropagateVisibility(gentleman.Activity ~= nil)
end

function SetSelected(selected)
  if Selectable() == true then
    if selected == true then
      g_character:SetState("selected")
    else
      g_character:SetState("normal")
    end
  end
end

function Selectable()
  return true
end
