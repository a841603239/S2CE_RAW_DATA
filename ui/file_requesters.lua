module((...), package.seeall)
local utils = require("Utilities")
local requester, last_save_path, file_name, is_save, callback_func, parent, overwrite

function CreateRequester(p, is_load, directory, ext, callback, title, ...)
  is_save = not is_load
  callback_func = callback
  parent = p
  requester = UIComponent(Component.CreateFromLayout("data/ui/frontend ui/file_requester", "file_requester", parent))
  requester:LuaCall("Initialise", is_load, directory, ext, RequesterEnded, title, ...)
end

function OverrideDeleteMethod(deletor)
  if requester ~= nil then
    requester:SetGlobal("deletor", deletor)
  end
end

function RequesterEnded(accepted)
  if requester ~= nil then
    Component.Destroy(requester:Address())
  end
  if accepted == true then
    last_save_path, file_name = requester:LuaCall("PathName")
    if is_save and vfs.exists(last_save_path, "rb") ~= nil then
      overwrite = UIComponent(Component.CreateFromLayout("data/ui/frontend ui/message_box", "message_box", parent))
      overwrite:LuaCall("Initialise", FrontEnd.LocalisationString("overwrite_title"), FrontEnd.LocalisationString("overwrite_msg"), OverwriteConfirmationAccept, OverwriteConfirmationDecline)
      this:LockPriority(overwrite:Priority())
      return
    end
    callback_func(last_save_path, file_name)
  end
end

function OverwriteConfirmationAccept()
  callback_func(last_save_path, file_name)
  OverwriteConfirmationDecline()
end

function OverwriteConfirmationDecline()
  Component.Destroy(overwrite:Address())
  overwrite = nil
  this:UnLockPriority()
end

function LoadRequesterEnded(accepted)
  if requester ~= nil then
    Component.Destroy(requester:Address())
  end
  if accepted then
    local path, file = requester:LuaCall("PathName")
    local setup = utils.LoadTable(path)
    SetSelectedTeamFaction(setup.Faction)
    army_setup:LuaCall("NotifyFactionSelected", setup.Faction)
    army_box:LuaCall("SetSetup", setup)
  end
end
