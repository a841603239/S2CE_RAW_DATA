local this = UIComponent(Address)
local parent = UIComponent(this:Parent("enlist_commander"))
local portrait = UIComponent(this:Find("portrait_PH"))
local commander_name = UIComponent(this:Find("dy_name"))
local command_rating = UIComponent(this:Find("command_stars"))
local recruitment_cost = UIComponent(this:Find("dy_cost"))
local m_trait_entry, m_character_pointer, m_unique_id, m_is_recruitable

function InitEnlistCommanderEntry(info)
  m_character_pointer = info.commander_pointer
  commander_name:SetStateText(info.Name)
  recruitment_cost:SetStateText(info.RecruitmentCost)
  command_rating:SetState(info.Attributes.PrimaryLevel)
  m_unique_id = info.UniqueId
  m_is_recruitable = info.IsRecruitable
  local info_pic = UIComponent(this:Find("portrait_PH"))
  local portrait = UIImage(info.InfoImage)
  portrait:SetComponentTexture(info_pic:Address(), 0)
  InitialiseTraits(info.Traits)
end

function InitialiseTraits(Traits)
  local trait_box = UIComponent(this:Find("traits_window"))
  if m_trait_entry == nil then
    m_trait_entry = trait_box:Find("character_trait_entry")
    local parent = UIComponent(m_trait_entry):Parent()
    UIComponent(parent):Divorce(m_trait_entry)
  end
  local trait_index = 1
  for s, v in ipairs(Traits) do
    if trait_index < 5 then
      out.dylan("adding trait")
      local c
      c = UIComponent(Component.CreateFromComponent(m_trait_entry, "trait_" .. v.Name, UIComponent(this:Find("trait_window" .. trait_index)):Address(), 0, 0, {}, {}))
      c:LuaCall("InitialiseTrait", v)
      trait_index = trait_index + 1
    else
      out.dylan("we have been given a commander to recruit that has more than 4 traits")
    end
  end
end

function CommanderPointer()
  return m_character_pointer
end

function Recruitable()
  return m_is_recruitable
end

function MakeEnlistmentInactive()
  this:SetState("inactive")
  portrait:SetState("inactive")
end

function OnClickUp()
  parent:LuaCall("SetSelectedCommander", m_unique_id)
end

this:SetEventCallback("OnMouseLClickUp", OnClickUp)

function UniqueID()
  return m_unique_id
end

function EnlistCommanderDestroyed()
  Component.Destroy(m_trait_entry)
end
