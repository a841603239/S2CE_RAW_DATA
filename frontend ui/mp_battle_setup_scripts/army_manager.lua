local requesters = require("file_requesters")
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local m_CallbackInterface

function SetupEnumerator()
  return m_CallbackInterface:InterfaceFunction("EnumerateArmySetups")
end

function DeleteSelectedFiles(files)
  m_CallbackInterface:InterfaceFunction("DeleteSelectedFiles", files)
end

function ConfirmSave(success)
  root:LuaCall("ShowMessageBox", "", success == true and FrontEnd.LocalisationString("save_success") or FrontEnd.LocalisationString("save_fail"))
end

function CancelSave()
  root:LuaCall("HideMessageBox")
end

function SaveRequesterEnded(path)
  local confirm_overwrite, success = m_CallbackInterface:InterfaceFunction("SaveRequesterEnded", path, false)
  if confirm_overwrite == true then
    root:LuaCall("ShowMessageBox", FrontEnd.LocalisationString("overwrite_title"), FrontEnd.LocalisationString("overwrite_msg"), function()
      ConfirmSave(m_CallbackInterface:InterfaceFunction("SaveRequesterEnded", path, true))
    end, function()
      CancelSave()
    end)
  else
    ConfirmSave(success)
  end
end

function CreateSaveRequester(callbacks)
  m_CallbackInterface = UIComponent(callbacks)
  requesters.CreateRequester(root:Address(), false, "", "", SaveRequesterEnded, "save_army", SetupEnumerator)
  requesters.OverrideDeleteMethod(DeleteSelectedFiles)
end

function DeleteSelectedVeterans(title, msg)
  root:LuaCall("ShowMessageBox", title, msg, ConfirmVeteranDeletion, CancelVeteranDeletion)
end

function ConfirmVeteranDeletion()
  root:LuaCall("HideMessageBox")
  return this:InterfaceFunction("ConfirmVeteranDeletion")
end

function CancelVeteranDeletion()
  root:LuaCall("HideMessageBox")
  return this:InterfaceFunction("CancelVeteranDeletion")
end
