function InitState()
  local visible = BattleUI.BattleEditorVisibleState()
  
  if visible == true then
    print("Battle editor is visible")
  else
    print("Battle editor is not visible")
  end
  UIComponent(Address):PropagateVisibility(visible)
end
