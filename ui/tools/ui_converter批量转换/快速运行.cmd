@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

set "PYCMD="

rem 依次尝试 py / python / python3，找到能用的就用
where py >nul 2>nul && set "PYCMD=py"
if not defined PYCMD (
    where python >nul 2>nul && set "PYCMD=python"
)
if not defined PYCMD (
    where python3 >nul 2>nul && set "PYCMD=python3"
)

if not defined PYCMD (
    echo.
    echo [错误] 没有找到 Python，请先安装 Python 并加入 PATH。
    echo 下载地址: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

if not exist "gui_convert_ui.py" (
    echo.
    echo [错误] 当前目录下找不到 gui_convert_ui.py
    echo 请把本 bat 放到 gui_convert_ui.py 同一个目录里。
    echo.
    pause
    exit /b 1
)

echo 使用 %PYCMD% 启动 GUI ...
"%PYCMD%" gui_convert_ui.py

if errorlevel 1 (
    echo.
    echo [警告] 程序以错误码 %errorlevel% 退出。
    pause
)

endlocal