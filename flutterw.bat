@echo off
setlocal
call "%~dp0..\flutterw.bat" %*
exit /b %ERRORLEVEL%
