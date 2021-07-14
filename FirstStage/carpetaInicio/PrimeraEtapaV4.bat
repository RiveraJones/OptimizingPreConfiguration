@echo off
title Primera parte
echo ----------------------------
echo Copiar carpeta base a n usuarios.
echo ----------------------------
::pause>nul
::Rutas
set CarpetaInicio=%~dp0
echo %CarpetaInicio%
set CarpetaBase=%CarpetaInicio%QNN_EMG_MAtlabV2.5\
echo %CarpetaBase%
::creo el path para mi carpeta newDataTraining
set newDataTraining=%cd%\newDataTraining\
echo %newDataTraining%
MD %newDataTraining%
::creo el path para mi carpeta newDataTesting
set newDataTesting=%cd%\newDataTesting\
echo %newDataTesting%
MD %newDataTesting%

::creo el path para mi carpeta newDataTesting
set newResults=%cd%\newDataTesting\results\
echo %newResults%
MD %newResults%

::creo el path para mi la extraccion de users training
set usersTraining=%cd%\EMG-EPN612Dataset\trainingJSON\
echo %usersTraining%

::creo el path para mi la extraccion de users testing
set usersTesting=%cd%\EMG-EPN612Dataset\testingJSON\
echo %usersTesting%

pause>nul

::copias de carpeta base training
for /L %%x in (1, 1, 3) do (
	echo %x
	xcopy %CarpetaBase% "%newDataTraining%user%%x\" /E
	
	xcopy "%usersTraining%user%%x\" "%newDataTraining%User%%x\Data\Specific\user%%x\" /E
	
	cd "%newDataTraining%user%%x"
	::cd /D %~dp0
	call editMyResetFunction.bat %%x
	call editMyResetFunctionTesting.bat %%x
	call editMyStepFunctionTesting.bat %%x
)

::copias de carpeta base a testing
for /L %%x in (1, 1, 3) do (
	echo %x
	xcopy %CarpetaBase% "%newDataTesting%user%%x\" /E
	
	xcopy "%usersTesting%user%%x\" "%newDataTesting%User%%x\Data\Specific\user%%x\" /E
	
	cd "%newDataTesting%user%%x"
	::cd /D %~dp0
	call editMyResetFunction.bat %%x
	call editMyResetFunctionTesting.bat %%x
	call editMyStepFunctionTesting.bat %%x
)
exit
