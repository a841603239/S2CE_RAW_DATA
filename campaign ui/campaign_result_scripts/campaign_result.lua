local utils = require("CoreUtils")
local message_handler = MessageManager
local this = UIComponent(Address)
local this_name = "campaign_result"
local reult_title = UIComponent(this:Find("title_frame"))

function InitialiseCampaignResultPanel(result_string)
  reult_title:SetStateText(result_string)
end

function ExitGame()
  out.dylan("ExitGame")
  CampaignUI.QuitToMainScreen()
  CloseThisWindow()
end

function ContinueGame()
  out.dylan("ContinueGame")
  CampaignUI.ContinueGameSelected()
  CloseThisWindow()
  message_handler.CheckForAutoOpen(true)
end

function CloseThisWindow()
  out.dylan("CloseThisWindow")
  Component.Call("Root.LuaCall", "RemoveCampaignResultPopup")
end
