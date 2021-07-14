@echo off
setlocal enabledelayedexpansion

set "param1=%~1"
goto :param1Check
:param1Prompt
set /p "param1=Numero de usuario: "
:param1Check
if "%param1%"=="" goto :param1Prompt

::del funcionBasica.m
rem file name
::Set infile=file.txt
::Set infile=funcionBasicaPadre.m
Set infile=myStepFunctionTestingPadre.m
rem what to find
Set find=xxx

rem value to replace
Set replace=%param1%

for /F "tokens=* delims=," %%n in (!infile!) do (
set LINE=%%n
set TMPR=!LINE:%find%=%replace%!
Echo !TMPR!>>myStepFunctionTesting.m
)
type myStepFunctionTesting.m
del myStepFunctionTestingPadre.m
