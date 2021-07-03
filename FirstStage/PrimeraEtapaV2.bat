@echo off
title Primera parte
echo ----------------------------
echo Copiar carpeta base a n usuarios.
echo ----------------------------
pause>nul  
::Rutas
set CarpetaBase=%~dp0
echo %CarpetaBase%
cd ..
set CarpetaPivote=%cd%\Users\
echo %CarpetaPivote%
set CarpetaDestino=%CarpetaBase%Data\Specific\
echo %CarpetaDestino%
pause>nul
MD %CarpetaPivote%
pause>nul
for /L %%x in (1, 1, 3) do (
	echo %x
	xcopy %CarpetaBase% "%CarpetaPivote%User(%%x)\" /E
    
	cd "%CarpetaPivote%User(%%x)"
	::cd /D %~dp0
	call editaScript.bat %%x
)
cd %~dp0
pause>nul
::Copio las 20 copias de la carpeta base a la carpeta destino
xcopy %CarpetaPivote% %CarpetaDestino% /E
pause>nul
::Elimino la carpeta pivote
RMDIR /Q /S %CarpetaPivote%
pause>nul
exit

