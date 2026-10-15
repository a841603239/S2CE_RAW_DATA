local this = UIComponent(Address)

function HandleDrop(items)
  for i, v in ipairs(items) do
    out.tom(UIComponent(v.Address):GlobalExists("ComponentType"))
    v.Handled = UIComponent(v.Address):GlobalExists("ComponentType") ~= "MinisterCard"
  end
  return items
end
