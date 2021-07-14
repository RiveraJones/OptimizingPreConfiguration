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

::creo el path para mi la extraccion de users training
set usersTraining=%cd%\carpetaDataset\training\
echo %usersTraining%

::creo el path para mi la extraccion de users testing
set usersTesting=%cd%\carpetaDataset\testing\
echo %usersTesting%

::pause>nul

::copias de carpeta base training
for /L %%x in (1, 1, 3) do (
	echo %x
	xcopy %CarpetaBase% "%newDataTraining%User%%x\" /E
	
	xcopy "%usersTraining%User%%x\" "%newDataTraining%User%%x\Data\Specific\User%%x\" /E
	
	cd "%newDataTraining%User%%x"
	::cd /D %~dp0
	call editMyResetFunction.bat %%x
	call editMyResetFunctionTesting.bat %%x
	call editMyStepFunctionTesting.bat %%x
)

::copias de carpeta base a testing
for /L %%x in (1, 1, 3) do (
	echo %x
	xcopy %CarpetaBase% "%newDataTesting%User%%x\" /E
	
	xcopy "%usersTesting%User%%x\" "%newDataTesting%User%%x\Data\Specific\User%%x\" /E
	
	cd "%newDataTesting%User%%x"
	::cd /D %~dp0
	call editMyResetFunction.bat %%x
	call editMyResetFunctionTesting.bat %%x
	call editMyStepFunctionTesting.bat %%x
	ren "%newDataTraining%User%%x\results_test_eval.mat" results_test_eval%%x.mat
)
exit
