local this = UIComponent(Address)

function Initialise(details, bg)
  UIComponent(UIComponent(this:Find("TX_university")):Find(0)):SetStateText(details.University)
  local researched = UIComponent(this:Find("TX_research_complete"))
  UIComponent(researched:Find("DY_tech_name")):SetStateText(details.SubTitle)
  details.Researched.FactionKey = details.FactionKey
  local c = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/tech_icon", "tech", researched:Find("icon_placeholder"), -4, -2, {
    "{tech:1}" .. details.Researched.IconFilename
  }))
  c:LuaCall("Initialise", this, details.Researched)
  local next = UIComponent(this:Find("TX_next_technology"))
  if details.Next ~= nil then
    details.Next.FactionKey = details.FactionKey
    UIComponent(next:Find("DY_next_technology")):SetStateText(details.Next.Name)
    local c = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/tech_icon", "tech", next:Find("icon_placeholder"), -4, -2, {
      "{tech:1}" .. details.Next.IconFilename
    }))
    c:LuaCall("Initialise", this, details.Next, nil, details.Turns)
  else
    next:SetVisible(false)
  end
end

function TechAvailable()
  return true
end

function TechDisplayOnly()
  return true
end
