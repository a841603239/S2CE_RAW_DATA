local utils = require("CoreUtils")
local this = UIComponent(Address)
local mDropInInterface
local syncronising = false
local confirmed = false
local client_id
local sync_bar = UIComponent(this:Find("sync_bar_fill"))
local sync_bar_width = sync_bar:Width()
local time_string = UIComponent(this:Find("tx_time"))
local avatar = MPAvatar(CampaignUI.MPOnlinePresence())

function Initialise()
  confirmed = false
  this:InterfaceFunction("NotifyConfirm", confirmed)
  mDropInInterface = UIMPDropInInterface(CampaignUI.MultiplayerDropInInterface(), 1)
  time_string:SetState("time_remaining")
  UIComponent(this:Find("button_yes")):SetEventCallback("OnMouseLClickUp", AcceptDropIn)
  UIComponent(this:Find("button_not_now")):SetEventCallback("OnMouseLClickUp", DeclineDropIn)
  UIComponent(this:Find("Steam_icon")):SetVisible(false)
end

function OnDestroyed()
  out.tom("Releasing drop in interface")
  mDropInInterface:Release()
  mDropInInterface = nil
end

function AcceptDropIn()
  out.tom("Dropin accepted")
  confirmed = true
  this:InterfaceFunction("NotifyConfirm", confirmed)
  mDropInInterface:AcceptRemoteDropIn()
  FinaliseConfirm()
end

function DeclineDropIn()
  out.tom("Dropin declined")
  mDropInInterface:DeclineRemoteDropIn()
  NotifyPlayerDisconnected()
end

function FinaliseConfirm()
  UIComponent(this:Find("button_yes")):SetState("inactive")
  UIComponent(this:Find("button_not_now")):SetState("inactive")
  confirmed = true
  this:InterfaceFunction("NotifyConfirm", confirmed)
end

function UpdateCountdown(time)
  out.tom("Update countdown ", time)
  UIComponent(time_string:Find("dy_time")):SetStateText(time)
end

function NotifyPlayerJoined(id, name)
  UIComponent(this:Find("dy_name")):SetStateText(name)
  client_id = id
  this:InterfaceFunction("NotifyClientID", client_id)
  UIComponent(this:Find("Steam_icon")):SetVisible(true)
  if client_id ~= nil then
    avatar:RequestAvatarAndLoadFallback(id, this:Find("Steam_icon"), 0)
  end
end

function NotifyPlayerDisconnected()
  Component.Destroy(Address)
end

function NotifySyncStarted()
  syncronising = true
  this:InterfaceFunction("NotifySync", syncronising)
  time_string:SetVisible(false)
  UIComponent(this:Find("sync_bar_frame")):SetVisible(true)
  out.tom("Sync started")
end

function NotifySyncFinished()
  out.tom("Sync finished")
  syncronising = false
  this:InterfaceFunction("NotifySync", syncronising)
  time_string:SetVisible(true)
  time_string:SetState("time_to_start")
  UIComponent(this:Find("sync_bar_frame")):SetVisible(false)
end

this:SetEventCallback("OnDestroyed", OnDestroyed)
