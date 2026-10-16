local utils = require("Utilities")
local this = UIComponent(Address)
local name = UIComponent(this:Find("name"))
local men = UIComponent(this:Find("men"))
local losses = UIComponent(this:Find("losses"))
local kills = UIComponent(this:Find("kills"))
local circle = UIComponent(this:Find("loading_circle"))
local skill_display = UIComponent(this:Find("skill_display"))
local avatar = UIComponent(this:Find("avatar"))
local icon = UIComponent(this:Find("icon"))
local flag = UIComponent(this:Find("faction_flag"))
local mp_index, mp_interface, displaying_avatar_details
local achievements_found = false
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(team, is_multiplayer, interface, show_skill)
  mp_index = team.mp_index
  mp_interface = interface
  local displaying_avatar_details = team.human_player and (team.portrait == nil or #team.portrait == 0)
  ShaneOutput(">>> Initialising MP_BATTLE entry, portrait is: " .. tostring(team.portrait))
  local image = UIImage(team.flags_path .. "/mini_flag.tga")
  image:SetComponentTexture(flag:Address(), 0)
  name:SetStateText(team.display_name)
  men:SetStateText(team.men_deployed)
  losses:SetStateText(team.losses)
  kills:SetStateText(team.enemy_killed)
  local change_symbol = "+"
  if 0 > team.skill_change then
    change_symbol = ""
  end
  if show_skill == true then
    if team.skill_change ~= 0 then
      skill_display:SetStateText(tostring(team.skill) .. " (" .. tostring(change_symbol) .. "" .. tostring(team.skill_change) .. ")")
    else
      skill_display:SetStateText(team.skill)
    end
  end
  circle:SetVisible(false)
  if displaying_avatar_details then
    local avatar_image = MPAvatar(mp_interface, mp_index)
    avatar_image:SetComponentTexture(avatar:Address(), 0)
    avatar_image:Free()
    UIComponent(avatar:Find("icon")):SetVisible(false)
  else
    local image = UIImage(team.portrait)
    image:SetComponentTexture(avatar:Find("icon"), 0)
  end
  if achievements_found == false then
    UpdateAchievements(team.achievements)
  end
  return team.local_player
end

function UpdateAchievements(achievements_table)
  for i = 1, 3 do
    UIComponent(this:Find("achievement" .. i)):PropagateVisibility(false)
  end
  local num_achievements = #achievements_table
  if 3 < num_achievements then
    num_achievements = 3
  end
  ShaneOutput("Processing " .. num_achievements .. " achievements")
  for i = 1, num_achievements do
    local component = UIComponent(this:Find("achievement" .. i))
    UIComponent(component:Find("border")):SetInteractive(false)
    if "Unsupported achievement icon" ~= achievements_table[i].Icon then
      ShaneOutput("Setting image for achievement " .. i .. " to data/ui/achievements/" .. achievements_table[i].Icon .. ".tga")
      local image = UIImage("data/ui/achievements/" .. achievements_table[i].Icon .. ".tga")
      image:SetComponentTexture(component:Address(), 0)
    else
      ShaneOutput("Achievement " .. i .. " unsupported")
    end
    component:PropagateVisibility(true)
    component:SetInteractive(true)
    component:SetTooltipText("[ALIGN:C]" .. achievements_table[i].Title .. "\n" .. "[ALIGN:L]" .. achievements_table[i].Description, true)
    achievements_found = true
  end
end
