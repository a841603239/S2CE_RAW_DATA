local utils = require("Utilities")
local this = UIComponent(Address)
this:SetDisabled(true)
local flags = {
  UIComponent(this:Find("flag_1")),
  UIComponent(this:Find("flag_2")),
  UIComponent(this:Find("flag_3")),
  UIComponent(this:Find("flag_4")),
  UIComponent(this:Find("flag_5"))
}
local name_component = UIComponent(this:Find("dy_name"))
local timer_component = UIComponent(this:Find("dy_timer"))
local mp_human_faction = false
for i, v in ipairs(flags) do
  v:SetDisabled(true)
end

function Initialise(info)
  local mon_filename = "/mon_64.tga"
  if info.prev_flag_2 == "" then
    flags[1]:SetVisible(false)
  else
    UIImage(info.prev_flag_2 .. mon_filename):SetComponentTexture(flags[1]:Address(), 0)
    flags[1]:SetVisible(true)
  end
  if info.prev_flag_1 == "" then
    flags[2]:SetVisible(false)
  else
    UIImage(info.prev_flag_1 .. mon_filename):SetComponentTexture(flags[2]:Address(), 0)
    flags[2]:SetVisible(true)
  end
  UIImage(info.flag_path .. mon_filename):SetComponentTexture(flags[3]:Address(), 0)
  if info.next_flag_1 == "" then
    flags[4]:SetVisible(false)
  else
    UIImage(info.next_flag_1 .. mon_filename):SetComponentTexture(flags[4]:Address(), 0)
    flags[4]:SetVisible(true)
  end
  if info.next_flag_2 == "" then
    flags[5]:SetVisible(false)
  else
    UIImage(info.next_flag_2 .. mon_filename):SetComponentTexture(flags[5]:Address(), 0)
    flags[5]:SetVisible(true)
  end
  name_component:SetStateText(info.name)
  mp_human_faction = info.mp_time_remaining ~= nil
  this:InterfaceFunction("Initialise", info.flag_path, mp_human_faction)
end
