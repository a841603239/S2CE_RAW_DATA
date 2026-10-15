local utilities = require("Utilities")
local this = UIComponent(Address)
local m_list = UIComponent(this:Find("popup_list"))
local m_menu = UIComponent(this:Find("popup_menu"))
local m_selected_txt = UIComponent(this:Find("dy_selected_txt"))
local m_selected_item, template
local template_y = 0
local border_height = UIComponent(m_menu:Find("border_top")):Height() + UIComponent(m_menu:Find("border_bottom")):Height()
local orig_list_width = m_list:Width()
g_notify_func = nil
this:SetProperty("RenderLastOnFocused", true)

function OnSelect()
  m_menu:PropagateVisibility(not m_menu:Visible())
end

function OnLoseFocus()
  m_menu:PropagateVisibility(false)
end

function OnDestroyed()
  if template ~= nil then
    Component.Destroy(template:Address())
    template = nil
  end
end

function SetOptions(options, preserve_selection_index, preserve_selection_data)
  m_selected_item = nil
  if template == nil then
    template = UIComponent(m_list:Find(0))
    _, template_y = utilities.OffsetFrom(m_list, template)
    m_list:Divorce(template:Address())
    this:SetEventCallback("OnDestroyed", OnDestroyed)
  end
  local x, y = 0, template_y
  m_list:DestroyChildren()
  local max_width = 0
  if options ~= nil then
    if type(options) == "table" then
      for i, v in ipairs(options) do
        local txt = v.Value
        local disabled = false
        if string.find(txt, "*") == 1 then
          txt = string.sub(txt, 2, #txt)
          disabled = true
        end
        local c = UIComponent(Component.CreateFromComponent(template:Address(), "option" .. m_list:ChildCount(), m_list:Address(), x, y, {}, {row_tx = txt}))
        c:SetGlobal("Data", v.Data)
        if disabled == true then
          c:SetState("inactive")
          c:SetDisabled(true)
          UIComponent(c:Find("row_tx")):SetStateColours(128, 128, 128, 128)
        end
        max_width = utilities.Max(max_width, c:Width())
        local c_x, c_y = c:Position()
        y = y + template:Height()
      end
    else
      for o in string.gmatch(options, "[^|]+") do
        local txt = o
        local disabled = false
        if string.find(txt, "*") == 1 then
          txt = string.sub(txt, 2, #txt)
          disabled = true
        end
        local c = UIComponent(Component.CreateFromComponent(template:Address(), "option" .. m_list:ChildCount(), m_list:Address(), x, y, {}, {row_tx = txt}))
        if disabled == true then
          c:SetState("inactive")
          c:SetDisabled(true)
          UIComponent(c:Find("row_tx")):SetStateColours(128, 128, 128, 128)
        end
        local c_x, c_y = c:Position()
        y = y + template:Height()
      end
    end
  end
  local listPosX, listPosY = m_list:Position()
  local max_y = 0
  local list_width = orig_list_width
  local screen_width, screen_height = Component.RootDimensions()
  if screen_height < listPosY + y then
    local columns = 1
    local max_height = y + listPosY
    while screen_height <= max_height do
      columns = columns + 1
      items_per_column = utilities.RupToInt(m_list:ChildCount() / columns)
      max_height = listPosY + items_per_column * template:Height()
    end
    list_width = list_width * columns
    x, y = 0, template_y
    for i = 0, m_list:ChildCount() - 1 do
      if max_height < listPosY + y + template:Height() then
        if max_y < y then
          max_y = y
        end
        x = x + template:Width()
        y = template_y
      end
      UIComponent(m_list:Find(i)):MoveTo(listPosX + x, listPosY + y)
      y = y + template:Height()
    end
    for i = m_list:ChildCount(), items_per_column * columns - 1 do
      local c = UIComponent(Component.CreateFromComponent(template:Address(), "option" .. m_list:ChildCount(), m_list:Address(), x, y, {}, {row_tx = ""}))
      c:SetInteractive(false)
      y = y + template_y
    end
  else
    m_list:Resize(list_width, y, false)
    m_menu:Resize(m_list:Width(), m_list:Height() + border_height, false)
  end
  m_list:Resize(list_width, max_y, false)
  m_menu:Resize(list_width, m_list:Height() + border_height, false)
  UIComponent(m_menu:Find("border_top")):Resize(list_width, border_height, false)
  UIComponent(m_menu:Find("border_bottom")):Resize(list_width, border_height, false)
  local thisX, thisY = this:Position()
  local menuX, menuY = m_menu:Position()
  if screen_width < thisX + list_width then
    m_menu:MoveTo(thisX + this:Width() - list_width, menuY)
  else
    m_menu:MoveTo(thisX, menuY)
  end
  local total_options = m_list:ChildCount()
  if 0 < total_options then
    local selected = false
    if preserve_selection_data ~= nil and 0 < #preserve_selection_data then
      selected = SelectOptionByDataValue(preserve_selection_data)
    elseif preserve_selection_index ~= nil then
      selected = SelectOption(m_list:Find(preserve_selection_index))
    end
    if selected == false then
      SelectOption(m_list:Find(0))
    end
  end
  return total_options
end

function SetOptionsNoneSelected(options)
  m_selected_item = nil
  if template == nil then
    template = UIComponent(m_list:Find(0))
    _, template_y = utilities.OffsetFrom(m_list, template)
    m_list:Divorce(template:Address())
    this:SetEventCallback("OnDestroyed", OnDestroyed)
  end
  local x, y = 0, template_y
  m_list:DestroyChildren()
  local max_width = 0
  if options ~= nil then
    if type(options) == "table" then
      for i, v in ipairs(options) do
        local txt = v.Value
        local disabled = false
        if string.find(txt, "*") == 1 then
          txt = string.sub(txt, 2, #txt)
          disabled = true
        end
        local c = UIComponent(Component.CreateFromComponent(template:Address(), "option" .. m_list:ChildCount(), m_list:Address(), x, y, {}, {row_tx = txt}))
        c:SetGlobal("Data", v.Data)
        if disabled == true then
          c:SetState("inactive")
          c:SetDisabled(true)
          UIComponent(c:Find("row_tx")):SetStateColours(128, 128, 128, 128)
        end
        max_width = utilities.Max(max_width, c:Width())
        local c_x, c_y = c:Position()
        y = y + template:Height()
      end
    else
      for o in string.gmatch(options, "[^|]+") do
        local txt = o
        local disabled = false
        if string.find(txt, "*") == 1 then
          txt = string.sub(txt, 2, #txt)
          disabled = true
        end
        local c = UIComponent(Component.CreateFromComponent(template:Address(), "option" .. m_list:ChildCount(), m_list:Address(), x, y, {}, {row_tx = txt}))
        if disabled == true then
          c:SetState("inactive")
          c:SetDisabled(true)
          UIComponent(c:Find("row_tx")):SetStateColours(128, 128, 128, 128)
        end
        local c_x, c_y = c:Position()
        y = y + template:Height()
      end
    end
  end
  local listPosX, listPosY = m_list:Position()
  local max_y = 0
  local list_width = orig_list_width
  local screen_width, screen_height = Component.RootDimensions()
  if screen_height < listPosY + y then
    local columns = 1
    local max_height = y + listPosY
    while screen_height <= max_height do
      columns = columns + 1
      items_per_column = utilities.RupToInt(m_list:ChildCount() / columns)
      max_height = listPosY + items_per_column * template:Height()
    end
    list_width = list_width * columns
    x, y = 0, template_y
    for i = 0, m_list:ChildCount() - 1 do
      if max_height < listPosY + y + template:Height() then
        if max_y < y then
          max_y = y
        end
        x = x + template:Width()
        y = template_y
      end
      UIComponent(m_list:Find(i)):MoveTo(listPosX + x, listPosY + y)
      y = y + template:Height()
    end
    for i = m_list:ChildCount(), items_per_column * columns - 1 do
      local c = UIComponent(Component.CreateFromComponent(template:Address(), "option" .. m_list:ChildCount(), m_list:Address(), x, y, {}, {row_tx = ""}))
      c:SetInteractive(false)
      y = y + template_y
    end
  else
    m_list:Resize(list_width, y, false)
    m_menu:Resize(m_list:Width(), m_list:Height() + border_height, false)
  end
  m_list:Resize(list_width, max_y, false)
  m_menu:Resize(list_width, m_list:Height() + border_height, false)
  UIComponent(m_menu:Find("border_top")):Resize(list_width, border_height, false)
  UIComponent(m_menu:Find("border_bottom")):Resize(list_width, border_height, false)
  local thisX, thisY = this:Position()
  local menuX, menuY = m_menu:Position()
  if screen_width < thisX + list_width then
    m_menu:MoveTo(thisX + this:Width() - list_width, menuY)
  else
    m_menu:MoveTo(thisX, menuY)
  end
  local total_options = m_list:ChildCount()
  return total_options
end

function SelectOptionByDataValue(option)
  for i = 0, m_list:ChildCount() - 1 do
    local child = m_list:Find(i)
    local datum = UIComponent(child):GlobalExists("Data")
    if datum ~= nil and datum == option then
      SelectOption(child)
      return true
    end
  end
  return false
end

function SelectOption(item)
  local c
  if type(item) == "number" then
    if item < m_list:ChildCount() then
      c = UIComponent(m_list:Find(item))
    end
  elseif type(item) == "string" then
    for i = 0, m_list:ChildCount() - 1 do
      c = UIComponent(m_list:Find(i))
      if UIComponent(c:Find(0)):GetStateText() == item then
        break
      end
    end
  else
    c = UIComponent(item)
  end
  if c ~= nil and c:IsInteractive() == true then
    if m_selected_item ~= nil then
      UIComponent(m_selected_item):SetState("unselected")
    end
    c:SetState("selected")
    local txt = UIComponent(c:Find(0))
    local s = txt:GetStateText()
    m_selected_item = c:Address()
    utilities.FitTextToComponent(this, "dy_selected_txt", s)
    local selected_index, selected_txt, selected_data = SelectedOption()
    if g_notify_func ~= nil then
      g_notify_func(Address, selected_index, selected_txt, selected_data)
    end
    this:InterfaceFunction("NotifySelected", selected_index, selected_data)
    return true
  end
  m_menu:PropagateVisibility(false)
  return false
end

function SelectedOption()
  for i = 0, m_list:ChildCount() - 1 do
    if m_list:Find(i) == m_selected_item then
      return i, m_selected_txt:GetStateText(), UIComponent(m_selected_item):GlobalExists("Data")
    end
  end
  return -1, m_selected_txt:GetStateText()
end
