local utils = require("Utilities")
local this = UIComponent(Address)
local effects_mapping = {
  head_of_government = {
    "prestige",
    "diplomacy",
    "economic_growth"
  },
  finance = {
    "tax_efficiency",
    "trade_efficiency",
    "economic_growth"
  },
  justice = {
    "repression",
    "garrison_effect",
    "policing_costs"
  },
  army = {
    "land_recruit_cost",
    "land_upkeep_cost",
    "army_research"
  },
  navy = {
    "naval_recruit_cost",
    "naval_upkeep_cost",
    "navy_research"
  },
  governor = {
    "tax_efficiency",
    "repression",
    "land_upkeep_cost"
  }
}

function Initialise(details, type_a_bg)
  if type_a_bg then
    this:SetState("A_normal")
  else
    this:SetState("B_normal")
  end
  local template = this:Find("CampaignCharacterCard")
  local card = UIComponent(utils.CreateCharacterCard(details, "card", Address, 1, 0, false, true, true))
  card:Resize(UIComponent(template):Dimensions())
  card:SetMoveable(false)
  Component.Destroy(template)
  if details.PostName then
    UIComponent(this:Find("dy_name")):SetStateText(details.Name .. " - " .. details.PostName)
  else
    UIComponent(this:Find("dy_name")):SetStateText(details.Name)
  end
  if string.find(details.Post, "governor") ~= nil then
    details.Post = "governor"
  end
  for i = 1, 3 do
    local e = effects_mapping[details.Post][i]
    local c = UIComponent(this:Find("effects_icons" .. i))
    c:SetState(e)
    for k, v in pairs(details.PostEffects) do
      if e == k then
        c = UIComponent(this:Find("dy_effect" .. i))
        c:SetStateText(string.format("%+d", v.Value))
        break
      end
    end
  end
end

function OnLeftClickUp()
end

function OnRightClickUp()
end
