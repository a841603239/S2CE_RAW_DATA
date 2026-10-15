local this = UIComponent(Address)

function Initialise(details)
  UIComponent(this:Find("DY_name1")):SetStateText(details.Name)
  UIComponent(this:Find("DY_job1")):SetStateText(details.Title)
  if details.Sword > 0 then
    parent = this:Find("sword-placeholders")
    x = 0
    for n = 1, details.Sword do
      pip = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/skill_pip", "pip", parent, x, 0))
      pip:SetState("Sword")
      x = x + pip:Width()
    end
  end
  if 0 < details.Pistol then
    parent = this:Find("gun-placeholders")
    x = 0
    for n = 1, details.Pistol do
      pip = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/skill_pip", "pip", parent, x, 0))
      pip:SetState("Gun")
      x = x + pip:Width()
    end
  end
end
