module((...), package.seeall)
local utils = require("CoreUtils")
local Huds, panel_manager
local all_messages = {}
local root_address, shown_message, stack_base
local update_increment = 0
local icon_height = 64
local last_update_time = 0
local messages_stored = false
local override_autoopen = {}
local stack_base_adjustment = 0

local function RoundToInt(number)
  number = number + 0.5
  return number - number % 1
end

function OverrideAutoShow(msg_type, override)
  if override == true then
    override_autoopen[msg_type] = true
  elseif override == false then
    override_autoopen[msg_type] = false
  else
    override_autoopen[msg_type] = nil
  end
end

function ClearOverrides()
  override_autoopen = {}
end

function RegisterRootAddress(a, ui, hm, pm)
  Huds = hm
  panel_manager = pm
  root_address = a
  ReInitialiseStackbase(ui)
end

function ReInitialiseStackbase(ui, adjustment)
  if adjustment ~= nil then
    stack_base_adjustment = adjustment
  end
  local sw, sh = ui.ScreenSize()
  stack_base = sh
  local h_w, h_h = Huds.Dimensions()
  stack_base = stack_base - (h_h + icon_height + stack_base_adjustment)
  if sw > h_w + icon_height then
    stack_base = sh - icon_height
  end
end

function ShowingMessage(addr)
  shown_message = addr
end

function HidingMessage(addr)
  out.tom("HidingMessage Called \n")
  if addr == shown_message then
    shown_message = nil
  end
end

function ShowMessage(details, env)
  if override_autoopen[details.Event] ~= nil then
    if override_autoopen[details.Event] then
      details.AutoShow = override_autoopen[details.Event]
    else
      return
    end
  end
  local msg = UIComponent(Component.CreateComponentFromTemplate("MessageIcon", "msg" .. #all_messages, root_address, 0, 0, {
    "{Icon:2}" .. details.Icon
  }))
  msg:LuaCall("Initialise", details, root_address, env)
  all_messages[#all_messages + 1] = {
    msg = msg,
    details = details,
    env = env.ID
  }
  local open_panel, side, at_top = panel_manager.IsPanelOpen("event_movie_panel")
  if details.AutoShow == true and shown_message == nil and (open_panel == nil or at_top == false) then
    msg:LuaCall("ShowMessage", details.RequiresResponse)
    shown_message = msg:Address()
  end
end

function StoreMessages()
  messages_stored = true
  for i, v in ipairs(all_messages) do
    v.read = v.msg:CurrentState() == "Read"
    v.msg = nil
  end
end

function HasMessagesStored()
  return messages_stored
end

function ShownMessage()
  return shown_message == nil
end

function PendingAutoShowMessage()
  for i, v in ipairs(all_messages) do
    if v.msg ~= nil and v.details.AutoShow == true and v.msg:LuaCall("WasRead") == false then
      return true
    end
  end
  return false
end

function ClearMessagesFromEnv(env)
  local i = #all_messages
  while 0 < i do
    local icon = all_messages[i]
    if icon.env == env.ID then
      if icon.msg ~= nil then
        icon.msg:LuaCall("Destroy", icon.msg:Address())
      end
      out.tom("Message @ index " .. i .. " (" .. icon.details.Title .. ") removed (in theory)")
      table.remove(all_messages, i)
    end
    i = i - 1
  end
  if defined.tom then
    out.tom("Remaining messages")
    for i, v in ipairs(all_messages) do
      out.tom(v.details.Title)
    end
  end
end

function RestoreMessages(env)
  for i, v in ipairs(all_messages) do
    if v.env == env.ID and v.msg == nil then
      out.tom("Reinstating stored message:", v.details.Title)
      v.msg = UIComponent(Component.CreateComponentFromTemplate("MessageIcon", "msg" .. i, root_address, 0, 0, {
        "{Icon:2}" .. v.details.Icon
      }))
      v.msg:LuaCall("Initialise", v.details, root_address, env)
      if v.read == true then
        v.msg:SetState("Read")
      end
    end
  end
  messages_stored = false
end

function Update(time, env)
  local target_height = 0
  local stack_height = 0
  local prev_icon_y = -icon_height
  for i, v in ipairs(all_messages) do
    if v.env == env.ID and v.msg then
      target_height = stack_base - stack_height
      local icon_x, icon_y = v.msg:Position()
      if target_height > icon_y then
        local update_time = (time - last_update_time) / 5
        icon_y = utils.RoundToInt(icon_y + update_increment + update_time)
        update_increment = update_time - utils.RoundToInt(update_time)
      elseif v.Moving == true then
        v.Moving = false
        env.TriggerMessageDropEvent()
      end
      if target_height < icon_y then
        icon_y = target_height
      end
      if 0 <= prev_icon_y and prev_icon_y >= icon_y + icon_height or prev_icon_y < 0 and prev_icon_y <= icon_y + icon_height then
        local current_x, current_y = v.msg:Position()
        v.Moving = current_y ~= icon_y
        v.msg:MoveTo(icon_x, icon_y)
      end
      prev_icon_y = icon_y
      stack_height = stack_height + icon_height
    end
  end
  last_update_time = time
end

function DismissAllMessages()
  local unclosed_messages = {}
  for i, v in ipairs(all_messages) do
    if v.msg:LuaCall("RequiresResponse") == false then
      v.msg:LuaCall("Destroy", v.msg:Address())
    else
      unclosed_messages[#unclosed_messages + 1] = v
      v.msg:Highlight(true)
    end
  end
  all_messages = unclosed_messages
  return #all_messages == 0
end

function HideMessage(msg)
  for i, v in ipairs(all_messages) do
    if v.msg ~= nil and v.msg:LuaCall("Destroy", msg) then
      table.remove(all_messages, i)
      break
    end
  end
  shown_message = nil
  CheckForAutoOpen()
end

function CheckForAutoOpen(force_reopen)
  for i, v in ipairs(all_messages) do
    if v.msg ~= nil and v.details.AutoShow == true and (force_reopen == true or v.msg:LuaCall("WasRead") == false) then
      v.msg:LuaCall("ShowMessage", v.details.RequiresResponse)
      shown_message = v.msg:Address()
      break
    end
  end
end

function HideAllMessages(hide)
  for i, v in ipairs(all_messages) do
    if v.msg ~= nil then
      v.msg:SetVisible(not hide)
    end
  end
end
