local compilerPath = PROJECT_PATH .. "binaries/LuaCompiler.retail.exe"
local outputPath = "%(FullPath)c"
local filePath = "%(FullPath)"
local compilerOption = " -o"
rule("LuaCompilerRule")
display("Lua")
fileextension(".lua")
buildmessage("Compiling %(Filename) ")
buildcommands(compilerPath .. compilerOption .. " \"" .. outputPath .. " \"" .. " \"" .. filePath .. " \"")
buildoutputs("Compiled")
project("UI_Pre")
kind("Utility")
location("./")
rules("LuaCompilerRule")
files("**.lua")
removefiles("**ui_premake5.lua")
dependson("LuaCompiler_Pre")
