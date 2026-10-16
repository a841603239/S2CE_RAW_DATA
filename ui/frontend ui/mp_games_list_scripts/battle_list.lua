local utils = require("Utilities")
local requesters = utils.Require("file_requesters")
local this = UIComponent(Address)

function ViewReplays()
  local ext, path = FrontEnd.FileExtenstionAndPathForWriteClass("replays")
  requesters.CreateRequester(this:Parent("mp_games_list"), true, path, ext, LoadReplay, FrontEnd.UILocalisationString("button_txt_NewState_Text_2e0063"), FrontEnd.EnumerateBattleReplays)
end

function LoadReplay(path, file)
  if FrontEnd.LoadBattleReplay(file) == false then
    UIComponent(Component.Root()):LuaCall("ShowMessageBox", "", FrontEnd.LocalisationString("load_fail"))
  end
end
