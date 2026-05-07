@echo off
setlocal
call "%~dp0..\dartw.bat" %*
exit /b %ERRORLEVEL%
