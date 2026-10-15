module((...), package.seeall)
local utils = require("Utilities")
local prefs_manager, current_options, prefs_setters, g_callbacks
local set_functions = {
  game = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last then
      prefs_manager:SetGameOptions(next)
      if g_callbacks.game ~= nil then
        g_callbacks.game(next)
      end
      return next
    end
  end,
  audio = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last then
      prefs_manager:SetAudioOptions(next)
      if g_callbacks.audio ~= nil then
        g_callbacks.audio(next)
      end
      return next
    end
  end,
  graphics = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last then
      prefs_manager:SetGraphicsOptions(next)
      if g_callbacks.graphics ~= nil then
        g_callbacks.graphics(next)
      end
      return next
    end
  end,
  ui = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last then
      prefs_manager:SetUIOptions(next)
      if g_callbacks.ui ~= nil then
        g_callbacks.ui(next)
      end
      return next
    end
  end,
  gamma = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last then
      prefs_manager:SetGammaOptions(next)
      if g_callbacks.gamma ~= nil then
        g_callbacks.gamma(next)
      end
      return next
    end
  end,
  voicechat = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last then
      prefs_manager:SetVoiceChatOptions(next)
      if g_callbacks.voicechat ~= nil then
        g_callbacks.voicechat(next)
      end
      return next
    end
  end,
  controls = function(last, next)
    setmetatable(next, getmetatable(last))
    if next ~= last or next.ChangedKeys ~= nil and #next.ChangedKeys > 0 then
      prefs_manager:SetControlOptions(next)
      if g_callbacks.controls ~= nil then
        g_callbacks.controls(next)
      end
      return next
    end
  end
}

function CreateManager(env, containers, callbacks)
  g_callbacks = callbacks ~= nil and callbacks or {}
  prefs_manager = UIPrefsInterface(env.RetrieveGameCore(), env.MultiplayerBaseInterface(), env.DropInInterface())
  prefs_setters = containers
  current_options = prefs_manager:CurrentOptions()
  if prefs_setters ~= nil then
    for k, v in pairs(prefs_setters) do
      v:LuaCall("Initialise", current_options[k], prefs_manager)
    end
  end
  return prefs_manager
end

function InitialisePrefsSetter(setter, mode, init_func)
  prefs_setters = {}
  prefs_setters[mode] = setter
  if init_func ~= nil then
    init_func(current_options[mode], prefs_manager)
  else
    setter:LuaCall("Initialise", current_options[mode], prefs_manager)
  end
end

function CancelChanges()
  for k, v in pairs(prefs_setters) do
    local o = v:LuaCall("GetCurrentOptions")
    setmetatable(o, getmetatable(current_options[k]))
    set_functions[k](o, current_options[k])
  end
end

function SetOptions()
  for k, v in pairs(prefs_setters) do
    local set = set_functions[k](current_options[k], v:LuaCall("GetCurrentOptions"))
    if set ~= nil then
      if k ~= "controls" then
        current_options[k] = set
      else
        utils.CopyIntoTable(set, current_options[k], "mapping")
        current_options[k].ChangedKeys = {}
      end
    end
  end
end
